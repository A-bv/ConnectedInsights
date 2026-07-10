import Foundation

/// Validates an Instagram account handle before it is interpolated into a Graph API
/// `business_discovery.username(...)` field expression.
///
/// Instagram handles are 1–30 characters of ASCII letters, digits, periods and underscores.
/// Restricting to exactly that set is also what keeps a handle from breaking out of the field
/// expression: none of those characters are structurally significant in the Graph query, so a
/// validated handle cannot inject extra fields or parameters.
enum InstagramAccountUsername {
    private static let allowed: Set<Character> = Set(
        "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789._"
    )

    /// Returns the normalized handle (a leading `@` is stripped), or throws
    /// ``InstagramGraphServiceError/invalidAccountUsername(_:)`` if it is empty, too long, or
    /// contains characters outside the permitted set.
    static func validated(_ raw: String) throws -> String {
        var handle = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        if handle.hasPrefix("@") {
            handle.removeFirst()
        }
        guard (1...30).contains(handle.count), handle.allSatisfy(allowed.contains) else {
            throw InstagramGraphServiceError.invalidAccountUsername(raw)
        }
        return handle
    }
}
