import SwiftUI

@main
struct VoxNoteApp: App {
    @StateObject private var store = StoreManager()
    @StateObject private var memoStore = MemoStore()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(store)
                .environmentObject(memoStore)
                .preferredColorScheme(.none)
        }
    }
}
