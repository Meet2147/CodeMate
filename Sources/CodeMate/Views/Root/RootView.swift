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

    // Sign in with Apple/Google (AuthGateView, AuthManager) is intentionally
    // not gating the app right now -- a redeemed license key alone is
    // enough to know who's paid and gate features, and it's what Polar's
    // checkout already tracks by email. Login mainly buys cross-device
    // progress sync, which isn't needed yet; it also needs real Apple
    // Developer Portal + Google Cloud OAuth setup that hasn't been done
    // (an ad-hoc-signed build with the Sign-in-with-Apple entitlement gets
    // killed outright by macOS, confirmed while building this). The auth
    // code is kept in the project, just not wired into this flow -- re-add
    // `if !auth.isSignedIn { AuthGateView() }` above once that setup is done
    // and an account layer is actually wanted.
    var body: some View {
        Group {
            if prefs.hasOnboarded {
                mainView
                    .transition(.opacity)
            } else {
                OnboardingView()
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: prefs.hasOnboarded)
    }

    private var mainView: some View {
        NavigationSplitView {
            VStack(alignment: .leading, spacing: 2) {
                ForEach(AppSection.allCases) { item in
                    sidebarRow(item)
                }
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 8)
            .padding(.top, 10)
            .navigationTitle("CodeMate")
            .navigationSplitViewColumnWidth(min: 200, ideal: 210, max: 240)
            .background(CMTheme.base(scheme))
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
                .frame(width: 520, height: 720)
        }
    }

    /// A hand-built row instead of List(selection:) -- that API's binding
    /// silently stopped updating `section` once before (a tag-type
    /// mismatch, since fixed) and clicks still weren't landing reliably
    /// after that fix, most likely because `.fixedSize()` on the label
    /// shrank the row's actual hit-testing area down to the text's
    /// intrinsic width instead of the full row. Building the row directly
    /// with an explicit full-width `.contentShape` removes any ambiguity
    /// about what area is clickable or how selection state updates.
    private func sidebarRow(_ item: AppSection) -> some View {
        let isSelected = section == item
        return HStack(spacing: 10) {
            Image(systemName: item.symbol)
                .font(.system(size: 13))
                .frame(width: 18)
            Text(item.rawValue)
                .font(.system(size: 13, weight: .medium))
            Spacer(minLength: 0)
        }
        .foregroundStyle(isSelected ? .white : CMTheme.textPrimary(scheme))
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .fill(isSelected ? AnyShapeStyle(CMTheme.accent) : AnyShapeStyle(Color.clear))
        )
        .contentShape(Rectangle())
        .onTapGesture { section = item }
    }
}
