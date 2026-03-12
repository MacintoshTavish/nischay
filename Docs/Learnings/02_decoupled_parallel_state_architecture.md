# Learning: Decoupled Parallel State Architecture

## The "Sequential Trap" Problem
Originally, the application's state evaluation logic was linear and sequential:
1. Check Accessibility.
2. If No -> Show Login + Accessibility Modal -> **EXIT**.
3. Check Auth.
4. If No -> Show Login -> **EXIT**.

This created a "trap" where a user who was successfully authenticated but had not yet granted accessibility permissions was **forced** back into the login screen. The app would successfully sign in, refresh, hit the Accessibility check, and reset the UI to the "Sign In" state because it was the first branch in the `if/else` stack.

## The Solution: Parallel Layers
We refactored the logic to treat Authentication and Permissions as independent, parallel concerns rather than a sequential chain.

### Logic Flow
1. **The Auth Layer (Identity)**:
   - This is the primary gate. If `isAuthd` is false, we show the Sign-In UI and stop. identity is required for all functional components.
2. **The Operational Layer (Functional UI)**:
   - If the user IS authenticated, we immediately initialize the **Toolbar (Login Bar)** and operational logic. We do not wait for permissions.
3. **The Permission Layer (Overlay)**:
   - We check Accessibility. If missing, we show an **Overlay** modal.
   - Crucially, this is non-blocking. The user sees the functional app behind the prompt.

## Implementation Pattern
```swift
func evaluateAppState() {
    windowManager.hideAllModals()
    
    // LAYER 1: Auth
    if !authManager.isAuthenticated {
        windowManager.showAuthFlow()
        return // Identity is a hard block
    }
    
    // LAYER 2: Operational
    windowManager.showOperationalUI() // Show the actual app bar
    
    // LAYER 3: Permissions
    if !AXIsProcessTrusted() && !hasSkippedAccessibility {
        windowManager.showAccessibilityModal() // Non-blocking overlay
    }
}
```

## Benefits
- **Zero-Loop Guarantee**: Auth state controls the Auth UI. Permission state only controls the Permission UI.
- **Improved UX**: Users can see their app is "logged in" even if they are still navigating System Settings.
- **Escape Hatches**: Allows for a "Skip for Now" feature because the functional UI is already loaded behind the scenes.
