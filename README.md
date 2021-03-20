[![ExCodable](https://iwill.im/images/ExCodable-1920x500.png)](#readme)

[![Swift 5.0](https://img.shields.io/badge/Swift-5.0-orange.svg)](https://swift.org/)
[![Swift Package Manager](https://img.shields.io/badge/spm-compatible-brightgreen.svg?style=flat)](https://swift.org/package-manager/)
[![Platforms](https://img.shields.io/cocoapods/p/ExCodable.svg)](#readme)
[![Build and Test](https://github.com/iwill/ExCodable/actions/workflows/build-and-test.yml/badge.svg)](https://github.com/iwill/ExCodable/actions/workflows/build-and-test.yml)
[![GitHub Releases (latest SemVer)](https://img.shields.io/github/v/release/iwill/ExCodable.svg?sort=semver)](https://github.com/iwill/ExCodable/releases)
[![Deploy to CocoaPods](https://github.com/iwill/ExCodable/actions/workflows/deploy_to_cocoapods.yml/badge.svg)](https://github.com/iwill/ExCodable/actions/workflows/deploy_to_cocoapods.yml)
[![Cocoapods](https://img.shields.io/cocoapods/v/ExCodable.svg)](https://cocoapods.org/pods/ExCodable)
[![LICENSE](https://img.shields.io/github/license/iwill/ExCodable.svg)](https://github.com/iwill/ExCodable/blob/master/LICENSE)
[![@minglq](https://img.shields.io/twitter/url?url=https%3A%2F%2Fgithub.com%2Fiwill%2FExCodable)](https://twitter.com/minglq)

En | [中文](https://iwill.im/ExCodable/)

## Contents

- [Features](#features)
- [Usage](#usage)
- [Requirements](#requirements)
- [Installation](#installation)
- [Credits](#credits)
- [License](#license)

## Features

- Extends Swift `Codable` - `Encodable & Decodable`;
- Supports Key-Mapping via `KeyPath` and Coding-Key:
    - `ExCodable` did not read/write memory via unsafe pointers;
    - No need to encode/decode properties one by one;
    - Just requires using `var` to declare properties and provide default values;
    - In most cases, the `CodingKey` type is no longer necessary, because it will only be used once, `String` literals may be better.
- Supports multiple Key-Mappings for different data sources;
- Supports multiple Alternative-Keys via `Array` for decoding;
- Supports Nested-Keys via `String` with dot syntax;
- Supports customized encode/decode via subscripts;
- Supports builtin and custom Type-Conversions;
- Supports `struct`, `class` and subclass;
- Uses JSON encoder/decoder by default, and supports PList;
- Uses Type-Inference, supports JSON `Data`, `String` and `Object`;
- Returns `Optional` values instead of throwing errors, to avoid frequent use of `try?`.

## Usage

### 0. `Codable`:

With `Codable`, it just needs to adop the `Codable` protocol without implementing any method of it.

```swift
struct TestAutoCodable: Codable, Equatable {
    private(set) var int: Int = 0
    private(set) var string: String?
    enum CodingKeys: String, CodingKey {
        case int = "i", string = "s"
    }
}
```

But, if you have to encode/decode manually for some reason ...

```swift
struct TestManualCodable: Equatable {
    private(set) var int: Int = 0
    private(set) var string: String?
}
```

```swift
extension TestManualCodable: Codable {
    
    enum Keys: CodingKey {
        case int, string
    }
    
    init(from decoder: Decoder) throws {
        let container = try? decoder.container(keyedBy: Keys.self)
        if let int = try? container?.decodeIfPresent(Int.self, forKey: Keys.int) {
            self.int = int
        }
        if let string = try? container?.decodeIfPresent(String.self, forKey: Keys.string) {
            self.string = string
        }
    }
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: Keys.self)
        try? container.encodeIfPresent(int, forKey: Keys.int)
        try? container.encodeIfPresent(string, forKey: Keys.string)
    }
    
}
```

### 1. Key-Mapping for `struct`:

With `ExCodable`, it needs to to declare properties with `var` and provide default values.

```swift
struct TestStruct: Equatable {
    private(set) var int: Int = 0
    private(set) var string: String?
}
```

```swift
extension TestStruct: ExCodable {
    
    static var keyMapping: [KeyMap<Self>] = [
        KeyMap(\.int, to: "int"),
        KeyMap(\.string, to: "string")
    ]
    
    init(from decoder: Decoder) throws {
        decode(with: Self.keyMapping, using: decoder)
    }
    func encode(to encoder: Encoder) throws {
        encode(with: Self.keyMapping, using: encoder)
    }
    
}
```

### 2. Alternative-Keys:

```swift
static var keyMapping: [KeyMap<Self>] = [
    KeyMap(\.int, to: "int", "i"),
    KeyMap(\.string, to: "string", "str", "s")
]
```

### 3. Nested-Keys:

```swift
static var keyMapping: [KeyMap<Self>] = [
    KeyMap(\.int, to: "nested.int"),
    KeyMap(\.string, to: "nested.nested.string")
]
```

### 4. Custom encode/decode:

```swift
struct TestCustomEncodeDecode: Equatable {
    var int: Int = 0
    var string: String?
}
```

```swift
extension TestCustomEncodeDecode: ExCodable {
    
    private enum Keys: String, CodingKey {
        case int, string
    }
    private static let dddd = "dddd"
    private func string(for int: Int) -> String {
        switch int {
            case 100: return "Continue"
            case 200: return "OK"
            case 304: return "Not Modified"
            case 403: return "Forbidden"
            case 404: return "Not Found"
            case 418: return "I'm a teapot"
            case 500: return "Internal Server Error"
            case 200..<400: return "success"
            default: return "failure"
        }
    }
    
    static var keyMapping: [KeyMap<Self>] = [
        KeyMap(\.int, to: Keys.int),
        KeyMap(\.string, to: Keys.string)
    ]
    
    init(from decoder: Decoder) throws {
        decode(with: Self.keyMapping, using: decoder)
        if string == nil || string == Self.dddd {
            string = string(for: int)
        }
    }
    func encode(to encoder: Encoder) throws {
        encode(with: Self.keyMapping, using: encoder)
        encoder[Keys.string] = Self.dddd
    }
    
}
```

### 5. Encode/decode constant properties with subscripts:

Using `let` to declare properties without default values.

```swift
struct TestSubscript: Equatable {
    let int: Int
    let string: String
}
```

```swift
extension TestSubscript: Codable {
    
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

### 6. Custom Type-Conversions:

Extends `KeyedDecodingContainer` with protocol `KeyedDecodingContainerCustomTypeConversion` and implement its method, decode values in alternative types and convert to target type.

```swift
extension KeyedDecodingContainer: KeyedDecodingContainerCustomTypeConversion {
    public func decodeForTypeConversion<T, K>(_ container: KeyedDecodingContainer<K>, codingKey: K, as type: T.Type) -> T? where T: Decodable, K: CodingKey {
        
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

### 7. Key-Mapping for `class`:

Cannot adopt `ExCodable` in extension of classes.

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
        decodeReference(with: Self.keyMapping, using: decoder)
    }
    func encode(to encoder: Encoder) throws {
        encode(with: Self.keyMapping, using: encoder)
    }
    
    static func == (lhs: TestClass, rhs: TestClass) -> Bool {
        return lhs.int == rhs.int && lhs.string == rhs.string
    }
}
```

### 8. Key-Mapping for subclass:

Requires declaring another static Key-Mapping for subclass.

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
        decodeReference(with: Self.keyMappingForTestSubclass, using: decoder)
    }
    override func encode(to encoder: Encoder) throws {
        try super.encode(to: encoder)
        encode(with: Self.keyMappingForTestSubclass, using: encoder)
    }
    
    static func == (lhs: TestSubclass, rhs: TestSubclass) -> Bool {
        return lhs.int == rhs.int
            && lhs.string == rhs.string
            && lhs.bool == rhs.bool
    }
}
```

### 9. Encode/decode with Type-Inference:

```swift
let test = TestStruct(int: 304, string: "Not Modified")
let data = test.encoded() as Data?
let copy1 = data?.decoded() as TestStruct?
let copy2 = TestStruct.decoded(from: data)
XCTAssertEqual(copy1, test)
XCTAssertEqual(copy2, test)
```

## Requirements

- iOS 8.0+ | tvOS 9.0+ | macOS X 10.10+ | watchOS 2.0+
- Xcode 12.0+
- Swift 5.0+

## Installation

- [Swift Package Manager](https://swift.org/package-manager/):

```swift
.package(url: "https://github.com/iwill/ExCodable", from: "0.4.0")
```

- [CocoaPods](http://cocoapods.org):

```ruby
pod 'ExCodable', '~> 0.4.0'
```

- Code Snippets:

> Title: ExCodable
> Summary: Adopte to ExCodable protocol
> Language: Swift  
> Platform: All  
> Completion: ExCodable  
> Availability: Top Level  

```swift
<#extension/struct/class#> <#Type#>: ExCodable {
    static var <#keyMapping#>: [KeyMap<<#SelfType#>>] = [
        KeyMap(\.<#property#>, to: <#"key"#>),
        <#...#>
    ]
    init(from decoder: Decoder) throws {
        decode<#Reference#>(with: Self.<#keyMapping#>, using: decoder)
    }
    func encode(to encoder: Encoder) throws {
        encode(with: Self.<#keyMapping#>, using: encoder)
    }
}
```

## Credits

- John Sundell ([@JohnSundell](https://github.com/JohnSundell)) and the ideas from his [Codextended](https://github.com/JohnSundell/Codextended)
- ibireme ([@ibireme](https://github.com/ibireme)) and the features from his [YYModel](https://github.com/ibireme/YYModel)
- Mr. Ming ([@iwill](https://github.com/iwill))

## License

**ExCodable** is released under the MIT license. See [LICENSE](./LICENSE) for details.
