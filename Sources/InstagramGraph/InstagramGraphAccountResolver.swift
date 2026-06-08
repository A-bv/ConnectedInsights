import Foundation

public struct InstagramGraphResolvedAccount {
    public let facebookPageId: String
    public let facebookPageName: String?
    public let instagramBusinessAccountId: String
    public let instagramUsername: String?

    public init(
        facebookPageId: String,
        facebookPageName: String?,
        instagramBusinessAccountId: String,
        instagramUsername: String?
    ) {
        self.facebookPageId = facebookPageId
        self.facebookPageName = facebookPageName
        self.instagramBusinessAccountId = instagramBusinessAccountId
        self.instagramUsername = instagramUsername
    }
}

public final class InstagramGraphAccountResolver {
    private let apiGraphVersion: String
    private let client: any InstagramGraphClientProtocol

    public init(
        apiGraphVersion: String = ConnectedInsightsConfiguration.production.graphAPIVersion
    ) {
        self.apiGraphVersion = apiGraphVersion
        self.client = InstagramGraphClient(apiGraphVersion: apiGraphVersion)
    }

    public init(
        apiGraphVersion: String = ConnectedInsightsConfiguration.production.graphAPIVersion,
        client: any InstagramGraphClientProtocol
    ) {
        self.apiGraphVersion = apiGraphVersion
        self.client = client
    }

    public func resolveAccount(
        facebookToken: String,
        completion: @escaping (Result<InstagramGraphResolvedAccount, Error>) -> Void
    ) {
        guard let url = meAccountsURL(facebookToken: facebookToken) else {
            completion(.failure(InstagramGraphServiceError.invalidURL("/me/accounts")))
            return
        }

        client.fetchGraphData(from: url) { result in
            switch result {
            case .success(let data):
                do {
                    let response = try JSONDecoder().decode(InstagramGraphMeAccountsResponse.self, from: data)
                    guard let page = response.data.first(where: { $0.instagramBusinessAccount != nil }),
                          let instagramAccount = page.instagramBusinessAccount
                    else {
                        completion(.failure(InstagramGraphServiceError.instagramAccountNotFound))
                        return
                    }

                    completion(.success(InstagramGraphResolvedAccount(
                        facebookPageId: page.id,
                        facebookPageName: page.name,
                        instagramBusinessAccountId: instagramAccount.id,
                        instagramUsername: instagramAccount.username
                    )))
                } catch {
                    let body = String(data: data, encoding: .utf8) ?? "<non-utf8 response>"
                    completion(.failure(InstagramGraphServiceError.decodingFailed(
                        type: "InstagramGraphMeAccountsResponse",
                        body: InstagramGraphLogRedactor.redacted(String(body.prefix(1_500)))
                    )))
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    public func resolveCredentials(
        facebookToken: String,
        completion: @escaping (Result<InstagramGraphCredentials, Error>) -> Void
    ) {
        resolveAccount(facebookToken: facebookToken) { result in
            completion(result.map { account in
                InstagramGraphCredentials(
                    facebookToken: facebookToken,
                    instagramBusinessAccountId: account.instagramBusinessAccountId
                )
            })
        }
    }

    private func meAccountsURL(facebookToken: String) -> String? {
        var components = URLComponents()
        components.scheme = "https"
        components.host = "graph.facebook.com"
        components.path = "/\(apiGraphVersion)/me/accounts"
        components.queryItems = [
            URLQueryItem(name: "fields", value: "id,name,instagram_business_account{id,username}"),
            URLQueryItem(name: "access_token", value: facebookToken),
        ]
        return components.url?.absoluteString
    }
}

private struct InstagramGraphMeAccountsResponse: Decodable {
    let data: [InstagramGraphPageAccount]
}

private struct InstagramGraphPageAccount: Decodable {
    let id: String
    let name: String?
    let instagramBusinessAccount: InstagramGraphInstagramAccount?

    private enum CodingKeys: String, CodingKey {
        case id
        case name
        case instagramBusinessAccount = "instagram_business_account"
    }
}

private struct InstagramGraphInstagramAccount: Decodable {
    let id: String
    let username: String?
}
