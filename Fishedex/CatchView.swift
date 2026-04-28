import SwiftUI

struct CatchView: View {
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 24) {
                header
                cameraCard
                manualAddCard
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
            .padding(.bottom, 28)
        }
        .background(FishedexTheme.background.ignoresSafeArea())
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .navigationBar)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Catch")
                .font(.title.bold())
                .foregroundStyle(FishedexTheme.ink)

            Text("Snap a fish photo to identify it and add it to your Fishédex.")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(FishedexTheme.muted)
        }
    }

    private var cameraCard: some View {
        VStack(spacing: 22) {
            ZStack {
                RoundedRectangle(cornerRadius: 34, style: .continuous)
                    .fill(Color.black)
                    .frame(height: 390)

                VStack(spacing: 18) {
                    Image(systemName: "camera.viewfinder")
                        .font(.system(size: 54, weight: .semibold))
                        .foregroundStyle(.white)

                    Text("Camera preview")
                        .font(.headline.weight(.bold))
                        .foregroundStyle(.white)

                    Text("Point your camera at a fish to start a catch scan.")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.64))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                }
            }

            Button {
                // Camera capture will be connected once capture permissions and identification are added.
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: "camera.fill")
                    Text("Catch with camera")
                }
                .font(.headline.weight(.bold))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 58)
                .background(FishedexTheme.ink)
                .clipShape(Capsule())
            }
            .buttonStyle(.plain)
        }
    }

    private var manualAddCard: some View {
        Button {
            // Manual entry will become the fallback path for catches without a clear photo.
        } label: {
            HStack(spacing: 16) {
                Image(systemName: "square.and.pencil")
                    .font(.title3.weight(.bold))
                    .foregroundStyle(FishedexTheme.ink)
                    .frame(width: 46, height: 46)
                    .background(Color.white)
                    .clipShape(Circle())

                VStack(alignment: .leading, spacing: 4) {
                    Text("Add manually")
                        .font(.headline.weight(.bold))
                        .foregroundStyle(FishedexTheme.ink)

                    Text("Use this if camera identification misses the catch.")
                        .font(.caption)
                        .foregroundStyle(FishedexTheme.muted)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(FishedexTheme.muted)
            }
            .padding(16)
            .fishedexCard(cornerRadius: 26)
        }
        .buttonStyle(.plain)
    }
}

struct CatchView_Previews: PreviewProvider {
    static var previews: some View {
        CatchView()
    }
}
