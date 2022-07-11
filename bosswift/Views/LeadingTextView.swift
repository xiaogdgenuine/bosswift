//
//  LeadingTextView.swift
//  Bosswift
//
//  Created by huikai on 2022/6/16.
//

import SwiftUI

struct LeadingTextView: View {
    var text: LocalizedStringKey?
    var textStr: String?

    init(_ text: LocalizedStringKey) {
        self.text = text
    }

    init(_ text: String) {
        self.textStr = text
    }

    var body: some View {
        if let text = text {
            Text(text)
                .frame(maxWidth: .infinity, alignment: .leading)
        } else if let textStr = textStr {
            Text(textStr)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

struct LeadingTextView_Previews: PreviewProvider {
    static var previews: some View {
        HStack {
            LeadingTextView("Test sample")
        }
        .frame(width: 500)
    }
}
