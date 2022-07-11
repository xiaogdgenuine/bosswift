import SwiftUI


struct ConsoleView: View {
    @ObservedObject var output: ConsoleOutput

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(spacing: 0) {
                    HStack {
                        if #available(macOS 12.0, *) {
                            Text(output.outputStr).textSelection(.enabled)
                        } else {
                            Text(output.outputStr)
                        }
                        Spacer()
                    }

                    if !output.finished {
                        HStack {
                            LoadingView()
                            Spacer()
                        }
                    }

                    Spacer()
                }

                HStack {
                }
                        .id(1)
            }
                    .frame(width: 350, height: 500)
                    .padding()
                    .onReceive(output.$outputStr) { _ in
                        DispatchQueue.main.async {
                            proxy.scrollTo(1, anchor: .bottom)
                        }
                    }
        }
    }
}

struct ConsoleView_Previews: PreviewProvider {
    static var previews: some View {
        ConsoleView(output: MockData.consoleOutput)
    }
}
