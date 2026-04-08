import SwiftUI

struct CelebrationGuest: Identifiable {
    let id = UUID()
    let name: String
    let relation: String
    let rating: Int
}

struct CelebrationDetailData {
    let title: String
    let category: String
    let moodEmoji: String
    let moodTitle: String
    let dateText: String
    let place: String
    let placeRating: Int
    let holidayRating: Int
    let note: String
    let guests: [CelebrationGuest]
}

struct CelebrationDetailView: View {
    let data: CelebrationDetailData
    let bottomInset: CGFloat
    let onBack: () -> Void
    let onEdit: () -> Void
    let onDelete: () -> Void

    var body: some View {
        GeometryReader { geo in
            let scale = min(geo.size.width / 393.0, geo.size.height / 852.0)

            ZStack {
                LinearGradient(
                    colors: [.black, Color(hex: 0x002672), .black],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()

                VStack(spacing: 0) {
                    topBar(scale: scale, topSafe: geo.safeAreaInsets.top)

                    ScrollView(.vertical, showsIndicators: false) {
                        VStack(alignment: .leading, spacing: 24 * scale) {
                            titleSection(scale: scale)
                            dateCard(scale: scale)
                            placeCard(scale: scale)
                            holidayRatingCard(scale: scale)
                            guestsCard(scale: scale)
                            noteCard(scale: scale)
                        }
                        .padding(.horizontal, 24 * scale)
                        .padding(.top, 24 * scale)
                        .padding(.bottom, max(bottomInset, 24 * scale))
                    }
                }
            }
        }
    }

    private func topBar(scale: CGFloat, topSafe: CGFloat) -> some View {
        HStack {
            Button(action: onBack) {
                Image(systemName: "arrow.left")
                    .font(.system(size: 20 * scale, weight: .regular))
                    .foregroundStyle(.white)
                    .frame(width: 36 * scale, height: 36 * scale)
            }
            .buttonStyle(.soundPlain)

            Spacer()

            HStack(spacing: 8 * scale) {
                Button(action: onEdit) {
                    HStack(spacing: 8 * scale) {
                        Image(systemName: "square.and.pencil")
                            .font(.system(size: 16 * scale, weight: .medium))
                        Text("Edit")
                            .font(.system(size: max(13, 14 * scale), weight: .medium))
                    }
                    .foregroundStyle(.white)
                    .padding(.horizontal, 10 * scale)
                    .frame(height: 32 * scale)
                    .background(Color.black)
                    .overlay(RoundedRectangle(cornerRadius: 10 * scale).stroke(Color.white.opacity(0.2), lineWidth: 0.57 * scale))
                    .clipShape(RoundedRectangle(cornerRadius: 10 * scale))
                }
                .buttonStyle(.soundPlain)

                Button(action: onDelete) {
                    HStack(spacing: 8 * scale) {
                        Image(systemName: "trash")
                            .font(.system(size: 16 * scale, weight: .medium))
                        Text("Delete")
                            .font(.system(size: max(13, 14 * scale), weight: .medium))
                    }
                    .foregroundStyle(Color(hex: 0xFF6467))
                    .padding(.horizontal, 10 * scale)
                    .frame(height: 32 * scale)
                    .background(Color.black)
                    .overlay(RoundedRectangle(cornerRadius: 10 * scale).stroke(Color(hex: 0xFB2C36, alpha: 0.2), lineWidth: 0.57 * scale))
                    .clipShape(RoundedRectangle(cornerRadius: 10 * scale))
                }
                .buttonStyle(.soundPlain)
            }
        }
        .padding(.horizontal, 16 * scale)
        .padding(.top, max(0, topSafe))
        .frame(height: 99 * scale + max(0, topSafe))
        .background(Color.black.opacity(0.8))
        .overlay(Rectangle().fill(Color.black).frame(height: 0.57 * scale), alignment: .bottom)
    }

    private func titleSection(scale: CGFloat) -> some View {
        VStack(alignment: .leading, spacing: 8 * scale) {
            HStack(alignment: .top) {
                Text(data.title)
                    .font(.system(size: max(30, 36 * scale), weight: .medium))
                    .foregroundStyle(.white)
                    .lineLimit(nil)
                Spacer()
                HStack(spacing: 6 * scale) {
                    Text(data.moodEmoji)
                    Text(data.moodTitle)
                        .font(.system(size: max(14, 16 * scale), weight: .regular))
                }
                .foregroundStyle(.white)
                .padding(.leading, 16 * scale)
                .padding(.trailing, 14 * scale)
                .frame(height: 41.12 * scale)
                .background(Color.white.opacity(0.2))
                .overlay(Capsule().stroke(Color.white.opacity(0.4), lineWidth: 0.57 * scale))
                .clipShape(Capsule())
            }

            Text(data.category)
                .font(.system(size: max(14, 16 * scale), weight: .regular))
                .foregroundStyle(.white.opacity(0.6))
        }
    }

    private func dateCard(scale: CGFloat) -> some View {
        infoCard(scale: scale) {
            Text("Date")
                .font(.system(size: max(13, 14 * scale), weight: .regular))
                .foregroundStyle(.white.opacity(0.6))
            Text(data.dateText)
                .font(.system(size: max(17, 18 * scale), weight: .regular))
                .foregroundStyle(.white)
        }
    }

    private func placeCard(scale: CGFloat) -> some View {
        infoCard(scale: scale) {
            HStack(spacing: 8 * scale) {
                Image("Icon-4")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 16 * scale, height: 16 * scale)
                Text("Place")
                    .font(.system(size: max(13, 14 * scale), weight: .regular))
                    .foregroundStyle(.white.opacity(0.6))
            }
            Text(data.place)
                .font(.system(size: max(17, 18 * scale), weight: .regular))
                .foregroundStyle(.white)
            HStack(spacing: 8 * scale) {
                Text("Rating:")
                    .font(.system(size: max(13, 14 * scale), weight: .regular))
                    .foregroundStyle(.white.opacity(0.6))
                stars(count: data.placeRating, size: 20 * scale, spacing: 4 * scale)
            }
        }
    }

    private func holidayRatingCard(scale: CGFloat) -> some View {
        infoCard(scale: scale) {
            Text("Holiday Rating")
                .font(.system(size: max(13, 14 * scale), weight: .regular))
                .foregroundStyle(.white.opacity(0.6))
            stars(count: data.holidayRating, size: 24 * scale, spacing: 4 * scale)
        }
    }

    private func guestsCard(scale: CGFloat) -> some View {
        infoCard(scale: scale, spacing: 12 * scale) {
            HStack(spacing: 8 * scale) {
                Image(systemName: "person.2")
                    .font(.system(size: 16 * scale))
                    .foregroundStyle(.white.opacity(0.6))
                Text("Guests (\(data.guests.count))")
                    .font(.system(size: max(13, 14 * scale), weight: .regular))
                    .foregroundStyle(.white.opacity(0.6))
            }

            VStack(spacing: 12 * scale) {
                ForEach(data.guests) { guest in
                    HStack {
                        HStack(spacing: 12 * scale) {
                            Text(String(guest.name.prefix(1)))
                                .font(.system(size: max(14, 16 * scale), weight: .regular))
                                .foregroundStyle(.black)
                                .frame(width: 40 * scale, height: 40 * scale)
                                .background(
                                    LinearGradient(
                                        colors: [Color(hex: 0xFDC700), Color(hex: 0xFF6900)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .clipShape(Circle())

                            VStack(alignment: .leading, spacing: 0) {
                                Text(guest.name)
                                    .font(.system(size: max(15, 16 * scale), weight: .regular))
                                    .foregroundStyle(.white)
                                Text(guest.relation)
                                    .font(.system(size: max(11, 12 * scale), weight: .regular))
                                    .foregroundStyle(.white.opacity(0.4))
                            }
                        }
                        Spacer()
                        stars(count: guest.rating, size: 16 * scale, spacing: 4 * scale, showEmpty: false)
                    }
                }
            }
        }
    }

    private func noteCard(scale: CGFloat) -> some View {
        infoCard(scale: scale, spacing: 8 * scale) {
            Text("Note")
                .font(.system(size: max(13, 14 * scale), weight: .regular))
                .foregroundStyle(.white.opacity(0.6))
            Text(data.note)
                .font(.system(size: max(15, 16 * scale), weight: .regular))
                .foregroundStyle(.white)
                .lineLimit(nil)
        }
    }

    private func stars(count: Int, size: CGFloat, spacing: CGFloat, showEmpty: Bool = true) -> some View {
        HStack(spacing: spacing) {
            ForEach(0..<5, id: \.self) { idx in
                if showEmpty || idx < count {
                    Image(systemName: idx < count ? "star.fill" : "star")
                        .font(.system(size: size, weight: .semibold))
                        .foregroundStyle(idx < count ? Color(hex: 0xFDC700) : .white.opacity(0.2))
                }
            }
        }
    }

    private func infoCard<Content: View>(scale: CGFloat, spacing: CGFloat = 8 * 1.0, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: spacing * scale) {
            content()
        }
        .padding(16.56 * scale)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white.opacity(0.05))
        .overlay(
            RoundedRectangle(cornerRadius: 16 * scale, style: .continuous)
                .stroke(Color.white.opacity(0.1), lineWidth: 0.57 * scale)
        )
        .clipShape(RoundedRectangle(cornerRadius: 16 * scale, style: .continuous))
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
