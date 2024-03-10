import Foundation
import AppKit
import OSLog

// A helper for managing Full Disk Access (FDA). An app that's granted FDA can access other apps' containers.
// Checking whether FDA is granted will add the app to the FDA entries in Privacy & Security (an exception to that is
// macOS 10.14 for which we cannot automatically add the entry)

public enum FullDiskAccess {
    private enum MacOS {
        case mojave // 10.14
        case catalina // 10.15
        case bigSur // 11
        case monterey // 12
        case ventura // 13
        case sonoma // 14
    }

    private static var currentOS: MacOS {
        if #available(macOS 14, *) {
            return .sonoma
        } else if #available(macOS 13, *) {
            return .ventura
        } else if #available(macOS 12, *) {
            return .monterey
        } else if #available(macOS 11, *) {
            return .bigSur
        } else if #available(macOS 10.15, *) {
            return .catalina
        } else {
            return .mojave
        }
    }

    /// Checks and returns the status of Full Disk Access for the current app. Accessing this property automatically
    /// adds the current app to the Full Disk Access entries in Privacy & Security.
    public static var isGranted: Bool {
        guard !appIsSandboxed else {
            os_log(.error, log: .fullDiskAccess, "isGranted will always return false in a sandboxed app.")
            return false
        }

        let checkPath: String

        switch currentOS {
        case .monterey, .ventura, .sonoma:
            checkPath = "~/Library/Containers/com.apple.stocks"
        case .mojave, .catalina, .bigSur:
            checkPath = "~/Library/Safari"
        }

        do {
            _ = try FileManager.default.contentsOfDirectory(atPath: expandedPath(checkPath))
            os_log(.debug, log: .fullDiskAccess, "Full Disk Access is granted (able to read %@)", checkPath)
            return true
        } catch let error {
            os_log(.debug, log: .fullDiskAccess, "Full Disk Access is not granted (Unable to read %@)", checkPath)
            return false
        }
    }


    /// Opens the System Settings (aka System Preferences) with the Privacy & Security preference pane open and the
    /// Full Disk Access tab pre-selected.
    public static func openSystemSettings() {
        let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_AllFiles")!
        NSWorkspace.shared.open(url)
    }

    /// Displays an alert to the user if Full Disk Access is not granted to the current app, with the option to open
    /// the Privacy & Security preference pane or skip.
    public static func promptIfNotGranted(
        title: String,
        message: String,
        settingsButtonTitle: String = "Open Settings",
        skipButtonTitle: String = "Later",
        canBeSuppressed: Bool = false,
        icon: NSImage? = nil
    ) {
        guard !canBeSuppressed || !promptSuppressed else {
            // Prompt has been suppressed by the user because they checked "Do not ask again."
            os_log(.debug, log: .fullDiskAccess, "Prompt has not appeared because it has been suppressed by the user")
            return
        }

        guard !appIsSandboxed else {
            // Sandboxed app cannot gain FDA
            os_log(.error, log: .fullDiskAccess, "Prompt has not appeared because the app is sandboxed")
            return
        }

        guard !isGranted else {
            // Granted app doesn't need it
            os_log(.debug, log: .fullDiskAccess, "Prompt has not appeared because Full Disk Access is already granted")
            return
        }

        let alert = NSAlert()
        alert.messageText = title
        alert.informativeText = message

        if canBeSuppressed {
            alert.showsSuppressionButton = true
        }

        if let icon {
            alert.icon = icon
        } else if let appIconImage = NSApp.applicationIconImage {
            // Draw the app icon with an info icon as a badge
            let appIconInset: CGFloat = 4
            let infoIconScale: CGFloat = 0.45
            alert.icon = NSImage(size: appIconImage.size, flipped: false) { drawRect in
                appIconImage.draw(in: drawRect.insetBy(dx: appIconInset, dy: appIconInset))
                let badgeRect = NSRect(
                    x: drawRect.width - (drawRect.width * infoIconScale),
                    y: 0,
                    width: drawRect.width * infoIconScale,
                    height: drawRect.height * infoIconScale
                )
                NSImage(named: "NSInfo")?.draw(in: badgeRect)
                return true
            }
        } else {
            alert.icon = NSImage(named: "NSInfo")
        }

        alert.addButton(withTitle: settingsButtonTitle)
        alert.addButton(withTitle: skipButtonTitle)

        let response = alert.runModal()

        if alert.suppressionButton?.state == .on {
            promptSuppressed = true
        }

        switch response {
        case .alertFirstButtonReturn:
            // Settings button
            openSystemSettings()
        case .alertSecondButtonReturn:
            // Skip button
            return
        default:
            return
        }
    }

    /// Resets the prompt suppression (i.e. if the user has selected "Do not ask again.", this resets their choice)
    public static func resetPromptSuppression() {
        promptSuppressed = false
    }
}

extension FullDiskAccess {
    private static var appIsSandboxed: Bool {
        ProcessInfo.processInfo.environment["APP_SANDBOX_CONTAINER_ID"] != nil
    }

    private static var promptSuppressed: Bool {
        get {
            UserDefaults.standard.bool(forKey: "fda_suppressed") ?? false
        }
        set {
            UserDefaults.standard.setValue(newValue, forKey: "fda_suppressed")
        }
    }

    private static func expandedPath(_ path: String) -> String {
        guard let pw = getpwuid(getuid()) else { return path }
        let homeURL = URL(fileURLWithFileSystemRepresentation: pw.pointee.pw_dir, isDirectory: true, relativeTo: nil)
        return path.replacingOccurrences(of: "~", with: homeURL.path)
    }
}

private extension OSLog {
    static let fullDiskAccess = OSLog(
        subsystem: Bundle.main.bundleIdentifier ?? "FDA",
        category: "FullDiskAccess"
    )
}
