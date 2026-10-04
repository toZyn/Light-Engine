package com.zyn.lightengine.overlay;

import java.util.Base64;
import java.util.Locale;
import java.util.Map;
import java.util.zip.CRC32;

/** URI payload policy, independent of Android. No filesystem or image rewriting. */
public final class OverlayRequest {
    public static final int MAX_PNG_BYTES = 256 * 1024;
    public static final int MAX_DIMENSION = 4096;
    public static final long MAX_PIXELS = 16_000_000L;
    public static final int MAX_URI_LENGTH = 360_000;
    public final String token, label;
    public final byte[] png;
    public final int x, y, width, height, imageWidth, imageHeight;
    public final boolean hide;

    private OverlayRequest(String token, byte[] png, int x, int y, int width, int height, String label, boolean hide) {
        this.token = token(token); this.hide = hide;
        if (hide) {
            this.png = null; this.label = "";
            this.x = this.y = this.width = this.height = this.imageWidth = this.imageHeight = 0;
            return;
        }
        if (png == null || png.length < 33 || png.length > MAX_PNG_BYTES) invalid("PNG must contain 33 to 262144 bytes");
        byte[] signature = {(byte)137, 80, 78, 71, 13, 10, 26, 10};
        for (int i = 0; i < signature.length; i++) if (png[i] != signature[i]) invalid("Image must be an original PNG");
        if (unsigned(png, 8) != 13 || png[12] != 'I' || png[13] != 'H' || png[14] != 'D' || png[15] != 'R') invalid("PNG IHDR is missing");
        long imageW = unsigned(png, 16), imageH = unsigned(png, 20);
        if (imageW < 1 || imageH < 1 || imageW > MAX_DIMENSION || imageH > MAX_DIMENSION || imageW * imageH > MAX_PIXELS) invalid("PNG exceeds image bounds");
        CRC32 crc = new CRC32(); crc.update(png, 12, 17);
        if (crc.getValue() != unsigned(png, 29)) invalid("PNG header checksum is invalid");
        if (width < 1 || height < 1 || width > MAX_DIMENSION || height > MAX_DIMENSION) invalid("Display dimensions must be 1 to 4096");
        if (x < -100000 || x > 100000 || y < -100000 || y > 100000) invalid("Coordinates must be -100000 to 100000");
        if (label == null || label.length() > 80) invalid("Label must contain at most 80 characters");
        for (int i = 0; i < label.length(); i++) if (Character.isISOControl(label.charAt(i))) invalid("Label contains a control character");
        this.png = png.clone(); this.label = label;
        this.x = x; this.y = y; this.width = width; this.height = height;
        this.imageWidth = (int)imageW; this.imageHeight = (int)imageH;
    }

    public static OverlayRequest parse(String action, Map<String, String> fields) {
        boolean hide = "hide".equals(action);
        if (!hide && !"show".equals(action)) invalid("Only show and hide actions are supported");
        if (fields == null) invalid("Request fields are missing");
        for (String field : fields.keySet()) {
            if (!"token".equals(field) && (hide || !("image".equals(field) || "x".equals(field) || "y".equals(field)
                || "width".equals(field) || "height".equals(field) || "label".equals(field)))) invalid("Unexpected request field");
        }
        String token = token(fields.get("token"));
        if (hide) return new OverlayRequest(token, null, 0, 0, 0, 0, "", true);
        String encoded = fields.get("image");
        if (encoded == null || encoded.length() > (MAX_PNG_BYTES * 4 + 2) / 3 || !encoded.matches("[A-Za-z0-9_-]+")) invalid("Image must be unpadded URL-safe base64 within 256 KiB");
        byte[] png;
        try { png = Base64.getUrlDecoder().decode(encoded); }
        catch (IllegalArgumentException error) { throw new IllegalArgumentException("Invalid image base64", error); }
        if (!Base64.getUrlEncoder().withoutPadding().encodeToString(png).equals(encoded)) invalid("Image base64 is not canonical");
        return showBytes(token, png, number(fields, "x"), number(fields, "y"), number(fields, "width"), number(fields, "height"), fields.get("label"));
    }

    public static OverlayRequest showBytes(String token, byte[] png, int x, int y, int width, int height, String label) {
        return new OverlayRequest(token, png, x, y, width, height, label, false);
    }

    public static String token(String token) {
        if (token == null || !token.matches("[0-9a-fA-F]{64}")) invalid("Token must contain exactly 64 hexadecimal characters");
        return token.toLowerCase(Locale.ROOT);
    }

    private static int number(Map<String, String> fields, String key) {
        String value = fields.get(key);
        if (value == null || !value.matches("-?[0-9]{1,10}")) invalid("Invalid integer: " + key);
        try { return Integer.parseInt(value); }
        catch (NumberFormatException error) { throw new IllegalArgumentException("Integer out of range: " + key, error); }
    }
    private static long unsigned(byte[] bytes, int offset) {
        return ((bytes[offset] & 255L) << 24) | ((bytes[offset + 1] & 255L) << 16) | ((bytes[offset + 2] & 255L) << 8) | (bytes[offset + 3] & 255L);
    }
    private static void invalid(String message) { throw new IllegalArgumentException(message); }
}
