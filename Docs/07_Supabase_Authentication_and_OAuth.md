# 07. Supabase Authentication and OAuth

## Introduction for Beginners
When you build an app that relies on cloud services, you need to know *who* is using the app. You don't want strangers consuming your expensive OpenAI API quota.

To solve this, Nischay uses **Supabase Auth**. Supabase is an open-source alternative to Firebase. It gives us a secure way to let users log in using Google, GitHub, or Apple, without us having to manage passwords.

---

## 1. What is OAuth?

**OAuth (Open Authorization)** is a standard protocol that allows a user to grant an app (Nischay) access to their identity on a different service (GitHub) without giving Nischay their GitHub password.

Nischay uses a specific flow of OAuth called **PKCE** (Proof Key for Code Exchange). It works like this:
1. `AuthManager.swift` asks Supabase for a login URL.
2. Nischay opens the user's default web browser (Safari or Chrome).
3. The user logs into GitHub and clicks "Allow".
4. GitHub redirects the browser back to Nischay.

### How does the browser talk to Nischay? (URL Schemes)
If you type `https://apple.com` into Safari, it loads a website.
If you type `mailto:test@test.com`, it opens the Mail app.

In Nischay's `Info.plist`, we registered a custom URL scheme: **`nischay://`**.
When GitHub redirects the browser to `nischay://auth-callback?token=XYZ`, macOS sees the `nischay://` prefix, wakes up our app, and hands the `token=XYZ` string directly to `AppDelegate.swift`.

---

## 2. Managing the Session (JWTs)

Once the `AppDelegate` receives the callback, it extracts two important tokens:
- **Access Token:** The passport that proves who the user is. (Lives for 1 hour)
- **Refresh Token:** The master key used to get a new Access Token without forcing the user to log in again. (Lives for 30 days)

### What is a JWT?
An Access Token is usually a **JWT** (JSON Web Token).
A JWT is a long, scrambled string (`eyJhbGciOi...`) that contains the user's ID, their email, and exactly when the token expires. 
Crucially, it is **cryptographically signed** by the Supabase server. This means Nischay cannot fake a JWT, and users cannot pretend to be someone else.

### Saving the Tokens (UserDefaults)
When Nischay receives these tokens, the `AuthManager` saves them securely using `UserDefaults` (a local database provided by macOS for keeping simple preferences).

Every time the user opens Nischay, the app checks if the Access Token is still alive. If it is dead, it uses the Refresh Token to beg Supabase for a fresh Access Token.

---

## 3. The Authentication Observer

The rest of the app needs to know when the user is logged in so it can enable the chat interface.

In `NischaySystemDelegate.setup()`, we added an **Observer**. 
An observer is like a radio tuned to a specific frequency. When `AuthManager` successfully logs in, it broadcasts a signal over `NotificationCenter.default`.

```swift
NotificationCenter.default.post(name: .nischayAuthStateChanged, object: nil)
```

The system delegate hears this broadcast, knows the user has authenticated, and instantly tells the `SupabaseManager` to fetch the user's past chat history from the cloud database.

## Summary for Beginners
- Nischay uses **Supabase** for secure user logins.
- It uses **OAuth PKCE**, opening Safari, and catching the login result via the `nischay://` URL scheme.
- It receives a **JWT** (JSON Web Token) containing the user's identity, securely signed by the server.
- These tokens are saved locally in `UserDefaults` so the user stays logged in across app restarts.
