import Darwin
import SwiftUI

@main
struct SymphonyKanbanApp: App {
    var body: some Scene {
        WindowGroup {
            SymphonyKanbanRootView()
        }
        .windowStyle(.hiddenTitleBar)
        .defaultSize(width: 1280, height: 800)
    }
}

private struct SymphonyKanbanRootView: View {
    @State private var hasActivatedStartupFlow = false

    private var isRunningForPreviews: Bool {
        SymphonyPreviewRuntimeView.isRunning
    }

    var body: some View {
        Group {
            if isRunningForPreviews {
                SymphonyPreviewDI.makeRootPreview()
            } else if hasActivatedStartupFlow {
                SymphonyUIDI.makeStartupGate()
            } else {
                SymphonyStartupLoadingView()
            }
        }
        .task {
            guard isRunningForPreviews == false,
                  hasActivatedStartupFlow == false else {
                return
            }

            // Let the app host settle its first frame before startup orchestration begins.
            try? await Task.sleep(nanoseconds: 150_000_000)
            hasActivatedStartupFlow = true
        }
    }
}

private enum SymphonyPreviewRuntimeView {
    static let isRunning: Bool = {
        if ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1" {
            return true
        }

        if ProcessInfo.processInfo.processName == "XCPreviewAgent"
            || ProcessInfo.processInfo.processName == "Xcode Previews" {
            return true
        }

        let imageCount = _dyld_image_count()
        for index in 0 ..< imageCount {
            guard let imageName = _dyld_get_image_name(index) else {
                continue
            }

            if String(cString: imageName).contains("__preview.dylib") {
                return true
            }
        }

        return false
    }()
}

#Preview {
    SymphonyPreviewDI.makeRootPreview()
        .frame(width: 1280, height: 800)
}
