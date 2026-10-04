package com.zyn.lightengine.overlay;

import android.app.Notification;
import android.app.NotificationChannel;
import android.app.NotificationManager;
import android.app.PendingIntent;
import android.app.Service;
import android.content.Intent;
import android.content.pm.ServiceInfo;
import android.content.res.Configuration;
import android.graphics.Bitmap;
import android.graphics.BitmapFactory;
import android.graphics.Color;
import android.graphics.PixelFormat;
import android.os.Build;
import android.os.Handler;
import android.os.IBinder;
import android.os.Looper;
import android.provider.Settings;
import android.util.DisplayMetrics;
import android.util.Log;
import android.view.Gravity;
import android.view.MotionEvent;
import android.view.View;
import android.view.WindowManager;
import android.widget.FrameLayout;
import android.widget.ImageView;
import android.widget.TextView;
import android.widget.Toast;
import java.util.concurrent.ArrayBlockingQueue;
import java.util.concurrent.Future;
import java.util.concurrent.ThreadPoolExecutor;
import java.util.concurrent.TimeUnit;

/** One user-approved, transparent image window. No game rendering or background restart. */
public final class OverlayService extends Service {
    static final String SHOW = "com.zyn.lightengine.overlay.SHOW";
    static final String HIDE = "com.zyn.lightengine.overlay.HIDE";
    static final String STOP = "com.zyn.lightengine.overlay.STOP";
    private static final String CHANNEL = "image-overlay";
    private static final int NOTIFICATION = 1;
    private final Handler main = new Handler(Looper.getMainLooper());
    private final OverlaySession session = new OverlaySession();
    private final Object resultLock = new Object();
    private final ThreadPoolExecutor decoder = new ThreadPoolExecutor(1, 1, 0, TimeUnit.MILLISECONDS,
        new ArrayBlockingQueue<Runnable>(1), task -> new Thread(task, "image-overlay-decode"));
    private Future<?> decodeTask;
    private long loadGeneration;
    private boolean destroyed;
    private Bitmap pendingBitmap, shownBitmap;
    private FrameLayout frame;
    private ImageView image;
    private TextView close;
    private OverlayRequest displayedRequest;
    private WindowManager windows;
    private WindowManager.LayoutParams layout;
    private int screenWidth, screenHeight;
    private final Runnable permissionWatch = new Runnable() {
        @Override public void run() {
            if (!Settings.canDrawOverlays(OverlayService.this)) { stopOverlay(); return; }
            main.postDelayed(this, 1000);
        }
    };

    @Override public void onCreate() {
        super.onCreate(); windows = (WindowManager)getSystemService(WINDOW_SERVICE);
        NotificationManager manager = (NotificationManager)getSystemService(NOTIFICATION_SERVICE);
        manager.createNotificationChannel(new NotificationChannel(CHANNEL, "Image overlay", NotificationManager.IMPORTANCE_LOW));
        refreshDisplayBounds();
    }

    @Override public int onStartCommand(Intent intent, int flags, int startId) {
        if (intent == null) { stopOverlay(); return START_NOT_STICKY; }
        if (STOP.equals(intent.getAction())) { stopOverlay(); return START_NOT_STICKY; }
        if (HIDE.equals(intent.getAction())) {
            if (session.hide(intent.getStringExtra("token"))) stopOverlay();
            else if (decodeTask == null && frame == null) stopSelf();
            return START_NOT_STICKY;
        }
        if (!SHOW.equals(intent.getAction()) || !Settings.canDrawOverlays(this)) { stopOverlay(); return START_NOT_STICKY; }
        final OverlayRequest request;
        try {
            request = OverlayRequest.showBytes(intent.getStringExtra("token"), intent.getByteArrayExtra("png"),
                intent.getIntExtra("x", 0), intent.getIntExtra("y", 0), intent.getIntExtra("width", 0),
                intent.getIntExtra("height", 0), intent.getStringExtra("label"));
        } catch (IllegalArgumentException error) {
            fail("Invalid image request", error); return START_NOT_STICKY;
        }
        // Only this app's consent Activity can start the unexported SHOW service.
        long consentGeneration = session.request(request); session.consent(consentGeneration);
        if (!session.activate(consentGeneration, Settings.canDrawOverlays(this))) { stopOverlay(); return START_NOT_STICKY; }
        try {
            Notification notification = notification(request.label);
            if (Build.VERSION.SDK_INT >= 34) startForeground(NOTIFICATION, notification, ServiceInfo.FOREGROUND_SERVICE_TYPE_SPECIAL_USE);
            else startForeground(NOTIFICATION, notification);
        } catch (RuntimeException error) {
            fail("Android declined the foreground image overlay", error); return START_NOT_STICKY;
        }
        main.removeCallbacks(permissionWatch); main.post(permissionWatch);
        cancelDecode();
        final long expected;
        synchronized (resultLock) { expected = loadGeneration; }
        final boolean draggable = intent.getBooleanExtra("draggable", true);
        try { decodeTask = decoder.submit(() -> decode(request, expected, draggable)); }
        catch (java.util.concurrent.RejectedExecutionException error) { fail("Image decoder is unavailable", error); }
        return START_NOT_STICKY;
    }

    private Notification notification(String label) {
        Intent stop = new Intent(this, OverlayService.class).setAction(STOP);
        PendingIntent stopAction = PendingIntent.getService(this, 1, stop, PendingIntent.FLAG_UPDATE_CURRENT | PendingIntent.FLAG_IMMUTABLE);
        PendingIntent open = PendingIntent.getActivity(this, 2, new Intent(this, OverlayActivity.class),
            PendingIntent.FLAG_UPDATE_CURRENT | PendingIntent.FLAG_IMMUTABLE);
        return new Notification.Builder(this, CHANNEL).setSmallIcon(android.R.drawable.ic_menu_gallery)
            .setContentTitle("Image overlay active").setContentText(label.isEmpty() ? "Tap Stop or the image's × to remove it" : label)
            .setContentIntent(open).setOngoing(true).setCategory(Notification.CATEGORY_SERVICE)
            .addAction(new Notification.Action.Builder(android.R.drawable.ic_menu_close_clear_cancel, "Stop", stopAction).build()).build();
    }

    private void decode(OverlayRequest request, long expected, boolean draggable) {
        Bitmap bitmap = null;
        try {
            BitmapFactory.Options bounds = new BitmapFactory.Options(); bounds.inJustDecodeBounds = true;
            BitmapFactory.decodeByteArray(request.png, 0, request.png.length, bounds);
            if (bounds.outWidth != request.imageWidth || bounds.outHeight != request.imageHeight || !"image/png".equals(bounds.outMimeType)) {
                throw new IllegalArgumentException("PNG decoder rejected the original image");
            }
            synchronized (resultLock) { if (destroyed || expected != loadGeneration) return; }
            BitmapFactory.Options options = new BitmapFactory.Options(); options.inPreferredConfig = Bitmap.Config.ARGB_8888;
            options.inScaled = false; options.inSampleSize = 1;
            bitmap = BitmapFactory.decodeByteArray(request.png, 0, request.png.length, options);
            if (bitmap == null) throw new IllegalArgumentException("PNG could not be decoded");
            synchronized (resultLock) {
                if (destroyed || expected != loadGeneration) { recycle(bitmap); return; }
                recycle(pendingBitmap); pendingBitmap = bitmap;
                main.post(() -> consumeDecoded(request, expected, draggable));
            }
        } catch (RuntimeException | OutOfMemoryError error) {
            recycle(bitmap);
            main.post(() -> {
                synchronized (resultLock) { if (destroyed || expected != loadGeneration) return; }
                fail("Image overlay could not decode this PNG", error);
            });
        }
    }

    private void consumeDecoded(OverlayRequest request, long expected, boolean draggable) {
        Bitmap bitmap;
        synchronized (resultLock) {
            if (destroyed || expected != loadGeneration) return;
            bitmap = pendingBitmap; pendingBitmap = null;
        }
        if (bitmap == null) return;
        if (!Settings.canDrawOverlays(this)) { recycle(bitmap); stopOverlay(); return; }
        removeWindow();
        refreshDisplayBounds();
        int closeSize = closeSize();
        OverlayGeometry fit = OverlayGeometry.fit(request.width, request.height, closeSize, screenWidth, screenHeight, request.x, request.y);
        layout = new WindowManager.LayoutParams(fit.width, fit.height, WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY,
            WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE | WindowManager.LayoutParams.FLAG_NOT_TOUCH_MODAL, PixelFormat.TRANSLUCENT);
        layout.gravity = Gravity.TOP | Gravity.LEFT;
        layout.x = fit.x; layout.y = fit.y;
        frame = new FrameLayout(this); frame.setBackgroundColor(Color.TRANSPARENT);
        image = new ImageView(this); image.setScaleType(ImageView.ScaleType.FIT_CENTER);
        image.setContentDescription(request.label.isEmpty() ? "Overlay image" : request.label);
        image.setImageBitmap(bitmap); shownBitmap = bitmap;
        frame.addView(image, new FrameLayout.LayoutParams(fit.imageWidth, fit.imageHeight, Gravity.TOP | Gravity.LEFT));
        close = new TextView(this); close.setText("×"); close.setTextSize(30); close.setGravity(Gravity.CENTER);
        close.setTextColor(Color.WHITE); close.setShadowLayer(3, 0, 0, Color.BLACK); close.setContentDescription("Close image overlay");
        close.setOnClickListener(v -> stopOverlay());
        frame.addView(close, new FrameLayout.LayoutParams(closeSize, closeSize, Gravity.TOP | Gravity.RIGHT));
        displayedRequest = request;
        if (draggable) image.setOnTouchListener(new View.OnTouchListener() {
            private float startX, startY; private int windowX, windowY;
            @Override public boolean onTouch(View view, MotionEvent event) {
                if (event.getActionMasked() == MotionEvent.ACTION_DOWN) {
                    startX = event.getRawX(); startY = event.getRawY(); windowX = layout.x; windowY = layout.y; return true;
                }
                if (event.getActionMasked() == MotionEvent.ACTION_MOVE) {
                    layout.x = clamp(windowX + Math.round(event.getRawX() - startX), 0, screenWidth - layout.width);
                    layout.y = clamp(windowY + Math.round(event.getRawY() - startY), 0, screenHeight - layout.height);
                    try { windows.updateViewLayout(frame, layout); }
                    catch (RuntimeException error) { fail("Android removed the image overlay", error); }
                    return true;
                }
                if (event.getActionMasked() == MotionEvent.ACTION_UP) { view.performClick(); return true; }
                return event.getActionMasked() == MotionEvent.ACTION_CANCEL;
            }
        });
        try { windows.addView(frame, layout); }
        catch (RuntimeException error) { fail("Android could not display the image overlay", error); }
    }

    private void cancelDecode() {
        synchronized (resultLock) { loadGeneration++; recycle(pendingBitmap); pendingBitmap = null; }
        if (decodeTask != null) { decodeTask.cancel(true); decodeTask = null; }
        decoder.purge();
    }
    private void removeWindow() {
        if (frame != null) {
            if (image != null) image.setImageDrawable(null);
            try { windows.removeViewImmediate(frame); }
            catch (IllegalArgumentException ignored) { /* Already removed by Android. */ }
        }
        frame = null; image = null; close = null; layout = null; displayedRequest = null;
        recycle(shownBitmap); shownBitmap = null;
    }
    private void stopOverlay() {
        session.revoke(); cancelDecode(); main.removeCallbacks(permissionWatch);
        removeWindow(); stopForeground(STOP_FOREGROUND_REMOVE); stopSelf();
    }
    private void fail(String message, Throwable error) {
        Log.e("LightEngineOverlay", message, error);
        Toast.makeText(this, message + ". No image is active.", Toast.LENGTH_LONG).show(); stopOverlay();
    }
    private static int clamp(int value, int min, int max) { return Math.max(min, Math.min(value, max)); }
    private int closeSize() { return Math.max(1, Math.round(48 * getResources().getDisplayMetrics().density)); }
    private void refreshDisplayBounds() {
        DisplayMetrics display = new DisplayMetrics(); windows.getDefaultDisplay().getRealMetrics(display);
        screenWidth = Math.max(1, display.widthPixels); screenHeight = Math.max(1, display.heightPixels);
    }
    @Override public void onConfigurationChanged(Configuration configuration) {
        super.onConfigurationChanged(configuration);
        try {
            refreshDisplayBounds();
            if (frame == null || displayedRequest == null) return;
            if (!Settings.canDrawOverlays(this)) { stopOverlay(); return; }
            OverlayGeometry fit = OverlayGeometry.fit(displayedRequest.width, displayedRequest.height, closeSize(), screenWidth, screenHeight, layout.x, layout.y);
            layout.width = fit.width; layout.height = fit.height; layout.x = fit.x; layout.y = fit.y;
            image.setLayoutParams(new FrameLayout.LayoutParams(fit.imageWidth, fit.imageHeight, Gravity.TOP | Gravity.LEFT));
            close.setLayoutParams(new FrameLayout.LayoutParams(closeSize(), closeSize(), Gravity.TOP | Gravity.RIGHT)); close.setTextSize(30);
            windows.updateViewLayout(frame, layout);
        }
        catch (RuntimeException error) { fail("Android could not resize the image overlay", error); }
    }
    private static void recycle(Bitmap bitmap) { if (bitmap != null && !bitmap.isRecycled()) bitmap.recycle(); }
    @Override public IBinder onBind(Intent intent) { return null; }
    @Override public void onDestroy() {
        synchronized (resultLock) {
            destroyed = true; loadGeneration++; main.removeCallbacksAndMessages(null);
            recycle(pendingBitmap); pendingBitmap = null;
        }
        session.revoke(); cancelDecode(); decoder.shutdownNow(); removeWindow();
        stopForeground(STOP_FOREGROUND_REMOVE); super.onDestroy();
    }
}
