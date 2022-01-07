import AWSLambdaRuntime
import Foundation

struct Input: Codable {
  let code: String
}

struct Output: Codable {
  let result: String
}

func compile(code: String) throws -> String {
    let fileName = "swiftyChallenge-" + UUID().uuidString
    let temporaryFile = FileManager.default.temporaryDirectory
        .appendingPathComponent("\(fileName).swift", isDirectory: false)
    try code.write(to: temporaryFile, atomically: true, encoding: .utf8)
    let output = try Shell.execute(command: "/usr/bin/swift", args: [temporaryFile.path])
    return output
}

Lambda.run { (context, input: Input, callback: @escaping (Result<Output, Error>) -> Void) in
    do {
        let output = try compile(code: input.code)
        callback(.success(Output(result: output)))
    } catch Shell.ShellError.failed(let string) {
        callback(.success(Output(result: string)))
    } catch let error {
        callback(.success(Output(result: error.localizedDescription)))
    }
}
