struct Entry {
    struct Meaning {
        var definitions: [String]
        var partsOfSpeech: [String]
    }
    
    var kana: String
    var kanji: String?
    var meaning: Meaning
}
