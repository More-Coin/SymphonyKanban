import SwiftUI

@main
struct SymphonyKanbanApp: App {
    var body: some Scene {
        WindowGroup {
            SymphonyKanbanRootView()
        }
    }
}

private struct SymphonyKanbanRootView: View {
    var body: some View {
        SymphonyUIDI.makeDashboardRoutes()
    }
}

#Preview {
    SymphonyKanbanRootView()
}
