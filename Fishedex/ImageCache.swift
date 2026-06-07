import CryptoKit
import SwiftUI
import UIKit

actor ImageCache {
    static let shared = ImageCache()

    private let memoryCache = NSCache<NSString, UIImage>()
    private let fileManager = FileManager.default
    private var inFlightTasks: [String: Task<UIImage?, Never>] = [:]

    private init() {
        memoryCache.countLimit = 150
        memoryCache.totalCostLimit = 64 * 1024 * 1024
    }

    func image(for url: URL) async -> UIImage? {
        let key = cacheKey(for: url)

        if let cached = memoryCache.object(forKey: key as NSString) {
            return cached
        }

        let fileURL = diskFileURL(forKey: key)
        if let data = try? Data(contentsOf: fileURL),
           let image = UIImage(data: data) {
            storeInMemory(image, key: key)
            return image
        }

        if let existing = inFlightTasks[key] {
            return await existing.value
        }

        let task = Task<UIImage?, Never> {
            await fetchAndStore(url: url, key: key)
        }
        inFlightTasks[key] = task
        let result = await task.value
        inFlightTasks.removeValue(forKey: key)
        return result
    }

    func store(data: Data, for url: URL) {
        guard let image = UIImage(data: data) else { return }
        let key = cacheKey(for: url)
        storeInMemory(image, key: key)
        let fileURL = diskFileURL(forKey: key)
        try? data.write(to: fileURL, options: .atomic)
    }

    func remove(for url: URL) {
        let key = cacheKey(for: url)
        memoryCache.removeObject(forKey: key as NSString)
        try? fileManager.removeItem(at: diskFileURL(forKey: key))
    }

    private func fetchAndStore(url: URL, key: String) async -> UIImage? {
        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            guard let http = response as? HTTPURLResponse,
                  (200 ... 299).contains(http.statusCode),
                  let image = UIImage(data: data) else {
                return nil
            }
            storeInMemory(image, key: key)
            try? data.write(to: diskFileURL(forKey: key), options: .atomic)
            return image
        } catch {
            return nil
        }
    }

    private func storeInMemory(_ image: UIImage, key: String) {
        let cost = image.jpegData(compressionQuality: 1)?.count ?? 0
        memoryCache.setObject(image, forKey: key as NSString, cost: cost)
    }

    private func diskFileURL(forKey key: String) -> URL {
        let directory = fileManager.urls(for: .cachesDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("RemoteImages", isDirectory: true)
        try? fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
        return directory.appendingPathComponent(key)
    }

    private func cacheKey(for url: URL) -> String {
        let digest = SHA256.hash(data: Data(url.absoluteString.utf8))
        return digest.map { String(format: "%02x", $0) }.joined()
    }
}

struct CachedRemoteImage<Content: View, Placeholder: View, Failure: View>: View {
    let urlString: String?
    @ViewBuilder let content: (Image) -> Content
    @ViewBuilder let placeholder: () -> Placeholder
    @ViewBuilder let failure: () -> Failure

    @State private var image: UIImage?
    @State private var didFail = false

    var body: some View {
        Group {
            if let image {
                content(Image(uiImage: image))
            } else if didFail {
                failure()
            } else {
                placeholder()
            }
        }
        .task(id: urlString) {
            image = nil
            didFail = false

            guard let urlString, let url = URL(string: urlString) else {
                didFail = true
                return
            }

            if let loaded = await ImageCache.shared.image(for: url) {
                image = loaded
            } else {
                didFail = true
            }
        }
    }
}
