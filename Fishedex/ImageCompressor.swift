import UIKit

enum ImageCompressor {
    static let maxUploadBytes = 1_048_576

    static func compressedJPEGData(from image: UIImage, maxBytes: Int = maxUploadBytes) -> Data? {
        compress(image: image, maxBytes: maxBytes)
    }

    static func compressedJPEGData(from data: Data, maxBytes: Int = maxUploadBytes) -> Data? {
        guard let image = UIImage(data: data) else { return nil }
        return compress(image: image, maxBytes: maxBytes)
    }

    private static func compress(image: UIImage, maxBytes: Int) -> Data? {
        var current = normalized(image)
        var quality: CGFloat = 0.85

        let maxDimension: CGFloat = 2048
        if max(current.size.width, current.size.height) > maxDimension {
            current = resized(image: current, maxDimension: maxDimension)
        }

        while quality >= 0.2 {
            if let data = current.jpegData(compressionQuality: quality), data.count <= maxBytes {
                return data
            }
            quality -= 0.1
        }

        var scale: CGFloat = 0.85
        while scale >= 0.35 {
            let dimension = max(current.size.width, current.size.height) * scale
            let smaller = resized(image: current, maxDimension: dimension)
            quality = 0.75
            while quality >= 0.2 {
                if let data = smaller.jpegData(compressionQuality: quality), data.count <= maxBytes {
                    return data
                }
                quality -= 0.1
            }
            scale -= 0.15
        }

        return current.jpegData(compressionQuality: 0.2)
    }

    private static func normalized(_ image: UIImage) -> UIImage {
        guard image.imageOrientation != .up else { return image }
        let renderer = UIGraphicsImageRenderer(size: image.size)
        return renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: image.size))
        }
    }

    private static func resized(image: UIImage, maxDimension: CGFloat) -> UIImage {
        let size = image.size
        guard max(size.width, size.height) > maxDimension else { return image }
        let ratio = maxDimension / max(size.width, size.height)
        let newSize = CGSize(width: size.width * ratio, height: size.height * ratio)
        let renderer = UIGraphicsImageRenderer(size: newSize)
        return renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: newSize))
        }
    }
}
