//
//  AboutView.swift
//  Bosswift
//
//  Created by huikai on 2022/7/2.
//

import SwiftUI

struct AboutView: View {
    @State var hoveringCoffeeBtn = false

    var body: some View {
        VStack {
            VStack(spacing: 32) {
                Text("About Bosswift")
                        .font(.title)
                Text("Icon from [Freepik - Flaticon](https://www.flaticon.com/premium-icon/principal_3152902?term=boss&related_id=3152902)")

                HStack {
                    Text("Who made it?")
                    Text("https://github.com/xiaogdgenuine/Bowsswift")
                }

                HStack {
                    Image(systemName: "cup.and.saucer")
                        .resizable()
                        .foregroundColor(.black)
                        .frame(width: 32, height: 32)
                    Text("Buy me a coffee")
                        .foregroundColor(.black)
                }
                .opacity(hoveringCoffeeBtn ? 0.5 : 1)
                .contentShape(Rectangle())
                .padding()
                .padding(.horizontal, 24)
                .onHover {
                    hoveringCoffeeBtn = $0
                }
                .background(Color.yellow)
                .cornerRadius(12)
                .cursor(.pointingHand)
                .onTapGesture {
                    NSWorkspace.shared.open(URL(string: "https://www.buymeacoffee.com/xiaogd")!)
                }
            }.padding()
        }.frame(maxHeight: .infinity)
    }
}

struct AboutView_Previews: PreviewProvider {
    static var previews: some View {
        AboutView()
    }
}
