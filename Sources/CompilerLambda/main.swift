import AWSLambdaRuntime
import Foundation

struct Input: Codable {
  let code: String
}

struct Output: Codable {
  let result: String
}

enum Shell {
    static func execute(command: String, args: [String]) throws -> String {
        let process = Process()
        let outputPipe = Pipe()
        
        process.executableURL = URL(fileURLWithPath: command)
        process.arguments = args
        process.standardOutput = outputPipe
        
        try process.run()
        
        let data = try outputPipe.fileHandleForReading.readToEnd()!
        
        process.waitUntilExit()

        
        return String(data: data, encoding: .utf8)!
    }
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
    } catch let error {
        callback(.success(Output(result: error.localizedDescription)))
    }
}
