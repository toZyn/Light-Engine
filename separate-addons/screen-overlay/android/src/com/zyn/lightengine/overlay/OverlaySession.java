package com.zyn.lightengine.overlay;

import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;

/** Explicit consent and generation policy. Callers provide the actual OS permission state. */
public final class OverlaySession {
    private long generation, consentGeneration = -1;
    private OverlayRequest pending;
    private String currentToken;

    public long request(OverlayRequest request) {
        if (request == null || request.hide) throw new IllegalArgumentException("Show request required");
        pending = request; currentToken = null; consentGeneration = -1;
        return ++generation;
    }
    public void consent(long expectedGeneration) {
        if (pending != null && generation == expectedGeneration) consentGeneration = generation;
    }
    public boolean canActivate(long expectedGeneration, boolean permissionGranted) {
        return permissionGranted && pending != null && generation == expectedGeneration && consentGeneration == generation;
    }
    public boolean activate(long expectedGeneration, boolean permissionGranted) {
        if (!canActivate(expectedGeneration, permissionGranted)) return false;
        currentToken = pending.token; return true;
    }
    public boolean hide(String token) {
        if ((currentToken == null && pending == null) || token == null) return false;
        String checked;
        try { checked = OverlayRequest.token(token); }
        catch (IllegalArgumentException ignored) { return false; }
        String ownedToken = pending != null ? pending.token : currentToken;
        if (!MessageDigest.isEqual(ownedToken.getBytes(StandardCharsets.US_ASCII), checked.getBytes(StandardCharsets.US_ASCII))) return false;
        revoke(); return true;
    }
    public void revoke() { generation++; pending = null; currentToken = null; consentGeneration = -1; }
}
