struct RawJishoResponse: Codable {
    struct Meta: Codable {
        var status: Int
    }

    struct JapaneseWord: Codable {
        var word: String?
        var reading: String?
    }
    
    struct Sense: Codable {
        var english_definitions: [String]
        var parts_of_speech: [String]
        
    }
    
    struct Entry: Codable {
        var slug: String
        var japanese: [JapaneseWord]
        var senses: [Sense]
    }
    
    var meta: Meta
    var data: [Entry]
}
