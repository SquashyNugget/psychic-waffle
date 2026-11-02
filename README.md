# Badminton Court Manager

**Full SwiftUI iPhone source project** — native stopwatch / knock-up app with four courts, sound alerts and a combined Lock Screen Live Activity.

This is **source code**, not a compiled, signed `.ipa`. It is prepared for development on **Windows** with VS Code and GitHub Copilot; **Xcode on an Apple Silicon Mac** is needed to compile iOS code. No paid services or AI API keys are required.

## Included functionality

- 4 independent courts displayed in a 2 × 2 layout on iPhone; wider grid on iPad.
- Each court selects **Knock Up** (two-minute countdown) or **Stopwatch** (unlimited count-up).
- Start/Pause/Resume/Reset per court, plus Knock Up All, Pause All and Reset All.
- At two minutes, native iOS **local notification** with the court number and the default notification sound. The OS controls vibration/haptics and notification presentation.
- The completed Knock Up returns to **00:00**, stops running, and shows **Finished** in the app until restarted or cleared.
- Counts correctly after the phone is locked or the app is reopened, using saved start timestamps rather than relying on foreground timers.
- One combined **ActivityKit Live Activity** with circular indicators and live countdown *text* for currently running courts. Dynamic Island display on supported iPhones.
- Offline functionality; no accounts, servers, subscriptions or third-party packages.
- Test alert button and notification-permission screen.
- Unit tests for the pure timer engine.

### Important platform limitation

Although iOS will deliver a scheduled local notification when the two-minute countdown expires while the phone is locked, iOS **does not guarantee it will wake the app** to update ActivityKit at that exact moment. A completed circle may remain visible on the Lock Screen until the app is opened or receives an allowed update. Then the completed court disappears from the combined Live Activity, and the last completed court causes the entire Live Activity to end. The ring's decorative stroke is *not* a guaranteed continuously animating progress ring while locked; the system-rendered countdown digits can change. An exact-second sound/vibration or automatic removal cannot be guaranteed by iOS.

## Folder guide

- `App/` — SwiftUI app entry point, app-wide state store and `Info.plist`.
- `Core/` — pure stopwatch/countdown data model and timer engine.
- `Services/` — persistence, native notifications, ActivityKit management.
- `Shared/` — Codable ActivityKit models compiled into both targets.
- `UI/` — main dashboard, court cards, rings and Settings.
- `WidgetExtension/` — separate Live Activity / Dynamic Island extension.
- `Resources/` — app icon and accent color.
- `Tests/` — seven timer tests executable using Swift Package Manager.
- `BadmintonCourtManager.xcodeproj/` — already-generated Xcode project (open directly).
- `project.yml` — optional XcodeGen alternative if you later add files.
- `Scripts/` — Mac project-generation and unsigned IPA build helpers.

## Windows (all coding can happen here)

1. Extract this ZIP on your Windows computer.
2. Open the extracted directory in **VS Code**, with GitHub Copilot Chat in Agent mode.
3. Edit Swift source files. You do not need a Mac to edit Swift, but Windows cannot compile the SwiftUI/ActivityKit iPhone targets.
4. Transfer the folder to your Mac mini via GitHub, a file share, or a USB drive.
5. Optional: use `swift test` on Windows if you have the Swift toolchain and a supported build environment; `Package.swift` tests the portable `Core/` logic.

## Mac mini: create the Xcode project (no coding on the Mac)

1. Install **Xcode** from the Mac App Store; launch it once to complete setup.
2. Double-click the included **`BadmintonCourtManager.xcodeproj`**. No coding, Homebrew or XcodeGen installation is necessary for the supplied files. If you'd rather use a single script, double-click `Scripts/create-xcode-project.command` (it just opens the included project).
3. Pick the `BadmintonCourtManager` **scheme**, your connected iPhone as the device, and your **Personal Team** under Signing & Capabilities for **both the app and the widget extension**. If needed, change the two unique bundle IDs in `project.yml`, regenerate and re-select your team.
4. Click **Run** (triangle) to install the development build. Accept the notification permission in Settings in the app. Enable Live Activities on the iPhone where available.
5. Start Court 1 Knock Up, lock the phone, and test the local alert at two minutes and the Lock Screen Live Activity.

## Mac mini: generate unsigned IPA for SideStore

With Xcode installed on your Mac mini, use:

```bash
./Scripts/build-unsigned-ipa.command
```

This creates `Output/BadmintonCourtManager-UNSIGNED.ipa`. It **must** still be signed by SideStore or a compatible signing tool before installation. SideStore/free Apple signing may fail to preserve the widget extension, App Intents or Live Activity behaviour. Verify SideStore's ability to sign **both** bundles on your actual device. Do not pay for a signing service until the extension works in a test build. The free Apple account's own development provisioning expires after seven days.

**Simplest reliable first test:** Xcode > Run to your connected iPhone. That uses your free Apple account and does not require manually exporting an IPA.

## Unit tests

On Mac/Linux (or correctly configured Swift on Windows):

```bash
swift test
```

## No guarantee of verified iOS build

The full project and generator configuration have been authored and syntax-checked outside macOS. **They have not been compiled against Apple's iOS SDK or installed on a physical iPhone here.** If Xcode reports an SDK-specific error, give the error text to GitHub Copilot, or bring it back to ChatGPT for correction. Keep the app's target and widget-extension target separate — a plain Swift file bundle without the extension will not support Live Activities.

## Maintaining Xcode project files if you add new Swift files

The bundled `.xcodeproj` already includes every file in this version. If you add new Swift files on Windows, regenerate the Xcode project on the Mac with `python3 Scripts/generate_xcodeproj.py` (Python 3) or with `xcodegen generate` after `brew install xcodegen`. Existing bundle identifiers and signing choices in Xcode may need reselecting after regeneration.

## Optional: build on GitHub Actions rather than the Mac mini

The `.github/workflows/build-unsigned-ipa.yml` workflow builds the app and embedded widget extension on a hosted macOS runner, using the project's existing `.xcodeproj`. Push this folder to your own GitHub repository, open **Actions → Build unsigned iOS IPA → Run workflow**, then download the build artifact. Runner availability and usage are subject to GitHub's current limits. The downloaded IPA is **unsigned**; SideStore must sign the app and extension before installation, and Live Activities might not survive this signing path. If the workflow fails, the complete Xcode build log is available in the Actions run.
