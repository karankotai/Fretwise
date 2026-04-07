import SwiftUI

struct AppTabView: View {

    var body: some View {
        TabView {
            ModuleListView()
                .tabItem {
                    Label("Learn", systemImage: "book.fill")
                }

            Text("Songs — Coming Soon")
                .tabItem {
                    Label("Songs", systemImage: "music.note.list")
                }

            Text("Tools — Coming Soon")
                .tabItem {
                    Label("Tools", systemImage: "wrench.and.screwdriver")
                }

            Text("Profile — Coming Soon")
                .tabItem {
                    Label("Profile", systemImage: "person.crop.circle")
                }
        }
        .tint(.green)
    }
}
