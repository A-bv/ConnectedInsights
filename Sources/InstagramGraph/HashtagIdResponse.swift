struct HashtagIdResponse: Decodable {
    let data: [DataItem]
}

struct DataItem: Decodable {
    let id: String
}
