//
//  RectangleButton.swift
//  Bosswift
//
//  Created by huikai on 2022/7/1.
//

import SwiftUI

struct RectangleButton: View {
    let text: String
    var highlightByDefault = false
    let onTap: () -> Void
    @State private var hovered = false

    var body: some View {
        HStack {
            Text(text)
                .font(.system(size: 16))
                .frame(maxWidth: .infinity)
        }
        .padding(.vertical, 12)
        .onHover {
            hovered = $0
        }
        .contentShape(Rectangle())
        .cursor(.pointingHand)
        .onTapGesture {
            onTap()
        }
        .border(Color.primary)
        .background(hovered ? Color.accentColor : highlightByDefault ? Color.accentColor.opacity(0.3) : Color(NSColor.textBackgroundColor))
    }
}

struct RectangleButton_Previews: PreviewProvider {
    static var previews: some View {
        RectangleButton(text: "Setup", highlightByDefault: true) {

        }
    }
}
