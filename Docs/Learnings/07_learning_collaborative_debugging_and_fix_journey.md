# Learning: The Collaborative Debugging Journey (Ghost in the Machine)

## Overview
This document chronicles the 6-hour debugging session to resolve the Nischay Auth Loop. It serves as a case study in how complex state interactions, legacy assumptions, and environment mismatches can create "impossible" bugs.

## Phase 1: The Protocol Mistake (GoTrue vs. Standard OAuth)
**The Mistake**: I initially implemented a standard OAuth2 PKCE exchange, assuming `grant_type` belonged in the JSON body and the authorization code key was `code`.

**The Symptom**: Persistent `400 Bad Request` with `unsupported_grant_type`.

**The Breakthrough (Friend's Insight #1)**: 
Your friend identified that Supabase's **GoTrue** engine is highly opinionated:
- `grant_type` MUST be a query parameter in the URL.
- The body key MUST be `auth_code`.
- The `redirect_uri` MUST be present in the body even if redundant.

**The Correction**: Refactored `AuthManager` to follow the non-standard GoTrue specification.

---

## Phase 2: The Logic Trap (Sequential vs. Parallel)
**The Mistake**: Once the network flow was fixed, the UI became the bottleneck. I implemented `evaluateAppState` using a linear `if/else` ladder that checked Accessibility *before* Auth.

**The Symptom**: The app was "signed in" (200 OK), but the user was immediately kicked back to the login screen.

**My Second Mistake**: I suspected the token session was the issue and implemented a strict `expiresAt` check. This actually made the loop worse because legacy tokens (without expiry) were now being treated as "invalid" and triggering sign-outs.

**The Breakthrough (Friend's Insight #2)**: 
Your friend performed a log trace and a code audit to find the "Trap":
- **Binary Mismatch**: Logs showed the app was running an older version than the code on disk.
- **The Accessibility Trap**: Because `!isTrusted` was the first branch in the code, it "swallowed" the authenticated user and showed the login screen as part of the accessibility prompt, create an infinite loop.

---

## Phase 3: The Parallel Layer Resolution
**The Correction**: We moved to a "Parallel Layers" architecture.
1.  **Identity Layer**: If `isAuthd`, show operational UI.
2.  **Permission Layer**: If `!isTrusted`, show overlay.

By separating these, we ensured the app's functionality (Toolbar) was no longer a hostage to its permissions (Accessibility).

---

## Key Takeaways for Future Debugging
1.  **Trust the Binary, Not the Source**: If logs don't reflect your latest code changes, `pkill` the process and perform a `clean build`.
2.  **Decouple Independent States**: Never put independent pre-requisites (like Auth and Permissions) into a single sequential `if/else` stack. Treat them as additive layers.
3.  **Opinionated Engines**: When dealing with open-source auth engines like GoTrue, standard documentation is a suggestion; the source code is the only truth.
4.  **Persistent Grace**: When introducing metadata (like expiry), always provide a grace path for "legacy" data that lacks that metadata to prevent immediate bricking of existing sessions.
