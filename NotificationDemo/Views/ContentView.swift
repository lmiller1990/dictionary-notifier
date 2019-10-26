import SwiftUI
import Foundation
import CoreData


struct ContentView: View {
    @State var word: String = ""
    @State var definition: String = ""
    @State var dictEntries: [Entry] = []
    @State var dbWords: [String] = []
    
    var endpoint: String = "https://jisho.org/api/v1/search/words"
    let manager = LocalNotificationManager()
    
    func getAllDbWords() -> [String] {
        self.deleteAll()
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
            return [""]
        }
        let managedContext = appDelegate.persistentContainer.viewContext
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "QueuedNotifications")

        var words: [String] = []
        do {
            let result = try managedContext.fetch(fetchRequest)
            print("Words: \(result.count)")
            for data in result as! [NSManagedObject] {
                let created = data.value(forKey: "created") as! Date
                // 432000 is 5 days in seconds
                if created.addingTimeInterval(432000) < Date() {
                    // delete - it is too old!
                    managedContext.delete(data)
                } else {
                    words.append(data.value(forKey: "word") as! String)
                }
            }
        } catch {
            print("Failed")
        }
        
        return words
    }
    
    func loadCurrentDbWords() {
        self.dbWords = self.getAllDbWords()
    }
    
    func parseRawJishoResponse(response: RawJishoResponse) -> [Entry] {
        
        return response.data.reduce([]) {(acc: [Entry], curr: RawJishoResponse.Entry) -> [Entry] in
            if curr.japanese.count > 0 && curr.japanese[0].reading != nil && curr.senses.count > 0 {
                return acc + [
                    Entry(
                        kana: curr.japanese[0].reading!,
                        kanji: curr.japanese[0].word != nil ? curr.japanese[0].word : nil,
                        meaning: Entry.Meaning(
                            definitions: curr.senses[0].english_definitions,
                            partsOfSpeech: curr.senses[0].parts_of_speech)
                    )
                ]
            }
            
            return acc
        }
    }
    
    func constructNotificationText(_ entry: Entry) -> String {
        var text = getWord(entry)
        if (entry.meaning.definitions.count > 0) {
            text += " - " + entry.meaning.definitions[0]
        }
        return text
    }
    
    func getWord(_ entry:  Entry) -> String {
        if (entry.kanji != nil) {
            return entry.kanji!
        }
        
        return entry.kana
    }
    
    func checkDb(_ entry: Entry) -> Bool {
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
            print("Something bad happened")
            return false
        }
        
        let managedContext = appDelegate.persistentContainer.viewContext
        
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "QueuedNotifications")
        fetchRequest.predicate = NSPredicate(format: "word == %@", entry.kana)
        
        do {
            let result = try managedContext.fetch(fetchRequest)
            return result.count > 0
        } catch {
            print("Failed")
            return false
        }
    }
    
    func addWordToDb(_ entry: Entry) {
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
            return
        }
        
        let managedContext = appDelegate.persistentContainer.viewContext
        
        let wordEntity = NSEntityDescription.entity(forEntityName: "QueuedNotifications", in: managedContext)!
        
        let word = NSManagedObject(entity: wordEntity, insertInto: managedContext)
        word.setValue(entry.kana, forKey: "word")
        word.setValue(UUID().uuidString, forKey: "uuid")
        word.setValue(Date(), forKey: "created")
       
        self.loadCurrentDbWords()
    }
    
    func handleNotification(entry: Entry) {
        if checkDb(entry) {
            print("Word in DB. Do nothing.")
            return
        }
        print("Adding word to DB.")
        
        let text = constructNotificationText(entry)
        addWordToDb(entry)
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
                    self.dictEntries = self.parseRawJishoResponse(response: response)
                } catch {
                    print("error", error, data)
                }
            }
        }
        task.resume()
    }
    
    func handleAppear() {
        loadCurrentDbWords()
    }
    
    func deleteAll() {
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else { return }
        
        let fetchRequest: NSFetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "QueuedNotifications")
        let batchDeleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
        let managedContext = appDelegate.persistentContainer.viewContext
        
        do {
            try managedContext.executeAndMergeChanges(using: batchDeleteRequest)
        } catch {
            // Dunno what to do or how to handle this
        }
    }
    
    func navigateToOptions() {
    }
    
    @State var shown = false

    
    var body: some View {
        VStack {
            HStack {
                Image(systemName: "gear")
                    .onTapGesture { self.shown.toggle() }
                    .sheet(isPresented: $shown) { () -> OptionsScreen in

                        return OptionsScreen(dismissFlag: self.$shown)
                    }
            
                                   
                SearchBarCancel(text: $word, onSearch: handleSearch)
            }.padding(.leading)
            
            // Button(action: self.deleteAll) {
            //    Text("Delete all")
            // }
            
            HStack {
                Text(definition)
            }
            
            DefinitionList(
                dictEntries: dictEntries,
                onRequestNotification: handleNotification,
                dbWords: dbWords
            )
            
            // Spacer()
        }.onAppear {
            self.handleAppear()
        }
    }
}

let dictEntries: [Entry] = [
    Entry(kana: "じしょ", kanji: "辞書", meaning: Entry.Meaning(definitions: ["Dictionary"], partsOfSpeech: ["Noun"]))
]

struct OptionsScreen: View {
    
    @Binding var dismissFlag: Bool
    
    var body : some View {
        Button(action: { self.dismissFlag = false }) {
            Text("dimiss")
        }
    }
}

struct ContentView_Previews: PreviewProvider  {
    static var previews: some View {
        ContentView(dictEntries: dictEntries)
    }
}
