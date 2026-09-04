import SwiftUI
import AuthenticationServices

/// First screen on a fresh launch (or after signing out): animated welcome
/// + Sign in with Apple / Google. Nothing past this point is reachable
/// without an account, since that's what ties a license/subscription to a
/// person. Company-picker onboarding follows once signed in.
struct AuthGateView: View {
    @Environment(AuthManager.self) private var auth
    @State private var hasAppeared = false
    @State private var bulletsVisible = false

    private let bullets = [
        ("curlybraces", "74 DSA problems, company-tagged, on-device AI help"),
        ("puzzlepiece.extension", "12 LLD/HLD system-design questions + a whiteboard"),
        ("person.2.wave.2", "Practice Together -- solve live with a friend over FaceTime")
    ]

    var body: some View {
        ZStack {
            animatedBackground

            VStack(spacing: 36) {
                Spacer(minLength: 20)

                logoMark
                    .scaleEffect(hasAppeared ? 1 : 0.6)
                    .opacity(hasAppeared ? 1 : 0)

                VStack(spacing: 10) {
                    Text("Welcome to CodeMate")
                        .font(.system(size: 30, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                    Text("Interview prep that never lets you panic.")
                        .font(.system(size: 14))
                        .foregroundStyle(.white.opacity(0.7))
                }
                .opacity(hasAppeared ? 1 : 0)
                .offset(y: hasAppeared ? 0 : 12)

                VStack(alignment: .leading, spacing: 12) {
                    ForEach(Array(bullets.enumerated()), id: \.offset) { index, bullet in
                        HStack(spacing: 10) {
                            Image(systemName: bullet.0)
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundStyle(.white)
                                .frame(width: 22)
                            Text(bullet.1)
                                .font(.system(size: 12.5))
                                .foregroundStyle(.white.opacity(0.85))
                        }
                        .opacity(bulletsVisible ? 1 : 0)
                        .offset(x: bulletsVisible ? 0 : -14)
                        .animation(.easeOut(duration: 0.4).delay(0.5 + Double(index) * 0.12), value: bulletsVisible)
                    }
                }
                .frame(maxWidth: 380, alignment: .leading)

                VStack(spacing: 12) {
                    SignInWithAppleButton(.continue) { request in
                        request.requestedScopes = [.fullName, .email]
                    } onCompletion: { result in
                        auth.handleAppleSignIn(result)
                    }
                    .signInWithAppleButtonStyle(.white)
                    .frame(width: 300, height: 44)

                    Button {
                        auth.signInWithGoogle()
                    } label: {
                        HStack(spacing: 10) {
                            Text("G").font(.system(size: 16, weight: .bold, design: .rounded))
                                .foregroundStyle(
                                    LinearGradient(colors: [.blue, .red, .yellow, .green], startPoint: .leading, endPoint: .trailing)
                                )
                            Text("Continue with Google")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(.black.opacity(0.85))
                        }
                        .frame(width: 300, height: 44)
                        .background(RoundedRectangle(cornerRadius: 8).fill(Color.white))
                    }
                    .buttonStyle(.plain)

                    if auth.isSigningIn {
                        ProgressView().controlSize(.small).tint(.white)
                    }
                    if let error = auth.lastError {
                        Text(error)
                            .font(.system(size: 11))
                            .foregroundStyle(.red.opacity(0.9))
                            .multilineTextAlignment(.center)
                            .frame(maxWidth: 320)
                    }
                }
                .opacity(hasAppeared ? 1 : 0)
                .offset(y: hasAppeared ? 0 : 12)

                Text("By continuing you agree this is a demo build -- see Settings for how licensing works.")
                    .font(.system(size: 9.5))
                    .foregroundStyle(.white.opacity(0.4))

                #if DEBUG
                // Apple sign-in needs the app ID registered + properly
                // signed (see Scripts/build_app.sh's notes), and Google
                // needs a real OAuth client ID -- neither works yet from an
                // ad-hoc local build. This link only exists in debug builds
                // (compiled out of `swift build -c release`) so testing the
                // rest of the app isn't blocked on that setup being done.
                Button("Skip sign-in (debug builds only)") {
                    auth.debugSignInAsDeveloper()
                }
                .buttonStyle(.plain)
                .font(.system(size: 10.5, weight: .semibold))
                .foregroundStyle(.white.opacity(0.55))
                #endif

                Spacer(minLength: 20)
            }
            .padding(40)
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.75)) { hasAppeared = true }
            withAnimation { bulletsVisible = true }
        }
    }

    private var logoMark: some View {
        PhaseAnimator([0, 1]) { phase in
            ZStack {
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(LinearGradient(colors: [Color(red: 0.42, green: 0.50, blue: 1.00), Color(red: 0.29, green: 0.34, blue: 0.92)], startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(width: 88, height: 88)
                    .shadow(color: Color(red: 0.35, green: 0.4, blue: 0.95).opacity(0.5), radius: 20, y: 8)
                Image(systemName: "curlybraces")
                    .font(.system(size: 42, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white)
                Circle()
                    .fill(Color(red: 1.0, green: 0.78, blue: 0.35))
                    .frame(width: 12, height: 12)
                    .offset(x: 24, y: 22)
            }
            .offset(y: phase == 0 ? 0 : -6)
        } animation: { _ in
            .easeInOut(duration: 2.2)
        }
    }

    private var animatedBackground: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30.0)) { context in
            let t = context.date.timeIntervalSinceReferenceDate
            LinearGradient(
                colors: [
                    Color(red: 0.08 + 0.02 * sin(t * 0.15), green: 0.08, blue: 0.16 + 0.03 * cos(t * 0.1)),
                    Color(red: 0.05, green: 0.05, blue: 0.09)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
        }
    }
}
