import SwiftUI
import CoreLocation
import UIKit

private enum CatchSuccessStep {
    case reveal
    case details
}

// MARK: - Catch success flow (reveal → details → save)

struct CatchSuccessView: View {
    @EnvironmentObject private var session: SessionManager
    @Environment(\.dismiss) private var dismiss

    let capturedImage: UIImage
    let initialLocationName: String
    let initialCoordinate: CLLocationCoordinate2D?
    let caughtAt: Date
    let detectionResult: FishDetectionResult?
    let onFinished: () -> Void

    @State private var step: CatchSuccessStep = .reveal
    @State private var selectedSpeciesID: Int?
    @State private var speciesSearch = ""
    @FocusState private var speciesFieldFocused: Bool
    @State private var showPixelArt = false
    @State private var trophyPulse = false

    @State private var nickname = ""
    @State private var locationName: String
    @State private var catchDate: Date
    @State private var lengthCm = ""
    @State private var weightKg = ""
    @State private var bait = ""
    @State private var notes = ""
    @State private var saveError: String?
    @State private var isSavingCatch = false
    @State private var skipSpeciesSearchValidation = false
    @State private var appliedAiSuggestion = false

    private var isSaving: Bool { isSavingCatch || session.isLoggingCatch }

    init(
        capturedImage: UIImage,
        initialLocationName: String,
        initialCoordinate: CLLocationCoordinate2D?,
        caughtAt: Date,
        detectionResult: FishDetectionResult? = nil,
        onFinished: @escaping () -> Void
    ) {
        self.capturedImage = capturedImage
        self.initialLocationName = initialLocationName
        self.initialCoordinate = initialCoordinate
        self.caughtAt = caughtAt
        self.detectionResult = detectionResult
        self.onFinished = onFinished
        _locationName = State(initialValue: initialLocationName)
        _catchDate = State(initialValue: caughtAt)
    }

    private var sortedSpecies: [Fish] {
        session.fish.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }

    private var selectedFish: Fish? {
        guard let selectedSpeciesID else { return nil }
        return session.fish.first { $0.id == selectedSpeciesID }
    }

    private var filteredSpecies: [Fish] {
        let query = speciesSearch.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return [] }
        return sortedSpecies.filter {
            $0.name.localizedCaseInsensitiveContains(query)
                || $0.scientificName.localizedCaseInsensitiveContains(query)
        }
    }

    private var showSpeciesResults: Bool {
        speciesFieldFocused && !speciesSearch.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        ZStack {
            background

            switch step {
            case .reveal:
                revealScreen
                    .transition(.opacity)
            case .details:
                detailsScreen
                    .transition(.move(edge: .trailing).combined(with: .opacity))
            }
        }
        .animation(.spring(response: 0.45, dampingFraction: 0.86), value: step)
        .onAppear {
            withAnimation(.easeInOut(duration: 0.9).repeatForever(autoreverses: true)) {
                trophyPulse = true
            }
            applyAiSuggestionIfNeeded()
        }
    }

    // MARK: - Reveal (trophy)

    private var revealScreen: some View {
        NavigationStack {
            revealScreenContent
        }
        .toolbar(.hidden, for: .navigationBar)
    }

    private var revealScreenContent: some View {
        VStack(spacing: 0) {
            AppHeaderView(
                onBack: { dismiss() },
                showsProfileButton: false,
                showsProfileAvatar: false
            )

            ScrollViewReader { proxy in
                ScrollView {
                    VStack(spacing: 20) {
                        if !speciesFieldFocused {
                            trophyTitle
                            trophyPhoto
                        } else {
                            Text("FISH CAUGHT!!!")
                                .font(FishedexFont.title2)
                                .foregroundStyle(FishedexTheme.headerRed)
                                .kerning(1)
                                .frame(maxWidth: .infinity)
                                .padding(.top, 8)
                        }

                        speciesPicker
                            .id("speciesPicker")
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, speciesFieldFocused ? 4 : 20)
                    .padding(.bottom, 24)
                }
                .scrollDismissesKeyboard(.interactively)
                .onChange(of: speciesFieldFocused) { _, focused in
                    guard focused else { return }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                        withAnimation(.easeOut(duration: 0.2)) {
                            proxy.scrollTo("speciesPicker", anchor: .bottom)
                        }
                    }
                }
                .onChange(of: speciesSearch) { _, _ in
                    guard speciesFieldFocused else { return }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                        withAnimation(.easeOut(duration: 0.2)) {
                            proxy.scrollTo("speciesPicker", anchor: .bottom)
                        }
                    }
                }
            }

            if !speciesFieldFocused {
                continueButton
                    .padding(.horizontal, 24)
                    .padding(.bottom, 36)
            }
        }
        .background(FishedexTheme.background)
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("DONE") {
                    speciesFieldFocused = false
                }
                .font(FishedexFont.headline)
            }
        }
    }

    private var trophyPhoto: some View {
        ZStack {
            TrophyFrame(accent: selectedFish.map { FishedexTheme.accent(for: $0) } ?? FishedexTheme.tabBlue)
                .scaleEffect(trophyPulse ? 1.01 : 1.0)

            Image(uiImage: capturedImage)
                .resizable()
                .scaledToFill()
                .frame(width: 252, height: 252)
                .clipped()
                .fishedexSquare()
                .fishedexBorder(lineWidth: 2)
        }
        .shadow(color: .black.opacity(0.12), radius: 0, x: 3, y: 3)
    }

    private var trophyTitle: some View {
        Text("FISH CAUGHT!!!")
            .font(FishedexFont.pokemon(26))
            .foregroundStyle(FishedexTheme.headerRed)
            .kerning(1)
            .multilineTextAlignment(.center)
    }

    private var speciesPicker: some View {
        VStack(spacing: 8) {
            Text("WHAT DID YOU CATCH?")
                .font(FishedexFont.caption)
                .foregroundStyle(FishedexTheme.muted)

            if appliedAiSuggestion, let detectionResult {
                aiSuggestionBanner(for: detectionResult)
            }

            if showSpeciesResults {
                speciesResultsList
            }

            HStack(spacing: 10) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(FishedexTheme.muted)

                TextField("Search fish type...", text: $speciesSearch)
                    .font(FishedexFont.headline)
                    .textInputAutocapitalization(.words)
                    .disableAutocorrection(true)
                    .focused($speciesFieldFocused)
                    .submitLabel(.done)
                    .onSubmit { speciesFieldFocused = false }
                    .onChange(of: speciesSearch) { _, newValue in
                        if skipSpeciesSearchValidation {
                            skipSpeciesSearchValidation = false
                            return
                        }
                        if let fish = selectedFish,
                           newValue.compare(fish.name, options: .caseInsensitive) != .orderedSame {
                            selectedSpeciesID = nil
                        }
                    }

                if !speciesSearch.isEmpty {
                    Button {
                        speciesSearch = ""
                        selectedSpeciesID = nil
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(FishedexTheme.muted)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(FishedexTheme.card)
            .fishedexSquare()
            .fishedexBorder(lineWidth: 2)

            if let fish = selectedFish, !showSpeciesResults {
                Text(fish.number)
                    .font(FishedexFont.subheadline)
                    .foregroundStyle(FishedexTheme.tabBlue)
            }
        }
        .padding(.horizontal, 8)
    }

    private var speciesResultsList: some View {
        Group {
            if filteredSpecies.isEmpty {
                Text("NO MATCHES")
                    .font(FishedexFont.caption)
                    .foregroundStyle(FishedexTheme.muted)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(FishedexTheme.card)
                    .fishedexSquare()
                    .fishedexBorder(lineWidth: 1)
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(filteredSpecies.prefix(8).enumerated()), id: \.element.id) { index, fish in
                        Button {
                            selectSpecies(fish)
                        } label: {
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(fish.name.uppercased())
                                        .font(FishedexFont.headline)
                                        .foregroundStyle(FishedexTheme.ink)
                                    Text(fish.scientificName)
                                        .font(FishedexFont.caption)
                                        .foregroundStyle(FishedexTheme.muted)
                                }
                                Spacer()
                                Text(fish.number)
                                    .font(FishedexFont.caption)
                                    .foregroundStyle(FishedexTheme.tabBlue)
                            }
                            .padding(.horizontal, 14)
                            .padding(.vertical, 10)
                            .background(
                                selectedSpeciesID == fish.id
                                    ? FishedexTheme.tabBlue.opacity(0.08)
                                    : Color.clear
                            )
                        }
                        .buttonStyle(.plain)

                        if index < min(8, filteredSpecies.count) - 1 {
                            Rectangle()
                                .fill(FishedexTheme.softLine)
                                .frame(height: 1)
                        }
                    }
                }
                .background(FishedexTheme.card)
                .fishedexSquare()
                .fishedexBorder(lineWidth: 1)
            }
        }
    }

    private var continueButton: some View {
        Button(action: advanceToDetails) {
            HStack(spacing: 8) {
                Text("GIVE YOUR FISH A NAME")
                    .font(FishedexFont.headline)
                Image(systemName: "arrow.right")
                    .font(.system(size: 12, weight: .bold))
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(selectedFish == nil ? FishedexTheme.muted : FishedexTheme.headerRed)
            .fishedexSquare()
            .fishedexBorder(lineWidth: 2)
        }
        .buttonStyle(.plain)
        .disabled(selectedFish == nil)
    }

    // MARK: - Details (name + log)

    private var detailsScreen: some View {
        VStack(spacing: 0) {
            AppHeaderView(
                onBack: { step = .reveal; showPixelArt = false },
                showsProfileButton: false,
                showsProfileAvatar: false,
                isBackDisabled: isSaving
            )

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    detailsHeader
                    artworkTransition
                    detailsForm
                    saveButton
                }
                .padding(24)
            }
        }
        .background(FishedexTheme.background)
    }

    private var detailsHeader: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("GIVE YOUR FISH A NAME")
                .font(FishedexFont.title)
                .foregroundStyle(FishedexTheme.headerRed)

            if let fish = selectedFish {
                Text("Your \(fish.name) is ready for the dex. Add a nickname and any details you want to remember.")
                    .font(FishedexFont.body)
                    .foregroundStyle(FishedexTheme.muted)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private var artworkTransition: some View {
        ZStack {
            Color.white
                .frame(height: 200)
                .frame(maxWidth: .infinity)
                .fishedexSquare()
                .fishedexBorder()

            if showPixelArt, let fish = selectedFish {
                FishArtworkView(fish: fish, height: 150, showsShadow: true)
                    .transition(.scale(scale: 0.6).combined(with: .opacity))
            } else {
                Image(uiImage: capturedImage)
                    .resizable()
                    .scaledToFill()
                    .frame(height: 180)
                    .frame(maxWidth: .infinity)
                    .clipped()
                    .transition(.opacity)
            }
        }
        .frame(height: 200)
        .clipped()
        .fishedexSquare()
        .fishedexBorder()
        .onAppear {
            withAnimation(.spring(response: 0.55, dampingFraction: 0.78)) {
                showPixelArt = true
            }
        }
    }

    private var detailsForm: some View {
        VStack(alignment: .leading, spacing: 16) {
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
                    .background(Color.white)
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
                    .background(Color.white)
                    .fishedexSquare()
                    .fishedexBorder(lineWidth: 1)
            }

            if let saveError {
                Text(saveError)
                    .font(FishedexFont.caption)
                    .foregroundStyle(FishedexTheme.headerRed)
            } else if let error = session.errorMessage {
                Text(error)
                    .font(FishedexFont.caption)
                    .foregroundStyle(FishedexTheme.headerRed)
            }
        }
    }

    private var saveButton: some View {
        Button(action: saveCatch) {
            HStack {
                Spacer()
                if isSaving {
                    ProgressView().tint(.white)
                } else {
                    Text("LOG CATCH")
                        .font(FishedexFont.headline)
                }
                Spacer()
            }
            .padding(.vertical, 14)
            .background(FishedexTheme.tabGreen)
            .foregroundStyle(.white)
            .fishedexSquare()
            .fishedexBorder()
        }
        .buttonStyle(.plain)
        .disabled(isSaving)
    }

    private var background: some View {
        FishedexTheme.background
            .ignoresSafeArea()
    }

    // MARK: - Actions

    private func aiSuggestionBanner(for result: FishDetectionResult) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("AI SUGGESTION")
                .font(FishedexFont.micro)
                .foregroundStyle(FishedexTheme.tabBlue)

            Text(result.classification.reasoning)
                .font(FishedexFont.caption)
                .foregroundStyle(FishedexTheme.muted)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(FishedexTheme.tabBlue.opacity(0.08))
        .fishedexSquare()
        .fishedexBorder(lineWidth: 1, color: FishedexTheme.tabBlue.opacity(0.35))
    }

    private func applyAiSuggestionIfNeeded() {
        guard let detectionResult,
              FishIdentificationService.shouldSuggestSpecies(for: detectionResult),
              let species = detectionResult.species,
              let fish = session.fish.first(where: { $0.id == species.id }) else {
            return
        }

        selectSpecies(fish)
        appliedAiSuggestion = true
    }

    private func selectSpecies(_ fish: Fish) {
        skipSpeciesSearchValidation = true
        selectedSpeciesID = fish.id
        speciesSearch = fish.name
        speciesFieldFocused = false
        dismissKeyboard()
    }

    private func advanceToDetails() {
        guard selectedFish != nil else { return }
        speciesFieldFocused = false
        showPixelArt = false
        step = .details
    }

    private func catchField(_ label: String, text: Binding<String>, prompt: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(FishedexFont.caption)
                .foregroundStyle(FishedexTheme.muted)

            TextField(prompt, text: text)
                .font(FishedexFont.body)
                .padding(12)
                .background(Color.white)
                .fishedexSquare()
                .fishedexBorder(lineWidth: 1)
        }
    }

    private func dismissKeyboard() {
        speciesFieldFocused = false
        UIApplication.shared.sendAction(
            #selector(UIResponder.resignFirstResponder),
            to: nil,
            from: nil,
            for: nil
        )
    }

    private func saveCatch() {
        guard !isSaving else { return }
        saveError = nil
        dismissKeyboard()
        isSavingCatch = true

        let image = capturedImage
        let input = LogCatchInput(
            speciesId: selectedSpeciesID,
            fishName: nickname.nilIfEmpty,
            weightKg: Double(weightKg.trimmingCharacters(in: .whitespacesAndNewlines)),
            lengthCm: Double(lengthCm.trimmingCharacters(in: .whitespacesAndNewlines)),
            locationName: locationName.nilIfEmpty,
            latitude: initialCoordinate?.latitude,
            longitude: initialCoordinate?.longitude,
            caughtAt: catchDate,
            bait: bait.nilIfEmpty,
            notes: notes.nilIfEmpty,
            photoData: nil
        )

        Task {
            defer { isSavingCatch = false }

            let photoData = await Task.detached(priority: .userInitiated) {
                ImageCompressor.compressedJPEGData(from: image)
            }.value

            do {
                var catchInput = input
                catchInput.photoData = photoData
                try await session.logCatch(catchInput)
                dismiss()
                onFinished()
            } catch {
                saveError = error.localizedDescription
            }
        }
    }
}

// MARK: - Trophy frame

private struct TrophyFrame: View {
    let accent: Color
    private let size: CGFloat = 276
    private let cornerLength: CGFloat = 18

    var body: some View {
        ZStack {
            Rectangle()
                .fill(FishedexTheme.card)
                .frame(width: size, height: size)
                .fishedexSquare()
                .fishedexBorder(lineWidth: 2)

            Rectangle()
                .fill(accent.opacity(0.12))
                .frame(width: size - 16, height: size - 16)
                .fishedexSquare()

            TrophyCorners(color: accent, length: cornerLength)
                .frame(width: size, height: size)
        }
    }
}

private struct TrophyCorners: View {
    let color: Color
    let length: CGFloat
    private let lineWidth: CGFloat = 3

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height

            Path { path in
                path.move(to: CGPoint(x: 0, y: length))
                path.addLine(to: .init(x: 0, y: 0))
                path.addLine(to: .init(x: length, y: 0))

                path.move(to: CGPoint(x: w - length, y: 0))
                path.addLine(to: .init(x: w, y: 0))
                path.addLine(to: .init(x: w, y: length))

                path.move(to: CGPoint(x: 0, y: h - length))
                path.addLine(to: .init(x: 0, y: h))
                path.addLine(to: .init(x: length, y: h))

                path.move(to: CGPoint(x: w - length, y: h))
                path.addLine(to: .init(x: w, y: h))
                path.addLine(to: .init(x: w, y: h - length))
            }
            .stroke(color, style: StrokeStyle(lineWidth: lineWidth, lineCap: .square))
        }
    }
}

private extension String {
    var nilIfEmpty: String? {
        let trimmed = trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}

#Preview {
    CatchSuccessView(
        capturedImage: UIImage(systemName: "fish.fill")!,
        initialLocationName: "Sydney, NSW",
        initialCoordinate: CLLocationCoordinate2D(latitude: -33.87, longitude: 151.21),
        caughtAt: Date(),
        onFinished: {}
    )
    .environmentObject(SessionManager())
}
