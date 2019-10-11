//
//  DefinitionRow.swift
//  NotificationDemo
//
//  Created by Lachlan Miller on 11/10/19.
//  Copyright © 2019 Lachlan Miller. All rights reserved.
//

import Foundation
import SwiftUI

struct DictionaryEntry: Identifiable {
    struct Word {
        var furigana: String
        var kanji: String?
    }
    struct Sense: Identifiable {
        var id: Int
        var partsOfSpeech: [String]
        var meanings: [String]
    }
    
    var id: Int
    var word: Word
    var senses: [Sense]
}

struct DefintionEnglish : View {
    var sense: DictionaryEntry.Sense
    
    var body : some View {
        VStack (alignment: .leading) {
            Text(sense.partsOfSpeech.joined(separator: ", ")).font(.footnote)
            ForEach(sense.meanings, id: \.self) { meaning in
                Text(meaning)
            }
        }
    }
}

struct DefinitionEntry : View {
    var entry: DictionaryEntry
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(entry.word.furigana)
                .font(.subheadline)
            
            if entry.word.kanji != nil {
                Text(entry.word.kanji!).font(.title)
            } else {
                Text(entry.word.furigana)
            }
            
            ForEach(entry.senses) { sense in
                DefintionEnglish(sense: sense)
                
            }
        }
    }
}

struct DefinitionRow : View {
    var dictEntries: [DictionaryEntry]
    
    var body: some View {
        List(dictEntries) { entry in
            DefinitionEntry(entry: entry)
        }
    }
}

let entries: [DictionaryEntry] = [
    DictionaryEntry(
        id: 1,
        word: DictionaryEntry.Word(furigana: "しほんしゅぎしゃかい", kanji: "資本主義社会"),
        senses: [
            DictionaryEntry.Sense(id: 1, partsOfSpeech: ["Noun"], meanings: ["Funds; capital"])
        ]
    ),
    
    DictionaryEntry(
        id: 2,
        word: DictionaryEntry.Word(furigana: "しほんしゅぎ", kanji: "資本主義"),
        senses: [
            DictionaryEntry.Sense(id: 1, partsOfSpeech: ["Noun", "No-adjective"], meanings: ["Capitalism", "To be a capitalist"])
        ]
    ),
]

struct DefinitionRow_Previews: PreviewProvider {
    static var previews: some View {
        DefinitionRow(dictEntries: entries)
    }
}
