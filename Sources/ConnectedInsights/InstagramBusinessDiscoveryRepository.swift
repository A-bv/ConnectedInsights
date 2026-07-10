import Foundation

final class InstagramBusinessDiscoveryRepository: BusinessDiscoveryProviding, Sendable {
    private let credentialsProvider: any InstagramGraphCredentialsProviding
    private let endpointBuilder: InstagramGraphEndpointBuilder
    private let client: any InstagramGraphClientProtocol

    init(
        credentialsProvider: any InstagramGraphCredentialsProviding,
        endpointBuilder: InstagramGraphEndpointBuilder,
        client: any InstagramGraphClientProtocol
    ) {
        self.credentialsProvider = credentialsProvider
        self.endpointBuilder = endpointBuilder
        self.client = client
    }

    func businessDiscovery(account: String) async throws -> Profile {
        // Validate the handle before it is interpolated into the field expression — this both
        // rejects bad input early (no wasted request) and guarantees the value cannot break out
        // of `business_discovery.username(...)`.
        let username = try InstagramAccountUsername.validated(account)
        let credentials = try credentialsProvider.validCredentials().get()

        guard let url = endpointBuilder.businessDiscoveryURL(
            account: username,
            credentials: credentials
        ) else {
            throw InstagramGraphServiceError.invalidURL("business discovery")
        }

        let data = try await client.fetchGraphData(from: url)

        do {
            let discovery = try JSONDecoder.instagram().decode(Discovery.self, from: data)
            guard let profile = discovery.businessDiscovery else {
                // A 2xx response without a `business_discovery` object means the handle is not a
                // reachable Business/Creator account (private, personal, or nonexistent).
                throw InstagramGraphServiceError.instagramAccountNotFound
            }
            return profile
        } catch let error as InstagramGraphServiceError {
            throw error
        } catch {
            let serviceError = instagramDecodingFailed(type: Discovery.self, data: data, underlying: error)
            InstagramGraphLogger.logFailure(serviceError, url: url)
            throw serviceError
        }
    }
}
