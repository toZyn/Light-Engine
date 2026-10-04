import hashlib
import http.client
import json
import os
import socket
import sys
import time
import unittest
from pathlib import Path
sys.path.insert(0,str(Path(__file__).resolve().parents[1]))
from PySide6.QtCore import QEvent, QPoint, QPointF, QRect, Qt, QTimer
from PySide6.QtGui import QMouseEvent
from PySide6.QtWidgets import QApplication, QMessageBox, QPushButton, QWidget
from PySide6.QtTest import QTest
from companion import Companion, unsupported_platform
from test_policy import TOKEN,png,bad_filter_png

class GUITests(unittest.TestCase):
    @classmethod
    def setUpClass(cls): cls.app=QApplication.instance() or QApplication(['overlay-native-test'])
    def setUp(self): self.companion=Companion(self.app,port=0)
    def tearDown(self):
        self.companion.shutdown();self.app.processEvents()
        if hasattr(self.companion,'shutdown_thread'):self.companion.shutdown_thread.join(4)
    def process(self):
        for _ in range(5):self.app.processEvents()
    def consent(self,allowed):
        timer=QTimer();timer.setInterval(10)
        def answer():
            dialog=self.app.activeModalWidget()
            if isinstance(dialog,QMessageBox):
                timer.stop();dialog.done(QMessageBox.Yes if allowed else QMessageBox.No)
        timer.timeout.connect(answer);timer.start()
        self.companion.policy.request_consent(TOKEN,'Native GUI fixture')
        self.process();timer.stop()
    def test_explicit_gui_denial_does_not_grant_pairing(self):
        self.consent(False);self.assertFalse(self.companion.policy.authorized(TOKEN))
        self.assertFalse(self.companion.overlay.isVisible())
    def test_native_transparency_original_pixels_geometry_and_hide(self):
        self.consent(True);self.assertTrue(self.companion.policy.authorized(TOKEN))
        original=png();result=self.companion.policy.submit(TOKEN,original,{'x':20,'y':30,'width':100,'height':100})
        self.assertFalse(result['displayed']);self.process()
        window=self.companion.overlay
        self.assertTrue(window.isVisible());self.assertTrue(window.testAttribute(Qt.WA_TranslucentBackground))
        self.assertTrue(window.windowFlags() & Qt.FramelessWindowHint)
        self.assertTrue(window.windowFlags() & Qt.WindowStaysOnTopHint)
        self.assertTrue(window.windowFlags() & Qt.WindowDoesNotAcceptFocus)
        self.assertEqual(window.source_bytes,original)
        self.assertEqual(window.source_sha256,hashlib.sha256(original).hexdigest())
        image=window.pixmap.toImage();self.assertEqual(image.pixelColor(0,0).getRgb(),(255,0,0,128))
        self.assertEqual(image.pixelColor(1,0).getRgb(),(0,255,0,255))
        self.assertEqual((window.x(),window.y(),window.width(),window.height()),(20,30,100,100))
        self.companion.policy.hide(TOKEN);self.process()
        self.assertFalse(window.isVisible());self.assertIsNone(window.source_bytes);self.assertTrue(window.pixmap.isNull())
    def test_queued_hide_blocks_old_image_and_user_stop_revokes_pairing(self):
        self.consent(True);self.companion.policy.submit(TOKEN,png(),{});self.companion.policy.hide(TOKEN);self.process()
        self.assertFalse(self.companion.overlay.isVisible())
        self.companion.policy.submit(TOKEN,png(),{});self.process();self.companion.overlay.close_button.click();self.process()
        self.assertFalse(self.companion.overlay.isVisible());self.assertFalse(self.companion.policy.authorized(TOKEN))
    def test_control_window_close_stops_overlay_and_keeps_no_tray_stop_reachable(self):
        self.consent(True);self.companion.policy.submit(TOKEN,png(),{});self.process()
        self.companion.controls.close();self.process()
        self.assertFalse(self.companion.policy.authorized(TOKEN));self.assertFalse(self.companion.overlay.isVisible())
        if not self.companion.tray_available:self.assertTrue(self.companion.controls.isVisible())
    def test_another_native_window_coexists_and_overlay_cannot_take_focus(self):
        other=QWidget();other.setWindowTitle('Another application window fixture');other.show();other.activateWindow();self.process()
        self.consent(True);other.activateWindow();self.process()
        self.companion.policy.submit(TOKEN,png(),{'x':100000,'y':-100000});self.process()
        window=self.companion.overlay;screen=window.screen().availableGeometry()
        self.assertTrue(other.isVisible());self.assertTrue(screen.contains(window.geometry()))
        self.assertNotEqual(self.app.activeWindow(),window)
        other.close()
    def test_wayland_is_explicitly_unsupported(self):
        original=os.environ.get('XDG_SESSION_TYPE')
        os.environ['XDG_SESSION_TYPE']='wayland'
        try:self.assertIn('Wayland',unsupported_platform(self.app))
        finally:
            if original is None:os.environ.pop('XDG_SESSION_TYPE',None)
            else:os.environ['XDG_SESSION_TYPE']=original
    def test_native_decoder_failure_releases_previous_image_before_owner_is_cleared(self):
        self.consent(True);self.companion.policy.submit(TOKEN,png(),{});self.process()
        self.assertTrue(self.companion.overlay.isVisible())
        # Exercise the final native decoding boundary even if validation catches
        # this PNG first; future Qt-specific rejection must not leave old pixels.
        self.companion.handle({'kind':'image','token':TOKEN,'revision':self.companion.policy.revision,
                               'bytes':bad_filter_png(),'sha256':'fixture','geometry':{}})
        self.assertFalse(self.companion.overlay.isVisible());self.assertIsNone(self.companion.overlay.source_bytes)
        self.assertIsNone(self.companion.policy.owner)
    def test_close_pending_session_dismisses_actual_consent_dialog_without_late_grant(self):
        timer=QTimer();timer.setInterval(10)
        failure=[];fallback=QTimer();fallback.setSingleShot(True)
        def release_fallback():
            dialog=self.app.activeModalWidget()
            if isinstance(dialog,QMessageBox):failure.append('release did not dismiss consent');dialog.reject()
        fallback.timeout.connect(release_fallback)
        def close_pending():
            dialog=self.app.activeModalWidget()
            if isinstance(dialog,QMessageBox):
                timer.stop()
                try:self.companion.policy.revoke(TOKEN)
                except Exception as error:failure.append(str(error));dialog.reject()
                fallback.start(1000)
        timer.timeout.connect(close_pending);timer.start()
        self.companion.policy.request_consent(TOKEN,'Closing script');self.process();timer.stop();fallback.stop()
        self.assertFalse(failure,str(failure))
        self.assertIsNone(self.app.activeModalWidget());self.assertFalse(self.companion.policy.authorized(TOKEN))
        self.assertTrue(self.companion.policy.request_consent(TOKEN,'Dead script')['denied'])
    def test_gui_shutdown_returns_promptly_with_an_incomplete_http_body(self):
        connection=socket.create_connection(self.companion.server.server_address,timeout=2)
        try:
            connection.sendall(b'POST /connect HTTP/1.0\r\nContent-Length: 8\r\n\r\n{')
            QTest.qWait(100);started=time.monotonic();self.companion.shutdown()
            self.assertLess(time.monotonic()-started,.2,'Shutdown blocked the Qt GUI thread')
        finally:connection.close()
    def test_explicit_quit_can_exit_the_native_event_loop_without_a_tray(self):
        button=next(b for b in self.companion.controls.findChildren(QPushButton) if b.text()=='Quit companion')
        guard=QTimer();guard.setSingleShot(True);guard.timeout.connect(lambda:self.app.exit(1));guard.start(1000)
        QTimer.singleShot(0,button.click)
        result=self.app.exec();guard.stop()
        self.assertEqual(result,0,'Explicit Quit was rejected by the persistent-controls close guard')
        self.assertTrue(self.companion.stopped)
    def test_drag_fits_smaller_target_bounds_without_changing_original_pixmap(self):
        self.consent(True);original=png();self.companion.policy.submit(TOKEN,original,{'width':200,'height':200});self.process()
        window=self.companion.overlay;pixmap=window.pixmap;bounds=QRect(0,0,80,60)
        class Target:
            def availableGeometry(self):return bounds
        original_screen=QApplication.screenAt;QApplication.screenAt=staticmethod(lambda point:Target())
        window.drag_offset=QPoint(0,0)
        try:
            event=QMouseEvent(QEvent.MouseMove,QPointF(10,10),QPointF(10,10),Qt.NoButton,Qt.LeftButton,Qt.NoModifier)
            window.mouseMoveEvent(event)
        finally:QApplication.screenAt=original_screen
        self.assertTrue(bounds.contains(window.geometry()),'Dragged overlay exceeds target monitor bounds')
        close=window.close_button.geometry().translated(window.pos())
        self.assertTrue(bounds.contains(close),'Close control became unreachable')
        self.assertIs(window.pixmap,pixmap);self.assertEqual(window.source_bytes,original)
        self.assertEqual(window.image_rect.width(),window.image_rect.height(),'Aspect ratio changed')
    def test_real_http_worker_queues_original_bytes_to_native_gui_and_hide(self):
        def request(method,path,body=None,headers=None):
            connection=http.client.HTTPConnection('127.0.0.1',self.companion.server.server_port,timeout=3)
            try:
                connection.request(method,path,body=body,headers=headers or {})
                response=connection.getresponse();return response.status,json.loads(response.read())
            finally:connection.close()
        status,result=request('POST','/connect',json.dumps({'token':TOKEN,'label':'HTTP GUI fixture'}))
        self.assertEqual(status,202);self.assertFalse(result['granted'])
        headers={'Authorization':'Bearer '+TOKEN}
        status,result=request('POST','/image',png(),headers)
        self.assertEqual(status,403);self.assertTrue(result['pending'])
        timer=QTimer();timer.setInterval(10)
        def answer():
            dialog=self.app.activeModalWidget()
            if isinstance(dialog,QMessageBox):timer.stop();dialog.done(QMessageBox.Yes)
        timer.timeout.connect(answer);timer.start();self.process();timer.stop()
        self.assertTrue(self.companion.policy.authorized(TOKEN))
        status,result=request('POST','/image?x=50&y=60',png(),headers)
        self.assertEqual(status,202);self.assertFalse(result['displayed']);self.process()
        self.assertTrue(self.companion.overlay.isVisible());self.assertEqual(self.companion.overlay.source_bytes,png())
        self.assertEqual(request('DELETE','/image',headers=headers)[0],202);self.process()
        self.assertFalse(self.companion.overlay.isVisible())

if __name__=='__main__':unittest.main()
