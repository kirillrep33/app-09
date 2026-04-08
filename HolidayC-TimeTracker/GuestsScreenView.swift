import SwiftUI

private enum GuestFormMode {
    case add
    case edit
}

struct GuestsScreenView: View {
    @EnvironmentObject private var store: AppDataStore
    let bottomInset: CGFloat
    let resetToken: Int

    @State private var formMode: GuestFormMode = .add
    @State private var editingGuest: AppGuest?
    @State private var isFormPresented = false

    init(bottomInset: CGFloat = 0, resetToken: Int = 0) {
        self.bottomInset = bottomInset
        self.resetToken = resetToken
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
                    VStack(alignment: .leading, spacing: 24 * scale) {
                        header(scale: scale)

                        if store.guests.isEmpty {
                            emptyState("No guest records yet.", scale: scale)
                        } else {
                            VStack(spacing: 12 * scale) {
                                ForEach(store.guests) { guest in
                                    guestCard(guest, scale: scale)
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 24 * scale)
                    .padding(.top, max(14 * scale, geo.safeAreaInsets.top + 6 * scale))
                    .padding(.bottom, max(bottomInset, 24 * scale))
                }

                if isFormPresented {
                    GuestFormView(
                        mode: formMode,
                        guest: editingGuest,
                        bottomInset: bottomInset,
                        onCancel: { isFormPresented = false },
                        onSave: { name, type, rating, note, isEdit in
                            if isEdit, let editingGuest {
                                store.updateGuest(id: editingGuest.id, name: name, type: type, rating: rating, note: note)
                            } else {
                                _ = store.addGuest(name: name, type: type, rating: rating, note: note)
                            }
                            isFormPresented = false
                        }
                    )
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .zIndex(10)
                }
            }
            .animation(.easeOut(duration: 0.2), value: isFormPresented)
            .onReceive(NotificationCenter.default.publisher(for: .openGuestCreateForm)) { _ in
                formMode = .add
                editingGuest = nil
                isFormPresented = true
            }
            .onChange(of: resetToken) { _ in
                formMode = .add
                editingGuest = nil
                isFormPresented = false
            }
        }
    }

    private func header(scale: CGFloat) -> some View {
        HStack {
            Text("Guests")
                .font(.system(size: max(32, 36 * scale), weight: .semibold))
                .foregroundStyle(.white)

            Spacer()

            Button {
                formMode = .add
                editingGuest = nil
                isFormPresented = true
            } label: {
                HStack(spacing: 8 * scale) {
                    Image(systemName: "plus")
                        .font(.system(size: 16 * scale, weight: .medium))
                        .foregroundStyle(.black)
                    Text("Add Guest")
                        .font(.system(size: max(13, 14 * scale), weight: .semibold))
                        .foregroundStyle(.black)
                }
                .frame(height: 36 * scale)
                .padding(.horizontal, 12 * scale)
                .background(Color(hex: 0xFDC700))
                .clipShape(Capsule())
            }
            .buttonStyle(.soundPlain)
        }
    }

    private func guestCard(_ guest: AppGuest, scale: CGFloat) -> some View {
        return VStack(alignment: .leading, spacing: 4 * scale) {
            HStack(alignment: .top, spacing: 16 * scale) {
                Text(String(guest.name.prefix(1)))
                    .font(.system(size: max(22, 36 * scale / 1.8), weight: .regular))
                    .foregroundStyle(.black)
                    .frame(width: 56 * scale, height: 56 * scale)
                    .background(
                        LinearGradient(
                            colors: [Color(hex: 0xFDC700), Color(hex: 0xFF6900)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .clipShape(Circle())

                VStack(alignment: .leading, spacing: 4 * scale) {
                    Text(guest.name)
                        .font(.system(size: max(17, 18 * scale), weight: .semibold))
                        .foregroundStyle(.white)

                    HStack(spacing: 12 * scale) {
                        tagView(guest.type, scale: scale)
                        stars(guest.behaviorRating, scale: scale)
                    }

                    if !guest.note.isEmpty {
                        Text(guest.note)
                            .font(.system(size: max(13, 14 * scale), weight: .regular))
                            .foregroundStyle(.white.opacity(0.4))
                            .lineSpacing(3 * scale)
                    }
                }
            }
        }
        .padding(16.56 * scale)
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(minHeight: 90.23 * scale, alignment: .topLeading)
        .background(Color.white.opacity(0.05))
        .overlay(
            RoundedRectangle(cornerRadius: 16 * scale, style: .continuous)
                .stroke(Color.white.opacity(0.1), lineWidth: 0.57 * scale)
        )
        .clipShape(RoundedRectangle(cornerRadius: 16 * scale, style: .continuous))
        .onTapGesture {
            formMode = .edit
            editingGuest = guest
            isFormPresented = true
        }
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button(role: .destructive) {
                store.deleteGuest(id: guest.id)
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
    }

    private func tagView(_ typeText: String, scale: CGFloat) -> some View {
        let normalized = typeText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let textColor: Color
        let background: Color
        let border: Color

        if normalized.contains("friend") {
            textColor = Color(hex: 0x51A2FF)
            background = Color(hex: 0x2B7FFF, alpha: 0.2)
            border = Color(hex: 0x2B7FFF, alpha: 0.4)
        } else if normalized.contains("relative") {
            textColor = Color(hex: 0xC27AFF)
            background = Color(hex: 0xAD46FF, alpha: 0.2)
            border = Color(hex: 0xAD46FF, alpha: 0.4)
        } else if normalized.contains("acquaint") {
            textColor = Color(hex: 0x05DF72)
            background = Color(hex: 0x00C950, alpha: 0.2)
            border = Color(hex: 0x00C950, alpha: 0.4)
        } else {
            textColor = Color.white.opacity(0.7)
            background = Color.white.opacity(0.12)
            border = Color.white.opacity(0.35)
        }

        return Text(typeText.isEmpty ? "Type not set" : typeText)
            .font(.system(size: max(11, 12 * scale), weight: .regular))
            .foregroundStyle(textColor)
            .padding(.horizontal, 8.56 * scale)
            .frame(height: 25.12 * scale)
            .background(background)
            .overlay(
                Capsule().stroke(border, lineWidth: 0.57 * scale)
            )
            .clipShape(Capsule())
    }

    private func stars(_ rating: Int, scale: CGFloat) -> some View {
        HStack(spacing: 3.99 * scale) {
            ForEach(0..<5, id: \.self) { idx in
                Image(systemName: idx < rating ? "star.fill" : "star")
                    .font(.system(size: 15 * scale, weight: .semibold))
                    .foregroundStyle(idx < rating ? Color(hex: 0xFFD700) : Color.white.opacity(0.2))
                    .shadow(color: idx < rating ? Color(hex: 0xFFD700, alpha: 0.6) : .clear, radius: 8 * scale)
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
}

private struct GuestFormView: View {
    let mode: GuestFormMode
    let guest: AppGuest?
    let bottomInset: CGFloat
    let onCancel: () -> Void
    let onSave: (String, String, Int, String, Bool) -> Void

    @State private var name = ""
    @State private var typeText = ""
    @State private var rating = 0
    @State private var note = ""
    @FocusState private var noteFocused: Bool

    var body: some View {
        GeometryReader { geo in
            let scale = min(geo.size.width / 393.0, geo.size.height / 852.0)

            ZStack(alignment: .top) {
                LinearGradient(
                    colors: [.black, Color(hex: 0x002672), .black],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()

                VStack(alignment: .leading, spacing: 24 * scale) {
                    topBar(scale: scale)
                    form(scale: scale)
                }
                .padding(.top, max(6 * scale, geo.safeAreaInsets.top))

            }
            .onAppear {
                if let guest {
                    name = guest.name
                    typeText = guest.type
                    rating = guest.behaviorRating
                    note = guest.note
                } else {
                    typeText = ""
                }
            }
        }
    }

    private func topBar(scale: CGFloat) -> some View {
        HStack {
            HStack(spacing: 12 * scale) {
                Button(action: onCancel) {
                    Image(systemName: "arrow.left")
                        .font(.system(size: 20 * scale, weight: .regular))
                        .foregroundStyle(.white)
                        .frame(width: 36 * scale, height: 36 * scale)
                }
                .buttonStyle(.soundPlain)

                Text(mode == .add ? "Add Guest" : "Edit Guest")
                    .font(.system(size: max(18, 20 * scale), weight: .medium))
                    .foregroundStyle(.white)
            }

            Spacer()

            Button(action: onCancel) {
                Text("Cancel")
                    .font(.system(size: max(13, 14 * scale), weight: .medium))
                    .foregroundStyle(.white.opacity(0.6))
                    .padding(.horizontal, 12 * scale)
                    .frame(height: 32 * scale)
            }
            .buttonStyle(.soundPlain)
        }
        .padding(.horizontal, 16 * scale)
        .frame(height: 68 * scale)
        .background(Color.black.opacity(0.8))
        .overlay(Rectangle().fill(Color.black).frame(height: 0.57 * scale), alignment: .bottom)
    }

    private func form(scale: CGFloat) -> some View {
        VStack(alignment: .leading, spacing: 24 * scale) {
            labeledField(title: "Name *", scale: scale) {
                TextField("", text: $name, prompt: Text("e.g., John Doe").foregroundColor(.white.opacity(0.4)))
                    .foregroundStyle(.white)
                    .font(.system(size: max(14, 16 * scale)))
                    .padding(.horizontal, 12 * scale)
                    .frame(height: 36 * scale)
                    .background(Color.white.opacity(0.05))
                    .overlay(RoundedRectangle(cornerRadius: 16 * scale, style: .continuous).stroke(Color.white.opacity(0.1), lineWidth: 0.57 * scale))
                    .clipShape(RoundedRectangle(cornerRadius: 16 * scale, style: .continuous))
            }

            labeledField(title: "Type", scale: scale) {
                TextField(
                    "",
                    text: $typeText,
                    prompt: Text("e.g., Friend").foregroundColor(.white.opacity(0.4))
                )
                    .foregroundStyle(.white)
                    .font(.system(size: max(14, 16 * scale)))
                    .padding(.horizontal, 12 * scale)
                    .frame(height: 37 * scale)
                    .background(Color.white.opacity(0.05))
                    .overlay(RoundedRectangle(cornerRadius: 16 * scale, style: .continuous).stroke(Color.white.opacity(0.1), lineWidth: 0.57 * scale))
                    .clipShape(RoundedRectangle(cornerRadius: 16 * scale, style: .continuous))
            }

            VStack(alignment: .leading, spacing: 12 * scale) {
                Text("Behavior Rating (Optional)")
                    .font(.system(size: max(13, 14 * scale), weight: .medium))
                    .foregroundStyle(.white.opacity(0.8))
                HStack(spacing: 4 * scale) {
                    ForEach(1...5, id: \.self) { value in
                        Button {
                            rating = value
                        } label: {
                            Image(systemName: value <= rating ? "star.fill" : "star")
                                .font(.system(size: 24 * scale, weight: .regular))
                                .foregroundStyle(value <= rating ? Color(hex: 0xFFD700) : Color.white.opacity(0.2))
                        }
                        .buttonStyle(.soundPlain)
                    }
                }
            }
            .padding(16.56 * scale)
            .background(Color.white.opacity(0.05))
            .overlay(RoundedRectangle(cornerRadius: 16 * scale, style: .continuous).stroke(Color.white.opacity(0.1), lineWidth: 0.57 * scale))
            .clipShape(RoundedRectangle(cornerRadius: 16 * scale, style: .continuous))

            labeledField(title: "Note (Optional)", scale: scale) {
                TextField(
                    "",
                    text: $note,
                    prompt: Text("Add any notes about this guest...").foregroundColor(.white.opacity(0.4))
                )
                    .foregroundStyle(.white)
                    .font(.system(size: max(14, 16 * scale)))
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
                    .overlay(RoundedRectangle(cornerRadius: 16 * scale, style: .continuous).stroke(Color.white.opacity(0.1), lineWidth: 0.57 * scale))
                    .clipShape(RoundedRectangle(cornerRadius: 16 * scale, style: .continuous))
            }

            Button {
                onSave(
                    name,
                    typeText.trimmingCharacters(in: .whitespacesAndNewlines),
                    rating,
                    note,
                    mode == .edit
                )
            } label: {
                Text(mode == .add ? "Add Guest" : "Save Guest")
                    .font(.system(size: max(17, 18 * scale), weight: .medium))
                    .foregroundStyle(.black)
                    .frame(maxWidth: .infinity)
                    .frame(height: 48 * scale)
                    .background(Color(hex: 0xFDC700))
                    .clipShape(RoundedRectangle(cornerRadius: 16 * scale, style: .continuous))
            }
            .buttonStyle(.soundPlain)
        }
        .padding(.horizontal, 24 * scale)
        .padding(.top, 24 * scale)
        .padding(.bottom, max(bottomInset, 24 * scale))
    }

    private func labeledField<Content: View>(title: String, scale: CGFloat, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8 * scale) {
            Text(title)
                .font(.system(size: max(13, 14 * scale), weight: .medium))
                .foregroundStyle(.white.opacity(0.8))
            content()
        }
    }
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

#Preview {
    GuestsScreenView(bottomInset: 120)
}
