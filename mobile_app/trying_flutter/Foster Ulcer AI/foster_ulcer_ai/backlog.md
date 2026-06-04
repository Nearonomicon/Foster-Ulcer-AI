# Backlog

## 2026-06-02

- Priority: Urgent
- Title: Send explicit image MIME types for `analyze-wound` and `analyze-fillin`
- Summary: Both upload paths currently use `http.MultipartFile.fromBytes(...)` without `contentType`, so the backend may receive `application/octet-stream` instead of `image/jpeg` or `image/png`. This is a likely cause of Gemini returning `{"status":"blocked","reason":"BlockedReason.OTHER"}` during image analysis.
- Scope: Update frontend upload code to send correct MIME types for wound images, and consider backend validation to reject non-`image/*` uploads early.
