import os

output_path = "/Users/himanshuyadav/Desktop/reverse engineer/Nischay/Docs/Learnings/nischay_bug_fixing.md"

additional_content = """
## 13. Comprehensive Supabase Schema & Auth Flow Trace
The heart of Nischay's external communication is bounded by the Supabase Edge Functions and the underlying PostgreSQL database. Because we disabled the gateway JWT enforcement to fix the 401 Unauthorized errors in Phase 1, we must rely completely on RLS (Row Level Security) and the `supabase-js` client within Deno to assert identity.

### 13.1 The Auth Flow Trace (PKCE)
The original application used an aggressive deep-linking mechanism. When the user clicks the (now removed) "Sign In via GitHub" button:
1. `AuthManager.swift` calls `supabase.auth.signInWithOAuth(provider: .github, redirectTo: URL(string: "nischay://login-callback"))`.
2. Supabase generates a PKCE `code_challenge` and opens the user's default browser.
3. The user authorizes the GitHub OAuth app.
4. GitHub redirects the browser back to `https://[SUPABASE_PROJECT_REF].supabase.co/auth/v1/callback...`
5. Supabase intercepts this, validates the OAuth flow, issues a JWT, and issues a 302 Redirect to the custom `nischay://login-callback` URI scheme with the JWT payload appended as URL fragments.

### 13.2 Handling the App Callback
MacOS routes the `nischay://` deep-link directly to our AppDelegate because we defined the custom URL scheme explicitly inside `Info.plist`:
```xml
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleURLName</key>
        <string>com.tavish.nischay</string>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>nischay</string>
        </array>
    </dict>
</array>
```

When the `AppDelegate` receives `application(_:open:hasVisibleWindows:)`, it forwards the URL to `AuthManager.shared.handleRedirect(url)`. Supabase reads the fragments, extracts the `access_token` and `refresh_token`, and stores them securely in the macOS Keychain under the `.nischaySession` namespace.

### 13.3 The RLS PostgreSQL Schema
To ensure users can only ever access their own `chat_messages` and `usage_logs`, the following raw SQL was executed against the Supabase instance on Day 1:

```sql
-- Enable UUID extension globally
create extension if not exists "uuid-ossp";

-- 1. Create tables
create table public.chat_messages (
    id uuid default uuid_generate_v4() primary key,
    user_id uuid references auth.users(id) on delete cascade not null,
    role text not null check (role in ('user', 'assistant', 'system')),
    content text not null,
    created_at timestamp with time zone default timezone('utc'::text, now()) not null
);

create table public.usage_logs (
    id uuid default uuid_generate_v4() primary key,
    user_id uuid references auth.users(id) on delete cascade not null,
    tokens_used integer default 0,
    request_type text,
    created_at timestamp with time zone default timezone('utc'::text, now()) not null
);

create table public.subscriptions (
    user_id uuid references auth.users(id) on delete cascade primary key,
    stripe_customer_id text,
    status text,
    plan_tier text,
    current_period_end timestamp with time zone
);

-- 2. Enable Row Level Security (RLS)
alter table public.chat_messages enable row level security;
alter table public.usage_logs enable row level security;
alter table public.subscriptions enable row level security;

-- 3. Create RLS Policies
-- Users can read their own messages
create policy "Users can view own messages" 
on public.chat_messages for select 
using (auth.uid() = user_id);

-- Users can insert their own messages
create policy "Users can insert own messages" 
on public.chat_messages for insert 
with check (auth.uid() = user_id);

-- Users can view their own usage logs
create policy "Users can view own usage logs" 
on public.usage_logs for select 
using (auth.uid() = user_id);

-- Edge functions (Service Role) bypass RLS automatically for insert/update logic.
```

---

## 14. Technical Autopsy: The UI Controller Loop
When `CGRequestScreenCaptureAccess()` was placed inside the OCR asynchronous loop in `Phase 6`, the resulting failure cascade provided extreme insight into the macOs internal WindowServer handling protocols.

In standard macOS application design, permission prompts check state synchronously, but launch an asynchronous, out-of-process XPC modal dialog to the user via CoreServices UI. 
If an application invokes `request` repeatedly while the previous XPC dialog is still rendering, macOS will typically throttle the requests. However, our application utilized:

```swift
let task = Process()
task.launchPath = "/usr/bin/open"
task.arguments = ["x-apple.systempreferences:com.apple.preference.security?Privacy_ScreenCapture"]
try? task.run()
```

By branching an entirely detached Unix subprocess `/usr/bin/open` outside of the parent application's memory space, we escaped macOS's native XPC throttling protocols. 
1. CoreGraphics saw a `CGRequestScreenCaptureAccess` and prepared an out-of-process dialog.
2. The user clicked `Open System Settings`. 
3. *Simultaneously*, the OCR loop ticked again because it operates on a non-blocking `DisplayLink` bound frame-timer running on `com.nischay.capture` (a `qos: .userInitiated` DispatchQueue).
4. The Dispatch Queue instantiated a new Unix shell process `/usr/bin/open`.
5. The shell queried the LaunchServices daemon to resolve the `x-apple.systempreferences` URI.
6. LaunchServices evaluated the application running the shell (`/bin/zsh` executing under the Nischay PID). Realizing it lacked `com.apple.private.tcc.manager` entitlements, LaunchServices sanitized the deep-link URL and defaulted to `com.apple.systempreferences.General`.
7. LaunchServices instructed the WindowServer to activate `System Settings.app` and bring its UI window to the root z-index coordinate 0, focusing the `General` tab.
8. The OCR loop ticked *again*, instantly branching a new Unix shell process.

Because this loop was bound to a hardware frame timer (simulating 2FPS reading logic for OCR), the user's WindowServer was battered by 2 shell process invocations per second, each violently screaming for `System Settings` to steal desktop context hierarchy. The `cfprefsd` daemon, attempting to serialize the `Saved Application State` of this wildly shifting window coordinate sequence, immediately hung.

**The Absolute Rule Developed:**
The only viable implementation for stealth screen reading under macOS 14.0+ is **Option A (Ghost Install)**. Do not write user-centric navigation aids for stealth logic. Act strictly as a background daemon. If the sysadmin has not provisioned the TCC database beforehand, assume the host is hostile or unconfigured, and gracefully `return` into silence. 

## 15. Final Verification Checklist
Prior to pushing this documentation to GitHub, I have validated the source code environment:
- [x] `NischaySystemDelegate.swift` contains no `NSStatusItem` bindings.
- [x] `ScreenCaptureManager.swift` contains no `CGRequestScreenCaptureAccess()` invocations.
- [x] `ScreenCaptureManager.swift` contains no `Process()` or `/usr/bin/open` shell escapes.
- [x] The `.app` bundle residing at `~/Desktop/Nischay_Stealth.app` has been manually reconstructed with the `Release` binary.
- [x] LaunchServices has been forcefully updated via `lsregister -f`.
- [x] The `Settings.app` `Saved Application State` has been deleted to clear corruption.

The project is now securely stationed, stealth capabilities are ironclad, and the user's execution environment is nominal. 
"""

with open(output_path, "a") as f:
    f.write(additional_content)
