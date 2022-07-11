import Foundation

let jsonEncoder = JSONEncoder()
let jsonDecoder = JSONDecoder()

@propertyWrapper
struct UserDefaultSetting<Value: Codable> {

    var wrappedValue: Value {
        get {
            if storeWithJsonFormat {
                if let encoded = UserDefaults.standard.object(forKey: key) as? String,
                   let encodedData = encoded.data(using: .utf8) {
                    return (try? jsonDecoder.decode(Value.self, from: encodedData)) ?? defaultValue
                }

                return defaultValue
            } else {
                let storedValue = UserDefaults.standard.value(forKey: key) as? Value
                return storedValue ?? defaultValue
            }
        }
        set {
            if let optional = newValue as? AnyOptional, optional.isNil {
                UserDefaults.standard.removeObject(forKey: key)
                return
            }

            if storeWithJsonFormat {
                if let json = try? jsonEncoder.encode(newValue),
                   let encoded = String(data: json, encoding: .utf8) {
                    UserDefaults.standard.set(encoded, forKey: key)
                }
            } else {
                UserDefaults.standard.set(newValue, forKey: key)
            }
            UserDefaults.standard.synchronize()
        }
    }
    var defaultValue: Value
    let key: String
    let storeWithJsonFormat: Bool

    init(wrappedValue defaultValue: Value, _ key: String, useJson: Bool = false) {
        self.defaultValue = defaultValue
        self.key = key
        self.storeWithJsonFormat = useJson
    }
}

private protocol AnyOptional {
    var isNil: Bool { get }
}

extension Optional: AnyOptional {
    var isNil: Bool { self == nil }
}

extension UserDefaults {
    func set<Element: Codable>(value: Element, forKey key: String) {
        let data = try? JSONEncoder().encode(value)
        UserDefaults.standard.setValue(data, forKey: key)
    }

    func codable<Element: Codable>(forKey key: String) -> Element? {
        guard let data = UserDefaults.standard.data(forKey: key) else { return nil }
        let element = try? JSONDecoder().decode(Element.self, from: data)
        return element
    }
}
