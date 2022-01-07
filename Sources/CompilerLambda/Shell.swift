import Foundation

enum Shell {
    enum ShellError: Error {
        case failed(String)
        case unknown
    }
    
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
        
        if let data = outputData, let outputString = String(data: data, encoding: .utf8) {
            return outputString
        } else if let data = errorData, let errorString = String(data: data, encoding: .utf8) {
            throw ShellError.failed(errorString)
        } else {
            throw ShellError.unknown
        }
    }
}
