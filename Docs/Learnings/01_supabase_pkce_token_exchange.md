# Learning: Supabase GoTrue PKCE Token Exchange

## The Breakthrough
The primary reason authentication was failing with `unsupported_grant_type` was a mismatch between the standard OAuth2 implementation and the specific requirements of the Supabase **GoTrue** engine (v1).

### 1. The `grant_type` Query Parameter
Unlike many OAuth providers that accept `grant_type` in the POST body, GoTrue expects `grant_type=pkce` to be passed as a **URL query parameter**.
- **Incorrect**: `POST /token` with `{"grant_type": "pkce", ...}`
- **Correct**: `POST /token?grant_type=pkce`

### 2. The `auth_code` field
While the standard specifies `code` as the key for the authorization code, the GoTrue endpoint for PKCE exchanges requires the key to be named **`auth_code`** in the JSON body.
- **Incorrect**: `{"code": "XYZ", ...}`
- **Correct**: `{"auth_code": "XYZ", ...}`

### 3. Header Requirements
For public clients (like a native Mac app), providing a `Redirect URI` is mandatory, and the `apikey` must be present both in the `apikey` header and typically as a `Bearer` token if a session is being refreshed.

## Implementation Snippet
```swift
var urlComponents = URLComponents(string: "\(url)/auth/v1/token")!
urlComponents.queryItems = [URLQueryItem(name: "grant_type", value: "pkce")]

var request = URLRequest(url: urlComponents.url!)
request.httpMethod = "POST"
request.setValue("application/json", forHTTPHeaderField: "Content-Type")

let body: [String: Any] = [
    "auth_code": code,
    "code_verifier": verifier,
    "redirect_uri": redirectUri
]
```
