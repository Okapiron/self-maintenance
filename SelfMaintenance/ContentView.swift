import SwiftUI

struct ContentView: View {
    @AppStorage(SettingsKey.hasCompletedOnboarding) private var hasCompletedOnboarding = false
    @AppStorage(SettingsKey.selectedTheme) private var selectedTheme = AppTheme.cleanBlue.rawValue

    private var theme: AppTheme {
        AppTheme(rawValue: selectedTheme) ?? .cleanBlue
    }

    var body: some View {
        Group {
            if hasCompletedOnboarding {
                TabView {
                    HomeView(theme: theme)
                        .tabItem {
                            Label("ホーム", systemImage: "house")
                        }

                    CalendarView(theme: theme)
                        .tabItem {
                            Label("カレンダー", systemImage: "calendar")
                        }

                    SpendingView(theme: theme)
                        .tabItem {
                            Label("支出", systemImage: "chart.bar")
                        }

                    SettingsView(theme: theme)
                        .tabItem {
                            Label("設定", systemImage: "gearshape")
                        }
                }
                .tint(theme.accent)
            } else {
                OnboardingView(theme: theme)
            }
        }
    }
}
