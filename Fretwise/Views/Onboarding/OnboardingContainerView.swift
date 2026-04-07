import SwiftUI

struct OnboardingContainerView: View {

    let onComplete: () -> Void
    @State private var step = 0

    var body: some View {
        TabView(selection: $step) {
            WelcomeView {
                withAnimation { step = 1 }
            }
            .tag(0)

            SkillLevelView { _ in
                withAnimation { step = 2 }
            }
            .tag(1)

            MicPermissionView {
                onComplete()
            }
            .tag(2)
        }
        .tabViewStyle(.page(indexDisplayMode: .always))
        .indexViewStyle(.page(backgroundDisplayMode: .always))
        .background(Color.black.ignoresSafeArea())
    }
}
