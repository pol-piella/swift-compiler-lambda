import Foundation

extension JSONEncoder {
    func string<T: Encodable>(from model: T) throws -> String {
        try String(decoding: self.encode(model), as: Unicode.UTF8.self)
    }
}

extension JSONDecoder {
  func decode<T: Decodable>(_ type: T.Type, from string: String) throws -> T {
    try self.decode(type, from: Data(string.utf8))
  }
}
