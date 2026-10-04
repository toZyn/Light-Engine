#!/usr/bin/env python3
"""Consented PNG overlay companion. Importing this module does not start or install it."""
import argparse
import http.client
import json
import os
import sys
import threading

from PySide6.QtCore import QObject, QPoint, QRect, Qt, Signal, Slot
from PySide6.QtGui import QAction, QImageReader, QPainter, QPixmap
from PySide6.QtWidgets import (QApplication, QLabel, QMenu, QMessageBox, QPushButton,
                             QStyle, QSystemTrayIcon, QVBoxLayout, QWidget)

from overlay_policy import OverlayPolicy, PolicyError, make_server, parse_uri

def unsupported_platform(app):
    if os.environ.get('XDG_SESSION_TYPE','').lower()=='wayland' or app.platformName().lower().startswith('wayland'):
        return 'Wayland does not provide a reliable cross-application topmost overlay. Use an X11 session or Windows.'
    if sys.platform not in ('linux','win32'):
        return 'This companion currently supports Windows and Linux X11 only.'
    if sys.platform=='linux' and app.platformName().lower()!='xcb':
        return 'A native Linux X11 desktop is required; offscreen and other Qt backends cannot provide this overlay.'
    return None

class Bridge(QObject):
    command=Signal(object)

class ControlsWindow(QWidget):
    def __init__(self,stop,tray_available):
        super().__init__();self.stop=stop;self.tray_available=tray_available
    def closeEvent(self,event):
        self.stop()
        if self.tray_available():event.accept()
        else:event.ignore()  # Quit remains explicit; keep Stop reachable without a tray.

class OverlayWindow(QWidget):
    def __init__(self,stop):
        super().__init__(None,Qt.Tool | Qt.FramelessWindowHint | Qt.WindowStaysOnTopHint | Qt.WindowDoesNotAcceptFocus)
        self.setAttribute(Qt.WA_TranslucentBackground)
        self.setAttribute(Qt.WA_ShowWithoutActivating)
        self.setFocusPolicy(Qt.NoFocus)
        self.setWindowTitle('Light Engine PNG overlay')
        self.pixmap=QPixmap();self.source_bytes=None;self.source_sha256=None
        self.image_rect=QRect();self.drag_offset=None;self.stop=stop
        self.close_button=QPushButton('×',self)
        self.close_button.setToolTip('Stop overlay and revoke pairing')
        self.close_button.setFocusPolicy(Qt.NoFocus)
        self.close_button.setStyleSheet('QPushButton { color: white; background: #333; border: 1px solid #eee; border-radius: 3px; font-size: 18px; }')
        self.close_button.clicked.connect(stop)

    def show_image(self,body,sha256,geometry):
        decoded=QPixmap()
        if not decoded.loadFromData(body,'PNG') or decoded.isNull():
            self.clear()
            return False,'Qt could not decode the supplied PNG.'
        primary=QApplication.primaryScreen()
        if primary is None:self.clear();return False,'No desktop monitor is available.'
        screen=QApplication.screenAt(QPoint(geometry.get('x',primary.availableGeometry().center().x()),
                                           geometry.get('y',primary.availableGeometry().center().y()))) or primary
        bounds=screen.availableGeometry()
        desired_w=geometry.get('width',decoded.width())
        desired_h=geometry.get('height',decoded.height())
        if 'width' in geometry and 'height' not in geometry:desired_h=round(desired_w*decoded.height()/decoded.width())
        if 'height' in geometry and 'width' not in geometry:desired_w=round(desired_h*decoded.width()/decoded.height())
        scale=min(desired_w/decoded.width(),desired_h/decoded.height(),bounds.width()/decoded.width(),bounds.height()/decoded.height())
        image_w,image_h=max(1,int(decoded.width()*scale)),max(1,int(decoded.height()*scale))
        width,height=max(24,image_w),max(24,image_h)
        width,height=min(width,bounds.width()),min(height,bounds.height())
        x=geometry.get('x',bounds.x()+(bounds.width()-width)//2)
        y=geometry.get('y',bounds.y()+(bounds.height()-height)//2)
        x=max(bounds.left(),min(x,bounds.right()-width+1));y=max(bounds.top(),min(y,bounds.bottom()-height+1))
        self.source_bytes,self.source_sha256,self.pixmap=body,sha256,decoded
        self.image_rect=QRect(0,0,image_w,image_h)
        self.setGeometry(x,y,width,height)
        self.close_button.setGeometry(max(0,width-22),0,22,22)
        self.show();self.update()
        return True,None

    def clear(self):
        self.hide();self.pixmap=QPixmap();self.source_bytes=None;self.source_sha256=None;self.image_rect=QRect()

    def fit_bounds(self,bounds):
        if self.image_rect.width()>bounds.width() or self.image_rect.height()>bounds.height():
            scale=min(bounds.width()/self.image_rect.width(),bounds.height()/self.image_rect.height())
            self.image_rect=QRect(0,0,max(1,int(self.image_rect.width()*scale)),max(1,int(self.image_rect.height()*scale)))
        width=min(bounds.width(),max(24,self.image_rect.width()))
        height=min(bounds.height(),max(24,self.image_rect.height()))
        self.resize(width,height)
        button_size=min(22,width,height)
        self.close_button.setGeometry(max(0,width-button_size),0,button_size,button_size)
        self.update()

    def paintEvent(self,event):
        if not self.pixmap.isNull():
            painter=QPainter(self)
            painter.setRenderHint(QPainter.SmoothPixmapTransform,self.image_rect.size()!=self.pixmap.size())
            painter.drawPixmap(self.image_rect,self.pixmap,self.pixmap.rect())

    def mousePressEvent(self,event):
        if event.button()==Qt.LeftButton:self.drag_offset=event.globalPosition().toPoint()-self.pos();event.accept()

    def mouseMoveEvent(self,event):
        if self.drag_offset is not None and event.buttons() & Qt.LeftButton:
            position=event.globalPosition().toPoint()-self.drag_offset
            screen=QApplication.screenAt(event.globalPosition().toPoint()) or self.screen()
            bounds=screen.availableGeometry()
            self.fit_bounds(bounds)
            # Keep the close control reachable while allowing movement to another monitor.
            position.setX(max(bounds.left(),min(position.x(),bounds.right()-self.width()+1)))
            position.setY(max(bounds.top(),min(position.y(),bounds.bottom()-self.height()+1)))
            self.move(position);event.accept()

    def mouseReleaseEvent(self,event):self.drag_offset=None
    def closeEvent(self,event):self.stop();event.ignore()

class Companion(QObject):
    def __init__(self,app,port=51874):
        super().__init__()
        self.app=app;self.stopped=False
        self.consent_dialog=None;self.consent_token=None
        QImageReader.setAllocationLimit(64)
        self.bridge=Bridge()
        self.policy=OverlayPolicy(self.bridge.command.emit,unsupported=unsupported_platform(app))
        self.overlay=OverlayWindow(self.stop_overlay)
        self.bridge.command.connect(self.handle,Qt.QueuedConnection)
        self.controls=ControlsWindow(self.stop_overlay,lambda:self.tray_available)
        self.controls.setWindowTitle('Light Engine overlay companion')
        layout=QVBoxLayout(self.controls)
        self.status_label=QLabel('Only paired addons can show an image.\nStop revokes pairing and removes the overlay.')
        layout.addWidget(self.status_label)
        stop=QPushButton('Stop overlay and revoke pairing');stop.clicked.connect(self.stop_overlay);layout.addWidget(stop)
        quit_button=QPushButton('Quit companion');quit_button.clicked.connect(self.quit_companion);layout.addWidget(quit_button)
        self.tray=QSystemTrayIcon(app.style().standardIcon(QStyle.SP_DesktopIcon),self)
        self.tray.setToolTip('Light Engine PNG overlay — Stop is always available')
        menu=QMenu()
        for text,callback in [('Controls',self.controls.show),('Stop overlay',self.stop_overlay),('Quit',self.quit_companion)]:
            action=QAction(text,menu);action.triggered.connect(callback);menu.addAction(action)
        self.tray.setContextMenu(menu);self.tray_menu=menu
        self.tray_available=QSystemTrayIcon.isSystemTrayAvailable()
        if self.tray_available:self.tray.show()
        else:self.controls.show()  # Keep a stop control available without a tray host.
        self.server=make_server(self.policy,port)
        self.thread=threading.Thread(target=lambda:self.server.serve_forever(poll_interval=.05),name='overlay-loopback',daemon=True)
        self.thread.start()
        app.aboutToQuit.connect(self.shutdown)

    @Slot(object)
    def handle(self,event):
        if self.stopped:return
        if event['kind']=='consent':
            if self.policy.pending_token!=event['token']:return
            token=event['token']
            dialog=QMessageBox(QMessageBox.Question,'Allow PNG overlay?',
                              f"Allow {event['label']} to show PNG images above other applications?\n\n"
                              f"Pairing fingerprint: {token[:8]}…{token[-8:]}\n"
                              'The overlay is draggable. Close × or use Stop to revoke access.',
                              QMessageBox.Yes | QMessageBox.No,self.controls)
            dialog.setDefaultButton(QMessageBox.No)
            self.consent_dialog,self.consent_token=dialog,token
            allowed=dialog.exec()==QMessageBox.Yes
            self.consent_dialog,self.consent_token=None,None
            self.policy.finish_consent(token,allowed)
        elif event['kind']=='cancel_consent':
            if self.consent_dialog and self.consent_token==event['token']:self.consent_dialog.reject()
        elif event['kind']=='image':
            if not self.policy.current(event['token'],event['revision']):return
            success,reason=self.overlay.show_image(event['bytes'],event['sha256'],event['geometry'])
            self.policy.finish_image(event['revision'],success,reason)
            if not success:
                self.status_label.setText('Overlay image rejected: '+reason)
                self.controls.show()
        elif event['kind']=='hide':
            if event['revision']==self.policy.revision:self.overlay.clear()

    def stop_overlay(self):
        self.policy.stop();self.overlay.clear()

    def quit_companion(self):
        self.shutdown();self.app.quit()

    def shutdown(self):
        if self.stopped:return
        self.stopped=True;self.policy.stop(close=True);self.overlay.clear()
        if self.consent_dialog:self.consent_dialog.reject()
        self.tray.hide();self.controls.hide()
        self.server.interrupt_request()
        def close_server():
            self.server.shutdown();self.server.server_close();self.thread.join(4)
        self.shutdown_thread=threading.Thread(target=close_server,name='overlay-shutdown',daemon=True)
        self.shutdown_thread.start()

def forward_pairing(token,label,port=51874):
    connection=http.client.HTTPConnection('127.0.0.1',port,timeout=3)
    try:
        connection.request('POST','/connect',json.dumps({'token':token,'label':label}),{'Content-Type':'application/json'})
        response=connection.getresponse();body=response.read(4096)
        if response.status not in (200,202):raise PolicyError('The running companion rejected pairing: '+body.decode(errors='replace'),response.status)
        return json.loads(body)
    finally:connection.close()

def main():
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--uri',help='lightengine-overlay://connect pairing request')
    args=parser.parse_args()
    try:pair=parse_uri(args.uri) if args.uri else None
    except (PolicyError,ValueError) as error:parser.error(str(error))
    if pair:
        try:forward_pairing(*pair);return 0
        except OSError:pass  # Start a companion if no instance is listening.
        except PolicyError as error:print(str(error),file=sys.stderr);return 1
    if sys.platform=='linux' and os.environ.get('XDG_SESSION_TYPE','').lower()=='wayland':
        print('Wayland is unsupported for this cross-application overlay. Use Linux X11 or Windows.',file=sys.stderr);return 1
    if sys.platform=='linux' and not os.environ.get('DISPLAY'):
        print('No native X11 display is available for the overlay companion.',file=sys.stderr);return 1
    app=QApplication([sys.argv[0]])
    app.setQuitOnLastWindowClosed(False)
    try:companion=Companion(app)
    except OSError as error:QMessageBox.warning(None,'Companion could not start',str(error));return 1
    if pair:
        try:companion.policy.request_consent(*pair)
        except PolicyError as error:QMessageBox.warning(companion.controls,'Overlay unavailable',str(error))
    try:return app.exec()
    finally:companion.shutdown()

if __name__=='__main__':raise SystemExit(main())
