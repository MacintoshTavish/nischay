# Chat History & Persistence

## Overview
A key feature of modern AI assistants is retaining conversation context. When you ask Nischay a follow-up question, it needs the history of the previous screen analyses to provide a coherent answer.

---

## 1. Local State (`NischaySystemDelegate.swift`)

The runtime state of the conversation is held in `NischaySystemDelegate.chatHistory`, which is an array of `ChatMessage` structs.

Every time the user asks a question, or the assistant yields a final streaming response, `saveChatMessage(_:)` is called. The entire array is attached to the OpenAI prompt payload to maintain context.

---

## 2. Remote Synchronization (`SupabaseManager.swift`)

To allow users to access their past sessions across devices (or across app restarts), chat history is synchronized with the Supabase PostgreSQL database.

### Ghidra Findings
In Ghidra, we decompiled two critical functions:
- `SupabaseManager_loadChatHistory.c`
- `SupabaseManager_saveChatMessage.c`

Both made standard HTTP requests, indicating direct PostgREST calls rather than complex Edge Function usage for simple CRUD operations.

### Swift Implementation

**Saving a Message:**
We use a standard URLSession `POST` to the Supabase REST endpoint (`/rest/v1/chat_messages`).
```swift
var request = URLRequest(url: URL(string: "\(config.supabaseURL)/rest/v1/chat_messages")!)
request.httpMethod = "POST"
// Includes Anon Key and Bearer Auth Token
```
The payload includes the `role`, `content`, and a `created_at` timestamp.

**Loading History:**
On app launch (specifically, within `authStateChanged` when a user logs in), `loadChatHistory()` is triggered.
We execute a `GET` request to the same endpoint, retrieving all rows belonging to the authenticated User ID, sorting them by `created_at`.

### Fallback Behavior
If the user prefers a completely private, offline-first experience (by clearing their `supabaseURL` in ConfigManager), the app never attempts to sync to PostgREST. `chatHistory` remains strictly in RAM, dying forever when the Nischay process is quit. 

This mirrors the "No Honor" fallback mode we observed during the reverse engineering process.
