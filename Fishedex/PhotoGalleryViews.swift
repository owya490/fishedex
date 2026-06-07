import SwiftUI
import PhotosUI

// MARK: - Gallery grid

struct CatchPhotoGalleryGrid: View {
    let photos: [CatchPhotoRow]
    var fish: Fish?
    var allowsUpload = false
    var isUploading = false
    var onPhotoTap: (Int) -> Void = { _ in }
    var onUpload: (Data) -> Void = { _ in }

    @State private var selectedPhotoItem: PhotosPickerItem?

    private let columns = [
        GridItem(.flexible(), spacing: 8),
        GridItem(.flexible(), spacing: 8),
        GridItem(.flexible(), spacing: 8),
    ]

    var body: some View {
        LazyVGrid(columns: columns, spacing: 8) {
            ForEach(Array(photos.enumerated()), id: \.element.id) { index, photo in
                Button {
                    onPhotoTap(index)
                } label: {
                    CatchPhotoView(
                        urlString: photo.photoUrl,
                        fish: fish,
                        height: 96
                    )
                    .fishedexSquare()
                    .fishedexBorder(lineWidth: 1)
                }
                .buttonStyle(.plain)
            }

            if allowsUpload {
                uploadTile
            }
        }
        .onChange(of: selectedPhotoItem) { _, item in
            guard let item else { return }
            Task {
                if let data = try? await item.loadTransferable(type: Data.self),
                   let compressed = ImageCompressor.compressedJPEGData(from: data) {
                    onUpload(compressed)
                }
                selectedPhotoItem = nil
            }
        }
    }

    @ViewBuilder
    private var uploadTile: some View {
        PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
            ZStack {
                Color(red: 0.95, green: 0.95, blue: 0.96)
                if isUploading {
                    ProgressView()
                } else {
                    VStack(spacing: 6) {
                        Image(systemName: "plus")
                            .font(.system(size: 22, weight: .bold))
                        Text("ADD")
                            .font(FishedexFont.micro)
                    }
                    .foregroundStyle(FishedexTheme.tabBlue)
                }
            }
            .frame(height: 96)
            .frame(maxWidth: .infinity)
            .fishedexSquare()
            .fishedexBorder(lineWidth: 1)
        }
        .buttonStyle(.plain)
        .disabled(isUploading)
    }
}

// MARK: - Fullscreen viewer

struct PhotoViewerOverlay: View {
    let photos: [CatchPhotoRow]
    @Binding var selectedIndex: Int?
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        if let selectedIndex {
            ZStack {
                Color.black.ignoresSafeArea()

                TabView(selection: Binding(
                    get: { selectedIndex },
                    set: { self.selectedIndex = $0 }
                )) {
                    ForEach(Array(photos.enumerated()), id: \.element.id) { index, photo in
                        ZoomablePhotoView(urlString: photo.photoUrl)
                            .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: photos.count > 1 ? .automatic : .never))

                VStack {
                    HStack {
                        Spacer()
                        Button {
                            self.selectedIndex = nil
                        } label: {
                            Image(systemName: "xmark")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundStyle(.white)
                                .padding(12)
                                .background(.black.opacity(0.5))
                                .fishedexSquare()
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 8)

                    Spacer()
                }
            }
        }
    }
}

private struct ZoomablePhotoView: View {
    let urlString: String

    var body: some View {
        Group {
            if let url = URL(string: urlString) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFit()
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    case .failure:
                        placeholder
                    default:
                        ProgressView().tint(.white)
                    }
                }
            } else {
                placeholder
            }
        }
        .padding(24)
    }

    private var placeholder: some View {
        Image(systemName: "photo")
            .font(.system(size: 48))
            .foregroundStyle(.white.opacity(0.5))
    }
}
