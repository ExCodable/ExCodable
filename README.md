# ExCodable

En | [中文](./README-zh.md)

**ExCodable** - Extensions for Swift `Codable`.

## Contents

- [Features](#features)
- [Usage](#usage)
- [Requirements](#requirements)
- [Installation](#installation)
- [Credits](#credits)
- [License](#license)

## Features

Supports `key-mapping` with KeyPath` and `CodingKey`:
- No need to read/write memory via `UnsafePointer`.
- No need to encode/decode properties one by one.
- Just requires using `var` to declare properties and provide default values.
- In most cases, `CodingKey` is no longer necessary, because it will only be used once, `String` literals may be better.

Encode/Decode:
- Supports encode/decode via subscripts.
- Supports multiple `alternative-keys` via `Array` for decoding.
- Supports `nested-keys` via `String` with dot syntax.
- Supports custom encode/decode-handler via closures.
- Supports builtin and custom `type-conversion`.

Simple and flexible Encodable/Decodable API:
- **Part of the API draws on the design of an awesome framework - [Codextended](https://github.com/JohnSundell/Codextended).**
- Uses JSON Encoder/Decoder by default.
- Uses `type-inference`.
- Returns `Optional` values instead of throwing errors.

## Usage

### 1. `key-mapping` for `struct`:

> Requires using `var` to declare properties and provide default values.

```swift
struct TestStruct: Equatable {
    var int: Int = 0
    var string: String = ""
}
```

```swift
extension TestStruct: ExCodable {
    
    static var keyMapping: [KeyMap<Self>] = [
        KeyMap(\.int, to: "int"),
        KeyMap(\.string, to: "string")
    ]
    
    init(from decoder: Decoder) throws {
        Self.keyMapping.decode(&self, using: decoder)
    }
    func encode(to encoder: Encoder) throws {
        Self.keyMapping.encode(self, using: encoder)
    }
    
}
```

### 2. `key-mapping` for `class`:

> Cannot adopt `ExCodable` in extension of classes.

```swift
class TestClass: ExCodable, Equatable {
    
    var int: Int = 0
    var string: String? = nil
    init(int: Int, string: String?) {
        self.int = int
        self.string = string
    }
    
    static var keyMapping: [KeyMap<TestClass>] = [
        KeyMap(ref: \.int, to: "int"),
        KeyMap(ref: \.string, to: "string")
    ]
    
    required init(from decoder: Decoder) throws {
        Self.keyMapping.decode(self, using: decoder)
    }
    func encode(to encoder: Encoder) throws {
        Self.keyMapping.encode(self, using: encoder)
    }
    
    static func == (lhs: TestClass, rhs: TestClass) -> Bool {
        return lhs.int == rhs.int && lhs.string == rhs.string
    }
}
```

### 3. `key-mapping` for `subclass`:

> Requires declaring another static key-mapping for subclass.

```swift
class TestSubclass: TestClass {
    var bool: Bool = false
    required init(int: Int, string: String, bool: Bool) {
        self.bool = bool
        super.init(int: int, string: string)
    }
    
    static var keyMappingForTestSubclass: [KeyMap<TestSubclass>] = [
        KeyMap(ref: \.bool, to: "bool")
    ]
    
    required init(from decoder: Decoder) throws {
        try super.init(from: decoder)
        Self.keyMappingForTestSubclass.decode(self, using: decoder)
    }
    override func encode(to encoder: Encoder) throws {
        try super.encode(to: encoder)
        Self.keyMappingForTestSubclass.encode(self, using: encoder)
    }
    
    static func == (lhs: TestSubclass, rhs: TestSubclass) -> Bool {
        return lhs.int == rhs.int
            && lhs.string == rhs.string
            && lhs.bool == rhs.bool
    }
}
```

### 4. `alternative-keys`:

```swift
    static var keyMapping: [KeyMap<Self>] = [
        KeyMap(\.int, to: "int", "i"),
        KeyMap(\.string, to: "string", "str", "s")
    ]
```

### 5. `nested-keys`:

```swift
    static var keyMapping: [KeyMap<Self>] = [
        KeyMap(\.int, to: "nested.int"),
        KeyMap(\.string, to: "nested.nested.string")
    ]
```

### 6. Custom encode/decode-handler

```swift
    static var keyMapping: [KeyMap<Self>] = [
        KeyMap(\.int, to: "int"),
        KeyMap(\.string, to: "string", encode: { (encoder, stringKeys, test, keyPath) in
            encoder[stringKeys.first!] = "dddd" 
        }, decode: { (test, keyPath, decoder, stringKeys) in
            switch test.int {
            case 100: test.string = "Continue"
            case 200: test.string = "OK"
            case 304: test.string = "Not Modified"
            case 403: test.string = "Forbidden"
            case 404: test.string = "Not Found"
            case 418: test.string = "I'm a teapot"
            case 500: test.string = "Internal Server Error"
            case 200..<400: test.string = "success"
            default: test.string = "failure"
            }
        })
    ]
```

### 7. Encode/Decode with subscripts:

> Using `let` to declare properties without default values.

```swift
struct TestSubscript: Equatable {
    let int: Int
    let string: String
}
```

```swift
extension TestSubscript: Encodable, Decodable {
    
    enum Keys: CodingKey {
        case int, string
    }
    
    init(from decoder: Decoder) throws {
        int = decoder[Keys.int] ?? 0
        string = decoder[Keys.string] ?? ""
    }
    func encode(to encoder: Encoder) throws {
        encoder[Keys.int] = int
        encoder[Keys.string] = string
    }
    
}
```

### 8. Custom `type-conversion`:

> Extends `KeyedDecodingContainer` with protocol `KeyedDecodingContainerCustomTypeConversion` and implement its method, decode values in alternative types and convert to target type.

```swift
extension KeyedDecodingContainer: KeyedDecodingContainerCustomTypeConversion {
    public func decodeForTypeConversion<T, K>(_ container: KeyedDecodingContainer<K>, codingKey: K, as type: T.Type) -> T? where T : Decodable, K : CodingKey {
        
        if type is Double.Type || type is Double?.Type {
            if let bool = try? decodeIfPresent(Bool.self, forKey: codingKey as! Self.Key) {
                return (bool ? 1.0 : 0.0) as? T
            }
        }
        
        else if type is Float.Type || type is Float?.Type {
            if let bool = try? decodeIfPresent(Bool.self, forKey: codingKey as! Self.Key) {
                return (bool ? 1.0 : 0.0) as? T
            }
        }
        
        return nil
    }
}
```

### 9. Encodable/Decodable:

```swift
        let test = TestStruct(int: 100, string: "Continue")
        if let data = test.encoded() as Data?,
           let copy = data.decoded() as TestStruct? {
            XCTAssertEqual(copy, test)
        }
        else {
            XCTFail()
        }
```

## Requirements

- iOS 10.0+ | macOS X 11.0+ | tvOS 10.0+
- Xcode 12.0+
- Swift 5.0+

## Installation

[Swift Package Manager](https://github.com/apple/swift-package-manager):

```swift
.package(url: "https://github.com/iwill/ExCodable", from: "0.1")
```

[CocoaPods](http://cocoapods.org):

```ruby
pod 'ExCodable', '~> 0.1'
```

## Credits

Mr. Ming ([@minglq](https://twitter.com/minglq/))

## License

**ExCodable** is released under the MIT license. See [LICENSE](./LICENSE) for details.
