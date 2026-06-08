import Foundation

public protocol InstagramProfileRepositoryProtocol: ProfileDataProviding {
    func loadProfileForAnalytics(
        mediaLimit: Int?,
        completion: @escaping (Result<Profile, Error>) -> Void
    )
}

public final class InstagramProfileRepository: InstagramProfileRepositoryProtocol {
    private let credentialsProvider: any InstagramGraphCredentialsProviding
    private let endpointBuilder: InstagramGraphEndpointBuilder
    private let client: any InstagramGraphClientProtocol
    private let onDataFetched: ((Data) -> Void)?

    public init(
        credentialsProvider: any InstagramGraphCredentialsProviding,
        endpointBuilder: InstagramGraphEndpointBuilder,
        client: any InstagramGraphClientProtocol,
        onDataFetched: ((Data) -> Void)? = nil
    ) {
        self.credentialsProvider = credentialsProvider
        self.endpointBuilder = endpointBuilder
        self.client = client
        self.onDataFetched = onDataFetched
    }

    public func loadProfileForAnalytics(
        mediaLimit: Int? = nil,
        completion: @escaping (Result<Profile, Error>) -> Void
    ) {
        switch credentialsProvider.validCredentials() {
        case .failure(let error):
            print("[ConnectedInsights][Graph] Failure: \(error.localizedDescription)")
            completion(.failure(error))
        case .success(let credentials):
            guard let encodedUrl = endpointBuilder.analyticsProfileURL(
                mediaLimit: mediaLimit,
                credentials: credentials
            ) else {
                completion(.failure(InstagramGraphServiceError.invalidURL("analytics profile")))
                return
            }
            fetchProfile(from: encodedUrl) { result in
                completion(result)
            }
        }
    }

    private func fetchProfile(
        from url: String,
        completion: @escaping (Result<Profile, Error>) -> Void
    ) {
        client.fetchGraphData(from: url) { result in
            switch result {
            case .failure(let error):
                self.logGraphFailure(error, url: url)
                completion(.failure(error))
            case .success(let data):
                guard let profile = try? JSONDecoder().decode(Profile.self, from: data) else {
                    completion(.failure(self.decodingError(data: data, sourceURL: url)))
                    return
                }
                self.onDataFetched?(data)
                completion(.success(profile))
            }
        }
    }

    private func decodingError(
        data: Data,
        sourceURL: String
    ) -> Error {
        let error = InstagramGraphServiceError.decodingFailed(
            type: String(describing: Profile.self),
            body: responsePreview(data)
        )
        logGraphFailure(error, url: sourceURL)
        return error
    }

    private func logGraphFailure(_ error: Error, url: String) {
        print("[ConnectedInsights][Graph] Failure: \(error.localizedDescription)")
        print("[ConnectedInsights][Graph] URL: \(InstagramGraphLogRedactor.redacted(url))")
    }

    private func responsePreview(_ data: Data) -> String {
        let body = String(data: data, encoding: .utf8) ?? "<non-utf8 response>"
        return InstagramGraphLogRedactor.redacted(String(body.prefix(1_500)))
    }
}
