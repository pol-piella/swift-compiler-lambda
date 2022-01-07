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
        let errorPipe = Pipe()
        
        process.executableURL = URL(fileURLWithPath: command)
        process.arguments = args
        process.standardOutput = outputPipe
        process.standardError = errorPipe
        
        try process.run()
        
        let outputData = try outputPipe.fileHandleForReading.readToEnd()
        let errorData = try errorPipe.fileHandleForReading.readToEnd()
        
        process.waitUntilExit()
        
        // TODO: - Better error handling
        if let data = outputData, let outputString = String(data: data, encoding: .utf8) {
            return outputString
        } else if let data = errorData, let errorString = String(data: data, encoding: .utf8) {
            return errorString
        } else {
            return "Could not read any of the output pipes"
        }
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
