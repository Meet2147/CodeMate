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
    @State private var section: AppSection = .practice
    @State private var showsSettings = false

    var body: some View {
        NavigationSplitView {
            List(AppSection.allCases, selection: $section) { item in
                Label(item.rawValue, systemImage: item.symbol)
                    .tag(item as AppSection?)
                    .padding(.vertical, 4)
            }
            .navigationTitle("CodeMate")
            .listStyle(.sidebar)
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
        }
        .sheet(isPresented: $showsSettings) {
            SettingsView()
                .frame(width: 480, height: 460)
        }
    }
}
