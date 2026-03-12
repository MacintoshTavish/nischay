# Learning: JWT Session Management & Resilience

## Expiry Tracking
A common failure point in persistent authentication is a "Stale Session." If an app loads a stored JWT from `UserDefaults` but the token has expired, an API call will fail (401), but the UI might still think the user is "logged in," causing infinite loading or error loops.

### The Fix: Metadata Storage
We updated the `UserSession` model to store the `expires_at` timestamp received from the token exchange.
- On launch, `AuthManager` checks `Date() < expiresAt - buffer`.
- If expired, `isAuthenticated` returns false immediately, forcing a clean login flow.

## Stale Session Resilience (The 401 Interceptor)
Even with expiry tracking, a session can become invalid (e.g., revoked server-side). 
We implemented a global check in `SupabaseManager` (the data layer):
1. Every authenticated request checks the response status.
2. If `HTTP 401 Unauthorized` is detected, the app triggers a central `signOut()`.
3. This pushes the app back to the `evaluateAppState` logic, which promptly shows the login screen.

## Legacy Compatibility
During the migration to strict expiry tracking, we encountered "Legacy Sessions" (old tokens in `UserDefaults` without an `expires_at` field).
**The Resilience Pattern**:
- If `currentSession` exists but `expiresAt` is `nil`, we assume the session is valid for the initial UI transition.
- We rely on the **401 Interceptor** to catch it if it's actually dead.
- This prevents a "Breaking Change" for existing users during the update.
