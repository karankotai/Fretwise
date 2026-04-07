import SwiftUI

struct ContentView: View {

    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false

    var body: some View {
        if hasCompletedOnboarding {
            AppTabView()
        } else {
            OnboardingContainerView {
                withAnimation {
                    hasCompletedOnboarding = true
                }
            }
        }
    }
}
