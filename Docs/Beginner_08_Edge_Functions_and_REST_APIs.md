# 08. Edge Functions and REST APIs

## Introduction for Beginners
If you are building an AI app, you might think: *"Why don't I just put my OpenAI API key directly inside Nischay's Swift code?"*

**DO NOT DO THIS.** If you put your OpenAI API key in the app, malicious users will decompile your app (just like we did to inputmethodd!), extract your secret key, and rack up a $10,000 bill on your credit card.

To prevent this, Nischay uses **Edge Functions**.

---

## 1. What is an Edge Function?

An **Edge Function** is a tiny piece of code that lives on a server (managed by Supabase or Cloudflare). It runs safely locked away in the cloud, where users cannot see the code.

Instead of the Nischay app talking to OpenAI directly, it talks to the Edge Function. The Edge Function then talks to OpenAI securely, and forwards the result back to Nischay.

### Storing Secrets Safely
Because the Edge Function lives on a server, you can store your `OPENAI_API_KEY` there as an Environment Variable. The app never knows what the key is.

---

## 2. Using REST (HTTP Requests in Swift)

To talk to the Edge Function, Nischay's `SupabaseManager` uses **REST** (Representational State Transfer). This is the standard language of the internet.

When you send a text in WhatsApp or load a webpage on Safari, your device is sending HTTP requests. Nischay does the exact same thing using Apple's `URLSession`.

### Anatomy of Nischay's Network Request

```swift
var request = URLRequest(url: URL(string: "https://your.supabase.co/functions/v1/analyze-screen")!)
request.httpMethod = "POST"
request.addValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
request.httpBody = // JSON text
```

1. **The URL Endpoint:** The specific address on the server we want to talk to (e.g., `/analyze-screen`).
2. **The Method (`POST`):** By using `POST`, Nischay tells the server: *"I have a large box of data for you to read."*
3. **The Headers (`Authorization`):** This is where Nischay attaches the user's **JWT** (the passport discussed in Auth docs). The Edge Function checks this passport to ensure the user is logged in. If they aren't, it immediately rejects the request with a `401 Unauthorized` error.
4. **The Body (JSON):** The actual payload (the user's question, and the massive OCR text string) formatted exactly like a dictionary.

---

## 3. The Pre-flight Usage Gate

One critical thing we discovered in Ghidra was that the original app forced a "Gate" before calling the AI. We replicated this perfectly.

Before Nischay fires the heavy, expensive `POST` request to OpenAI, it fires a fast `POST` to a different Edge Function called `/check-usage`.

```swift
let usage = await supabaseManager.checkFeatureUsage(.screenAnalysis, amount: 1.0)
```

The database checks: *"Has this user made more than 100 requests today?"*
If yes, `usage.allowed = false`.
The `NischaySystemDelegate` catches this `false` value, cancels the AI analysis entirely, and displays a red error bubble in the UI telling the user to buy a subscription.

## Summary for Beginners
- Never put API keys inside Swift code.
- Nischay routes all AI queries through **Supabase Edge Functions** to hide the OpenAI key.
- Nischay uses **HTTP POST** requests to send the OCR data.
- It attaches the user's **JWT** as a header to prove their identity.
- It calls a lightweight `/check-usage` endpoint before burning money on expensive AI calls to enforce subscription limits.
