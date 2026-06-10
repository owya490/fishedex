import Foundation
import Supabase
import UIKit

enum FishIdentificationError: LocalizedError {
    case notEnabled
    case notAuthenticated
    case imageProcessingFailed
    case serverError(String)

    var errorDescription: String? {
        switch self {
        case .notEnabled:
            "AI fish detection is not available for this account."
        case .notAuthenticated:
            "Sign in to use AI fish detection."
        case .imageProcessingFailed:
            "Could not prepare the photo for analysis."
        case .serverError(let message):
            message
        }
    }
}

enum FishIdentificationService {
    private static let minimumConfidence = 0.55

    static func shouldSuggestSpecies(for result: FishDetectionResult) -> Bool {
        guard let species = result.species else { return false }
        return result.classification.confidence >= minimumConfidence && species.id > 0
    }

    static func classify(image: UIImage) async throws -> FishDetectionResult {
        guard let photoData = ImageCompressor.compressedJPEGData(from: image) else {
            throw FishIdentificationError.imageProcessingFailed
        }

        struct ClassifyFishRequest: Encodable {
            let imageBase64: String
            let mimeType: String
        }

        struct ErrorResponse: Decodable {
            let error: String
        }

        let request = ClassifyFishRequest(
            imageBase64: photoData.base64EncodedString(),
            mimeType: "image/jpeg"
        )

        do {
            return try await supabase.functions.invoke(
                "classify-fish",
                options: FunctionInvokeOptions(body: request)
            )
        } catch let error as FunctionsError {
            if case .httpError(_, let data) = error,
               let serverError = try? JSONDecoder().decode(ErrorResponse.self, from: data) {
                throw FishIdentificationError.serverError(serverError.error)
            }
            throw FishIdentificationError.serverError(error.localizedDescription)
        }
    }
}
