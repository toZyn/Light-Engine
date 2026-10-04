package org.love2d.android;

import android.Manifest;
import android.app.Activity;
import android.content.ActivityNotFoundException;
import android.content.ComponentName;
import android.content.Intent;
import android.content.pm.PackageManager;
import android.graphics.Color;
import android.net.Uri;
import android.os.Build;
import android.os.Bundle;
import android.os.Environment;
import android.os.Handler;
import android.os.Looper;
import android.provider.Settings;
import android.util.Log;
import android.view.Gravity;
import android.widget.Button;
import android.widget.LinearLayout;
import android.widget.TextView;
import android.widget.Toast;

import java.io.File;
import java.io.IOException;

public class StoragePermissionActivity extends Activity {
    private static final int STORAGE_PERMISSION_REQUEST = 4201;
    private static final long ACCESS_CHECK_DELAY_MS = 350;

    private final Handler handler = new Handler(Looper.getMainLooper());
    private final Runnable accessCheck = this::verifyStorageAccess;

    private boolean gameStarted = false;
    private boolean promptShown = false;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);

        if (hasStoragePermission() && ensureExternalDirectories()) {
            startGame();
        } else {
            showStoragePrompt();
            requestStorageAccess();
        }
    }

    @Override
    protected void onResume() {
        super.onResume();
        if (!gameStarted) handler.postDelayed(accessCheck, ACCESS_CHECK_DELAY_MS);
    }

    @Override
    protected void onDestroy() {
        handler.removeCallbacks(accessCheck);
        super.onDestroy();
    }

    @Override
    public void onRequestPermissionsResult(int requestCode, String[] permissions,
            int[] grantResults) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults);
        if (requestCode == STORAGE_PERMISSION_REQUEST) {
            handler.postDelayed(accessCheck, ACCESS_CHECK_DELAY_MS);
        }
    }

    private boolean hasStoragePermission() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            return Environment.isExternalStorageManager();
        }
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            return checkSelfPermission(Manifest.permission.WRITE_EXTERNAL_STORAGE)
                == PackageManager.PERMISSION_GRANTED;
        }
        return true;
    }

    private boolean ensureExternalDirectories() {
        File root = new File(Environment.getExternalStorageDirectory(),
            "Android/media/" + getPackageName());
        String[] names = {"mods", "addons", "saves"};

        if (!root.isDirectory() && !root.mkdirs()) return false;
        // Exclude this app's content before creating any mod/add-on/save folders.
        // createNewFile preserves an existing marker and its contents.
        try {
            new File(root, ".nomedia").createNewFile();
        } catch (IOException | SecurityException error) {
            Log.w("LightEngineStorage", "Could not create .nomedia", error);
        }
        for (String name : names) {
            File directory = new File(root, name);
            if (!directory.isDirectory() && !directory.mkdirs()) return false;
        }
        return true;
    }

    private void showStoragePrompt() {
        if (promptShown || gameStarted) return;
        promptShown = true;

        LinearLayout layout = new LinearLayout(this);
        layout.setOrientation(LinearLayout.VERTICAL);
        layout.setGravity(Gravity.CENTER);
        layout.setPadding(48, 48, 48, 48);
        layout.setBackgroundColor(Color.BLACK);

        TextView message = new TextView(this);
        message.setText("FNF LÖVE necesita acceso a Android/media para cargar mods, addons y guardados en tiempo real.");
        message.setTextColor(Color.WHITE);
        message.setTextSize(18);
        message.setGravity(Gravity.CENTER);
        layout.addView(message, new LinearLayout.LayoutParams(
            LinearLayout.LayoutParams.MATCH_PARENT,
            LinearLayout.LayoutParams.WRAP_CONTENT));

        Button grant = new Button(this);
        grant.setText("Grant storage access");
        grant.setOnClickListener(view -> requestStorageAccess());
        LinearLayout.LayoutParams buttonParams = new LinearLayout.LayoutParams(
            LinearLayout.LayoutParams.WRAP_CONTENT,
            LinearLayout.LayoutParams.WRAP_CONTENT);
        buttonParams.topMargin = 32;
        layout.addView(grant, buttonParams);

        setContentView(layout);
    }

    private void requestStorageAccess() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            Intent intent = new Intent(
                Settings.ACTION_MANAGE_APP_ALL_FILES_ACCESS_PERMISSION,
                Uri.parse("package:" + getPackageName())
            );
            try {
                startActivity(intent);
                return;
            } catch (ActivityNotFoundException ignored) {
                intent = new Intent(Settings.ACTION_MANAGE_ALL_FILES_ACCESS_PERMISSION);
            }
            startActivity(intent);
        } else if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M
                && checkSelfPermission(Manifest.permission.WRITE_EXTERNAL_STORAGE)
                != PackageManager.PERMISSION_GRANTED) {
            requestPermissions(
                new String[] {Manifest.permission.READ_EXTERNAL_STORAGE,
                    Manifest.permission.WRITE_EXTERNAL_STORAGE},
                STORAGE_PERMISSION_REQUEST
            );
        }
    }

    private void verifyStorageAccess() {
        if (gameStarted) return;

        if (hasStoragePermission() && ensureExternalDirectories()) {
            startGame();
        } else {
            showStoragePrompt();
            Toast.makeText(this,
                "Storage access is required to load external mods and addons.",
                Toast.LENGTH_LONG).show();
        }
    }

    private void startGame() {
        if (gameStarted || !ensureExternalDirectories()) return;
        gameStarted = true;
        handler.removeCallbacks(accessCheck);

        Intent gameIntent = new Intent(getIntent());
        gameIntent.setComponent(new ComponentName(this, GameActivity.class));
        gameIntent.addFlags(Intent.FLAG_ACTIVITY_NO_ANIMATION);
        startActivity(gameIntent);
        finish();
    }
}
