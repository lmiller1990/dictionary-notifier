import SwiftUI
import Foundation
import CoreData


struct ContentView: View {
    @EnvironmentObject var settings: NotificationSettings
    @State var word: String = ""
    @State var definition: String = ""
    @State var dictEntries: [Entry] = []
    @State var dbWords: [String] = []
    @State var frequenciesInHours: [Int] = []
    @State private var loading = false
    @State private var errorMessage = ""
    
    let endpoint: String = "https://jisho.org/api/v1/search/words"
    var manager = LocalNotificationManager()
    
    func getNotificationFrequeniesInSeconds() -> [Double] {
        return self.getNotificationFrequenciesInHours().map { hours in
            return Double(hours * 60 * 60)
        }
    }
    
    func handleUpdateNotifications(_ notificationIntervals: [NotificationInterval]) -> Void {
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
            return
        }
        let managedContext = appDelegate.persistentContainer.viewContext
   
        for number in 0..<3 {
            let fetchFrequency = NSFetchRequest<NSFetchRequestResult>(entityName: "NotificationFrequencies")
            fetchFrequency.predicate = NSPredicate(format: "number == %@", NSNumber(value: number + 1))
            
            do {
                print("Saving notification with \(notificationIntervals[number].duration) h")
                let result = try managedContext.fetch(fetchFrequency) as! [NotificationFrequencies]
                result.first?.setValue(notificationIntervals[number].duration, forKey: "hours")
            } catch {
                return
            }
        }
        self.frequenciesInHours = getNotificationFrequenciesInHours()
        self.manager.setNotificationFrequencies(frequencies: self.getNotificationFrequeniesInSeconds())
    }
    
    func getNotificationFrequenciesInHours() -> [Int] {
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
            return []
        }
        let managedContext = appDelegate.persistentContainer.viewContext
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "NotificationFrequencies")
        
        var frequencies: [Int] = []
        do {
            let result = try managedContext.fetch(fetchRequest)
            if result.count == 0 {
                print("Creating Default frequencies")
                for (index, hours) in [6, 18, 48].enumerated() {
                    // create the frequencies
                    let notificationEntity = NSEntityDescription.entity(forEntityName: "NotificationFrequencies", in: managedContext)!
                    
                    let frequency = NSManagedObject(entity: notificationEntity, insertInto: managedContext)
                    frequency.setValue(hours, forKey: "hours")
                    frequency.setValue(index + 1, forKey: "number")
                    frequencies.append(hours)
                }
                
                return frequencies
            }
            
            // else, we should load the frequencies from the db
            for number in 1..<4 {
                let fetchFrequency = NSFetchRequest<NSFetchRequestResult>(entityName: "NotificationFrequencies")
                fetchFrequency.predicate = NSPredicate(format: "number == %@", NSNumber(value: number))
                print("Loading Frequencies")

                do {
                    let result = try managedContext.fetch(fetchFrequency) as! [NotificationFrequencies]
                    if result.count != 1 {
                        return []
                    }
                    
                    frequencies.append(result.first?.value(forKey: "hours") as! Int)
                } catch {
                    return []
                }
            }
            return frequencies

        } catch {
            print("Error setting notification frequencies")
        }
        
        return []
    }
    
    func getAllDbWords() -> [String] {
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
            return [""]
        }
        let managedContext = appDelegate.persistentContainer.viewContext
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "QueuedNotifications")

        var words: [String] = []
        do {
            let result = try managedContext.fetch(fetchRequest)
            for data in result as! [NSManagedObject] {
                let created = data.value(forKey: "created") as! Date
                // 12h in seconds
                if created.addingTimeInterval(43200) < Date() {
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
        print("== Words in DB ==")
        for word in self.dbWords {
            print(word)
        }
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
            return entry.kanji! + "(\(entry.kana))"
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
            return
        }
        
        let text = constructNotificationText(entry)
        addWordToDb(entry)
        self.manager.addNotification(title: text)
        self.manager.schedule()
    }
    
    func handleSearch() {
        print("Searching for \(self.word.lowercased())")
        self.errorMessage = ""
        self.loading = true
        
        var components = URLComponents(string: endpoint)!
        components.queryItems = [
            URLQueryItem(name: "keyword", value: self.word.lowercased())
        ]
        let task = URLSession.shared.dataTask(with: components.url!) { (data, response, error) in
            if let data = data {
                do {
                    let response = try JSONDecoder().decode(RawJishoResponse.self, from: data)
                    let entries = self.parseRawJishoResponse(response: response)
                    self.dictEntries = entries
                    self.loading = false
                    if entries.count == 0 {
                        self.errorMessage = "No definition found for \(self.word)."
                    }
                } catch {
                    print("error", error, data)
                    self.loading = false
                }
            }
        }
        task.resume()
    }
    
    func handleAppear() {
        // self.manager.testNotification()
        self.frequenciesInHours = getNotificationFrequenciesInHours()
        self.manager.setNotificationFrequencies(frequencies: self.getNotificationFrequeniesInSeconds())
        print("Frequencies in hours", self.frequenciesInHours)
        loadCurrentDbWords()
        
        if self.settings.wordFromNotification != "" {
            self.word = self.settings.wordFromNotification
            self.handleSearch()
        } else {
            print("no word from notification")
        }
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
    
    @State var shown = false
    
    var body: some View {
        
        VStack {
            HStack {
                Image(systemName: "gear")
                    .onTapGesture { self.shown.toggle() }
                    .sheet(isPresented: $shown) { () -> OptionsView in
                        return OptionsView(
                            dismissFlag: self.$shown,
                            frequenciesInHours: self.frequenciesInHours,
                            handleUpdate: self.handleUpdateNotifications
                        )
                    }
                
                SearchBarCancel(text: $word, onSearch: handleSearch)
            }
            .padding(.leading)
            .padding(.trailing)
            
            if self.loading {
                ActivityIndicator(shouldAnimate: self.$loading).padding(.top)
            }
            
            if errorMessage != "" {
                Text("\(errorMessage)")
            }
        
            DefinitionList(
                dictEntries: dictEntries,
                onRequestNotification: handleNotification,
                dbWords: dbWords
            )
        }.onAppear {
            self.handleAppear()
        }
        
    }
}

let dictEntries: [Entry] = [
    Entry(kana: "じしょ", kanji: "辞書", meaning: Entry.Meaning(definitions: ["Dictionary"], partsOfSpeech: ["Noun"]))
]

struct ContentView_Previews: PreviewProvider  {
    static var previews: some View {
        ContentView(dictEntries: dictEntries)
    }
}
