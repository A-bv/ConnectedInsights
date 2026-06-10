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
            InstagramGraphLogger.logFailure(error, url: "credentials check")
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
                InstagramGraphLogger.logFailure(error, url: url)
                completion(.failure(error))
            case .success(let data):
                guard let profile = try? JSONDecoder().decode(Profile.self, from: data) else {
                    let error = InstagramGraphServiceError.decodingFailed(
                        type: String(describing: Profile.self),
                        body: InstagramGraphLogger.responsePreview(data)
                    )
                    InstagramGraphLogger.logFailure(error, url: url)
                    completion(.failure(error))
                    return
                }
                self.onDataFetched?(data)
                completion(.success(profile))
            }
        }
    }
}
