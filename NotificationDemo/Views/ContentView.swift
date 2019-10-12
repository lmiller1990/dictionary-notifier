import SwiftUI
import Foundation


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
    
    func constructNotificationText(_ entry: Entry) -> String {
        var text = ""
        if (entry.kanji != nil) {
            text = entry.kanji!
        } else {
            text = entry.kana
        }
        
        if (entry.meaning.definitions.count > 0) {
            text += " - " + entry.meaning.definitions[0]
        }
        
        print("Notification text is \(text)")
        
        return text
    }
    
    func handleNotification(entry: Entry) {
        let text = constructNotificationText(entry)
        self.manager.addNotification(title: text)
        self.manager.schedule()
    }
    
    func handleSearch() {
        print("Searching for \(self.word.lowercased())")
        
        var components = URLComponents(string: endpoint)!
        components.queryItems = [
            URLQueryItem(name: "keyword", value: self.word.lowercased())
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
            
            DefinitionList(
                dictEntries: dictEntries,
                onRequestNotification: handleNotification
            )
            
            Spacer()
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
