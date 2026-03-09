# 25. Enums (Enumerations)

## Introduction for Beginners
When the user clicks "Ask Nischay," Nischay's `SupabaseManager` checks the Postgres database to see if the user's subscription allows them to execute a "Screen Analysis".

How do we pass that request name to the Supabase Manager? Do we just type a string?

No. Strings are incredibly dangerous.

---

## 1. The Danger of Strings

Imagine we wrote it using raw Strings:
```swift
let usage = await supabaseManager.checkFeatureUsage(featureName: "ScreenAnalysis", amount: 1.0)
```

In 3 months, you decide to edit the code. You make a typo:
```swift
let usage = await supabaseManager.checkFeatureUsage(featureName: "ScrenAnalytics", amount: 1.0)
```

Swift's compiler has no idea you spelled it wrong. It happily compiles the app. The user clicks the button, the app sends `"ScrenAnalytics"` to the Supabase server, the server fails to find that string in the database, and the app permanently breaks for the user. 

---

## 2. Using Enums for Safety

An **Enum** (Enumeration) is a list of extremely strict, predefined options. It forces the developer to choose from a dropdown menu, making typos impossible.

In `Models.swift`, we define the feature flag enum:

```swift
enum NischayFeature: String {
    case screenAnalysis = "screen_analysis"
    case shortMode = "short_answer"
    case voicePlayback = "voice_synthesis"
}
```

Now, the `checkFeatureUsage` function demands an Enum instead of a raw String.

```swift
func checkFeatureUsage(_ feature: NischayFeature, amount: Double) async -> UsageResult
```

### The Magic of Autocomplete

Instead of typing `"ScreenAnalysis"`, the developer simply types a dot `.`.
Xcode instantly drops a menu showing exactly three choices:
- `.screenAnalysis`
- `.shortMode`
- `.voicePlayback`

```swift
let usage = await checkFeatureUsage(.screenAnalysis, amount: 1.0)
```

If you try to type `.screnAnalytics`, the Swift compiler instantly fails and refuses to build the app, completely preventing the bug from ever reaching the user.

## 3. Raw Values
Wait, how does the Enum actually send the `"screen_analysis"` text over the internet to Supabase?

Because we declared `enum NischayFeature: String`, the Enum has a secret superpower called `rawValue`.

Inside the final network request in `SupabaseManager`, we pull the invisible string out of the Enum:
```swift
// feature = .screenAnalysis
let stringToSendToSupabase = feature.rawValue 
print(stringToSendToSupabase) // Prints: "screen_analysis"
```

## Summary for Beginners
- Never use raw "Magic Strings" for important logic, because typos cause silent failures.
- An **Enum** forces you to pick from a strict, predefined set of options.
- Enums make the Xcode compiler incredibly smart, catching typos before you even run the app.
- They can hold secret **`rawValue`s** (like Strings or Integers) to send over the network.
