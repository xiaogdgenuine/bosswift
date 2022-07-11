import SwiftUI
import Foundation

struct LoadingView: View {
    var body: some View {
        ProgressView()
                .frame(width: 16, height: 16)
                .scaleEffect(0.5, anchor: .center)
    }
}