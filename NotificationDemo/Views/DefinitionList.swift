import Foundation
import SwiftUI

struct DefintionEnglish : View {
    var meaning: Entry.Meaning
    
    var body : some View {
        VStack (alignment: .leading) {
            Text(meaning.partsOfSpeech.joined(separator: ", ")).font(.footnote)
            ForEach(meaning.definitions, id: \.self) { meaning in
                Text(meaning)
            }
        }
    }
}

struct DefinitionEntry : View {
    var entry: Entry
    var onRequestNotification: (_ entry: Entry) -> Void
    var dbWords: [String] = []
    
    func setReminder() {
        onRequestNotification(entry)
    }
    
    func inDb(_ entry: Entry) -> Bool {
        return dbWords.contains(entry.kana)
    }
    
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                if entry.kanji != nil {
                    Text(entry.kana)
                        .font(.subheadline)
                    
                    Text(entry.kanji!)
                        .font(.title)
                } else {
                    Text(entry.kana).font(.title)
                }
                
                DefintionEnglish(meaning: entry.meaning)
            }
            
            Spacer()
            
            HStack {
                Image(systemName: self.inDb(entry) ? "bell.fill" : "bell")
                    .onTapGesture { self.setReminder() }
                
            }
        }
    }
}

struct DefinitionList : View {
    var dictEntries: [Entry]
    var onRequestNotification: (_ word: Entry) -> Void
    var dbWords: [String]
    @State var shown = false
    @State var sentences: [Sentence] = []
    
    func loadExampleSentences(entry: Entry) {
        do {
            let element: String = entry.kanji != nil ? entry.kanji! : entry.kana
            
            let path = "\(Bundle.main.resourcePath!)/examples.txt"
            guard let reader = LineReader(path: path) else {
                print("Could not open file...")
                throw "Error..."
            }
            
            var i: Int = 0
            var arr: [Sentence] = []
            var foundJapanese: [String] = []
            var foundEnglish: [String] = []

            for line in reader {
                if line.contains(element) {
                    let split = line.split(separator: "|")
                    
                    if split.count == 2 {
                        let english = String(split[0])
                        let japanese = String(split[1])
                        
                        if !foundEnglish.contains(english) && !foundJapanese.contains(japanese) {
                            i += 1
                            foundJapanese.append(japanese)
                            foundEnglish.append(english)
                            arr.append(Sentence(id: i, english: english, japanese: japanese))
                        }
                    }
                }
                
                if i > 15 { break }
            }
            
            self.sentences = arr
            self.shown.toggle()
        } catch {
            // ...
        }
    }
    
    var body: some View {
        List(dictEntries, id: \.kana) { entry in
            DefinitionEntry(
                entry: entry,
                onRequestNotification: self.onRequestNotification,
                dbWords: self.dbWords
            )
                .contentShape(Rectangle())
                .onTapGesture { self.loadExampleSentences(entry: entry) }
                .sheet(isPresented: self.$shown) { () -> ExampleSentenceView in
                    return ExampleSentenceView(
                        dismissFlag: self.$shown,
                        sentences: self.sentences
                    )
            }
        }
    }
}

let entries: [Entry] = [
    Entry(
        kana: "しほんしゅぎしゃかい",
        kanji: "資本主義社会",
        meaning: Entry.Meaning(definitions: ["Funds; capital"], partsOfSpeech: ["Noun"])
    ),
    
    Entry(
        kana: "アルバイト",
        meaning: Entry.Meaning(definitions: ["part-time job", "side job"], partsOfSpeech: ["Noun", "Suru verb"])
    ),
    
    Entry(
        kana: "イエメンオオトカゲ",
        meaning: Entry.Meaning(definitions: ["Yemen monitor (Varanus yemenensis, species of carnivorous monitor lizard found at the base of the Tihama mountains along the western coast of Yemen)"], partsOfSpeech: ["Noun", "Suru verb"])
    )
]

func mock(_ entry: Entry) -> Void {
    return
}

struct DefinitionList_Previews: PreviewProvider {
    static var previews: some View {
        DefinitionList(
            dictEntries: entries,
            onRequestNotification: mock,
            dbWords: []
        )
    }
}
