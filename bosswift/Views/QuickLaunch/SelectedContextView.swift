//
//  SelectedContextView.swift
//  Bosswift
//
//  Created by huikai on 2022/6/27.
//

import SwiftUI

struct SelectedContextView: View {
    let context: String

    var body: some View {
        Text(context)
            .font(.system(size: 18))
            .lineLimit(1)
            .padding(.horizontal)
            .padding(.vertical, 4)
            .foregroundColor(Color.white)
            .background(Color.blue)
            .cornerRadius(4)
    }
}

struct SelectedContextView_Previews: PreviewProvider {
    static var previews: some View {
        SelectedContextView(context: "Kedamanga: feature/1988-Support_7z_Format")
    }
}
