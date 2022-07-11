//
//  WelcomeView.swift
//  Bosswift
//
//  Created by huikai on 2022/7/1.
//

import SwiftUI

struct WelcomeView: View {
    @Environment(\.colorScheme) var colorScheme: ColorScheme
    let onNextStep: () -> Void

    var body: some View {
        VStack(alignment: .leading) {
            LeadingTextView("Welcome!")
                .font(.system(size: 32))
            
            HStack {
                Text("Bosswift, a command launcher works perfectly with")
                Text("**Git Worktree**.")
                    .foregroundColor(.blue)
                    .underline()
                    .cursor(.pointingHand)
                    .onTapGesture {
                        let url = URL.init(string: "https://git-scm.com/docs/git-worktree")
                        guard let url = url else { return }
                        NSWorkspace.shared.open(url)
                    }
                Spacer()
            }
                .padding(.top, 8)
                .font(.system(size: 18))

            VStack(alignment: .leading) {
                LeadingTextView("Step 1: Pick a worktree.")
                    .foregroundColor(.secondary)
                    .font(.title3)
                Image(colorScheme == .dark ? "WelcomeDemoStep1Dark" : "WelcomeDemoStep1Light")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 480)

                Divider()
                LeadingTextView("Step 2: Do command!")
                    .foregroundColor(.secondary)
                    .padding(.top)
                    .font(.title3)
                Image(colorScheme == .dark ? "WelcomeDemoStep2Dark" : "WelcomeDemoStep2Light")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 480)
            }.padding()

            RectangleButton(text: "Let's get Bossy!", highlightByDefault: true) {
                onNextStep()
            }
        }
            .padding(32)
            .background(Color(NSColor.textBackgroundColor))
    }
}

struct WelcomeView_Previews: PreviewProvider {
    static var previews: some View {
        WelcomeView {}
            .frame(height: 800)
    }
}
