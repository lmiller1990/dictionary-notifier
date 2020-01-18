import SwiftUI

struct Sentence {
    var id: Int
    var english: String
    var japanese: String
}
extension String: Error {}

struct ExampleSentence : View {
    var sentence: Sentence
    
    
    var body : some View {
        Text(sentence.japanese + "(" + sentence.english + ")")
    }
}

struct ExampleSentenceView : View {
    @Binding var dismissFlag: Bool
    var sentences: [Sentence]
    
    var body : some View {
        Group {
            Text("Examples").font(.subheadline).padding(.top)
            
            if sentences.count == 0 {
                Text("No example sentences found.").font(.subheadline).padding(.top)
            }
            List(self.sentences, id: \.id) { sentence in
                ExampleSentence(sentence: sentence)
            }
        }
    }
}


struct ExampleSentenceView_Previews: PreviewProvider {
    static var previews: some View {
        ExampleSentenceView(
            dismissFlag: .constant(false),
            sentences: [
                Sentence(id: 1, english: "Let's try something.", japanese: "何かしてみましょう。"),
                Sentence(id: 2, english: "I have to go to sleep.", japanese: "私は眠らなければなりません。")
            ]
        )
    }
}

