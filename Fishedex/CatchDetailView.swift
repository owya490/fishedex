import SwiftUI

struct CatchDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var session: SessionManager

    let catchID: UUID

    @State private var nickname = ""
    @State private var locationName = ""
    @State private var catchDate = Date()
    @State private var lengthCm = ""
    @State private var weightKg = ""
    @State private var bait = ""
    @State private var notes = ""
    @State private var didLoadFields = false
    @State private var saveError: String?
    @State private var viewerPhotoIndex: Int?
    @State private var galleryError: String?

    private var catchRow: UserCatchRow? {
        session.catches.first { $0.id == catchID }
    }

    private var fish: Fish? {
        catchRow.flatMap { session.fish(for: $0) }
    }

    private var accent: Color {
        fish.map { FishedexTheme.accent(for: $0) } ?? FishedexTheme.tabBlue
    }

    private var catchPhotos: [CatchPhotoRow] {
        session.photos(for: catchID)
    }

    private var hasUnsavedChanges: Bool {
        guard let catchRow, didLoadFields else { return false }

        if normalizedOptional(nickname) != normalizedOptional(catchRow.customName) { return true }
        if normalizedOptional(locationName) != normalizedOptional(catchRow.locationName) { return true }
        if normalizedOptional(bait) != normalizedOptional(catchRow.bait) { return true }
        if normalizedOptional(notes) != normalizedOptional(catchRow.notes) { return true }
        if parsedDouble(lengthCm) != catchRow.lengthCm { return true }
        if parsedDouble(weightKg) != catchRow.weightKg { return true }
        if !Calendar.current.isDate(catchDate, equalTo: catchRow.caughtAt, toGranularity: .minute) {
            return true
        }
        return false
    }

    private var canSaveChanges: Bool {
        hasUnsavedChanges && !session.isUpdatingCatch
    }

    var body: some View {
        Group {
            if let catchRow {
                detailContent(catchRow: catchRow)
            } else {
                VStack(spacing: 0) {
                    AppHeaderView(onBack: { dismiss() })
                    Spacer()
                    Text("Catch not found.")
                        .font(FishedexFont.body)
                        .foregroundStyle(FishedexTheme.muted)
                    Spacer()
                }
            }
        }
        .background(Color(red: 0.95, green: 0.95, blue: 0.96).ignoresSafeArea())
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
        .fullScreenCover(isPresented: viewerPresented) {
            PhotoViewerOverlay(
                photos: catchPhotos,
                selectedIndex: $viewerPhotoIndex
            )
        }
        .onChange(of: catchRow?.id) { _, _ in
            loadFieldsIfNeeded()
        }
        .onAppear {
            loadFieldsIfNeeded()
        }
    }

    private func detailContent(catchRow: UserCatchRow) -> some View {
        VStack(spacing: 0) {
            AppHeaderView(onBack: { dismiss() })

            ScrollView(showsIndicators: false) {
                VStack(spacing: 16) {
                    heroCard(catchRow: catchRow)
                    galleryCard
                    catchLogCard(catchRow: catchRow)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 20)
            }
        }
    }

    private var viewerPresented: Binding<Bool> {
        Binding(
            get: { viewerPhotoIndex != nil },
            set: { if !$0 { viewerPhotoIndex = nil } }
        )
    }

    private func heroCard(catchRow: UserCatchRow) -> some View {
        VStack(spacing: 0) {
            Group {
                if let fish {
                    FishArtworkView(fish: fish, height: 140, showsShadow: true)
                } else {
                    PixelGrayFishIconView(size: 100)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
            .background(accent.opacity(0.08))

            VStack(alignment: .leading, spacing: 8) {
                Text(displayTitle(for: catchRow).uppercased())
                    .font(FishedexFont.title2)
                    .foregroundStyle(FishedexTheme.ink)
                    .fixedSize(horizontal: false, vertical: true)

                Text(session.catchSpeciesName(for: catchRow).uppercased())
                    .font(FishedexFont.subheadline)
                    .foregroundStyle(FishedexTheme.tabBlue)

                if let fish {
                    Text(fish.number)
                        .font(FishedexFont.caption)
                        .foregroundStyle(FishedexTheme.muted)

                    TraitPill(label: fish.habitat.uppercased(), tint: accent)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(16)
        }
        .background(Color.white)
        .fishedexSquare()
        .fishedexBorder()
    }

    private var galleryCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("CATCH GALLERY")
                .font(FishedexFont.caption)
                .foregroundStyle(FishedexTheme.muted)
                .kerning(0.6)

            Text("Photos for this catch. Tap to view full size.")
                .font(FishedexFont.caption)
                .foregroundStyle(FishedexTheme.muted)
                .fixedSize(horizontal: false, vertical: true)

            CatchPhotoGalleryGrid(
                photos: catchPhotos,
                fish: fish,
                allowsUpload: true,
                isUploading: session.uploadingCatchPhotoIDs.contains(catchID),
                onPhotoTap: { viewerPhotoIndex = $0 },
                onUpload: uploadPhoto
            )

            if let galleryError {
                Text(galleryError)
                    .font(FishedexFont.caption)
                    .foregroundStyle(FishedexTheme.headerRed)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Color.white)
        .fishedexSquare()
        .fishedexBorder()
    }

    private func catchLogCard(catchRow: UserCatchRow) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("CATCH LOG")
                .font(FishedexFont.caption)
                .foregroundStyle(FishedexTheme.muted)
                .kerning(0.6)

            Text("Edit your catch details below.")
                .font(FishedexFont.caption)
                .foregroundStyle(FishedexTheme.muted)
                .fixedSize(horizontal: false, vertical: true)

            catchField("NICKNAME", text: $nickname, prompt: "e.g. Big Blue")
            catchField("LOCATION", text: $locationName, prompt: "Where were you fishing?")

            VStack(alignment: .leading, spacing: 6) {
                Text("DATE & TIME")
                    .font(FishedexFont.caption)
                    .foregroundStyle(FishedexTheme.muted)

                DatePicker("", selection: $catchDate, displayedComponents: [.date, .hourAndMinute])
                    .labelsHidden()
                    .datePickerStyle(.compact)
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(red: 0.95, green: 0.95, blue: 0.96))
                    .fishedexSquare()
                    .fishedexBorder(lineWidth: 1)
            }

            HStack(spacing: 12) {
                catchField("LENGTH (CM)", text: $lengthCm, prompt: "30")
                    .keyboardType(.decimalPad)
                catchField("WEIGHT (KG)", text: $weightKg, prompt: "1.5")
                    .keyboardType(.decimalPad)
            }

            catchField("BAIT", text: $bait, prompt: "e.g. Prawn, lure, worm")

            VStack(alignment: .leading, spacing: 6) {
                Text("NOTES")
                    .font(FishedexFont.caption)
                    .foregroundStyle(FishedexTheme.muted)

                TextField("Weather, story...", text: $notes, axis: .vertical)
                    .font(FishedexFont.body)
                    .lineLimit(3...6)
                    .padding(12)
                    .background(Color(red: 0.95, green: 0.95, blue: 0.96))
                    .fishedexSquare()
                    .fishedexBorder(lineWidth: 1)
            }

            if fish != nil {
                CatchFactRow(label: "Species", value: session.catchSpeciesName(for: catchRow))
            }

            if let saveError {
                Text(saveError)
                    .font(FishedexFont.caption)
                    .foregroundStyle(FishedexTheme.headerRed)
            }

            Button(action: saveChanges) {
                HStack {
                    Spacer()
                    if session.isUpdatingCatch {
                        ProgressView().tint(.white)
                    } else {
                        Text("SAVE CHANGES")
                            .font(FishedexFont.headline)
                    }
                    Spacer()
                }
                .padding(.vertical, 12)
                .background(canSaveChanges ? FishedexTheme.tabGreen : Color(red: 0.86, green: 0.86, blue: 0.87))
                .foregroundStyle(canSaveChanges ? .white : FishedexTheme.muted)
                .fishedexSquare()
                .fishedexBorder()
            }
            .buttonStyle(.plain)
            .disabled(!canSaveChanges)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Color.white)
        .fishedexSquare()
        .fishedexBorder()
    }

    private func catchField(_ label: String, text: Binding<String>, prompt: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(FishedexFont.caption)
                .foregroundStyle(FishedexTheme.muted)

            TextField(prompt, text: text)
                .font(FishedexFont.body)
                .padding(12)
                .background(Color(red: 0.95, green: 0.95, blue: 0.96))
                .fishedexSquare()
                .fishedexBorder(lineWidth: 1)
        }
    }

    private func displayTitle(for catchRow: UserCatchRow) -> String {
        let trimmed = nickname.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty { return trimmed }
        return session.catchTitle(for: catchRow)
    }

    private func normalizedOptional(_ value: String?) -> String? {
        value?.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty
    }

    private func parsedDouble(_ text: String) -> Double? {
        Double(text.trimmingCharacters(in: .whitespacesAndNewlines))
    }

    private func loadFieldsIfNeeded() {
        guard let catchRow, !didLoadFields else { return }
        nickname = catchRow.customName ?? ""
        locationName = catchRow.locationName ?? ""
        catchDate = catchRow.caughtAt
        lengthCm = catchRow.lengthCm.map { String(format: "%g", $0) } ?? ""
        weightKg = catchRow.weightKg.map { String(format: "%g", $0) } ?? ""
        bait = catchRow.bait ?? ""
        notes = catchRow.notes ?? ""
        didLoadFields = true
    }

    private func saveChanges() {
        saveError = nil

        let input = UpdateCatchInput(
            customName: nickname.nilIfEmpty,
            weightKg: Double(weightKg.trimmingCharacters(in: .whitespacesAndNewlines)),
            lengthCm: Double(lengthCm.trimmingCharacters(in: .whitespacesAndNewlines)),
            locationName: locationName.nilIfEmpty,
            bait: bait.nilIfEmpty,
            notes: notes.nilIfEmpty,
            caughtAt: catchDate
        )

        Task {
            do {
                try await session.updateCatch(id: catchID, input: input)
            } catch {
                saveError = error.localizedDescription
            }
        }
    }

    private func uploadPhoto(_ data: Data) {
        galleryError = nil
        Task {
            do {
                try await session.uploadCatchPhoto(catchId: catchID, imageData: data)
            } catch {
                galleryError = error.localizedDescription
            }
        }
    }
}

struct CatchPhotoView: View {
    let urlString: String?
    var fish: Fish?
    var height: CGFloat = 120

    var body: some View {
        Group {
            if urlString != nil {
                CachedRemoteImage(
                    urlString: urlString,
                    content: {
                        $0
                            .resizable()
                            .scaledToFill()
                            .transition(.opacity)
                    },
                    placeholder: { loadingPlaceholder },
                    failure: { photoUnavailablePlaceholder }
                )
            } else {
                noPhotoPlaceholder
            }
        }
        .frame(height: height)
        .frame(maxWidth: .infinity)
        .clipped()
    }

    private var loadingPlaceholder: some View {
        ZStack {
            Color(red: 0.95, green: 0.95, blue: 0.96)
            ProgressView()
                .tint(FishedexTheme.tabBlue)
        }
    }

    private var photoUnavailablePlaceholder: some View {
        ZStack {
            Color(red: 0.95, green: 0.95, blue: 0.96)
            Image(systemName: "photo")
                .font(.system(size: height * 0.28))
                .foregroundStyle(FishedexTheme.muted)
        }
    }

    @ViewBuilder
    private var noPhotoPlaceholder: some View {
        if let fish {
            FishArtworkView(fish: fish, height: height * 0.85, showsShadow: false)
                .frame(maxWidth: .infinity)
        } else {
            photoUnavailablePlaceholder
        }
    }
}

private struct CatchFactRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack(alignment: .top) {
            Text(label.uppercased())
                .font(FishedexFont.micro)
                .foregroundStyle(FishedexTheme.muted)
                .kerning(0.4)
                .frame(width: 72, alignment: .leading)

            Text(value)
                .font(FishedexFont.subheadline)
                .foregroundStyle(FishedexTheme.ink)
                .fixedSize(horizontal: false, vertical: true)

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(Color(red: 0.95, green: 0.95, blue: 0.96))
        .fishedexSquare()
        .fishedexBorder(lineWidth: 1)
    }
}

private extension String {
    var nilIfEmpty: String? {
        let trimmed = trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}

#Preview {
    NavigationStack {
        CatchDetailView(catchID: UUID())
            .environmentObject(SessionManager())
    }
}
