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
    var body: some View {
        SymphonyUIDI.makeNavigationRoutes()
    }
}

#Preview {
    SymphonyKanbanRootView()
        .frame(width: 1280, height: 800)
}
