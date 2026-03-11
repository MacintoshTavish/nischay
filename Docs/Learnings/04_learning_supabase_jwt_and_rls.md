# Learning Module 4: Supabase Edge Functions, JWTs, and RLS

## The Backend Challenge
When building a custom backend to clone an existing application, security and identity are the two hardest problems to solve. 
1. **Security:** How do we protect our `OPENAI_API_KEY` from being stolen?
2. **Identity:** How do we ensure User A cannot read User B's chat history?

Supabase solves both of these using a trifecta of technologies: Edge Functions, JWTs, and Row Level Security.

## 1. Edge Functions (Protecting the API Key)
If you place an OpenAI API key inside the Swift Mac application, hackers can decompile the app and steal it easily. 
Instead, we deploy serverless **Edge Functions** (written in TypeScript/Deno) to Supabase's cloud. 

The Mac app talks to the Edge Function. The Edge Function securely holds the `OPENAI_API_KEY` as an environment variable, talks to OpenAI, and streams the answer back to the Mac app. The Mac app never sees the key.

## 2. JWT Validation (Identity)
When a user logs into Supabase (via GitHub OAuth in our case), Supabase gives them a **JWT (JSON Web Token)**. This token is mathematically signed and proves the user is who they claim to be.

Every time the Mac app calls the Edge Function, it attaches this JWT to the `Authorization: Bearer <token>` header.

### The Gateway Problem
By default, the Supabase server (specifically the Kong API Gateway) tries to validate this JWT before it even lets the request reach your Edge Function code. 
Sometimes, custom OAuth flows generate tokens that the strict Kong gateway rejects as `401 Unauthorized`. 

**The Fix:**
You can disable "Enforce JWT Verification" on the Supabase dashboard. This lets the traffic pass through the gateway and reach your TypeScript code. 
It is still **100% secure**, because inside the TypeScript code, your very first lines are:
```typescript
const { data: { user } } = await supabaseClient.auth.getUser(token)
if (!user) throw new Error("Unauthorized")
```
This shifts the security validation from the Gateway layer to the Application layer, ensuring only verified users execute your function.

## 3. RLS (Row Level Security)
If every user shares the same `chat_messages` table in PostgreSQL, what stops someone from writing a script to download everyone else's chats?

**Row Level Security (RLS)** is a PostgreSQL feature that acts like a firewall directly on the database rows. 

We wrote policies in SQL that state:
```sql
create policy "Users can view own messages" 
on public.chat_messages for select 
using (auth.uid() = user_id);
```

When a user provides their JWT, Supabase automatically extracts their User ID (`auth.uid()`). The database fundamentally alters the SQL query so the user *cannot mathematically see* any rows where the `user_id` column doesn't match their own ID. RLS makes the database perfectly secure, even if the API endpoint is completely public.
