import SwiftUI

private struct OnboardingPage: Identifiable {
    let id = UUID()
    let title: String
    let subtitle: String
    let icon: String
    let accent: [Color]
    let indicator: [Color]
    let glow: Color
}

struct OnboardingView: View {
    @State private var currentPage = 0

    private let pages: [OnboardingPage] = [
        .init(
            title: "Track how\nholidays made\nyou feel",
            subtitle: "Remember not just what happened,\nbut how each celebration made you\nfeel",
            icon: "sparkles",
            accent: [Color(hex: 0xFFD700), Color(hex: 0xFFC300), Color(hex: 0xFF8C00)],
            indicator: [Color(hex: 0xFFD700), Color(hex: 0xFFC300), Color(hex: 0xFF8C00)],
            glow: Color(hex: 0xFFD700)
        ),
        .init(
            title: "Rate guests\nand locations",
            subtitle: "Keep track of who brings the best\nenergy and which places create the best\nmemories",
            icon: "person.2",
            accent: [Color(hex: 0xFF0055), Color(hex: 0xFF1A8C), Color(hex: 0xFF3366)],
            indicator: [Color(hex: 0xE10600), Color(hex: 0xFF1493), Color(hex: 0xFF6B6B)],
            glow: Color(hex: 0xE10600)
        ),
        .init(
            title: "See mood\ntrends and top\nguests",
            subtitle: "Discover patterns and insights to\nmake your future celebrations even\nbetter",
            icon: "arrow.up.right",
            accent: [Color(hex: 0x25D6FF), Color(hex: 0x297CFF), Color(hex: 0x35E8C2)],
            indicator: [Color(hex: 0x1E90FF), Color(hex: 0x00B66C), Color(hex: 0x1E90FF)],
            glow: Color(hex: 0x1E90FF)
        )
    ]

    var body: some View {
        GeometryReader { geo in
            let scale = min(geo.size.width / 393.0, geo.size.height / 852.0)
            let vSpacing = max(20, 47 * scale)

            ZStack {
                Image("Onboarding 6")
                    .resizable()
                   
                    .ignoresSafeArea()

                LinearGradient(
                    colors: [Color.blue.opacity(0.35), Color.black.opacity(0.55)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()

                RadialGradient(
                    colors: [Color.yellow.opacity(0.18), .clear],
                    center: .center,
                    startRadius: 0,
                    endRadius: 460
                )
                .ignoresSafeArea()

                VStack(spacing: vSpacing) {
                    TabView(selection: $currentPage) {
                        ForEach(Array(pages.enumerated()), id: \.element.id) { index, page in
                            pageContent(page: page, scale: scale)
                                .tag(index)
                        }
                    }
                    .tabViewStyle(.page(indexDisplayMode: .never))
                    .frame(maxHeight: .infinity)

                    footer(scale: scale)
                }
                .padding(.horizontal, 24 * scale)
                .padding(.top, max(32, geo.safeAreaInsets.top + 12))
                .padding(.bottom, max(20, geo.safeAreaInsets.bottom + 8))
            }
        }
    }

    private func pageContent(page: OnboardingPage, scale: CGFloat) -> some View {
        VStack(spacing: max(24, 40 * scale)) {
            iconCircle(icon: page.icon, accent: page.accent, scale: scale)

            VStack(spacing: max(18, 26 * scale)) {
                Text(page.title)
                    .font(.system(size: max(30, 36 * scale), weight: .bold))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4 * scale)
                    .minimumScaleFactor(0.85)

                Text(page.subtitle)
                    .font(.system(size: max(15, 18 * scale), weight: .regular))
                    .foregroundStyle(.white.opacity(0.82))
                    .multilineTextAlignment(.center)
                    .lineSpacing(5 * scale)
                    .minimumScaleFactor(0.85)
            }

            pageIndicator(scale: scale)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
    }

    private func iconCircle(icon: String, accent: [Color], scale: CGFloat) -> some View {
        let side = max(124, 160 * scale)

        return ZStack {
            LinearGradient(colors: accent, startPoint: .top, endPoint: .bottom)
                .frame(width: side, height: side)
                .clipShape(Circle())
                .shadow(color: accent.first?.opacity(0.65) ?? .yellow, radius: 14 * scale)

            Circle()
                .fill(Color(hex: 0x0A0E27))
                .frame(width: side - 8 * scale, height: side - 8 * scale)
                .overlay(Circle().stroke(Color.white.opacity(0.12), lineWidth: 1.5 * scale))

            Image(systemName: icon)
                .font(.system(size: max(36, 66 * scale), weight: .semibold))
                .foregroundStyle(.white)
        }
    }

    private func pageIndicator(scale: CGFloat) -> some View {
        HStack(spacing: 12 * scale) {
            ForEach(0..<pages.count, id: \.self) { index in
                if index == currentPage {
                    let active = pages[currentPage]
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: active.indicator,
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .frame(width: 48 * scale, height: 12 * scale)
                        .shadow(color: active.glow, radius: 20 * scale)
                        .shadow(color: active.glow.opacity(0.5), radius: 40 * scale)
                        .shadow(color: active.glow.opacity(0.2), radius: 60 * scale)
                } else {
                    Circle()
                        .fill(Color.white.opacity(0.25))
                        .frame(width: 12 * scale, height: 12 * scale)
                }
            }
        }
    }

    private func footer(scale: CGFloat) -> some View {
        VStack(spacing: 12 * scale) {
            if currentPage < pages.count - 1 {
                Button {
                    withAnimation(.easeInOut(duration: 0.25)) {
                        currentPage += 1
                    }
                } label: {
                    Text("CONTINUE")
                        .font(.system(size: max(16, 18 * scale), weight: .bold))
                        .foregroundStyle(Color(hex: 0x0A0E27))
                        .frame(maxWidth: .infinity)
                        .frame(height: max(50, 56 * scale))
                        .background(
                            LinearGradient(
                                colors: [Color(hex: 0xFFC300), Color(hex: 0xFFD700)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 16 * scale, style: .continuous))
                }

                Button {
                    withAnimation(.easeInOut(duration: 0.25)) {
                        currentPage = pages.count - 1
                    }
                } label: {
                    Text("Skip")
                        .font(.system(size: max(13, 15 * scale), weight: .semibold))
                        .foregroundStyle(Color.white.opacity(0.75))
                        .frame(maxWidth: .infinity)
                        .frame(height: 30 * scale)
                }
            } else {
                Button {
          
                } label: {
                    HStack(spacing: 6 * scale) {
                        Text("🎉")
                        Text("GET STARTED WITH SAMPLE DATA")
                    }
                    .font(.system(size: max(15, 16 * scale), weight: .bold))
                    .foregroundStyle(Color(hex: 0x0A0E27))
                    .frame(maxWidth: .infinity)
                    .frame(height: max(50, 56 * scale))
                    .background(
                        LinearGradient(
                            colors: [Color(hex: 0xFFC300), Color(hex: 0xFFD700)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 16 * scale, style: .continuous)
                            .stroke(Color.white.opacity(0.3), lineWidth: 1)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 16 * scale, style: .continuous))
                    .shadow(color: Color(hex: 0xFFD700, alpha: 0.4), radius: 10 * scale, y: 4 * scale)
                }

                Button {
               
                } label: {
                    Text("Start Fresh")
                        .font(.system(size: max(16, 18 * scale), weight: .bold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: max(50, 56 * scale))
                        .background(
                            LinearGradient(
                                colors: [Color(hex: 0xFFC300), Color(hex: 0xFFD700)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 16 * scale, style: .continuous))
                }
            }
        }
        .frame(maxWidth: .infinity)
    }
}

private extension Color {
    init(hex: UInt, alpha: Double = 1.0) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255.0,
            green: Double((hex >> 8) & 0xFF) / 255.0,
            blue: Double(hex & 0xFF) / 255.0,
            opacity: alpha
        )
    }
}
#Preview {
    OnboardingView()
}
