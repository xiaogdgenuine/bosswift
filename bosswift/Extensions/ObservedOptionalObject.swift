import Combine
import SwiftUI

/// A property wrapper that works like `ObservedObject`, but takes an optional object instead.
///
/// The `@ObservedObject` wrapper requires, that the observed object actually exists. In some cases
/// it's convenient to be able to observe an object which might be nil. This is where
/// `@ObservedOptionalObject` can be used.
///
/// ```swift
/// struct SomeView: View {
///     // Instead of
///     @ObservedObject var anObject: Model? // Won't work
///
///     // use
///     @ObservedOptionalObject var anObject: Model?
///
///     var body: some View {
///         HStack {
///             Text("Name")
///             if let name = anObject?.name {
///                 Text(name)
///             }
///         }
///     }
/// }
/// ```
@available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *)
@propertyWrapper public struct ObservedOptionalObject<T: ObservableObject>: DynamicProperty {

    @StateObject private var proxy = Proxy()

    /// The Proxy class holds the optional observed object and republisheds it's `objectWillChange`
    /// events.
    private class Proxy: ObservableObject {
        var wrappedObject: T? { didSet {

            // Update the publisher if the objects identity change or if
            // either the old value or the new value are `nil`
            if let wrappedObject = wrappedObject, let oldValue = oldValue {
                if ObjectIdentifier(wrappedObject) != ObjectIdentifier(oldValue) {
                    updatePublisher()
                }
            } else {
                updatePublisher()
            }
        } }

        private var cancellable: AnyCancellable?

        private func updatePublisher() {
            cancellable?.cancel()
            cancellable = wrappedObject?
                    .objectWillChange
                    .sink { [weak self] _ in
                        self?.objectWillChange.send()
                    }
        }
    }

    /// The observed object itself.
    private(set) public var wrappedValue: T?

    /// Create a new ObservedOptionalObject with an initial value
    public init(initialValue: T?) {
        self.wrappedValue = initialValue
    }

    /// Create a new ObservedOptionalObject. Don't call this initializer directly.
    /// Instead use `@OptionalObservedObject`
    public init(wrappedValue: T?) {
        self.wrappedValue = wrappedValue
    }

    public func update() {
        proxy.wrappedObject = wrappedValue
    }

    @dynamicMemberLookup public struct Wrapper {

        let wrappedObject: T?

        /// Returns an optional binding to the resulting value of a given key path.
        ///
        /// - Parameter keyPath  : A key path to a specific resulting value.
        ///
        /// - Returns: A new binding .
        public subscript<Subject>(dynamicMember keyPath: ReferenceWritableKeyPath<T, Subject>) -> Binding<Subject>? {
            guard let wrappedObject = wrappedObject else { return nil }

            return Binding {
                wrappedObject[keyPath: keyPath]
            } set: { value in
                wrappedObject[keyPath: keyPath] = value
            }
        }
    }

    /// A projection to create bindings to the observed object
    public var projectedValue: Wrapper {
        Wrapper(wrappedObject: wrappedValue)
    }

}