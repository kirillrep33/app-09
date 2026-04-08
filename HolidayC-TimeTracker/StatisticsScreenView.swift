import SwiftUI

private struct RankedItem: Identifiable {
    let id = UUID()
    let rank: Int
    let title: String
    let subtitle: String
    let avatar: String
    let rating: Int
}

private enum StatsMode {
    case month
    case year
}

struct StatisticsScreenView: View {
    @EnvironmentObject private var store: AppDataStore
    let bottomInset: CGFloat
    let resetToken: Int
    @State private var mode: StatsMode = .month

    private var guests: [RankedItem] {
        let grouped = Dictionary(grouping: store.events.flatMap(\.guestIDs), by: { $0 })
        let ranked = grouped.map { (id, events) -> RankedItem? in
            guard let guest = store.guests.first(where: { $0.id == id }) else { return nil }
            return RankedItem(rank: 0, title: guest.name.replacingOccurrences(of: " ", with: "\n"), subtitle: "\(events.count) holidays", avatar: String(guest.name.prefix(1)), rating: guest.behaviorRating)
        }.compactMap { $0 }
            .sorted { ($0.rating, $0.subtitle) > ($1.rating, $1.subtitle) }
            .prefix(5)
        return Array(ranked.enumerated()).map { idx, item in
            RankedItem(rank: idx + 1, title: item.title, subtitle: item.subtitle, avatar: item.avatar, rating: item.rating)
        }
    }

    private var places: [RankedItem] {
        let grouped = Dictionary(grouping: store.events, by: { $0.place })
        let ranked = grouped.map { place, events -> RankedItem in
            let avg = Int((Double(events.reduce(0) { $0 + $1.placeRating }) / Double(max(1, events.count))).rounded())
            return RankedItem(rank: 0, title: "📍 " + place.replacingOccurrences(of: " ", with: "\n"), subtitle: "\(events.count) visits", avatar: "", rating: avg)
        }
            .sorted { ($0.rating, $0.subtitle) > ($1.rating, $1.subtitle) }
            .prefix(5)
        return Array(ranked.enumerated()).map { idx, item in
            RankedItem(rank: idx + 1, title: item.title, subtitle: item.subtitle, avatar: "", rating: item.rating)
        }
    }

    init(bottomInset: CGFloat = 0, resetToken: Int = 0) {
        self.bottomInset = bottomInset
        self.resetToken = resetToken
    }

    var body: some View {
        GeometryReader { geo in
            let scale = min(geo.size.width / 393.0, geo.size.height / 852.0)

            ZStack {
                LinearGradient(
                    colors: [Color(hex: 0x0A0E27), Color(hex: 0x0F1629), Color(hex: 0x0A0E27)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()

                ScrollView(.vertical, showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 24 * scale) {
                        Text("📊 Statistics")
                            .font(.system(size: max(30, 36 * scale), weight: .bold))
                            .foregroundStyle(.white)
                            .shadow(color: Color(hex: 0xFFD700, alpha: 0.3), radius: 24 * scale)

                        modeSwitch(scale: scale)
                        moodTrendCard(scale: scale)
                        rankingCard(title: "Top Guests", icon: "person.2", iconColors: [Color(hex: 0x1E90FF), Color(hex: 0x00B66C)], data: guests, scale: scale, showAvatar: true)
                        rankingCard(title: "Top Places", icon: "mappin.circle", iconColors: [Color(hex: 0xE10600), Color(hex: 0xFF1493)], data: places, scale: scale, showAvatar: false)
                        insightsCard(scale: scale)
                    }
                    .padding(.horizontal, 24 * scale)
                    .padding(.top, max(14 * scale, geo.safeAreaInsets.top + 6 * scale))
                    .padding(.bottom, max(bottomInset, 24 * scale))
                }
            }
            .onChange(of: resetToken) { _ in
                mode = .month
            }
        }
    }

    private func modeSwitch(scale: CGFloat) -> some View {
        HStack(spacing: 12 * scale) {
            modeButton(title: "Month", isActive: mode == .month, scale: scale) { mode = .month }
            modeButton(title: "Year", isActive: mode == .year, scale: scale) { mode = .year }
        }
    }

    private func modeButton(title: String, isActive: Bool, scale: CGFloat, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: max(14, 16 * scale), weight: .bold))
                .foregroundStyle(isActive ? Color(hex: 0x0A0E27) : .white.opacity(0.7))
                .frame(height: 49.12 * scale)
                .padding(.horizontal, 24 * scale)
                .background(
                    Group {
                        if isActive {
                            LinearGradient(colors: [Color(hex: 0xFFC300), Color(hex: 0xFFD700)], startPoint: .leading, endPoint: .trailing)
                        } else {
                            Color(hex: 0x0F1629, alpha: 0.6)
                        }
                    }
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16 * scale, style: .continuous)
                        .stroke(Color(hex: 0xFFD700, alpha: isActive ? 0.0 : 0.2), lineWidth: 0.57 * scale)
                )
                .clipShape(RoundedRectangle(cornerRadius: 16 * scale, style: .continuous))
                .shadow(color: isActive ? Color(hex: 0xFFD700, alpha: 0.4) : .clear, radius: 16 * scale, y: 4 * scale)
        }
        .buttonStyle(.soundPlain)
    }

    private func moodTrendCard(scale: CGFloat) -> some View {
        gradientCard(scale: scale) {
            headerRow(title: "Mood Trend", icon: "chart.line.uptrend.xyaxis", colors: [Color(hex: 0xFFD700), Color(hex: 0xFFC300)], iconColor: Color(hex: 0x0A0E27), scale: scale)
            MoodTrendChart(scale: scale, mode: mode, events: store.events)
                .frame(height: 250 * scale)
            if store.events.isEmpty {
                Text("No mood data yet.")
                    .font(.system(size: max(12, 13 * scale), weight: .semibold))
                    .foregroundStyle(.white.opacity(0.65))
            }
        }
    }

    private func rankingCard(title: String, icon: String, iconColors: [Color], data: [RankedItem], scale: CGFloat, showAvatar: Bool) -> some View {
        gradientCard(scale: scale) {
            headerRow(title: title, icon: icon, colors: iconColors, iconColor: .white, scale: scale)
            VStack(spacing: 12 * scale) {
                if data.isEmpty {
                    emptyState(showAvatar ? "No guest data yet." : "No place data yet.", scale: scale)
                } else {
                    ForEach(data) { item in
                        rankRow(item: item, scale: scale, showAvatar: showAvatar)
                    }
                }
            }
        }
    }

    private func insightsCard(scale: CGFloat) -> some View {
        gradientCard(scale: scale) {
            headerRow(title: "Insights", icon: "sparkles", colors: [Color(hex: 0xFFD700), Color(hex: 0xFF8C00)], iconColor: Color(hex: 0x0A0E27), scale: scale)
            VStack(spacing: 12 * scale) {
                if store.events.isEmpty {
                    emptyState("No insights yet.", scale: scale)
                } else {
                    insightRow("Most joyful month: December", scale: scale)
                    insightRow("You often feel tired after\nCorporate Event events", scale: scale)
                    insightRow("Average holiday rating: 4.1\nstars", scale: scale)
                }
            }
        }
    }

    private func gradientCard<Content: View>(scale: CGFloat, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 16 * scale) {
            content()
        }
        .padding(26 * scale)
        .background(
            LinearGradient(
                colors: [Color(hex: 0xFFD700, alpha: 0.10), Color(hex: 0x0F1629, alpha: 0.8), Color(hex: 0xE10600, alpha: 0.10)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16 * scale, style: .continuous)
                .stroke(Color(hex: 0xFFD700, alpha: 0.3), lineWidth: 1.7 * scale)
        )
        .clipShape(RoundedRectangle(cornerRadius: 16 * scale, style: .continuous))
        .shadow(color: .black.opacity(0.5), radius: 20 * scale, y: 8 * scale)
        .shadow(color: Color(hex: 0xFFD700, alpha: 0.15), radius: 30 * scale)
    }

    private func headerRow(title: String, icon: String, colors: [Color], iconColor: Color, scale: CGFloat) -> some View {
        HStack(spacing: 8 * scale) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: colors,
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(width: 40 * scale, height: 40 * scale)
                if title == "Insights" {
                    Image(assetIconName(for: title))
                        .renderingMode(.template)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 20 * scale, height: 20 * scale)
                        .foregroundStyle(Color(hex: 0x0A0E27))
                } else {
                    Image(assetIconName(for: title))
                        .resizable()
                        .scaledToFit()
                        .frame(width: 20 * scale, height: 20 * scale)
                }
            }
            Text(title)
                .font(.system(size: max(22, 24 * scale), weight: .bold))
                .foregroundStyle(.white)
        }
    }

    private func rankRow(item: RankedItem, scale: CGFloat, showAvatar: Bool) -> some View {
        HStack {
            HStack(spacing: 12 * scale) {
                Text("\(item.rank)")
                    .font(.system(size: max(13, 14 * scale), weight: .bold))
                    .foregroundStyle(Color(hex: 0x0A0E27))
                    .frame(width: 25 * scale, height: 32 * scale)
                    .background(LinearGradient(colors: [Color(hex: 0xFFD700), Color(hex: 0xFFC300)], startPoint: .top, endPoint: .bottom))
                    .clipShape(Capsule())
                    .shadow(color: Color(hex: 0xFFD700, alpha: 0.4), radius: 10 * scale)

                if showAvatar {
                    Text(item.avatar)
                        .font(.system(size: max(17, 18 * scale), weight: .bold))
                        .foregroundStyle(.white)
                        .frame(width: 38 * scale, height: 48 * scale)
                        .background(LinearGradient(colors: [Color(hex: 0x1E90FF), Color(hex: 0x00B66C)], startPoint: .top, endPoint: .bottom))
                        .overlay(Capsule().stroke(Color.white.opacity(0.2), lineWidth: 1.4 * scale))
                        .clipShape(Capsule())
                }

                VStack(alignment: .leading, spacing: 0) {
                    Text(item.title)
                        .font(.system(size: max(15, 16 * scale), weight: .bold))
                        .foregroundStyle(.white)
                    Text(item.subtitle)
                        .font(.system(size: max(11, 12 * scale), weight: .semibold))
                        .foregroundStyle(.white.opacity(0.6))
                }
            }

            Spacer()
            stars(rating: item.rating, scale: scale)
        }
        .padding(.horizontal, 16 * scale)
        .frame(height: 97.13 * scale)
        .background(Color(hex: 0x0F1629, alpha: 0.6))
        .overlay(
            RoundedRectangle(cornerRadius: 16 * scale, style: .continuous)
                .stroke(Color(hex: 0xFFD700, alpha: 0.2), lineWidth: 0.57 * scale)
        )
        .clipShape(RoundedRectangle(cornerRadius: 16 * scale, style: .continuous))
    }

    private func stars(rating: Int, scale: CGFloat) -> some View {
        HStack(spacing: 4 * scale) {
            ForEach(0..<5, id: \.self) { idx in
                Image(systemName: idx < rating ? "star.fill" : "star")
                    .font(.system(size: 15 * scale, weight: .semibold))
                    .foregroundStyle(idx < rating ? Color(hex: 0xFFD700) : Color.white.opacity(0.2))
                    .shadow(color: idx < rating ? Color(hex: 0xFFD700, alpha: 0.6) : .clear, radius: 10 * scale)
            }
        }
    }

    private func insightRow(_ text: String, scale: CGFloat) -> some View {
        HStack(alignment: .top, spacing: 12 * scale) {
            Circle()
                .fill(LinearGradient(colors: [Color(hex: 0xFFD700), Color(hex: 0xFFC300)], startPoint: .top, endPoint: .bottom))
                .frame(width: 12 * scale, height: 12 * scale)
                .shadow(color: Color(hex: 0xFFD700, alpha: 0.5), radius: 8 * scale)
                .padding(.top, 6 * scale)
            Text(text)
                .font(.system(size: max(15, 16 * scale), weight: .semibold))
                .foregroundStyle(.white.opacity(0.9))
        }
        .padding(.horizontal, 14 * scale)
        .frame(maxWidth: .infinity, minHeight: 59.4 * scale, alignment: .leading)
        .background(LinearGradient(colors: [Color(hex: 0xFFD700, alpha: 0.2), Color(hex: 0xFFC300, alpha: 0.1)], startPoint: .leading, endPoint: .trailing))
        .overlay(
            RoundedRectangle(cornerRadius: 16 * scale, style: .continuous)
                .stroke(Color(hex: 0xFFD700, alpha: 0.3), lineWidth: 1.7 * scale)
        )
        .clipShape(RoundedRectangle(cornerRadius: 16 * scale, style: .continuous))
    }

    private func emptyState(_ text: String, scale: CGFloat) -> some View {
        Text(text)
            .font(.system(size: max(15, 16 * scale), weight: .semibold))
            .foregroundStyle(.white.opacity(0.65))
            .frame(maxWidth: .infinity)
            .multilineTextAlignment(.center)
            .padding(.vertical, 28 * scale)
            .background(Color.white.opacity(0.05))
            .overlay(
                RoundedRectangle(cornerRadius: 16 * scale, style: .continuous)
                    .stroke(Color.white.opacity(0.12), lineWidth: 0.57 * scale)
            )
            .clipShape(RoundedRectangle(cornerRadius: 16 * scale, style: .continuous))
    }

    private func assetIconName(for title: String) -> String {
        switch title {
        case "Mood Trend": return "Icon-3"
        case "Top Guests": return "Icon-2"
        case "Top Places": return "Icon-4"
        case "Insights": return "Icon 3"
        default: return "Icon-3"
        }
    }
}

private struct MoodTrendChart: View {
    let scale: CGFloat
    let mode: StatsMode
    let events: [AppEvent]

    var body: some View {
        GeometryReader { geo in
            let leftAxis = 56 * scale
            let bottomAxis = 28 * scale
            let chartRect = CGRect(
                x: leftAxis,
                y: 8 * scale,
                width: max(1, geo.size.width - leftAxis - 6 * scale),
                height: max(1, geo.size.height - bottomAxis - 8 * scale)
            )

            ZStack(alignment: .topLeading) {
               
                ForEach(0..<4, id: \.self) { i in
                    let y = chartRect.minY + (chartRect.height / 3) * CGFloat(i)
                    Path { p in
                        p.move(to: CGPoint(x: chartRect.minX, y: y))
                        p.addLine(to: CGPoint(x: chartRect.maxX, y: y))
                    }
                    .stroke(Color(hex: 0xFFD700, alpha: 0.15), style: StrokeStyle(lineWidth: 1, dash: [3, 3]))
                }

              
                ForEach(0..<6, id: \.self) { i in
                    let x = chartRect.minX + (chartRect.width / 5) * CGFloat(i)
                    Path { p in
                        p.move(to: CGPoint(x: x, y: chartRect.minY))
                        p.addLine(to: CGPoint(x: x, y: chartRect.maxY))
                    }
                    .stroke(Color(hex: 0xFFD700, alpha: 0.15), style: StrokeStyle(lineWidth: 1, dash: [3, 3]))
                }

            
                Path { p in
                    p.move(to: CGPoint(x: chartRect.minX, y: chartRect.maxY))
                    p.addLine(to: CGPoint(x: chartRect.maxX, y: chartRect.maxY))
                }
                .stroke(Color(hex: 0xFFD700, alpha: 0.5), lineWidth: 1)

                Path { p in
                    p.move(to: CGPoint(x: chartRect.minX, y: chartRect.minY))
                    p.addLine(to: CGPoint(x: chartRect.minX, y: chartRect.maxY))
                }
                .stroke(Color(hex: 0xFFD700, alpha: 0.5), lineWidth: 1)

              
                if !plotValues.isEmpty {
                    Path { p in
                        let step = chartRect.width / CGFloat(max(1, plotValues.count - 1))
                        let points: [CGPoint] = plotValues.enumerated().map { idx, value in
                            let y = chartRect.maxY - (chartRect.height * value)
                            return CGPoint(x: chartRect.minX + step * CGFloat(idx), y: y)
                        }
                        p.move(to: points[0])
                        for point in points.dropFirst() {
                            p.addLine(to: point)
                        }
                    }
                    .stroke(Color(hex: 0xFFD700), style: StrokeStyle(lineWidth: 4 * scale, lineCap: .round, lineJoin: .round))
                    .shadow(color: Color(hex: 0xFFD700, alpha: 0.5), radius: 6 * scale)
                }

                
                VStack(alignment: .trailing, spacing: chartRect.height / 3 - 5 * scale) {
                    Text("Joy")
                    Text("Calm")
                    Text("Tired")
                }
                .font(.system(size: max(10, 12 * scale), weight: .bold))
                .foregroundStyle(.white.opacity(0.7))
                .frame(width: leftAxis - 8 * scale, alignment: .trailing)
                .padding(.top, chartRect.minY - 6 * scale)

             
                HStack(spacing: 0) {
                    ForEach(xLabels, id: \.self) { label in
                        Text(label)
                            .frame(maxWidth: .infinity, alignment: .center)
                    }
                }
                .font(.system(size: max(10, 12 * scale), weight: .bold))
                .foregroundStyle(.white.opacity(0.7))
                .frame(width: chartRect.width, alignment: .leading)
                .padding(.leading, chartRect.minX + 2 * scale)
                .padding(.top, chartRect.maxY + 4 * scale)
            }
        }
    }

    private var xLabels: [String] {
        let cal = Calendar.current
        let now = Date()
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        if mode == .year {
            formatter.dateFormat = "MMM"
            let startMonth = cal.date(from: cal.dateComponents([.year, .month], from: now)) ?? now
            return (0..<6).compactMap {
                cal.date(byAdding: .month, value: $0, to: startMonth).map { formatter.string(from: $0) }
            }
        } else {
            formatter.dateFormat = "MMM d"
            let todayDay = cal.component(.day, from: now)
            let startDay = max(1, todayDay - 4)
            let monthStart = cal.date(from: cal.dateComponents([.year, .month], from: now)) ?? now
            return (startDay...todayDay).compactMap { d in
                cal.date(byAdding: .day, value: d - 1, to: monthStart).map { formatter.string(from: $0) }
            }
        }
    }

    private var plotValues: [CGFloat] {
        if events.isEmpty {
            return []
        }
        let moodValue: (AppMood) -> CGFloat = { mood in
            switch mood {
            case .joy: return 1.0
            case .calm: return 0.5
            case .tired: return 0.0
            }
        }
        let cal = Calendar.current
        let now = Date()
        if mode == .year {
            let startMonth = cal.date(from: cal.dateComponents([.year, .month], from: now)) ?? now
            return (0..<6).map { shift in
                guard let monthDate = cal.date(byAdding: .month, value: shift, to: startMonth) else { return 0 }
                let target = cal.dateComponents([.year, .month], from: monthDate)
                let values = events.filter { ev in
                    let c = cal.dateComponents([.year, .month], from: ev.date)
                    return c.year == target.year && c.month == target.month
                }.map { moodValue($0.mood) }
                guard !values.isEmpty else { return 0 }
                return values.reduce(0, +) / CGFloat(values.count)
            }
        } else {
            let current = cal.dateComponents([.year, .month], from: now)
            let monthEvents = events.filter {
                let c = cal.dateComponents([.year, .month], from: $0.date)
                return c.year == current.year && c.month == current.month
            }
            let todayDay = cal.component(.day, from: now)
            let startDay = max(1, todayDay - 4)
            return (startDay...todayDay).map { day in
                let values = monthEvents.filter {
                    let d = cal.component(.day, from: $0.date)
                    return d == day
                }.map { moodValue($0.mood) }
                guard !values.isEmpty else { return 0 }
                return values.reduce(0, +) / CGFloat(values.count)
            }
        }
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
    StatisticsScreenView(bottomInset: 120)
}
