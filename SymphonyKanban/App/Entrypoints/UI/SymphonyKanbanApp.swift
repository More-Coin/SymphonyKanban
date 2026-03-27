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
    @State private var pendingTrackerAuthCallbackURL: URL?

    var body: some View {
        SymphonyUIDI.makeNavigationRoutes(
            pendingTrackerAuthCallbackURL: $pendingTrackerAuthCallbackURL
        )
        .onOpenURL { url in
            pendingTrackerAuthCallbackURL = url
        }
    }
}

#Preview {
    SymphonyKanbanRootView()
        .frame(width: 1280, height: 800)
}
