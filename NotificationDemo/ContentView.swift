import SwiftUI
import Foundation

struct Senses: Codable {
    let english_definitions: [String]
}

struct Definition: Codable {
    let senses: [Senses]
}

struct Response: Codable {
    let data: [Definition]
}

struct ContentView: View {
    @State var word: String = ""
    @State var definition: String = ""
    var endpoint: String = "https://jisho.org/api/v1/search/words"
    let manager = LocalNotificationManager()
  
    func handleSearch() {
        print("Searching for \(word)")
    }
    
    func lookupWord() -> Void {
        var components = URLComponents(string: endpoint)!
        components.queryItems = [
            URLQueryItem(name: "keyword", value: self.word)
        ]
        let task = URLSession.shared.dataTask(with: components.url!) { (data, response, error) in
            if let data = data {
                do {
                    let res = try JSONDecoder().decode(Response.self, from: data)
                    self.definition = res.data[0].senses[0].english_definitions[0]
                    self.manager.addNotification(title: "\(self.word): \(self.definition)")
                    self.manager.schedule()
                } catch {
                    self.definition = "Could not find definition."
                    // Dunno
                }
            }
        }
        task.resume()
    }
    
    var body: some View {
        VStack {
            SearchBarCancel(text: $word, onSearch: handleSearch)
            
            HStack {
                Button(action: { self.lookupWord() }) {
                    Text("Lookup")
                }
            }
            
            HStack {
                Text(definition)
            }
            
            Spacer()
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
