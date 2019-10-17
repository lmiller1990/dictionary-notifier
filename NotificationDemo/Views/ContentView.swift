import SwiftUI
import Foundation
import CoreData


struct ContentView: View {
    @State var word: String = ""
    @State var definition: String = ""
    @State var dictEntries: [Entry] = []
    
    var endpoint: String = "https://jisho.org/api/v1/search/words"
    let manager = LocalNotificationManager()
    
    func createData(){
        
        //As we know that container is set up in the AppDelegates so we need to refer that container.
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else { return }
        
        //We need to create a context from this container
        let managedContext = appDelegate.persistentContainer.viewContext
        
        //Now let’s create an entity and new user records.
        let userEntity = NSEntityDescription.entity(forEntityName: "Users", in: managedContext)!
        
        //final, we need to add some data to our newly created record for each keys using
        //here adding 5 data with loop
        
        for i in 1...5 {
            
            let user = NSManagedObject(entity: userEntity, insertInto: managedContext)
            user.setValue("Ankur\(i)", forKeyPath: "name")
        }
        
        //Now we have set all the values. The next step is to save them inside the Core Data
        
        do {
            try managedContext.save()
            
        } catch let error as NSError {
            print("Could not save. \(error), \(error.userInfo)")
        }
    }
    
    init() {
        print("Initializing")
        
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else { return }
        
        let managedContext = appDelegate.persistentContainer.viewContext
        
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "QueuedNotifications")
        
        do {
            let result = try managedContext.fetch(fetchRequest)
            for data in result as! [NSManagedObject] {
                print(data.value(forKey: "uuid") as! String)
                print(data.value(forKey: "word") as! String)
            }
        } catch {
            print("Failed")
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
        
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
            return ""
        }
        
        let managedContext = appDelegate.persistentContainer.viewContext
        
        let userEntity = NSEntityDescription.entity(forEntityName: "QueuedNotifications", in: managedContext)!
        
        let user = NSManagedObject(entity: userEntity, insertInto: managedContext)
        user.setValue(text, forKey: "word")
        user.setValue(UUID().uuidString, forKey: "uuid")
        
        
        if (entry.meaning.definitions.count > 0) {
            text += " - " + entry.meaning.definitions[0]
        }
        
        print("Notification text is \(text)")
        
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
        
        let word = getWord(entry)
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "QueuedNotifications")
        fetchRequest.predicate = NSPredicate(format: "word == %@", word)
        
        do {
            let result = try managedContext.fetch(fetchRequest)
            return result.count > 0
        } catch {
            print("Failed")
            return false
        }
    }
    
    func addWordToDb(_ entry: Entry) {
        let text = getWord(entry)
        
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
            return
        }
        
        let managedContext = appDelegate.persistentContainer.viewContext
        
        let userEntity = NSEntityDescription.entity(forEntityName: "QueuedNotifications", in: managedContext)!
        
        let user = NSManagedObject(entity: userEntity, insertInto: managedContext)
        user.setValue(text, forKey: "word")
        user.setValue(UUID().uuidString, forKey: "uuid")
    }
    
    func handleNotification(entry: Entry) {
        if checkDb(entry) {
            print("Word in DB. Do nothing.")
            return
        }
        print("Adding word to DB.")
        addWordToDb(entry)
        
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
