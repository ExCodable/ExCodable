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
- Supports encode/decode with or without `IfPresent`;
- Supports abort (throws error) or continue (returns nil) encode/decode if error encountered;
- Uses JSON encoder/decoder by default, and supports PList;
- Uses Type-Inference, supports JSON `Data`, `String` and `Object`.

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

But, if you have to encode/decode manually for some reason, e.g. Alternative-Keys and Nested-Keys ...

```swift
struct TestManualCodable: Equatable {
    private(set) var int: Int = 0
    private(set) var string: String?
}

extension TestManualCodable: Codable {
    
    enum Keys: CodingKey {
        case int, i
        case nested, string
    }
    
    init(from decoder: Decoder) throws {
        if let container = try? decoder.container(keyedBy: Keys.self) {
            if let int = (try? container.decodeIfPresent(Int.self, forKey: Keys.int))
                ?? (try? container.decodeIfPresent(Int.self, forKey: Keys.i)) {
                self.int = int
            }
            if let nestedContainer = try? container.nestedContainer(keyedBy: Keys.self, forKey: Keys.nested),
               let string = try? nestedContainer.decodeIfPresent(String.self, forKey: Keys.string) {
                self.string = string
            }
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: Keys.self)
        try? container.encodeIfPresent(int, forKey: Keys.int)
        var nestedContainer = container.nestedContainer(keyedBy: Keys.self, forKey: Keys.nested)
        try? nestedContainer.encodeIfPresent(string, forKey: Keys.string)
    }
}

```

**With `ExCodable`**:

```swift
struct TestExCodable: Equatable {
    private(set) var int: Int = 0
    private(set) var string: String?
}

extension TestExCodable: ExCodable {
    static let keyMapping: [KeyMap<Self>] = [
        KeyMap(\.int, to: "int"),
        KeyMap(\.string, to: "string")
    ]
    init(from decoder: Decoder) throws {
        try decode(from: decoder, with: Self.keyMapping)
    }
}

```

### 1. Key-Mapping for `struct`:

With `ExCodable`, it needs to to declare properties with `var` and provide default values.

```swift
struct TestStruct: Equatable {
    private(set) var int: Int = 0
    private(set) var string: String?
    var bool: Bool!
}

```

```swift
extension TestStruct: ExCodable {
    
    static let keyMapping: [KeyMap<Self>] = [
        KeyMap(\.int, to: "int"),
        KeyMap(\.string, to: "string"),
    ]
    
    init(from decoder: Decoder) throws {
        try decode(from: decoder, with: Self.keyMapping)
    }
    // `encode` with default implementation can be omitted
    // func encode(to encoder: Encoder) throws {
    //     try encode(to: encoder, with: Self.keyMapping)
    // }
}

```

### 2. Alternative-Keys:

```swift
static let keyMapping: [KeyMap<Self>] = [
    KeyMap(\.int, to: "int", "i"),
    KeyMap(\.string, to: "string", "str", "s")
]

```

### 3. Nested-Keys:

```swift
static let keyMapping: [KeyMap<Self>] = [
    KeyMap(\.int, to: "int"),
    KeyMap(\.string, to: "nested.string")
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
    
    private enum Keys: CodingKey {
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
    
    static let keyMapping: [KeyMap<Self>] = [
        KeyMap(\.int, to: Keys.int),
    ]
    
    init(from decoder: Decoder) throws {
        try decode(from: decoder, with: Self.keyMapping)
        string = decoder[Keys.string]
        if string == nil || string == Self.dddd {
            string = string(for: int)
        }
    }
    func encode(to encoder: Encoder) throws {
        try encode(to: encoder, with: Self.keyMapping)
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
extension TestSubscript: Encodable, Decodable {
    
    enum Keys: CodingKey {
        case int, string
    }
    
    init(from decoder: Decoder) throws {
        // - seealso:
        // string = decoder.decode(<#T##codingKeys: CodingKey...##CodingKey#>)
        // string = try decoder.decodeThrows(<#T##codingKeys: CodingKey...##CodingKey#>)
        // string = try decoder.decodeNonnullThrows(<#T##codingKeys: CodingKey...##CodingKey#>)
        int = decoder[Keys.int] ?? 0
        string = decoder[Keys.string] ?? ""
    }
    func encode(to encoder: Encoder) throws {
        // - seealso:
        // encoder.encode(<#T##value: Encodable?##Encodable?#>, for: <#T##CodingKey#>)
        // try encoder.encodeThrows(<#T##value: Encodable?##Encodable?#>, for: <#T##CodingKey#>)
        // try encoder.encodeNonnullThrows(<#T##value: Encodable##Encodable#>, for: <#T##CodingKey#>)
        encoder[Keys.int] = int
        encoder[Keys.string] = string
    }
}

```

### 6. Custom Type-Conversions:

Declare struct `FloatToBoolDecodingTypeConverter` with protocol `ExCodableDecodingTypeConverter` and implement its method, decode values in alternative types and convert to target type:

```swift
struct FloatToBoolDecodingTypeConverter: ExCodableDecodingTypeConverter {
    public func decode<T: Decodable, K: CodingKey>(_ container: KeyedDecodingContainer<K>, codingKey: K, as type: T.Type) -> T? {
        // Bool -> Double
        if type is Double.Type || type is Double?.Type {
            if let bool = try? container.decodeIfPresent(Bool.self, forKey: codingKey) {
                return (bool ? 1.0 : 0.0) as? T
            }
        }
        // Bool -> Float
        else if type is Float.Type || type is Float?.Type {
            if let bool = try? container.decodeIfPresent(Bool.self, forKey: codingKey) {
                return (bool ? 1.0 : 0.0) as? T
            }
        }
        // Double or Float NOT found
        return nil
    }
}

```

Register `FloatToBoolDecodingTypeConverter` with an instance:

```swift
register(FloatToBoolDecodingTypeConverter())
```

### 7. Key-Mapping for `class`:

Cannot adopt `ExCodable` in extension of classes.

```swift
class TestClass: ExCodable, Equatable {
    
    var int: Int = 0
    var string: String? = nil
    init(int: Int, string: String?) {
        (self.int, self.string) = (int, string)
    }
    
    static let keyMapping: [KeyMap<TestClass>] = [
        KeyMap(ref: \.int, to: "int"),
        KeyMap(ref: \.string, to: "string")
    ]
    
    required init(from decoder: Decoder) throws {
        try decodeReference(from: decoder, with: Self.keyMapping)
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
    
    static let keyMappingForTestSubclass: [KeyMap<TestSubclass>] = [
        KeyMap(ref: \.bool, to: "bool")
    ]
    
    required init(from decoder: Decoder) throws {
        try super.init(from: decoder)
        try decodeReference(from: decoder, with: Self.keyMappingForTestSubclass)
    }
    override func encode(to encoder: Encoder) throws {
        try super.encode(to: encoder)
        try encode(to: encoder, with: Self.keyMappingForTestSubclass)
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
let data = try? test.encoded() as Data?
let copy1 = try? data?.decoded() as TestStruct?
let copy2 = data.map { try? TestStruct.decoded(from: $0) }
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
.package(url: "https://github.com/iwill/ExCodable", from: "0.5.0")

```

- [CocoaPods](http://cocoapods.org):

```ruby
pod 'ExCodable', '~> 0.5.0'

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
    static let <#keyMapping#>: [KeyMap<<#SelfType#>>] = [
        KeyMap(\.<#property#>, to: <#"key"#>),
        <#...#>
    ]
    init(from decoder: Decoder) throws {
        try decode<#Reference#>(from: decoder, with: Self.<#keyMapping#>)
    }
    func encode(to encoder: Encoder) throws {
        try encode(to: encoder, with: Self.<#keyMapping#>)
    }
}

```

## Like it?

Hope you like this project, don't forget to give it a star [⭐](https://github.com/iwill/ExCodable#repository-container-header)

[![Stargazers over time](https://starchart.cc/iwill/ExCodable.svg)](https://starchart.cc/iwill/ExCodable)


## Credits

- John Sundell ([@JohnSundell](https://github.com/JohnSundell)) and the ideas from his [Codextended](https://github.com/JohnSundell/Codextended)
- ibireme ([@ibireme](https://github.com/ibireme)) and the features from his [YYModel](https://github.com/ibireme/YYModel)
- Mr. Míng ([@iwill](https://github.com/iwill)) | i+ExCodable@iwill.im

## License

**ExCodable** is released under the MIT license. See [LICENSE](./LICENSE) for details.

