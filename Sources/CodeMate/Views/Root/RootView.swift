import SwiftUI

enum AppSection: String, CaseIterable, Identifiable {
    case practice = "DSA Practice"
    case systemDesign = "LLD / HLD"
    case progress = "My Progress"

    var id: String { rawValue }
    var symbol: String {
        switch self {
        case .practice: return "curlybraces"
        case .systemDesign: return "square.on.square.dashed"
        case .progress: return "chart.line.uptrend.xyaxis"
        }
    }
}

struct RootView: View {
    @Environment(\.colorScheme) private var scheme
    @Environment(AppPreferences.self) private var prefs
    @State private var section: AppSection = .practice
    @State private var showsSettings = false

    var body: some View {
        if prefs.hasOnboarded {
            mainView
        } else {
            OnboardingView()
        }
    }

    private var mainView: some View {
        NavigationSplitView {
            List(AppSection.allCases, selection: $section) { item in
                Label(item.rawValue, systemImage: item.symbol)
                    .font(.system(size: 13, weight: .medium))
                    .lineLimit(1)
                    .fixedSize(horizontal: true, vertical: false)
                    .tag(item as AppSection?)
                    .padding(.vertical, 5)
            }
            .navigationTitle("CodeMate")
            .listStyle(.sidebar)
            .navigationSplitViewColumnWidth(min: 200, ideal: 210, max: 240)
            .safeAreaInset(edge: .bottom) {
                Button {
                    showsSettings = true
                } label: {
                    Label("Settings", systemImage: "gearshape")
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .buttonStyle(NeumorphicButtonStyle())
                .padding(12)
            }
        } detail: {
            Group {
                switch section {
                case .practice: PracticeHomeView()
                case .systemDesign: SystemDesignHomeView()
                case .progress: ProgressHomeView()
                }
            }
            .background(CMTheme.base(scheme).ignoresSafeArea())
            .animation(.easeInOut(duration: 0.18), value: section)
        }
        .navigationSplitViewStyle(.balanced)
        .sheet(isPresented: $showsSettings) {
            SettingsView()
                .frame(width: 520, height: 600)
        }
    }
}
