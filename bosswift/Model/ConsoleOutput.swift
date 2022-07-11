import Foundation


class ConsoleOutput: ObservableObject {
    @Published var finished = false
    @Published var outputStr: String = ""
//    @Published var outputLines: [String] = []

    init() {
        outputStr.reserveCapacity(100000)
    }
    
    func output(line: String) {
        DispatchQueue.main.async {
            self.outputStr.append(contentsOf: "\(line)")
        }
    }
}
