import SwiftUI

struct ContentView: View {
    @EnvironmentObject var store: StoreManager
    @State private var selectedTab: Tab = .record

    enum Tab { case record, memos, settings }

    var body: some View {
        TabView(selection: $selectedTab) {
            RecordView()
                .tabItem { Label("Record", systemImage: "mic.fill") }
                .tag(Tab.record)

            MemoListView()
                .tabItem { Label("Memos", systemImage: "list.bullet.rectangle.fill") }
                .tag(Tab.memos)

            SettingsView()
                .tabItem { Label("Settings", systemImage: "gearshape.fill") }
                .tag(Tab.settings)
        }
        .accentColor(.purple)
    }
}
