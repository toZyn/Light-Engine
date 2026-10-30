package org.love2d.android;

import android.Manifest;
import android.app.Activity;
import android.app.Application;
import android.content.Intent;
import android.content.pm.ActivityInfo;
import android.content.pm.PackageManager;
import android.content.res.Configuration;
import android.net.Uri;
import android.os.Build;
import android.os.Bundle;
import android.os.Environment;
import android.os.Handler;
import android.os.Looper;
import android.os.Process;
import android.provider.Settings;
import android.system.Os;
import android.util.DisplayMetrics;

public class StoragePermissionActivity extends Activity {
    private static final int REQ_ALL_FILES = 4101;
    private static final int REQ_LEGACY_STORAGE = 4102;
    private static final int MAX_LANDSCAPE_WAIT_RETRIES = 6;
    private static final long LANDSCAPE_WAIT_STEP_MS = 25L;
    private static final String PREFS_NAME = "light_engine_storage_perm";
    private static final String KEY_PROMPTED = "prompted";

    private static volatile boolean lifecycleRegistered = false;
    private static volatile boolean gameEverCreated = false;
    private static volatile boolean gameCurrentlyAlive = false;

    private final Handler mainHandler = new Handler(Looper.getMainLooper());
    private boolean waitingForSettings = false;
    private boolean waitingForLandscape = false;
    private boolean gameLaunched = false;
    private int landscapeRetries = 0;

    private static synchronized void ensureLifecycleMonitor(Application app) {
        if (lifecycleRegistered || app == null) {
            return;
        }
        lifecycleRegistered = true;
        app.registerActivityLifecycleCallbacks(new Application.ActivityLifecycleCallbacks() {
            @Override
            public void onActivityCreated(Activity activity, Bundle savedInstanceState) {
                if (activity instanceof GameActivity) {
                    activity.setRequestedOrientation(ActivityInfo.SCREEN_ORIENTATION_SENSOR_LANDSCAPE);
                    gameEverCreated = true;
                    gameCurrentlyAlive = true;
                }
            }

            @Override
            public void onActivityStarted(Activity activity) {}

            @Override
            public void onActivityResumed(Activity activity) {
                if (activity instanceof GameActivity) {
                    activity.setRequestedOrientation(ActivityInfo.SCREEN_ORIENTATION_SENSOR_LANDSCAPE);
                }
            }

            @Override
            public void onActivityPaused(Activity activity) {}

            @Override
            public void onActivityStopped(Activity activity) {}

            @Override
            public void onActivitySaveInstanceState(Activity activity, Bundle outState) {}

            @Override
            public void onActivityDestroyed(Activity activity) {
                if (activity instanceof GameActivity) {
                    if (activity.isChangingConfigurations()) {
                        return;
                    }
                    gameCurrentlyAlive = false;
                    // Native C++ singletons in liblove.so / libopenal.so / PhysFS cannot be
                    // safely re-initialized inside a cached Android Linux process after
                    // SDLActivity.onDestroy() tears down SDL_main. Exit the PID cleanly once
                    // activity destruction completes so the next launch starts fresh.
                    new Handler(Looper.getMainLooper()).post(new Runnable() {
                        @Override
                        public void run() {
                            if (!gameCurrentlyAlive) {
                                Process.killProcess(Process.myPid());
                                System.exit(0);
                            }
                        }
                    });
                }
            }
        });
    }

    private static void configureSdlHotplugHints() {
        if (Build.VERSION.SDK_INT >= 21) {
            try {
                // Prevent SDL2's Android HIDDeviceManager from claiming USB_CLASS_HID
                // interfaces on physical keyboards/hubs (which triggers focus-stealing
                // USB permission dialogs on connect and 1000ms bulkTransfer join() stalls
                // on the main UI thread on disconnect). Android InputManager handles
                // USB/Bluetooth keyboards and controllers natively.
                Os.setenv("SDL_JOYSTICK_HIDAPI", "0", true);
            } catch (Throwable ignored) {}
        }
    }

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        configureSdlHotplugHints();
        setRequestedOrientation(ActivityInfo.SCREEN_ORIENTATION_SENSOR_LANDSCAPE);
        super.onCreate(savedInstanceState);
        ensureLifecycleMonitor(getApplication());

        if (gameEverCreated && !gameCurrentlyAlive) {
            Intent relaunch = new Intent(this, StoragePermissionActivity.class);
            relaunch.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK | Intent.FLAG_ACTIVITY_CLEAR_TASK);
            startActivity(relaunch);
            finish();
            Process.killProcess(Process.myPid());
            System.exit(0);
            return;
        }

        if (gameCurrentlyAlive || hasStoragePermission() || wasPromptedBefore()) {
            startGame();
            return;
        }

        markPrompted();
        requestStoragePermission();
    }

    @Override
    protected void onResume() {
        super.onResume();
        if (waitingForSettings) {
            waitingForSettings = false;
            startGame();
        }
    }

    private boolean hasStoragePermission() {
        if (Build.VERSION.SDK_INT >= 30) {
            return Environment.isExternalStorageManager();
        }
        if (Build.VERSION.SDK_INT >= 23) {
            return checkSelfPermission(Manifest.permission.WRITE_EXTERNAL_STORAGE)
                == PackageManager.PERMISSION_GRANTED;
        }
        return true;
    }

    private boolean wasPromptedBefore() {
        return getSharedPreferences(PREFS_NAME, MODE_PRIVATE)
            .getBoolean(KEY_PROMPTED, false);
    }

    private void markPrompted() {
        getSharedPreferences(PREFS_NAME, MODE_PRIVATE)
            .edit()
            .putBoolean(KEY_PROMPTED, true)
            .apply();
    }

    private void requestStoragePermission() {
        if (Build.VERSION.SDK_INT >= 30) {
            waitingForSettings = true;
            try {
                Intent intent = new Intent(
                    Settings.ACTION_MANAGE_APP_ALL_FILES_ACCESS_PERMISSION,
                    Uri.parse("package:" + getPackageName())
                );
                startActivityForResult(intent, REQ_ALL_FILES);
                return;
            } catch (Exception ignored) {
                try {
                    Intent fallback = new Intent(Settings.ACTION_MANAGE_ALL_FILES_ACCESS_PERMISSION);
                    startActivityForResult(fallback, REQ_ALL_FILES);
                    return;
                } catch (Exception ignoredAgain) {
                    waitingForSettings = false;
                }
            }
            startGame();
        } else if (Build.VERSION.SDK_INT >= 23) {
            requestPermissions(new String[] {
                Manifest.permission.READ_EXTERNAL_STORAGE,
                Manifest.permission.WRITE_EXTERNAL_STORAGE
            }, REQ_LEGACY_STORAGE);
        } else {
            startGame();
        }
    }

    @Override
    protected void onActivityResult(int requestCode, int resultCode, Intent data) {
        super.onActivityResult(requestCode, resultCode, data);
        if (requestCode == REQ_ALL_FILES) {
            waitingForSettings = false;
            startGame();
        }
    }

    @Override
    public void onRequestPermissionsResult(int requestCode, String[] permissions, int[] grantResults) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults);
        if (requestCode == REQ_LEGACY_STORAGE) {
            startGame();
        }
    }

    @Override
    public void onConfigurationChanged(Configuration newConfig) {
        super.onConfigurationChanged(newConfig);
        if (waitingForLandscape && !gameLaunched && isDisplayLandscape()) {
            waitingForLandscape = false;
            mainHandler.removeCallbacksAndMessages(null);
            launchGameActivityNow();
        }
    }

    private boolean isDisplayLandscape() {
        DisplayMetrics dm = getResources().getDisplayMetrics();
        return dm != null && dm.widthPixels >= dm.heightPixels;
    }

    private void startGame() {
        if (gameLaunched) {
            return;
        }
        setRequestedOrientation(ActivityInfo.SCREEN_ORIENTATION_SENSOR_LANDSCAPE);
        if (!gameCurrentlyAlive && !isDisplayLandscape() && landscapeRetries < MAX_LANDSCAPE_WAIT_RETRIES) {
            waitingForLandscape = true;
            landscapeRetries++;
            mainHandler.removeCallbacksAndMessages(null);
            mainHandler.postDelayed(new Runnable() {
                @Override
                public void run() {
                    if (gameLaunched) {
                        return;
                    }
                    if (isDisplayLandscape() || landscapeRetries >= MAX_LANDSCAPE_WAIT_RETRIES) {
                        waitingForLandscape = false;
                        launchGameActivityNow();
                    } else {
                        startGame();
                    }
                }
            }, LANDSCAPE_WAIT_STEP_MS);
            return;
        }
        launchGameActivityNow();
    }

    private void launchGameActivityNow() {
        if (gameLaunched) {
            return;
        }
        gameLaunched = true;
        waitingForLandscape = false;
        mainHandler.removeCallbacksAndMessages(null);
        Intent gameIntent = new Intent(this, GameActivity.class);
        if (gameCurrentlyAlive) {
            gameIntent.addFlags(
                Intent.FLAG_ACTIVITY_REORDER_TO_FRONT
                | Intent.FLAG_ACTIVITY_SINGLE_TOP
                | Intent.FLAG_ACTIVITY_NO_ANIMATION
            );
        } else {
            gameIntent.addFlags(Intent.FLAG_ACTIVITY_NO_ANIMATION);
        }
        startActivity(gameIntent);
        finish();
        overridePendingTransition(0, 0);
    }
}
