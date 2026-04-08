import SwiftUI

enum AppMood: String, CaseIterable, Codable {
    case joy = "Joy"
    case calm = "Calm"
    case tired = "Tired"

    var emoji: String {
        switch self {
        case .joy: return "🤩"
        case .calm: return "😌"
        case .tired: return "😴"
        }
    }
}

struct AppGuest: Identifiable, Equatable, Codable {
    let id: UUID
    var name: String
    var type: String
    var behaviorRating: Int
    var note: String
}

struct AppEvent: Identifiable, Equatable, Codable {
    let id: UUID
    var title: String
    var type: String
    var date: Date
    var place: String
    var mood: AppMood
    var holidayRating: Int
    var placeRating: Int
    var note: String
    var guestIDs: [UUID]
}

final class AppDataStore: ObservableObject {
    @Published var guests: [AppGuest] {
        didSet { save() }
    }
    @Published var events: [AppEvent] {
        didSet { save() }
    }

    private let guestsKey = "appDataStore.guests"
    private let eventsKey = "appDataStore.events"

    init() {
        let defaults = UserDefaults.standard
        guests = Self.load([AppGuest].self, forKey: guestsKey, from: defaults) ?? []
        events = Self.load([AppEvent].self, forKey: eventsKey, from: defaults) ?? []
    }

    func addGuest(name: String, type: String, rating: Int, note: String) -> AppGuest {
        let guest = AppGuest(id: UUID(), name: name, type: type, behaviorRating: rating, note: note)
        guests.append(guest)
        return guest
    }

    func updateGuest(id: UUID, name: String, type: String, rating: Int, note: String) {
        guard let idx = guests.firstIndex(where: { $0.id == id }) else { return }
        guests[idx].name = name
        guests[idx].type = type
        guests[idx].behaviorRating = rating
        guests[idx].note = note
    }

    func deleteGuest(id: UUID) {
        guests.removeAll { $0.id == id }
        events = events.map { event in
            var next = event
            next.guestIDs.removeAll { $0 == id }
            return next
        }
    }

    func addEvent(_ event: AppEvent) {
        events.insert(event, at: 0)
    }

    func updateEvent(_ event: AppEvent) {
        guard let idx = events.firstIndex(where: { $0.id == event.id }) else { return }
        events[idx] = event
    }

    func deleteEvent(id: UUID) {
        events.removeAll { $0.id == id }
    }

    private func save() {
        let defaults = UserDefaults.standard
        if let guestsData = try? JSONEncoder().encode(guests) {
            defaults.set(guestsData, forKey: guestsKey)
        }
        if let eventsData = try? JSONEncoder().encode(events) {
            defaults.set(eventsData, forKey: eventsKey)
        }
    }

    private static func load<T: Decodable>(_ type: T.Type, forKey key: String, from defaults: UserDefaults) -> T? {
        guard let data = defaults.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(type, from: data)
    }
}

enum AppTab: CaseIterable {
    case holidays
    case calendar
    case stats
    case guests
}

final class RootTabViewModel: ObservableObject {
    @Published var selectedTab: AppTab = .holidays
    @Published var isBottomBarHidden = false
}

struct MainTabContainerView: View {
    @StateObject private var viewModel = RootTabViewModel()
    @StateObject private var store = AppDataStore()
    @State private var isHolidayDetailPresented = false
    @State private var isHolidayFormPresented = false
    @State private var resetToken = 0

    var body: some View {
        GeometryReader { geo in
     
            let rawScale = geo.size.width / 393.0
            let scale = rawScale.isFinite ? max(rawScale, 0.01) : 1.0
            let safeBottom = max(geo.safeAreaInsets.bottom, 8)
            let navOverlayHeight = (30 + 80.97 + 1.7 + 0.87) * scale + safeBottom

            ZStack(alignment: .bottom) {
                LinearGradient(
                    colors: [.black, Color(hex: 0x002672), .black],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()

                TabView(selection: $viewModel.selectedTab) {
                    HolidaysMainView(bottomInset: navOverlayHeight + 16 * scale, resetToken: resetToken)
                        .tag(AppTab.holidays)

                    CalendarScreenView(
                        bottomInset: navOverlayHeight + 16 * scale,
                        resetToken: resetToken,
                        onEventPanelVisibilityChanged: { isVisible in
                            if viewModel.selectedTab == .calendar {
                                viewModel.isBottomBarHidden = isVisible
                            }
                        }
                    )
                        .tag(AppTab.calendar)

                    StatisticsScreenView(bottomInset: navOverlayHeight + 16 * scale, resetToken: resetToken)
                        .tag(AppTab.stats)

                    GuestsScreenView(bottomInset: navOverlayHeight + 16 * scale, resetToken: resetToken)
                        .tag(AppTab.guests)
                }
                .environmentObject(store)
                .tabViewStyle(.page(indexDisplayMode: .never))
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.clear)

                if viewModel.selectedTab == .holidays && !viewModel.isBottomBarHidden && !isHolidayDetailPresented && !isHolidayFormPresented {
                    floatingAddButton(scale: scale, safeBottom: safeBottom)
                }

                if !viewModel.isBottomBarHidden {
                    CustomBottomNavigationBar(selectedTab: $viewModel.selectedTab, scale: scale, safeBottom: safeBottom)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .animation(.easeOut(duration: 0.2), value: viewModel.isBottomBarHidden)
            .ignoresSafeArea(edges: .bottom)
            .ignoresSafeArea(.keyboard, edges: .bottom)
            .onChange(of: viewModel.selectedTab) { tab in
                resetToken += 1
                if tab != .calendar {
                    viewModel.isBottomBarHidden = false
                }
                if tab != .holidays {
                    isHolidayDetailPresented = false
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: .holidayDetailOpened)) { _ in
                isHolidayDetailPresented = true
            }
            .onReceive(NotificationCenter.default.publisher(for: .holidayDetailClosed)) { _ in
                isHolidayDetailPresented = false
            }
            .onReceive(NotificationCenter.default.publisher(for: .holidayFormOpened)) { _ in
                isHolidayFormPresented = true
            }
            .onReceive(NotificationCenter.default.publisher(for: .holidayFormClosed)) { _ in
                isHolidayFormPresented = false
            }
            .onReceive(NotificationCenter.default.publisher(for: .switchToGuestsTab)) { _ in
                viewModel.selectedTab = .guests
            }
        }
    }

    private func placeholderScreen(title: String) -> some View {
        ZStack {
            LinearGradient(
                colors: [.black, Color(hex: 0x002672), .black],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            Text(title)
                .font(.system(size: 34, weight: .bold))
                .foregroundStyle(.white.opacity(0.9))
        }
    }

    private func floatingAddButton(scale: CGFloat, safeBottom: CGFloat) -> some View {
        Button {
            NotificationCenter.default.post(name: .openHolidayCreateForm, object: nil)
        } label: {
            Image(systemName: "plus")
                .font(.system(size: 28 * scale, weight: .medium))
                .foregroundStyle(Color(hex: 0x0A0E27))
                .frame(width: 64 * scale, height: 64 * scale)
                .background(
                    LinearGradient(
                        colors: [Color(hex: 0xFFD700), Color(hex: 0xFFC300)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .overlay(Circle().stroke(Color.white.opacity(0.2), lineWidth: 1.2 * scale))
                .clipShape(Circle())
                .shadow(color: Color(hex: 0xFFD700), radius: 20 * scale)
                .shadow(color: Color(hex: 0xFFD700, alpha: 0.3), radius: 40 * scale)
                .shadow(color: Color(hex: 0xFFD700, alpha: 0.1), radius: 60 * scale)
        }
        .buttonStyle(.soundPlain)
        .padding(.trailing, 24 * scale)
        .padding(.bottom, 104 * scale + safeBottom)
        .frame(maxWidth: .infinity, alignment: .trailing)
    }
}

private struct CustomBottomNavigationBar: View {
    @Binding var selectedTab: AppTab
    let scale: CGFloat
    let safeBottom: CGFloat

    var body: some View {
        HStack(spacing: 29.93 * scale) {
            tabItem(icon: "sparkles", title: "Holidays", tab: .holidays)
            tabItem(icon: "calendar", title: "Calendar", tab: .calendar)
            tabItem(icon: "chart.bar", title: "Stats", tab: .stats)
            tabItem(icon: "person.2", title: "Guests", tab: .guests)
        }
        .padding(.top , 20 * scale)
        .frame(maxWidth: .infinity)
        .frame(height: 80.97 * scale, alignment: .center)
        .padding(.horizontal, 30.97 * scale)
        .padding(.top, 1.7 * scale)
        .padding(.bottom, 0.87 * scale + safeBottom)
        .background(Color(hex: 0x0F1629, alpha: 0.6))
        .overlay(
            Rectangle()
                .fill(Color(hex: 0xFFD700, alpha: 0.2))
                .frame(height: 1.703 * scale),
            alignment: .top
        )
        .overlay(
            Rectangle()
                .stroke(Color(hex: 0xFFD700, alpha: 0.2), lineWidth: 0.568 * scale)
        )
    }

    private func tabItem(icon: String, title: String, tab: AppTab) -> some View {
        let isActive = selectedTab == tab

        return Button {
            selectedTab = tab
        } label: {
            VStack(spacing: 4 * scale) {
                Image(systemName: icon)
                    .font(.system(size: 20 * scale, weight: .semibold))
                    .foregroundStyle(isActive ? Color(hex: 0x0A0E27) : .white.opacity(0.6))
                    .frame(width: 39.99 * scale, height: 39.99 * scale)
                    .background(
                        Group {
                            if isActive {
                                LinearGradient(
                                    colors: [Color(hex: 0xFFD700), Color(hex: 0xFFC300)],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            } else {
                                Color.clear
                            }
                        }
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 16 * scale, style: .continuous))
                    .shadow(color: isActive ? Color(hex: 0xFFD700, alpha: 0.5) : .clear, radius: 20 * scale)

                Text(title)
                    .font(.system(size: max(9, 12 * scale), weight: .semibold))
                    .foregroundStyle(isActive ? Color(hex: 0xFFD700) : .white.opacity(0.6))
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
            }
            .frame(maxWidth: .infinity, minHeight: 59.98 * scale, maxHeight: 59.98 * scale)
        }
        .buttonStyle(.soundPlain)
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
    MainTabContainerView()
}
