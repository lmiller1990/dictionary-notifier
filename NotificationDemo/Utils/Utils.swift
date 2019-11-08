import Foundation

enum GenericError : Error {
    case unreachableCode
}

class FileUtils {
    static func readFile(filename: String) throws -> [String] {
        
        let filePath = Bundle.main.resourcePath!
        
        let textContent = try! String(contentsOfFile: filePath + "/\(filename)", encoding: String.Encoding.utf8)
    
        return textContent.split(separator: "\n").map { String($0) }
//        if let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
//            let fileURL = dir.appendingPathComponent(filename)
//            do {
//                let text = try String(contentsOf: fileURL, encoding: .utf8)
//
//                return text.split(separator: "\n").map { String($0) }
//            }
//            catch {
//                print("Some error here...\(error)")
//            }
//        }
//
//        throw GenericError.unreachableCode
    }
}
