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
    
    var body: some View {
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
    }
}

struct DefinitionList : View {
    var dictEntries: [Entry]
    
    var body: some View {
        List(dictEntries, id: \.kana) { entry in
            DefinitionEntry(entry: entry)
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
    )
]

struct DefinitionList_Previews: PreviewProvider {
    static var previews: some View {
        DefinitionList(dictEntries: entries)
    }
}
