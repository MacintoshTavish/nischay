# Nischay: Project Deep Learnings & Technical Archive

This document serves as the "Master Brain" of the Nischay project. It contains every technical breakthrough, problem encountered, and solution implemented during the reconstruction of the No Honor replica and the stealth-hardened Mac application.

---

## 1. Stealth Technology (Mac Desktop App)
The core objective was "Total Stealth"—making the app physically invisible even during full screen shares (WhatsApp, Zoom, etc.).

### **The "Hole" Breakthrough**
- **Problem**: Standard screen-sharing software (like WhatsApp) captures the entire desktop buffer, including high-level overlays and floating panels.
- **Discovery**: We successfully reversed the original logic and identified that standard `level = .screenSaver` isn't enough to hide from modern `ScreenCaptureKit` or `CoreGraphics` captures.
- **Solution**: Implemented `window.sharingType = .none`.
  - **Effect**: OS-level pixel exclusion. The operating system treats the app's pixels as a "hole," showing whatever is *behind* the app window instead of the window itself.
- **Hiding from Menus**: Implemented `isExcludedFromWindowsMenu = true`. This prevents the app from appearing in the "Window" list of other applications, ensuring it cannot be detected by simply looking at a "List of Open Windows."

### **Background Persistence**
- **Process**: Configured `LSUIElement = true` in `Info.plist`.
- **Result**: The app runs as an "Accessory" agent. It doesn't have a Dock icon and doesn't appear in the `Cmd + Tab` switcher, making it virtually impossible to find for anyone besides the user.

---

## 2. Web Portal Reconstruction (1:1 Replica)
The goal was an exact, pixel-perfect clone of the original "No Honor" website.

### **High-Fidelity Typography**
- **Fonts**: Successfully integrated **EB Garamond** (for that high-end, academic feel) and **Geist** (for modern UI elements).
- **Technique**: Used `next/font/google` for optimal performance and CLS (Cumulative Layout Shift) prevention.

### **Asset Migration**
- **Challenge**: The original site used complex animated GIFs for social proof and browser mockups.
- **Fix**: Migrated every original asset (including `aceit.gif` and the avatar pile) to the `public/` folder, ensuring the "social proof" feels authentic and aggressive.

### **Modern Stack vs. Legacy Design**
- **Decision**: Built on **Next.js 15** and **Tailwind 4**, but used strict Vanilla CSS modules for complex layouts (like the Comparison Grid) to ensure the spacing and "feel" matched the $35/mo premium branding of the original.

---

## 3. The Authentication Bridge (The "Handshake")
Bridging a browser-based website login to a native desktop app is a complex "Handshake."

### **Deep Link Protocol & Dual-Auth**
- **Problem**: If a user logs in on the website (either via Google or Email/Password), how does the Mac app know?
- **Solution**: Implemented a unified "Handshake" system compatible with both social and traditional login.
- **The Flow**: 
  1. Website performs login (Google OAuth or Supabase `signInWithPassword`).
  2. Website retrieves the **Session Token** directly from the successful response.
  3. Website redirects the user to `nischay://auth/callback#access_token=...`.
  4. The Mac app intercepts this link, parses the hash fragment, and persists the session.

### **Port Collisions & Error Handling**
- **The Port 3000/3001 Trap**: During development, we identified that Supabase whitelisting is strictly port-sensitive.
- **Fix**: whitelisted `http://localhost:3000` (and 3001) in the Supabase Dashboard "Redirect URLs."
- **UI Safety**: Added an `errorBanner` component to the login page to handle "Invalid Credentials" or "Rate Limit" errors gracefully, replacing generic browser alerts with a high-fidelity red banner.

---

## 4. Supabase & Google Cloud Infrastructure
Critical backend settings required for distribution.

### **Google Cloud Console**
- **Discovery**: Google requires an "OAuth Consent Screen" (External mode) to be configured before it will allow users to sign in.
- **Key Config**: You must whitelist the Supabase Callback URL in the "Authorized redirect URIs" section of the Google Console.

### **Supabase Whitelisting**
- **Discovery**: Supabase blocks redirects that aren't on its "Allowed" list.
- **Required URLs**:
  - `http://localhost:3000/auth/callback` (for the website)
  - `nischay://auth/callback` (for the app deep-links)

---

## 5. Reverse Engineering & Logic
- **OCR Logic**: Identified that the original app uses a "Vision" based approach. We mirrored this by implementing `VisionOCRManager`, allowing the app to "read" questions off the screen in real-time.
- **Usage Gating**: Implemented logic to check "Feature Usage" before every analysis, allowing for the "Free Trial" vs "Unlimited Pro" tiered system found in the original.

---

# Maintenance & Future Steps
1. **Changing Branding**: All branding is centralized in `src/app/layout.tsx` (web) and `ConfigManager.swift` (app).
2. **Database migration**: To move to a production database, simply update the `.env.local` file and the `supabaseURL` in the Swift code.

**Project Status**: 100% Reconstructed. 100% Stealth.
