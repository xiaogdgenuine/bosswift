import Foundation
import SwiftUI
import Combine

extension View {
    /// https://stackoverflow.com/a/61985678/3393964
    public func cursor(_ cursor: NSCursor) -> some View {
        self.onHover { inside in
            if inside {
                cursor.push()
            } else {
                NSCursor.pop()
            }
        }
    }

    func placeholder<Content: View>(
            when shouldShow: Bool,
            alignment: Alignment = .leading,
            @ViewBuilder placeholder: () -> Content) -> some View {

        ZStack(alignment: alignment) {
            placeholder().opacity(shouldShow ? 1 : 0)
            self
        }
    }

    func selfSizeMask<T: View>(_ mask: T) -> some View {
        ZStack {
            self.opacity(0)
            mask.mask(self)
        }.fixedSize()
    }
}

extension Binding {
    func onChange(_ handler: @escaping (Value) -> Void) -> Binding<Value> {
        Binding(
                get: { self.wrappedValue },
                set: { newValue in
                    self.wrappedValue = newValue
                    handler(newValue)
                }
        )
    }
}

struct ScrollViewDidScrollViewModifier: ViewModifier {

    class ViewModel: NSObject, ObservableObject {
        @Published var contentOffset: CGPoint = .zero
        var scrollView: NSScrollView?

        func subscribe(scrollView: NSScrollView) {
            scrollView.contentView.postsBoundsChangedNotifications = true
            self.scrollView = scrollView
            NotificationCenter.default.addObserver(self,
                                                   selector: #selector(scrollViewViewDidScroll(_:)),
                                                   name: NSView.boundsDidChangeNotification,
                                                   object: scrollView.contentView)
        }

        @objc func scrollViewViewDidScroll(_ notification: Notification) {
            contentOffset = self.scrollView?.documentVisibleRect.origin ?? .zero
        }
    }

    @StateObject var viewModel = ViewModel()
    var didScroll: (CGPoint) -> Void

    func body(content: Content) -> some View {
        content
                .introspectScrollView { scrollView in
                    viewModel.subscribe(scrollView: scrollView)
                }
                .onReceive(viewModel.$contentOffset) { contentOffset in
                    didScroll(contentOffset)
                }
    }
}

extension View {
    func didScroll(_ didScroll: @escaping (CGPoint) -> Void) -> some View {
        self.modifier(ScrollViewDidScrollViewModifier(didScroll: didScroll))
    }
}
