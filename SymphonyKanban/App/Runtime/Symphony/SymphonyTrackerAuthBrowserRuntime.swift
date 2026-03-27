import Foundation
#if os(macOS)
import AppKit
#endif

@MainActor
struct SymphonyTrackerAuthBrowserRuntime {
    private let openExternalURL: (URL) -> Void

    init(
        openExternalURL: @escaping (URL) -> Void = { url in
            #if os(macOS)
            NSWorkspace.shared.open(url)
            #endif
        }
    ) {
        self.openExternalURL = openExternalURL
    }

    func open(
        _ url: URL
    ) {
        openExternalURL(url)
    }
}
