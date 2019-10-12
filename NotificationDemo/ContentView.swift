import SwiftUI
import Foundation

struct Entry {
    struct Meaning {
        var definitions: [String]
        var partsOfSpeech: [String]
    }
    
    var kana: String
    var kanji: String?
    var meaning: Meaning
}

struct ContentView: View {
    @State var word: String = ""
    @State var definition: String = ""
    @State var dictEntries: [Entry] = []
    
    var endpoint: String = "https://jisho.org/api/v1/search/words"
    let manager = LocalNotificationManager()
    
    func parseRawJishoResponse(response: RawJishoResponse) -> [Entry] {
        
        return response.data.reduce([]) {(acc: [Entry], curr: RawJishoResponse.Entry) -> [Entry] in
            if curr.japanese.count > 0 && curr.japanese[0].reading != nil && curr.senses.count > 0 {
                return acc + [Entry(
                    kana: curr.japanese[0].reading!,
                    kanji: curr.japanese[0].word != nil ? curr.japanese[0].word : nil,
                    meaning: Entry.Meaning(
                        definitions: curr.senses[0].english_definitions,
                        partsOfSpeech: curr.senses[0].parts_of_speech
                    )
                )]
            }
            
            return acc
        }
    }
    
    func handleSearch() {
        print("Searching for \(word)")
        
        var components = URLComponents(string: endpoint)!
        components.queryItems = [
            URLQueryItem(name: "keyword", value: self.word)
        ]
        let task = URLSession.shared.dataTask(with: components.url!) { (data, response, error) in
            if let data = data {
                do {
                    let response = try JSONDecoder().decode(RawJishoResponse.self, from: data)
                    print(response)
                    self.dictEntries = self.parseRawJishoResponse(response: response)
                } catch {
                    print("error", error, data)
                }
                // self.manager.addNotification(title: "\(self.word): \(self.definition)")
                // self.manager.schedule()
            }
        }
        task.resume()
    }
    
    var body: some View {
        VStack {
            SearchBarCancel(text: $word, onSearch: handleSearch)
            
            
            HStack {
                Text(definition)
            }
            
            DefinitionList(dictEntries: dictEntries)
            
            Spacer()
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
