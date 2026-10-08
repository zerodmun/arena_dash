# Arena Dash: Deployment & Distribution Guide

This document outlines the build, signing, and deployment workflows for **Arena Dash** across Android and Web targets.

---

## 1. Android Release Build & Signing

Arena Dash uses Godot 4's headless export pipeline coupled with Google's Android SDK build tools.

### 1.1 Prerequisites
- **JDK 17**: OpenJDK 17 (`/opt/homebrew/opt/openjdk@17` or Temurin 17).
- **Android Command-Line Tools & SDK**:
  - `platforms;android-34`
  - `build-tools;34.0.0`
- **Godot 4.7+ CLI**: Installed and accessible via PATH (`godot`).

### 1.2 Automated Build Script (`build_apk.sh`)
The project provides [`build_apk.sh`](file:///Users/tentendigitalindonesia/Downloads/XxX/Apps/testing-app/build_apk.sh), which sets environment variables, exports the APK headless, and signs it.

```bash
# Export and sign release APK
./build_apk.sh --export-release

# Export debug APK (for faster iteration)
./build_apk.sh --export-debug
```

### 1.3 Keystore Configuration
For release signing, Godot reads from `export_presets.cfg` or command-line parameters. Local development uses `debug.keystore`:
```bash
# Generate a new release keystore if deploying to Google Play:
keytool -v -genkey -v -keystore release.keystore -alias arenadash \
  -keyalg RSA -keysize 2048 -validity 10000
```

### 1.4 Cryptographic Signature Verification
Always verify the generated APK with `apksigner`:
```bash
JAVA_HOME="/opt/homebrew/opt/openjdk@17/libexec/openjdk.jdk/Contents/Home" \
/opt/homebrew/share/android-commandlinetools/build-tools/34.0.0/apksigner verify --verbose build/arena_dash.apk
```
Expected output:
```
Verifies
Verified using v2 scheme (APK Signature Scheme v2): true
Verified using v3 scheme (APK Signature Scheme v3): true
Number of signers: 1
```

### 1.5 Device Installation
```bash
adb install -r build/arena_dash.apk
```

---

## 2. WebAssembly (Browser) Hosting

Godot 4 Web exports utilize multi-threading and WebAssembly SIMD, requiring **SharedArrayBuffer** support.

### 2.1 HTTP Header Requirements
Browsers enforce that pages using `SharedArrayBuffer` must be in a cross-origin isolated environment. The web server MUST return the following headers on all responses:

```http
Cross-Origin-Opener-Policy: same-origin
Cross-Origin-Embedder-Policy: require-corp
```

### 2.2 Local Development Server
Use the included [`serve_web.py`](file:///Users/tentendigitalindonesia/Downloads/XxX/Apps/testing-app/serve_web.py):
```bash
python3 serve_web.py
# Serves http://127.0.0.1:8060/ with correct COOP/COEP headers
```

### 2.3 Production Web Server Configurations

#### Nginx
```nginx
server {
    listen 80;
    server_name arena-dash.yourdomain.com;
    root /path/to/testing-app/build/web;
    index index.html;

    location / {
        add_header Cross-Origin-Opener-Policy "same-origin" always;
        add_header Cross-Origin-Embedder-Policy "require-corp" always;
        add_header Access-Control-Allow-Origin "*" always;
        try_files $uri $uri/ /index.html;
    }

    # Enable gzip compression for wasm and pck
    gzip on;
    gzip_types application/javascript application/wasm application/octet-stream;
}
```

#### Caddy
```caddy
arena-dash.yourdomain.com {
    root * /path/to/testing-app/build/web
    file_server

    header {
        Cross-Origin-Opener-Policy "same-origin"
        Cross-Origin-Embedder-Policy "require-corp"
    }
}
```

#### Apache (`.htaccess`)
```apache
<IfModule mod_headers.c>
    Header set Cross-Origin-Opener-Policy "same-origin"
    Header set Cross-Origin-Embedder-Policy "require-corp"
</IfModule>
```

---

## 3. Web Pack Re-generation
When updating GDScript or scene assets without recompiling the Godot web binary:
```bash
godot --headless --export-pack Web build/web/index.pck
```
This updates the game data in seconds and will immediately take effect on the web server.
