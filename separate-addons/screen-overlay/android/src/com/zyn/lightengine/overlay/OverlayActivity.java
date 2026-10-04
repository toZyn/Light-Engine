package com.zyn.lightengine.overlay;

import android.app.Activity;
import android.app.AlertDialog;
import android.content.Intent;
import android.net.Uri;
import android.os.Bundle;
import android.provider.Settings;
import android.widget.CheckBox;
import android.widget.LinearLayout;
import android.widget.TextView;
import android.widget.Toast;

/** Public URI entry point: every show request needs new, explicit image consent. */
public final class OverlayActivity extends Activity {
    private final OverlaySession consent = new OverlaySession();
    private OverlayRequest request;
    private long generation;
    private boolean approved, awaitingPermission, leftForPermission, draggable = true;
    private AlertDialog dialog;

    @Override public void onCreate(Bundle savedState) {
        super.onCreate(savedState);
        TextView introduction = new TextView(this);
        introduction.setPadding(32, 48, 32, 32);
        introduction.setText("Light Engine Image Overlay\n\nSend one PNG using the standalone screen-overlay addon. Only that image appears above home and other apps. Every image requires your approval.\n\nDrag the image to move it. Tap its × or the foreground Stop control to remove it.");
        setContentView(introduction);
        if (savedState != null) {
            draggable = savedState.getBoolean("draggable", true);
            approved = savedState.getBoolean("approved", false);
            awaitingPermission = savedState.getBoolean("awaitingPermission", false);
            leftForPermission = savedState.getBoolean("leftForPermission", false);
        }
        accept(getIntent(), savedState != null);
    }

    @Override public void onNewIntent(Intent intent) {
        super.onNewIntent(intent);
        accept(intent, false);
    }

    private void accept(Intent intent, boolean restoring) {
        if (intent == null || intent.getData() == null) return;
        try {
            OverlayRequest incoming = RequestUris.parse(intent.getData());
            if (incoming.hide) {
                // A private service validates the token against its current image.
                startService(new Intent(this, OverlayService.class).setAction(OverlayService.HIDE).putExtra("token", incoming.token));
                boolean ownedPending = consent.hide(incoming.token);
                if (ownedPending || request == null) {
                    if (dialog != null) dialog.dismiss();
                    request = null; approved = awaitingPermission = leftForPermission = false;
                    finish();
                }
                return;
            }
            if (dialog != null) dialog.dismiss();
            consent.revoke(); request = incoming; setIntent(intent);
            if (!restoring) { approved = awaitingPermission = leftForPermission = false; draggable = true; }
            generation = consent.request(request);
            if (restoring && approved && awaitingPermission) {
                consent.consent(generation); return;
            }
            approved = false;
            askForImageConsent();
        } catch (IllegalArgumentException error) {
            new AlertDialog.Builder(this).setTitle("Image overlay unavailable")
                .setMessage(error.getMessage()).setPositiveButton("Close", (d, which) -> finish()).show();
        } catch (IllegalStateException | SecurityException error) {
            Toast.makeText(this, "Android could not contact the overlay service: " + error.getMessage(), Toast.LENGTH_LONG).show();
            finish();
        }
    }

    private void askForImageConsent() {
        LinearLayout content = new LinearLayout(this); content.setOrientation(LinearLayout.VERTICAL);
        content.setPadding(32, 16, 32, 8);
        TextView details = new TextView(this);
        String label = request.label.isEmpty() ? "PNG image" : request.label;
        details.setText(label + "\nOriginal PNG: " + request.imageWidth + " × " + request.imageHeight
            + "\nDisplay size: " + request.width + " × " + request.height
            + " pixels\n\nDisplay this image above home and other apps? The close button and foreground Stop control remove it.");
        content.addView(details);
        CheckBox drag = new CheckBox(this); drag.setText("Allow dragging the image"); drag.setChecked(draggable); content.addView(drag);
        dialog = new AlertDialog.Builder(this).setTitle("Show this image?").setView(content)
            .setNegativeButton("Cancel", (d, which) -> finish())
            .setPositiveButton("Show image", (d, which) -> {
                draggable = drag.isChecked(); approved = true; consent.consent(generation);
                if (Settings.canDrawOverlays(this)) activate();
                else requestPermission();
            }).setOnCancelListener(d -> finish()).show();
    }

    private void requestPermission() {
        awaitingPermission = true; leftForPermission = false;
        try {
            startActivity(new Intent(Settings.ACTION_MANAGE_OVERLAY_PERMISSION, Uri.parse("package:" + getPackageName())));
        } catch (android.content.ActivityNotFoundException | SecurityException error) {
            awaitingPermission = false;
            Toast.makeText(this, "Overlay permission settings are unavailable. No image was shown.", Toast.LENGTH_LONG).show(); finish();
        }
    }

    @Override public void onPause() {
        if (awaitingPermission) leftForPermission = true;
        super.onPause();
    }
    @Override public void onResume() {
        super.onResume();
        if (awaitingPermission && leftForPermission && request != null) {
            awaitingPermission = false;
            if (approved && Settings.canDrawOverlays(this)) activate();
            else { Toast.makeText(this, "Permission was not granted. No image was shown.", Toast.LENGTH_LONG).show(); finish(); }
        }
    }

    private void activate() {
        if (!approved || !consent.activate(generation, Settings.canDrawOverlays(this))) return;
        Intent intent = new Intent(this, OverlayService.class).setAction(OverlayService.SHOW)
            .putExtra("token", request.token).putExtra("png", request.png).putExtra("label", request.label)
            .putExtra("x", request.x).putExtra("y", request.y).putExtra("width", request.width).putExtra("height", request.height)
            .putExtra("draggable", draggable);
        try { startForegroundService(intent); }
        catch (IllegalStateException | SecurityException error) {
            Toast.makeText(this, "Android declined the image overlay: " + error.getMessage(), Toast.LENGTH_LONG).show();
        }
        finish();
    }

    @Override public void onSaveInstanceState(Bundle out) {
        out.putBoolean("approved", approved); out.putBoolean("awaitingPermission", awaitingPermission);
        out.putBoolean("leftForPermission", leftForPermission); out.putBoolean("draggable", draggable);
        super.onSaveInstanceState(out);
    }
    @Override public void onDestroy() {
        if (dialog != null) dialog.dismiss(); request = null; consent.revoke();
        super.onDestroy();
    }
}
