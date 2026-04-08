import SwiftUI

extension Notification.Name {
    static let openHolidayCreateForm = Notification.Name("openHolidayCreateForm")
    static let holidayDetailOpened = Notification.Name("holidayDetailOpened")
    static let holidayDetailClosed = Notification.Name("holidayDetailClosed")
    static let holidayFormOpened = Notification.Name("holidayFormOpened")
    static let holidayFormClosed = Notification.Name("holidayFormClosed")
    static let switchToGuestsTab = Notification.Name("switchToGuestsTab")
    static let openGuestCreateForm = Notification.Name("openGuestCreateForm")
}

enum HolidayFormMode {
    case create
    case edit
}

struct HolidayFormSeed {
    let id: UUID?
    let title: String
    let type: String
    let date: Date
    let place: String
    let mood: AppMood
    let holidayRating: Int
    let placeRating: Int
    let note: String
    let guestIDs: [UUID]
}

struct HolidayFormInput {
    let id: UUID?
    let title: String
    let type: String
    let date: Date
    let place: String
    let mood: AppMood
    let holidayRating: Int
    let placeRating: Int
    let note: String
    let guestIDs: [UUID]
}

struct HolidayFormView: View {
    let mode: HolidayFormMode
    let seed: HolidayFormSeed?
    let guests: [AppGuest]
    let bottomInset: CGFloat
    let onCancel: () -> Void
    let onSubmit: (HolidayFormInput) -> Void

    @State private var title = ""
    @State private var type = ""
    @State private var date = Date()
    @State private var place = ""
    @State private var mood: AppMood = .joy
    @State private var holidayRating = 5
    @State private var placeRating = 5
    @State private var note = ""
    @State private var selectedGuests: Set<UUID> = []
    @State private var isDatePickerPresented = false
    @State private var pickerMonth = Date()
    @FocusState private var noteFocused: Bool

    private let weekDays = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]

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
                        VStack(alignment: .leading, spacing: 32 * scale) {
                            basicInfoSection(scale: scale)
                            moodSection(scale: scale)
                            ratingsSection(scale: scale)
                            guestsSection(scale: scale)
                            noteSection(scale: scale)
                            submitButton(scale: scale)
                        }
                        .padding(.horizontal, 24 * scale)
                        .padding(.top, 24 * scale)
                        .padding(.bottom, max(20 * scale, bottomInset))
                    }
                }

                if isDatePickerPresented {
                    datePickerOverlay(scale: scale)
                        .zIndex(20)
                        .transition(.opacity)
                }

            }
            .onAppear {
                if let seed {
                    title = seed.title
                    type = seed.type
                    date = seed.date
                    place = seed.place
                    mood = seed.mood
                    holidayRating = seed.holidayRating
                    placeRating = seed.placeRating
                    note = seed.note
                    selectedGuests = Set(seed.guestIDs)
                }
                pickerMonth = startOfMonth(date)
            }
            .animation(.easeOut(duration: 0.2), value: isDatePickerPresented)
        }
    }

    private func topBar(scale: CGFloat, topSafe: CGFloat) -> some View {
        HStack {
            HStack(spacing: 12 * scale) {
                Button(action: onCancel) {
                    Image(systemName: "arrow.left")
                        .font(.system(size: 20 * scale, weight: .regular))
                        .foregroundStyle(.white)
                        .frame(width: 36 * scale, height: 36 * scale)
                }
                .buttonStyle(.soundPlain)

                Text(mode == .create ? "New Holiday" : "Edit Holiday")
                    .font(.system(size: max(18, 20 * scale), weight: .semibold))
                    .foregroundStyle(.white)
            }

            Spacer()

            Button(action: onCancel) {
                Text("Cancel")
                    .font(.system(size: max(13, 14 * scale), weight: .semibold))
                    .foregroundStyle(.white.opacity(0.6))
            }
            .buttonStyle(.soundPlain)
        }
        .padding(.horizontal, 16 * scale)
        .padding(.top, max(0, topSafe))
        .padding(.bottom, 8 * scale)
    }

    private func basicInfoSection(scale: CGFloat) -> some View {
        VStack(alignment: .leading, spacing: 16 * scale) {
            sectionTitle("Basic Information", scale: scale)
            labeledTextField("Title *", text: $title, placeholder: "e.g., New Year's Eve Party", scale: scale)
            typePicker(scale: scale)
            datePickerRow(scale: scale)
            labeledTextField("Place", text: $place, placeholder: "e.g., Downtown Restaurant", scale: scale)
        }
    }

    private func moodSection(scale: CGFloat) -> some View {
        VStack(alignment: .leading, spacing: 16 * scale) {
            sectionTitle("How did you feel?", scale: scale)
            HStack(spacing: 12 * scale) {
                ForEach(AppMood.allCases, id: \.rawValue) { item in
                    Button {
                        mood = item
                    } label: {
                        VStack(spacing: 8 * scale) {
                            Text(item.emoji)
                                .font(.system(size: 36 * scale))
                            Text(item.rawValue)
                                .font(.system(size: max(14, 16 * scale), weight: .semibold))
                                .foregroundStyle(item == mood ? .white : .white.opacity(0.6))
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 107 * scale)
                        .background(item == mood ? Color(hex: 0xFDC700, alpha: 0.2) : Color.white.opacity(0.05))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16 * scale, style: .continuous)
                                .stroke(item == mood ? Color(hex: 0xFDC700) : Color.white.opacity(0.1), lineWidth: 1.7 * scale)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 16 * scale, style: .continuous))
                    }
                    .buttonStyle(.soundPlain)
                }
            }
        }
    }

    private func ratingsSection(scale: CGFloat) -> some View {
        VStack(alignment: .leading, spacing: 16 * scale) {
            sectionTitle("Ratings", scale: scale)
            ratingCard(title: "Holiday Rating", rating: $holidayRating, scale: scale)
            ratingCard(title: "Place Rating", rating: $placeRating, scale: scale)
        }
    }

    private func guestsSection(scale: CGFloat) -> some View {
        VStack(alignment: .leading, spacing: 16 * scale) {
            HStack {
                sectionTitle("Guests", scale: scale)
                Spacer()
                Button {
                    onCancel()
                    NotificationCenter.default.post(name: .switchToGuestsTab, object: nil)
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
                        NotificationCenter.default.post(name: .openGuestCreateForm, object: nil)
                    }
                } label: {
                    Text("+ Add Guest")
                        .font(.system(size: max(13, 14 * scale), weight: .semibold))
                        .foregroundStyle(Color(hex: 0xFDC700))
                        .padding(.horizontal, 12 * scale)
                        .frame(height: 32 * scale)
                        .background(Color(hex: 0x0A0E27))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14 * scale, style: .continuous)
                                .stroke(Color(hex: 0xFDC700, alpha: 0.4), lineWidth: 0.57 * scale)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 14 * scale, style: .continuous))
                }
                .buttonStyle(.soundPlain)
            }

            if guests.isEmpty {
                Text("No guests yet. Add guests in Guests tab first.")
                    .font(.system(size: max(13, 14 * scale), weight: .semibold))
                    .foregroundStyle(.white.opacity(0.6))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 8 * scale)
            } else {
                VStack(spacing: 8 * scale) {
                    ForEach(guests) { guest in
                        guestRow(guest: guest, scale: scale)
                    }
                }
            }
        }
    }

    private func noteSection(scale: CGFloat) -> some View {
        VStack(alignment: .leading, spacing: 16 * scale) {
            sectionTitle("Note", scale: scale)
            TextField(
                "",
                text: $note,
                prompt: Text("Add any additional thoughts or memories...").foregroundColor(.white.opacity(0.4))
            )
                .font(.system(size: max(14, 16 * scale)))
                .foregroundStyle(.white)
                .focused($noteFocused)
                .submitLabel(.done)
                .onSubmit {
                    noteFocused = false
                    hideKeyboard()
                }
                .frame(height: 64 * scale, alignment: .topLeading)
                .padding(.horizontal, 12 * scale)
                .padding(.vertical, 8 * scale)
                .background(Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 20 * scale, style: .continuous)
                        .stroke(Color.white.opacity(0.1), lineWidth: 0.57 * scale)
                )
                .clipShape(RoundedRectangle(cornerRadius: 20 * scale, style: .continuous))
        }
    }

    private func submitButton(scale: CGFloat) -> some View {
        Button {
            let input = HolidayFormInput(
                id: seed?.id,
                title: title.trimmingCharacters(in: .whitespacesAndNewlines),
                type: type,
                date: date,
                place: place.trimmingCharacters(in: .whitespacesAndNewlines),
                mood: mood,
                holidayRating: holidayRating,
                placeRating: placeRating,
                note: note.trimmingCharacters(in: .whitespacesAndNewlines),
                guestIDs: Array(selectedGuests)
            )
            onSubmit(input)
        } label: {
            Text(mode == .create ? "Create Holiday" : "Save Holiday")
                .font(.system(size: max(17, 18 * scale), weight: .semibold))
                .foregroundStyle(.black)
                .frame(maxWidth: .infinity)
                .frame(height: 48 * scale)
                .background(Color(hex: 0xFDC700))
                .clipShape(RoundedRectangle(cornerRadius: 20 * scale, style: .continuous))
        }
        .buttonStyle(.soundPlain)
    }

    private func guestRow(guest: AppGuest, scale: CGFloat) -> some View {
        let selected = selectedGuests.contains(guest.id)
        return Button {
            if selected {
                selectedGuests.remove(guest.id)
            } else {
                selectedGuests.insert(guest.id)
            }
        } label: {
            HStack {
                HStack(spacing: 12 * scale) {
                    Text(String(guest.name.prefix(1)))
                        .font(.system(size: max(14, 16 * scale), weight: .semibold))
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
                            .font(.system(size: max(14, 16 * scale), weight: .semibold))
                            .foregroundStyle(.white)
                        Text(guest.type.isEmpty ? "Type not set" : guest.type)
                            .font(.system(size: max(11, 12 * scale), weight: .semibold))
                            .foregroundStyle(.white.opacity(0.4))
                    }
                }
                Spacer()
                RoundedRectangle(cornerRadius: 4 * scale, style: .continuous)
                    .stroke(selected ? Color(hex: 0xFDC700) : Color.white.opacity(0.4), lineWidth: 1.70309 * scale)
                    .frame(width: 20 * scale, height: 20 * scale)
                    .background(
                        Group {
                            if selected {
                                RoundedRectangle(cornerRadius: 4 * scale, style: .continuous)
                                    .fill(Color(hex: 0xFDC700))
                                    .overlay(
                                        Image(systemName: "checkmark")
                                            .font(.system(size: 11.99 * scale, weight: .bold))
                                            .foregroundStyle(.black)
                                    )
                            } else {
                                Color.clear
                            }
                        }
                    )
            }
            .padding(.horizontal, 12 * scale)
            .frame(height: 65.13 * scale)
            .background(Color.white.opacity(0.05))
            .overlay(
                RoundedRectangle(cornerRadius: 20 * scale, style: .continuous)
                    .stroke(Color.white.opacity(0.1), lineWidth: 0.57 * scale)
            )
            .clipShape(RoundedRectangle(cornerRadius: 20 * scale, style: .continuous))
        }
        .buttonStyle(.soundPlain)
    }

    private func ratingCard(title: String, rating: Binding<Int>, scale: CGFloat) -> some View {
        VStack(alignment: .leading, spacing: 12 * scale) {
            Text(title)
                .font(.system(size: max(13, 14 * scale), weight: .semibold))
                .foregroundStyle(.white.opacity(0.8))

            HStack(spacing: 4 * scale) {
                ForEach(1...5, id: \.self) { idx in
                    Button {
                        rating.wrappedValue = idx
                    } label: {
                        Image(systemName: idx <= rating.wrappedValue ? "star.fill" : "star")
                            .font(.system(size: 24 * scale, weight: .regular))
                            .foregroundStyle(idx <= rating.wrappedValue ? Color(hex: 0xFFD700) : Color.white.opacity(0.2))
                            .shadow(color: idx <= rating.wrappedValue ? Color(hex: 0xFFD700, alpha: 0.6) : .clear, radius: 8 * scale)
                    }
                    .buttonStyle(.soundPlain)
                }
            }
        }
        .padding(16.56 * scale)
        .background(Color.white.opacity(0.05))
        .overlay(
            RoundedRectangle(cornerRadius: 16 * scale, style: .continuous)
                .stroke(Color.white.opacity(0.1), lineWidth: 0.57 * scale)
        )
        .clipShape(RoundedRectangle(cornerRadius: 16 * scale, style: .continuous))
    }

    private func typePicker(scale: CGFloat) -> some View {
        VStack(alignment: .leading, spacing: 8 * scale) {
            Text("Type")
                .font(.system(size: max(13, 14 * scale), weight: .semibold))
                .foregroundStyle(.white.opacity(0.8))
            TextField(
                "",
                text: $type,
                prompt: Text("e.g., Birthday").foregroundColor(.white.opacity(0.4))
            )
                .font(.system(size: max(14, 16 * scale)))
                .foregroundStyle(.white.opacity(0.8))
                .padding(.horizontal, 12 * scale)
                .frame(height: 37 * scale)
                .background(Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 20 * scale, style: .continuous)
                        .stroke(Color.white.opacity(0.1), lineWidth: 0.57 * scale)
                )
                .clipShape(RoundedRectangle(cornerRadius: 20 * scale, style: .continuous))
        }
    }

    private func datePickerRow(scale: CGFloat) -> some View {
        VStack(alignment: .leading, spacing: 8 * scale) {
            Text("Date *")
                .font(.system(size: max(13, 14 * scale), weight: .semibold))
                .foregroundStyle(.white.opacity(0.8))
            Button {
                pickerMonth = startOfMonth(date)
                isDatePickerPresented = true
            } label: {
                Text(formatDate(date))
                    .font(.system(size: max(14, 16 * scale)))
                    .foregroundStyle(.white.opacity(0.9))
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .buttonStyle(.soundPlain)
                .padding(.horizontal, 12 * scale)
                .frame(height: 36 * scale)
                .background(Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 20 * scale, style: .continuous)
                        .stroke(Color.white.opacity(0.1), lineWidth: 0.57 * scale)
                )
                .clipShape(RoundedRectangle(cornerRadius: 20 * scale, style: .continuous))
                .colorScheme(.dark)
        }
    }

    private func datePickerOverlay(scale: CGFloat) -> some View {
        ZStack {
            Color.black.opacity(0.55)
                .ignoresSafeArea()
                .onTapGesture { isDatePickerPresented = false }

            VStack(spacing: 16 * scale) {
                HStack {
                    Text("\(monthTitle(pickerMonth)) \(yearTitle(pickerMonth))")
                        .font(.system(size: max(18, 20 * scale), weight: .bold))
                        .foregroundStyle(.white)
                    Spacer()
                    HStack(spacing: 8 * scale) {
                        calendarNavButton(systemName: "chevron.left", scale: scale) {
                            shiftPickerMonth(by: -1)
                        }
                        calendarNavButton(systemName: "chevron.right", scale: scale) {
                            shiftPickerMonth(by: 1)
                        }
                    }
                }

                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8 * scale), count: 7), spacing: 8 * scale) {
                    ForEach(weekDays, id: \.self) { day in
                        Text(day)
                            .font(.system(size: max(11, 12 * scale), weight: .bold))
                            .foregroundStyle(Color(hex: 0xFFD700))
                            .frame(maxWidth: .infinity)
                    }
                    ForEach(pickerDays()) { day in
                        dateCell(day: day, scale: scale)
                    }
                }

                Button("Done") { isDatePickerPresented = false }
                    .font(.system(size: max(14, 16 * scale), weight: .semibold))
                    .foregroundStyle(.black)
                    .frame(maxWidth: .infinity)
                    .frame(height: 42 * scale)
                    .background(Color(hex: 0xFDC700))
                    .clipShape(RoundedRectangle(cornerRadius: 14 * scale, style: .continuous))
            }
            .padding(20 * scale)
            .background(Color(hex: 0x0F1629, alpha: 0.95))
            .overlay(
                RoundedRectangle(cornerRadius: 20 * scale, style: .continuous)
                    .stroke(Color(hex: 0xFFD700, alpha: 0.25), lineWidth: 0.8 * scale)
            )
            .clipShape(RoundedRectangle(cornerRadius: 20 * scale, style: .continuous))
            .padding(.horizontal, 24 * scale)
        }
    }

    private func calendarNavButton(systemName: String, scale: CGFloat, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 15 * scale, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 30 * scale, height: 30 * scale)
                .background(Color.white.opacity(0.07))
                .clipShape(RoundedRectangle(cornerRadius: 10 * scale, style: .continuous))
        }
        .buttonStyle(.soundPlain)
    }

    private func dateCell(day: PickerDay, scale: CGFloat) -> some View {
        Button {
            guard let value = day.value else { return }
            let comps = Calendar.current.dateComponents([.year, .month], from: pickerMonth)
            if let selected = Calendar.current.date(from: DateComponents(year: comps.year, month: comps.month, day: value)) {
                date = selected
                isDatePickerPresented = false
            }
        } label: {
            Text(day.value.map(String.init) ?? "")
                .font(.system(size: max(12, 13 * scale), weight: .bold))
                .foregroundStyle(isSelectedDay(day.value) ? Color(hex: 0x0A0E27) : .white)
                .frame(maxWidth: .infinity, minHeight: 34 * scale)
                .background(
                    Group {
                        if isSelectedDay(day.value) {
                            LinearGradient(colors: [Color(hex: 0xFFD700), Color(hex: 0xFFC300)], startPoint: .top, endPoint: .bottom)
                        } else {
                            Color.clear
                        }
                    }
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 10 * scale, style: .continuous)
                        .stroke(Color.white.opacity(day.value == nil ? 0.0 : 0.12), lineWidth: 0.57 * scale)
                )
                .clipShape(RoundedRectangle(cornerRadius: 10 * scale, style: .continuous))
        }
        .buttonStyle(.soundPlain)
        .disabled(day.value == nil)
    }

    private func isSelectedDay(_ day: Int?) -> Bool {
        guard let day else { return false }
        let c = Calendar.current
        let a = c.dateComponents([.year, .month], from: pickerMonth)
        let b = c.dateComponents([.year, .month, .day], from: date)
        return a.year == b.year && a.month == b.month && b.day == day
    }

    private func pickerDays() -> [PickerDay] {
        let c = Calendar.current
        let month = startOfMonth(pickerMonth)
        let range = c.range(of: .day, in: .month, for: month) ?? 1..<29
        let firstWeekdayIndex = c.component(.weekday, from: month) - 1
        var result: [PickerDay] = (0..<firstWeekdayIndex).map { PickerDay(id: "empty-\($0)", value: nil) }
        result.append(contentsOf: range.map { PickerDay(id: "day-\($0)", value: $0) })
        return result
    }

    private func shiftPickerMonth(by value: Int) {
        if let next = Calendar.current.date(byAdding: .month, value: value, to: pickerMonth) {
            pickerMonth = startOfMonth(next)
        }
    }

    private func startOfMonth(_ d: Date) -> Date {
        let c = Calendar.current
        let comps = c.dateComponents([.year, .month], from: d)
        return c.date(from: comps) ?? d
    }

    private func formatDate(_ d: Date) -> String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.dateFormat = "EEEE, MMM d, yyyy"
        return f.string(from: d)
    }

    private func monthTitle(_ d: Date) -> String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.dateFormat = "MMMM"
        return f.string(from: d)
    }

    private func yearTitle(_ d: Date) -> String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.dateFormat = "yyyy"
        return f.string(from: d)
    }

    private func labeledTextField(_ label: String, text: Binding<String>, placeholder: String, scale: CGFloat) -> some View {
        VStack(alignment: .leading, spacing: 8 * scale) {
            Text(label)
                .font(.system(size: max(13, 14 * scale), weight: .semibold))
                .foregroundStyle(.white.opacity(0.8))
            TextField("", text: text, prompt: Text(placeholder).foregroundColor(.white.opacity(0.4)))
                .font(.system(size: max(14, 16 * scale)))
                .foregroundStyle(.white)
                .padding(.horizontal, 12 * scale)
                .frame(height: 36 * scale)
                .background(Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 20 * scale, style: .continuous)
                        .stroke(Color.white.opacity(0.1), lineWidth: 0.57 * scale)
                )
                .clipShape(RoundedRectangle(cornerRadius: 20 * scale, style: .continuous))
        }
    }

    private func sectionTitle(_ text: String, scale: CGFloat) -> some View {
        Text(text)
            .font(.system(size: max(17, 18 * scale), weight: .semibold))
            .foregroundStyle(.white.opacity(0.8))
    }
}

private struct PickerDay: Identifiable {
    let id: String
    let value: Int?
}

private extension View {
    func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
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
