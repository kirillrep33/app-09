import SwiftUI

private enum CalendarMood {
    case joy
    case calm
    case tired

    var emoji: String {
        switch self {
        case .joy: return "🤩"
        case .calm: return "😌"
        case .tired: return "😴"
        }
    }

    var label: String {
        switch self {
        case .joy: return "Joy"
        case .calm: return "Calm"
        case .tired: return "Tired"
        }
    }
}

private struct CalendarDay: Identifiable {
    let id: String
    let value: Int?
    let event: AppEvent?
}

struct CalendarScreenView: View {
    @EnvironmentObject private var store: AppDataStore
    let bottomInset: CGFloat
    let resetToken: Int
    let onEventPanelVisibilityChanged: (Bool) -> Void

    @State private var displayedMonth = CalendarScreenView.currentMonthStart()
    @State private var selectedEvent: AppEvent?
    @State private var selectedDay: Int?

    init(bottomInset: CGFloat = 0, resetToken: Int = 0, onEventPanelVisibilityChanged: @escaping (Bool) -> Void = { _ in }) {
        self.bottomInset = bottomInset
        self.resetToken = resetToken
        self.onEventPanelVisibilityChanged = onEventPanelVisibilityChanged
    }

    private let weekDays = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
    private let columns: [GridItem] = Array(repeating: GridItem(.flexible(), spacing: 8), count: 7)
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

                VStack(alignment: .leading, spacing: 24 * scale) {
                    header(scale: scale)
                    calendarCard(scale: scale)
                    legend(scale: scale)
                    if store.events.isEmpty {
                        emptyState("No holidays in calendar yet.", scale: scale)
                    }
                    Spacer(minLength: max(18 * scale, bottomInset))
                }
                .padding(.horizontal, 24 * scale)
                .padding(.top, max(16 * scale, geo.safeAreaInsets.top + 8 * scale))

                if let event = selectedEvent {
                    eventPanel(event: event, scale: scale)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                        .zIndex(10)
                }
            }
            .animation(.easeOut(duration: 0.22), value: selectedEvent != nil)
            .onChange(of: selectedEvent != nil) { isVisible in
                onEventPanelVisibilityChanged(isVisible)
            }
            .onChange(of: resetToken) { _ in
                displayedMonth = Self.currentMonthStart()
                selectedEvent = nil
                selectedDay = nil
            }
        }
    }

    private func header(scale: CGFloat) -> some View {
        HStack(alignment: .center) {
            Text("📅 \(monthTitle(displayedMonth))\n\(yearTitle(displayedMonth))")
                .font(.system(size: max(30, 36 * scale), weight: .bold))
                .foregroundStyle(.white)
                .lineSpacing(2 * scale)
                .shadow(color: Color(hex: 0xFFD700, alpha: 0.3), radius: 28 * scale)

            Spacer()

            HStack(spacing: 8 * scale) {
                navButton(systemName: "chevron.left", scale: scale) {
                    shiftMonth(by: -1)
                }
                navButton(systemName: "chevron.right", scale: scale) {
                    shiftMonth(by: 1)
                }
            }
        }
    }

    private func navButton(systemName: String, scale: CGFloat, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 20 * scale, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 45.11 * scale, height: 45.11 * scale)
                .background(Color(hex: 0x0F1629, alpha: 0.6))
                .overlay(
                    RoundedRectangle(cornerRadius: 16 * scale, style: .continuous)
                        .stroke(Color(hex: 0xFFD700, alpha: 0.2), lineWidth: 0.57 * scale)
                )
                .clipShape(RoundedRectangle(cornerRadius: 16 * scale, style: .continuous))
                .shadow(color: .black.opacity(0.4), radius: 12 * scale, y: 6 * scale)
        }
        .buttonStyle(.soundPlain)
    }

    private func calendarCard(scale: CGFloat) -> some View {
        let days = calendarDaysForDisplayedMonth()

        return VStack(spacing: 16 * scale) {
            LazyVGrid(columns: columns, spacing: 0) {
                ForEach(weekDays, id: \.self) { day in
                    Text(day)
                        .font(.system(size: max(13, 14 * scale), weight: .bold))
                        .foregroundStyle(Color(hex: 0xFFD700))
                        .frame(maxWidth: .infinity, minHeight: 20 * scale)
                        .padding(.bottom, 10 * scale)
                }
            }

            LazyVGrid(columns: columns, spacing: 8 * scale) {
                ForEach(days) { day in
                    dayCell(day: day, scale: scale)
                }
            }
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
            RoundedRectangle(cornerRadius: 24 * scale, style: .continuous)
                .stroke(Color(hex: 0xFFD700, alpha: 0.3), lineWidth: 1.7 * scale)
        )
        .clipShape(RoundedRectangle(cornerRadius: 24 * scale, style: .continuous))
        .shadow(color: .black.opacity(0.5), radius: 20 * scale, y: 10 * scale)
        .shadow(color: Color(hex: 0xFFD700, alpha: 0.15), radius: 36 * scale)
    }

    private func dayCell(day: CalendarDay, scale: CGFloat) -> some View {
        return VStack(spacing: 4 * scale) {
            Text(day.value.map(String.init) ?? "")
                .font(.system(size: max(13, 14 * scale), weight: .bold))
                .foregroundStyle(dayTextColor(day: day))

            if let mood = day.event?.mood {
                Circle()
                    .fill(mood == .joy ? Color(hex: 0xFFD700) : (mood == .calm ? .white : Color(hex: 0xE10600)))
                    .frame(width: 8 * scale, height: 8 * scale)
                    .shadow(
                        color: mood == .joy ? Color(hex: 0xFFD700, alpha: 0.6) : (mood == .calm ? Color.white.opacity(0.5) : Color(hex: 0xE10600, alpha: 0.6)),
                        radius: 8 * scale
                    )
            }
        }
        .frame(maxWidth: .infinity, minHeight: dayHeight(day) * scale)
        .background(dayBackground(day: day))
        .overlay(
            RoundedRectangle(cornerRadius: 16 * scale, style: .continuous)
                .stroke(dayBorder(day: day), lineWidth: isSelected(day) ? 1.7 * scale : 0.57 * scale)
        )
        .clipShape(RoundedRectangle(cornerRadius: 16 * scale, style: .continuous))
        .shadow(color: isSelected(day) ? Color(hex: 0xFFD700, alpha: 0.35) : .clear, radius: 20 * scale)
        .contentShape(RoundedRectangle(cornerRadius: 16 * scale, style: .continuous))
        .onTapGesture {
            selectedDay = day.value
            selectedEvent = day.event
        }
    }

    private func dayBackground(day: CalendarDay) -> some View {
        Group {
            if isSelected(day) {
                LinearGradient(
                    colors: [Color(hex: 0xFFD700), Color(hex: 0xFFC300)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            } else if day.event != nil {
                Color(hex: 0x0F1629, alpha: 0.6)
            } else {
                Color.clear
            }
        }
    }

    private func dayBorder(day: CalendarDay) -> Color {
        if isSelected(day) { return Color.white.opacity(0.3) }
        if day.event != nil { return Color(hex: 0xFFD700, alpha: 0.2) }
        return Color.white.opacity(0.05)
    }

    private func dayTextColor(day: CalendarDay) -> Color {
        if isSelected(day) { return Color(hex: 0x0A0E27) }
        if selectedDay != nil && isToday(day) { return .white.opacity(0.4) }
        if day.event != nil { return .white }
        if day.value == nil { return .clear }
        return .white.opacity(0.4)
    }

    private func legend(scale: CGFloat) -> some View {
        HStack(spacing: 32 * scale) {
            legendItem(color: Color(hex: 0xFFD700), glow: Color(hex: 0xFFD700, alpha: 0.6), title: "Joy", scale: scale)
            legendItem(color: .white, glow: Color.white.opacity(0.5), title: "Calm", scale: scale)
            legendItem(color: Color(hex: 0xE10600), glow: Color(hex: 0xE10600, alpha: 0.6), title: "Tired", scale: scale)
        }
        .frame(maxWidth: .infinity, alignment: .center)
    }

    private func legendItem(color: Color, glow: Color, title: String, scale: CGFloat) -> some View {
        HStack(spacing: 8 * scale) {
            Circle()
                .fill(color)
                .frame(width: 16 * scale, height: 16 * scale)
                .shadow(color: glow, radius: 10 * scale)
            Text(title)
                .font(.system(size: max(13, 14 * scale), weight: .semibold))
                .foregroundStyle(.white.opacity(0.8))
        }
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

    private func eventPanel(event: AppEvent, scale: CGFloat) -> some View {
        VStack(alignment: .leading, spacing: 20 * scale) {
            HStack(alignment: .top) {
                Text(eventTitleDate(event.date))
                    .font(.system(size: max(20, 42 * scale / 2), weight: .bold))
                    .foregroundStyle(.white)
                Spacer()
                Button {
                    selectedEvent = nil
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 20 * scale, weight: .regular))
                        .foregroundStyle(.white.opacity(0.75))
                }
                .buttonStyle(.soundPlain)
            }

            VStack(alignment: .leading, spacing: 10 * scale) {
                HStack(alignment: .top) {
                    Text(event.title)
                        .font(.system(size: max(20, 22 * scale), weight: .bold))
                        .foregroundStyle(.white)
                    Spacer(minLength: 10 * scale)
                    HStack(spacing: 6 * scale) {
                        Text(event.mood.emoji)
                        Text(event.mood.rawValue)
                            .font(.system(size: max(13, 14 * scale), weight: .bold))
                    }
                    .foregroundStyle(moodText(mapMood(event.mood)))
                    .padding(.horizontal, 14 * scale)
                    .frame(height: 35 * scale)
                    .background(moodBackground(mapMood(event.mood)))
                    .overlay(
                        Capsule().stroke(moodBorder(mapMood(event.mood)), lineWidth: 1.7 * scale)
                    )
                    .clipShape(Capsule())
                    .shadow(color: moodGlow(mapMood(event.mood)), radius: 10 * scale)
                }

                HStack(spacing: 18 * scale) {
                    Text("📍 \(event.place)")
                        .font(.system(size: max(14, 16 * scale), weight: .semibold))
                        .foregroundStyle(.white.opacity(0.7))
                        .lineLimit(1)
                    HStack(spacing: 5 * scale) {
                        Image(systemName: "person.2")
                        Text("\(event.guestIDs.count)")
                    }
                    .font(.system(size: max(14, 16 * scale), weight: .semibold))
                    .foregroundStyle(.white.opacity(0.7))
                }

                HStack(spacing: 4 * scale) {
                    ForEach(0..<5, id: \.self) { idx in
                        Image(systemName: idx < event.holidayRating ? "star.fill" : "star")
                            .font(.system(size: 15 * scale, weight: .bold))
                            .foregroundStyle(idx < event.holidayRating ? Color(hex: 0xFFD700) : Color.white.opacity(0.2))
                    }
                }
            }
            .padding(16 * scale)
            .background(Color(hex: 0x0F1629, alpha: 0.55))
            .overlay(
                RoundedRectangle(cornerRadius: 16 * scale, style: .continuous)
                    .stroke(Color(hex: 0xFFD700, alpha: 0.3), lineWidth: 0.8 * scale)
            )
            .clipShape(RoundedRectangle(cornerRadius: 16 * scale, style: .continuous))
        }
        .padding(.horizontal, 20 * scale)
        .padding(.top, 22 * scale)
        .padding(.bottom, 26 * scale)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            LinearGradient(
                colors: [Color(hex: 0x0F1629, alpha: 0.92), Color(hex: 0x0A0E27, alpha: 0.96)],
                startPoint: .top,
                endPoint: .bottom
            )
        )
        .overlay(
            Rectangle()
                .fill(Color(hex: 0xFFD700, alpha: 0.2))
                .frame(height: 1),
            alignment: .top
        )
        .shadow(color: .black.opacity(0.55), radius: 24 * scale, y: -6 * scale)
        .shadow(color: Color(hex: 0xFFD700, alpha: 0.15), radius: 30 * scale, y: 6 * scale)
        .frame(maxHeight: .infinity, alignment: .bottom)
        .ignoresSafeArea(edges: .bottom)
    }

    private func shiftMonth(by value: Int) {
        guard let updated = Calendar.current.date(byAdding: .month, value: value, to: displayedMonth) else { return }
        displayedMonth = updated
        selectedEvent = nil
        selectedDay = nil
    }

    private func calendarDaysForDisplayedMonth() -> [CalendarDay] {
        let calendar = Calendar.current
        let start = calendar.date(from: calendar.dateComponents([.year, .month], from: displayedMonth)) ?? displayedMonth
        let range = calendar.range(of: .day, in: .month, for: start) ?? 1..<29
        let firstWeekdayIndex = calendar.component(.weekday, from: start) - 1

        var result: [CalendarDay] = (0..<firstWeekdayIndex).map { idx in
            CalendarDay(id: "empty-\(idx)", value: nil, event: nil)
        }

        for day in range {
            let event = eventFor(day: day, in: displayedMonth)
            result.append(CalendarDay(id: "day-\(day)", value: day, event: event))
        }
        return result
    }

    private func eventFor(day: Int, in monthDate: Date) -> AppEvent? {
        let calendar = Calendar.current
        let monthComp = calendar.dateComponents([.year, .month], from: monthDate)
        return store.events.first { item in
            let comp = calendar.dateComponents([.year, .month, .day], from: item.date)
            return comp.year == monthComp.year && comp.month == monthComp.month && comp.day == day
        }
    }

    private func isSelected(_ day: CalendarDay) -> Bool {
        guard let value = day.value else { return false }
        if let selectedDay, selectedDay == value {
            return true
        }
        if let selected = selectedEvent {
            let comp = Calendar.current.dateComponents([.year, .month, .day], from: selected.date)
            let current = Calendar.current.dateComponents([.year, .month], from: displayedMonth)
            return comp.year == current.year && comp.month == current.month && comp.day == value
        }
        let calendar = Calendar.current
        let monthComp = calendar.dateComponents([.year, .month], from: displayedMonth)
        let todayComp = calendar.dateComponents([.year, .month, .day], from: Date())
        return monthComp.year == todayComp.year && monthComp.month == todayComp.month && value == todayComp.day
    }

    private func dayHeight(_ day: CalendarDay) -> CGFloat {
        _ = day
        return 49.1
    }

    private func monthTitle(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "MMMM"
        return formatter.string(from: date)
    }

    private func yearTitle(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy"
        return formatter.string(from: date)
    }

    private func eventTitleDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "EEEE, MMMM d, yyyy"
        return formatter.string(from: date)
    }

    private func moodBackground(_ mood: CalendarMood) -> LinearGradient {
        switch mood {
        case .joy:
            return LinearGradient(colors: [Color(hex: 0xFFD700, alpha: 0.3), Color(hex: 0xFFC300, alpha: 0.3)], startPoint: .leading, endPoint: .trailing)
        case .calm:
            return LinearGradient(colors: [Color.white.opacity(0.2), Color.white.opacity(0.2)], startPoint: .leading, endPoint: .trailing)
        case .tired:
            return LinearGradient(colors: [Color(hex: 0xE10600, alpha: 0.3), Color(hex: 0xFF1493, alpha: 0.3)], startPoint: .leading, endPoint: .trailing)
        }
    }

    private func moodText(_ mood: CalendarMood) -> Color {
        switch mood {
        case .joy: return Color(hex: 0xFFD700)
        case .calm: return .white
        case .tired: return Color(hex: 0xFF6B6B)
        }
    }

    private func moodBorder(_ mood: CalendarMood) -> Color {
        switch mood {
        case .joy: return Color(hex: 0xFFD700, alpha: 0.5)
        case .calm: return Color.white.opacity(0.5)
        case .tired: return Color(hex: 0xE10600, alpha: 0.5)
        }
    }

    private func moodGlow(_ mood: CalendarMood) -> Color {
        switch mood {
        case .joy: return Color(hex: 0xFFD700, alpha: 0.3)
        case .calm: return Color.white.opacity(0.2)
        case .tired: return Color(hex: 0xE10600, alpha: 0.3)
        }
    }

    private static func currentMonthStart() -> Date {
        let now = Date()
        let calendar = Calendar.current
        let comps = calendar.dateComponents([.year, .month], from: now)
        return calendar.date(from: comps) ?? now
    }

    private func mapMood(_ mood: AppMood) -> CalendarMood {
        switch mood {
        case .joy: return .joy
        case .calm: return .calm
        case .tired: return .tired
        }
    }

    private func isToday(_ day: CalendarDay) -> Bool {
        guard let value = day.value else { return false }
        let calendar = Calendar.current
        let monthComp = calendar.dateComponents([.year, .month], from: displayedMonth)
        let todayComp = calendar.dateComponents([.year, .month, .day], from: Date())
        return monthComp.year == todayComp.year && monthComp.month == todayComp.month && value == todayComp.day
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
    CalendarScreenView(bottomInset: 120)
}
