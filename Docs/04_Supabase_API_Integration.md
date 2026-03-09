# Supabase & API Integration

## Overview
While the app interacts with OpenAI for its intelligence, it does not do so directly by default. Based on the reverse engineering of the original binary, the app funnels all traffic through a Supabase backend using Edge Functions.

This architecture offers several security and business advantages:
1. **Secret Hiding:** The OpenAI API key is stored securely in Supabase Secrets, never shipped in the client binary.
2. **Access Control:** Supabase Auth issues JWTs, ensuring only logged-in users can execute functions.
3. **Monetization Gate:** Features can be gated behind Postgres database checks for subscription status or usage quotas.

---

## The 6 Edge Function Endpoints

The `SupabaseManager` is configured to communicate with six specific Supabase Edge Functions extracted from the `otool` dump.

### 1. `/functions/v1/analyze-screen`
- **Purpose:** The main workhorse. Accepts the OCR text and user question, forwards it to OpenAI, and returns a streamed response.
- **Payload:** `{"content": "...", "requestType": "chat", "useShortMode": false}`
- **Streaming:** Returns a `text/event-stream`. The client parses `data:` prefixes manually, appending chunks to the UI in real-time.

### 2. `/functions/v1/analyze-screen-short`
- **Purpose:** A variant of the above, optimized for very brief, concise answers. Toggled via the "Short" checkbox in the UI.

### 3. `/functions/v1/check-usage`
- **Purpose:** Query the user's current token/request usage against their monthly limit.

### 4. `/functions/v1/record-usage`
- **Purpose:** Increment the usage counter in the backend Postgres database after a successful AI request.

### 5. `/functions/v1/check-subscription`
- **Purpose:** Validates if the user has an active Stripe subscription tied to their Supabase user ID. Returns a boolean array for specific features.

### 6. `/functions/v1/check-version`
- **Purpose:** A simple endpoint allowing the backend to force client updates by returning a minimum supported build number.

---

## The Pre-Flight Usage Check

A critical discovery in the Ghidra decompilation of `streamAnalyzeText_entry.c` was a synchronous pre-flight check before any payload is sent to the AI:

```c
long usageStatus = _objc_msgSend(manager, "checkFeatureUsage:amount:", 1, 1.0);
if (usageStatus != 1) { 
    // block request, show error 
}
```

In Nischay's `NischaySystemDelegate.swift`, this is accurately replicated:
```swift
let usage = await supabaseManager.checkFeatureUsage(.screenAnalysis, amount: 1.0)
guard usage.allowed else {
    self.broadcast(.nischayAnalysisError, "Usage limit reached. Consider upgrading.")
    return
}
```

---

## Direct OpenAI Fallback (`OpenAIManager`)

If the user has not configured Supabase (e.g., URL is empty), the app gracefully falls back to a direct-to-OpenAI mode.

- **Storage:** Reads `openAIAPIKey` from local `UserDefaults`.
- **API:** Directly hits `https://api.openai.com/v1/chat/completions`.
- **Vision Support:** If configured, it bypasses the local OCR entirely and sends the raw `NSImage` (converted to base64 JPEG) directly to the `gpt-4-vision-preview` model, instructing the model to do the extraction and analysis.
