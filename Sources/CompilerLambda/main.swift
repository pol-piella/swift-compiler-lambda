import AWSLambdaRuntime
import Foundation
import SwifterRe
import AWSLambdaEvents

struct Input: Codable {
  let code: String
}

struct Output: Codable {
    let output: String
    let errors: [CompilerError]
}

struct CompilerError: Codable {
    var lineNumber: Int?
    var characterNumber: Int?
    let message: String
}

let jsonEncoder = JSONEncoder()

func compile(code: String) throws -> String {
    let fileName = "swiftyChallenge-" + UUID().uuidString
    let temporaryFile = FileManager.default.temporaryDirectory
        .appendingPathComponent("\(fileName).swift", isDirectory: false)
    try code.write(to: temporaryFile, atomically: true, encoding: .utf8)
    let output = try Shell.execute(command: "/usr/bin/swift", args: [temporaryFile.path])
    return output
}

// Needed for CORS
let headers: HTTPHeaders = ["Access-Control-Allow-Origin": "*"]

Lambda.run { (context, input: Input, callback: @escaping (Result<APIGateway.V2.Response, Error>) -> Void) in
    do {
        let output = try compile(code: input.code)
        let data = try jsonEncoder.encode(output)
        callback(.success(.init(statusCode: .ok, headers: headers, body: String(data: data, encoding: .utf8))))
    } catch Shell.ShellError.failed(let string) {
        let errors = string.matching(pattern: #".swift:(\d*):(\d*): error: ([^/]+)"#)
        let compilerErrors = errors.map { match in
            CompilerError(
                lineNumber: Int(match.groups[0].value),
                characterNumber: Int(match.groups[1].value),
                message: match.groups[2].value
            )
        }
        let output = Output(output: "", errors: compilerErrors)
        guard let data = try? jsonEncoder.encode(output) else { callback(.success(.init(statusCode: .badRequest))); return }
        callback(.success(.init(statusCode: .ok, headers: headers, body: String(data: data, encoding: .utf8))))
    } catch let error {
        let output = Output(output: "", errors: [CompilerError(message: error.localizedDescription)])
        guard let data = try? jsonEncoder.encode(output) else { callback(.success(.init(statusCode: .badRequest))); return }
        callback(.success(.init(statusCode: .ok, headers: headers, body: String(data: data, encoding: .utf8))))
    }
}
