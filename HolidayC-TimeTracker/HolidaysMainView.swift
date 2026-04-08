import SwiftUI

struct HolidaysMainView: View {
    @EnvironmentObject private var store: AppDataStore
    let resetToken: Int
    @State private var selectedFilter = "All"
    @State private var searchText = ""
    @State private var formMode: HolidayFormMode = .create
    @State private var editingSeed: HolidayFormSeed?
    @State private var selectedItem: AppEvent?
    @State private var isDetailPresented = false
    @State private var isFormPresented = false
    let bottomInset: CGFloat

    init(bottomInset: CGFloat = 0, resetToken: Int = 0) {
        self.bottomInset = bottomInset
        self.resetToken = resetToken
    }

    private let filters = ["All", "Joy", "Calm", "Tired"]

    private var filteredItems: [AppEvent] {
        store.events.sorted(by: { $0.date > $1.date }).filter { item in
            let moodOk = selectedFilter == "All" || item.mood.rawValue == selectedFilter
            let text = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
            let searchOk = text.isEmpty || item.title.localizedCaseInsensitiveContains(text) || item.place.localizedCaseInsensitiveContains(text)
            return moodOk && searchOk
        }
    }

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

                ScrollView(.vertical, showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 16 * scale) {
                        Text("🎉 Holidays")
                            .font(.system(size: max(30, 36 * scale), weight: .bold))
                            .foregroundStyle(.white)
                            .shadow(color: Color(hex: 0xFFD700, alpha: 0.3), radius: 24 * scale)
                            .padding(.top, max(6, geo.safeAreaInsets.top))

                        searchField(scale: scale)
                        filterRow(scale: scale)

                        if filteredItems.isEmpty {
                            emptyState("No holiday records yet.", scale: scale)
                                .padding(.top, 28 * scale)
                        } else {
                            VStack(spacing: 16 * scale) {
                                ForEach(filteredItems) { item in
                                    HolidayCard(item: item, scale: scale)
                                        .onTapGesture {
                                            selectedItem = item
                                            isDetailPresented = true
                                        }
                                }
                            }
                            .padding(.top, 8 * scale)
                        }
                    }
                    .padding(.horizontal, 24 * scale)
                    .padding(.bottom, max(24 * scale, bottomInset))
                }

                if isDetailPresented, let item = selectedItem {
                    CelebrationDetailView(
                        data: detailData(for: item),
                        bottomInset: bottomInset,
                        onBack: { isDetailPresented = false },
                        onEdit: {
                            formMode = .edit
                            editingSeed = makeSeed(from: item)
                            isFormPresented = true
                        },
                        onDelete: {
                            store.deleteEvent(id: item.id)
                            isDetailPresented = false
                        }
                    )
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .zIndex(9)
                }

                if isFormPresented {
                    HolidayFormView(
                        mode: formMode,
                        seed: editingSeed,
                        guests: store.guests,
                        bottomInset: bottomInset,
                        onCancel: { isFormPresented = false },
                        onSubmit: { input in
                            var savedEvent: AppEvent
                            if let id = input.id {
                                savedEvent = AppEvent(
                                    id: id,
                                    title: input.title,
                                    type: input.type,
                                    date: input.date,
                                    place: input.place,
                                    mood: input.mood,
                                    holidayRating: input.holidayRating,
                                    placeRating: input.placeRating,
                                    note: input.note,
                                    guestIDs: input.guestIDs
                                )
                                store.updateEvent(savedEvent)
                            } else {
                                savedEvent = AppEvent(
                                    id: UUID(),
                                    title: input.title,
                                    type: input.type,
                                    date: input.date,
                                    place: input.place,
                                    mood: input.mood,
                                    holidayRating: input.holidayRating,
                                    placeRating: input.placeRating,
                                    note: input.note,
                                    guestIDs: input.guestIDs
                                )
                                store.addEvent(savedEvent)
                            }
                            selectedItem = savedEvent
                            isFormPresented = false
                        }
                    )
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .zIndex(10)
                }
            }
            .animation(.easeOut(duration: 0.2), value: isFormPresented)
            .animation(.easeOut(duration: 0.2), value: isDetailPresented)
            .onReceive(NotificationCenter.default.publisher(for: .openHolidayCreateForm)) { _ in
                formMode = .create
                editingSeed = HolidayFormSeed(
                    id: nil,
                    title: "",
                    type: "",
                    date: Date(),
                    place: "",
                    mood: .joy,
                    holidayRating: 5,
                    placeRating: 5,
                    note: "",
                    guestIDs: []
                )
                isDetailPresented = false
                isFormPresented = true
            }
            .onChange(of: isDetailPresented) { isPresented in
                NotificationCenter.default.post(
                    name: isPresented ? .holidayDetailOpened : .holidayDetailClosed,
                    object: nil
                )
            }
            .onChange(of: isFormPresented) { isPresented in
                NotificationCenter.default.post(
                    name: isPresented ? .holidayFormOpened : .holidayFormClosed,
                    object: nil
                )
            }
            .onChange(of: resetToken) { _ in
                selectedFilter = "All"
                searchText = ""
                formMode = .create
                editingSeed = nil
                selectedItem = nil
                isDetailPresented = false
                isFormPresented = false
            }
        }
    }

    private func searchField(scale: CGFloat) -> some View {
        HStack(spacing: 10 * scale) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 18 * scale, weight: .semibold))
                .foregroundStyle(Color(hex: 0xFFD700, alpha: 0.6))
            TextField(
                "",
                text: $searchText,
                prompt: Text("Search holidays...").foregroundColor(.white.opacity(0.5))
            )
                .font(.system(size: max(14, 16 * scale)))
                .foregroundStyle(.white)
        }
        .padding(.horizontal, 16 * scale)
        .frame(height: 56 * scale)
        .background(Color.white.opacity(0.08))
        .overlay(
            RoundedRectangle(cornerRadius: 16 * scale, style: .continuous)
                .stroke(Color(hex: 0xFFD700, alpha: 0.2), lineWidth: 0.7 * scale)
        )
        .clipShape(RoundedRectangle(cornerRadius: 16 * scale, style: .continuous))
        .shadow(color: .black.opacity(0.4), radius: 16 * scale, y: 6 * scale)
    }

    private func filterRow(scale: CGFloat) -> some View {
        HStack(spacing: 8 * scale) {
            ForEach(filters, id: \.self) { filter in
                Button {
                    selectedFilter = filter
                } label: {
                    Text(filter)
                        .font(.system(size: max(12, 14 * scale), weight: .bold))
                        .foregroundStyle(selectedFilter == filter ? Color(hex: 0x0A0E27) : .white.opacity(0.7))
                        .frame(height: 41 * scale)
                        .padding(.horizontal, 20 * scale)
                        .background(
                            Group {
                                if selectedFilter == filter {
                                    LinearGradient(colors: [Color(hex: 0xFFC300), Color(hex: 0xFFD700)], startPoint: .leading, endPoint: .trailing)
                                } else {
                                    Color(hex: 0x0F1629, alpha: 0.6)
                                }
                            }
                        )
                        .overlay(
                            Capsule()
                                .stroke(Color(hex: 0xFFD700, alpha: selectedFilter == filter ? 0.0 : 0.2), lineWidth: 0.7 * scale)
                        )
                        .clipShape(Capsule())
                        .shadow(color: selectedFilter == filter ? Color(hex: 0xFFD700, alpha: 0.4) : .clear, radius: 12 * scale)
                }
                .buttonStyle(.soundPlain)
            }
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

    private func detailData(for item: AppEvent) -> CelebrationDetailData {
        CelebrationDetailData(
            title: item.title,
            category: item.type,
            moodEmoji: item.mood.emoji,
            moodTitle: item.mood.rawValue,
            dateText: fullDate(from: item.date),
            place: item.place,
            placeRating: item.placeRating,
            holidayRating: item.holidayRating,
            note: item.note.isEmpty ? "No note yet." : item.note,
            guests: item.guestIDs.compactMap { id in
                guard let guest = store.guests.first(where: { $0.id == id }) else { return nil }
                return .init(name: guest.name, relation: guest.type, rating: guest.behaviorRating)
            }
        )
    }

    private func makeSeed(from item: AppEvent) -> HolidayFormSeed {
        HolidayFormSeed(
            id: item.id,
            title: item.title,
            type: item.type,
            date: item.date,
            place: item.place,
            mood: item.mood,
            holidayRating: item.holidayRating,
            placeRating: item.placeRating,
            note: item.note,
            guestIDs: item.guestIDs
        )
    }

    private func fullDate(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "EEEE, MMMM d, yyyy"
        return formatter.string(from: date)
    }

}

private struct HolidayCard: View {
    let item: AppEvent
    let scale: CGFloat

    var body: some View {
        VStack(alignment: .leading, spacing: 12 * scale) {
            HStack(alignment: .top, spacing: 8 * scale) {
                VStack(alignment: .leading, spacing: 4 * scale) {
                    Text(item.title)
                        .font(.system(size: max(18, 20 * scale), weight: .bold))
                        .foregroundStyle(.white)
                    Text(shortDate(item.date))
                        .font(.system(size: max(13, 14 * scale)))
                        .foregroundStyle(.white.opacity(0.7))
                }
                Spacer(minLength: 6 * scale)
                moodPill(item.mood)
            }

            HStack(spacing: 16 * scale) {
                Text("📍 \(item.place)")
                    .font(.system(size: max(13, 14 * scale)))
                    .foregroundStyle(.white.opacity(0.7))
                    .lineLimit(1)
                HStack(spacing: 4 * scale) {
                    Image(systemName: "person.2")
                    Text("\(item.guestIDs.count)")
                }
                .font(.system(size: max(13, 14 * scale)))
                .foregroundStyle(.white.opacity(0.7))
                Spacer()
            }

            HStack {
                HStack(spacing: 4 * scale) {
                    ForEach(0..<5, id: \.self) { index in
                        Image(systemName: index < item.holidayRating ? "star.fill" : "star")
                            .font(.system(size: 15 * scale, weight: .semibold))
                            .foregroundStyle(index < item.holidayRating ? Color(hex: 0xFFD700) : Color.white.opacity(0.2))
                            .shadow(color: index < item.holidayRating ? Color(hex: 0xFFD700, alpha: 0.6) : .clear, radius: 8 * scale)
                    }
                }
                Spacer()
                Text(item.type.uppercased())
                    .font(.system(size: max(11, 12 * scale), weight: .semibold))
                    .foregroundStyle(.white.opacity(0.5))
                    .tracking(0.6 * scale)
            }
        }
        .padding(24 * scale)
        .background(Color(hex: 0x0F1629, alpha: 0.6))
        .overlay(
            RoundedRectangle(cornerRadius: 16 * scale, style: .continuous)
                .stroke(Color(hex: 0xFFD700, alpha: 0.2), lineWidth: 0.7 * scale)
        )
        .clipShape(RoundedRectangle(cornerRadius: 16 * scale, style: .continuous))
        .shadow(color: .black.opacity(0.4), radius: 16 * scale, y: 8 * scale)
    }

    private func shortDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "MMMM d, yyyy"
        return formatter.string(from: date)
    }

    private func moodPill(_ mood: AppMood) -> some View {
        HStack(spacing: 6 * scale) {
            Text(mood.emoji)
            Text(mood.rawValue)
                .font(.system(size: max(13, 14 * scale), weight: .bold))
        }
        .foregroundStyle(mood.textColor)
        .padding(.horizontal, 14 * scale)
        .frame(height: 35.4 * scale)
        .background(mood.background)
        .overlay(
            Capsule().stroke(mood.borderColor, lineWidth: 1.7 * scale)
        )
        .clipShape(Capsule())
        .shadow(color: mood.glow, radius: 10 * scale)
    }
}

private extension AppMood {
    var textColor: Color {
        switch self {
        case .joy: return Color(hex: 0xFFD700)
        case .calm: return .white
        case .tired: return Color(hex: 0xFF6B6B)
        }
    }

    var background: LinearGradient {
        switch self {
        case .joy:
            return LinearGradient(colors: [Color(hex: 0xFFD700, alpha: 0.3), Color(hex: 0xFFC300, alpha: 0.3)], startPoint: .leading, endPoint: .trailing)
        case .calm:
            return LinearGradient(colors: [Color.white.opacity(0.2), Color.white.opacity(0.2)], startPoint: .leading, endPoint: .trailing)
        case .tired:
            return LinearGradient(colors: [Color(hex: 0xE10600, alpha: 0.3), Color(hex: 0xFF1493, alpha: 0.3)], startPoint: .leading, endPoint: .trailing)
        }
    }

    var borderColor: Color {
        switch self {
        case .joy: return Color(hex: 0xFFD700, alpha: 0.5)
        case .calm: return Color.white.opacity(0.5)
        case .tired: return Color(hex: 0xE10600, alpha: 0.5)
        }
    }

    var glow: Color {
        switch self {
        case .joy: return Color(hex: 0xFFD700, alpha: 0.3)
        case .calm: return Color.white.opacity(0.2)
        case .tired: return Color(hex: 0xE10600, alpha: 0.3)
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
    HolidaysMainView()
}
