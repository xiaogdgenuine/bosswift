import Combine
import Foundation
import Cocoa

class ShellTask: ObservableObject {
    private let task: Process
    let command: String
    var onFinish = PassthroughSubject<Int, Never>()
    @Published var showingOutput = false

    let output = ConsoleOutput()
    let needOutput: Bool

    init(task: Process, command: String, needOutput: Bool = true) {
        self.task = task
        self.command = command
        self.needOutput = needOutput
    }

    func terminate() {
        task.terminate()
        DispatchQueue.main.async {
            self.showingOutput = false
            self.output.finished = true
        }
    }

    func activeOutput() {
        showingOutput = true
    }

    func launch() {
        if needOutput {
            let pipe = Pipe()
            pipe.fileHandleForReading.readabilityHandler = { pipe in
                if let line = String(data: pipe.availableData, encoding: .utf8) {
                    self.output.output(line: line)
                } else {
                    self.output.output(line: "Error decoding data: \(pipe.availableData)")
                }
            }

            task.standardError = pipe
            task.standardOutput = pipe
        }

        DispatchQueue.global().async {
            self.output.output(line: "Running: \(self.command)\n\n")
            self.task.launch()
            self.task.waitUntilExit()
            try? (self.task.standardOutput as? Pipe)?.fileHandleForReading.close()
            try? (self.task.standardError as? Pipe)?.fileHandleForReading.close()
            

            DispatchQueue.main.async {
                self.output.finished = true
                self.onFinish.send(Int(self.task.terminationStatus))
            }
        }
    }
}
