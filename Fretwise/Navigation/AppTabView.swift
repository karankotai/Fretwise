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

            TunerView()
                .tabItem {
                    Label("Tuner", systemImage: "tuningfork")
                }

            Text("Profile — Coming Soon")
                .tabItem {
                    Label("Profile", systemImage: "person.crop.circle")
                }
        }
        .tint(.green)
    }
}
