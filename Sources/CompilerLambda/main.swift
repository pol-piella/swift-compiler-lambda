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
let jsonDecoder = JSONDecoder()

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

Lambda.run { (context, request: APIGateway.V2.Request, callback: @escaping (Result<APIGateway.V2.Response, Error>) -> Void) in
    guard request.context.http.method == .POST && request.context.http.path == "/compile" else { callback(.success(.init(statusCode: .badRequest, body: "Path or method not allowed"))); return }
    do {
        let input = try jsonDecoder.decode(Input.self, from: request.body!)
        let output = try compile(code: input.code)
        callback(.success(.init(statusCode: .ok, headers: headers, body: try jsonEncoder.encodeAsString(Output(output: output, errors: [])))))
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
        guard let data = try? jsonEncoder.encodeAsString(output) else { callback(.success(.init(statusCode: .badRequest))); return }
        callback(.success(.init(statusCode: .ok, headers: headers, body: data)))
    } catch let error {
        let output = Output(output: "", errors: [CompilerError(message: error.localizedDescription)])
        guard let data = try? jsonEncoder.encodeAsString(output) else { callback(.success(.init(statusCode: .badRequest))); return }
        callback(.success(.init(statusCode: .ok, headers: headers, body: data)))
    }
}
