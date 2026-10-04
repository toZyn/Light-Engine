package com.zyn.lightengine.overlay;

/** Pixel geometry shared by first display and configuration changes. */
public final class OverlayGeometry {
    public final int imageWidth, imageHeight, width, height, x, y;
    private OverlayGeometry(int imageWidth, int imageHeight, int width, int height, int x, int y) {
        this.imageWidth = imageWidth; this.imageHeight = imageHeight;
        this.width = width; this.height = height; this.x = x; this.y = y;
    }
    public static OverlayGeometry fit(int requestedWidth, int requestedHeight, int closeSize, int screenWidth, int screenHeight, int x, int y) {
        if (requestedWidth < 1 || requestedHeight < 1 || closeSize < 1 || screenWidth < 1 || screenHeight < 1) {
            throw new IllegalArgumentException("Positive image, control and screen dimensions required");
        }
        int imageWidth = Math.min(requestedWidth, screenWidth), imageHeight = Math.min(requestedHeight, screenHeight);
        int width = Math.min(screenWidth, Math.max(imageWidth, closeSize)), height = Math.min(screenHeight, Math.max(imageHeight, closeSize));
        return new OverlayGeometry(imageWidth, imageHeight, width, height, Math.max(0, Math.min(x, screenWidth - width)), Math.max(0, Math.min(y, screenHeight - height)));
    }
}
