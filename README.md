# 💾 FullDiskAccess

FullDiskAccess is a Swift package for querying and prompting for Full Disk Access permission on macOS 10.14+

### When do you need Full Disk Access?

When your macOS app is not sandboxed and you need to access system files or files belonging to other apps. Example apps: file backup apps, apps that need to search the entire system, etc.

### Why a package?

The lack of documentation regarding Full Disk Access creates a lot of confusion online, so I ran 6 VMs to confirm behavior between macOS versions. This package makes clear what's possible and what's not, and makes it easy to check permission and prompt the user.

### Usage

#### Checking the current status

```swift
import FullDiskAccess

if FullDiskAccess.isGranted {
    // Great!
}
```

ℹ️ On macOS 10.15+, checking `isGranted` will automatically add your app to the Full Disk Access entries in Privacy & Security (unchecked)

#### Prompting the user to enable Full Disk Access

Apps cannot enable Full Disk Access automatically (for good reason), so the user will have to do that. We make it easy by automatically adding the app to the Full Disk Access entries in Privacy & Security (unchecked) and guiding the user to that screen.

```swift
import FullDiskAccess

FullDiskAccess.promptIfNotGranted(
    title: "Enable Full Disk Access for MacSymbolicator",
    message: "MacSymbolicator requires Full Disk Access to search for DSYMs using Spotlight.",
    settingsButtonTitle: "Open Settings",
    skipButtonTitle: "Later",
    skipHandler: { print("User skipped permission screen!") },
    canBeSuppressed: false, // `true` will display a "Do not ask again." checkbox and honor it
    icon: nil
)
```

<img width="300" src="https://github.com/inket/FullDiskAccess/assets/679224/236b719d-2b4a-4f03-8aef-ba1d11e176c4">

<img width="480" src="https://github.com/inket/FullDiskAccess/assets/679224/d52dab09-2974-45bd-807a-dc3f8edb8f55">

#### Other tasks

```swift

import FullDiskAccess

// Opens the System Settings (aka System Preferences) with the Privacy & Security preference pane open and the
// Full Disk Access tab pre-selected.
FullDiskAccess.openSystemSettings()

// Resets the prompt suppression (i.e. if the user has selected "Do not ask again.", this resets their choice)
FullDiskAccess.resetPromptSuppression() {
```

### Support the project

<a href="https://www.buymeacoffee.com/mahdibchatnia" target="_blank"><img src="https://cdn.buymeacoffee.com/buttons/v2/default-yellow.png" alt="Buy Me A Coffee" height="48" width="173" ></a>

### Contribute

Believe something is not right or have a suggestion for improvements? Your feedback is welcome. Please create an issue!

### Contact

[@inket](https://github.com/inket) / [@inket](https://mastodon.social/@inket) on Mastodon / [mahdi.jp](https://mahdi.jp)
