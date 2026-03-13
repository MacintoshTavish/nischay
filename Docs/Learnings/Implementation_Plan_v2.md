# Unified Interface Implementation Plan

Consolidate the multiple disparate windows into a single, cohesive, premium glassmorphic interface.

## User Review Required

> [!IMPORTANT]
> This change will effectively remove the separate "Main Window", "Controls Window", and "Chat Input Window" in favor of a unified "Nischay Panel". This is a significant UI overhaul to match the premium aesthetics seen in the Instructions overlay.

## Proposed Changes

### UI Consolidation & Design Unification

#### [REPURPOSE] [InstructionsOverlayView.swift](file:///Users/himanshuyadav/Desktop/reverse%20engineer/Nischay/Sources/Nischay/UI/Modals/InstructionsOverlayView.swift) -> `UnifiedDashboardView.swift`
- **Logic**: Implement a `@State` or `@ObservedObject` to switch between `.instructions`, `.results`, and `.chat`.
- **Aesthetics**: Keep the `VisualEffectView` background and premium 20px padding.
- **Components**:
  - `InstructionsView`: The current instruction text.
  - `ResultsView`: A clean, scrollable text area for AI responses.
  - `ChatView`: A unified chat history and a sleek text input field.

#### [MODIFY] [WindowManager.swift](file:///Users/himanshuyadav/Desktop/reverse%20engineer/Nischay/Windows/WindowManager.swift)
- **Elimination**: Remove `createMainWindow()`, `createControlsWindow()`, and `createChatInputWindow()`. These represent the "separate popup" the user wants gone.
- **Focus**: The `instructionsWindow` (to be renamed `dashboardWindow`) becomes the sole large panel.

#### [MODIFY] [PillToolbarView.swift](file:///Users/himanshuyadav/Desktop/reverse%20engineer/Nischay/Sources/Nischay/UI/Modals/PillToolbarView.swift)
- Update `onAnalyze` and `onChat` to tell the `SystemDelegate` to update the dashboard's mode.

#### [MODIFY] [NischaySystemDelegate.swift](file:///Users/himanshuyadav/Desktop/reverse%20engineer/Nischay/Sources/Nischay/Core/NischaySystemDelegate.swift)
- Update state orchestration to toggle the `UnifiedDashboardView` content.
- Ensure shortcut keys (⌘↩ and ⌘\) correctly interact with the new unified panel.

## Verification Plan

### Automated Tests
- `swift build` to ensure all UI routing is correctly typed.

### Manual Verification
1. Launch Nischay: Observe only the pill toolbar and the glassmorphic Instructions panel.
2. Click "Analyze": Verify the Instructions panel smoothly updates its content to show the AI response.
3. Click "Chat": Verify the panel switches to a chat interface with a text input.
4. Verify the "old" dark NSPanel windows決して出現しないこと (never appear).
