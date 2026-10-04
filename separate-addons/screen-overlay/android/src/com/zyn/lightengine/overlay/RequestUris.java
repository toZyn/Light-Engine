package com.zyn.lightengine.overlay;

import android.net.Uri;
import java.util.HashMap;
import java.util.Map;

final class RequestUris {
    private RequestUris() { }
    static OverlayRequest parse(Uri uri) {
        if (uri == null || uri.toString().length() > OverlayRequest.MAX_URI_LENGTH
            || !"lightengine-overlay".equals(uri.getScheme()) || uri.isOpaque()
            || uri.getFragment() != null || uri.getUserInfo() != null || uri.getPort() != -1
            || (uri.getPath() != null && !uri.getPath().isEmpty())) {
            throw new IllegalArgumentException("Invalid image-overlay URI");
        }
        Map<String, String> fields = new HashMap<>();
        for (String name : uri.getQueryParameterNames()) {
            java.util.List<String> values = uri.getQueryParameters(name);
            if (values.size() != 1) throw new IllegalArgumentException("Duplicate request field");
            fields.put(name, values.get(0));
        }
        return OverlayRequest.parse(uri.getHost(), fields);
    }
}
