# Deep Dive: Modern Auth Hand-off (Supabase PKCE to Deep-link)

## The Challenge
Authenticating a native desktop application often requires a web-based login (OAuth) for security and UX reasons (password managers, Google/Github integration). Bridging that web session back to the native app securely is the "Auth Hand-off".

## 1. The OAuth 2.0 PKCE Flow
Nischay uses the **Proof Key for Code Exchange (PKCE)** flow, which is the gold standard for public clients (like mobile or desktop apps) that cannot safely store a client secret.

### The Steps:
1.  **Code Verifier Production**: The app generates a random string (`code_verifier`).
2.  **Code Challenge Generation**: The app hashes the verifier using SHA256 and Base64Url encodes it (`code_challenge`).
3.  **Redirect to Supabase**: The app opens the system browser to the Supabase auth URL, passing the `code_challenge` and a `redirect_to` parameter pointing to our web portal.

## 2. The Web Gateway Bridge
Instead of redirecting directly to a custom scheme (which browsers often block), we redirect to our Next.js web portal (`nischay.app/auth/callback`).

### Web Portal Logic:
The web portal detects the `code` in the URL and intelligently passes it to the Mac app via a custom URL scheme.

```javascript
// Next.js Callback Handler
const code = searchParams.get("code");
if (code) {
  window.location.href = `nischay://auth/callback?code=${code}`;
}
```

## 3. The Custom URL Scheme Catch
In the Mac app's `Info.plist`, we register the `nischay` scheme.

```xml
<key>CFBundleURLTypes</key>
<array>
  <dict>
    <key>CFBundleURLSchemes</key>
    <array>
      <string>nischay</string>
    </array>
  </dict>
</array>
```

The `AppDelegate` then listens for these events:

```swift
func application(_ application: NSApplication, open urls: [URL]) {
    for url in urls {
        if url.scheme == "nischay" {
            AuthManager.shared.handleCallback(url: url)
        }
    }
}
```

## 4. The Token Exchange (The "Friend's Breakfix")
During our development, we encountered a critical failure in the token exchange. The standard GoTrue implementation failed because of missing parameters.

### The Resolution:
We discovered that Supabase expects `grant_type=pkce` in the URL query string and the auth code in a field named `auth_code` in the JSON body.

```swift
// The "Friend's fix" implemented in AuthManager.swift
let tokenUrl = "\(supabaseURL)/auth/v1/token?grant_type=pkce"
let body = [
    "auth_code": code,
    "code_verifier": verifier
]
```

## Conclusion
By using a web-portal as a bridge and implementing the PKCE exchange with the specific GoTrue requirements, Nischay achieves a seamless "Single Sign-On" experience that feels like it's native but leverages the security of modern web auth.
