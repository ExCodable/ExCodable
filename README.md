# ExCodable

[![Swift 5.0](https://img.shields.io/badge/Swift-5.0-orange.svg)](https://swift.org/)
[![Swift Package Manager](https://img.shields.io/badge/spm-compatible-brightgreen.svg?style=flat)](https://swift.org/package-manager/)
![Platforms](https://img.shields.io/cocoapods/p/ExCodable.svg)
[![Build and Test](https://github.com/iwill/ExCodable/actions/workflows/build-and-test.yml/badge.svg)](https://github.com/iwill/ExCodable/actions/workflows/build-and-test.yml)
[![GitHub Releases (latest SemVer)](https://img.shields.io/github/v/release/iwill/ExCodable.svg?sort=semver)](https://github.com/iwill/ExCodable/releases)
[![Deploy to CocoaPods](https://github.com/iwill/ExCodable/actions/workflows/deploy_to_cocoapods.yml/badge.svg)](https://github.com/iwill/ExCodable/actions/workflows/deploy_to_cocoapods.yml)
[![Cocoapods](https://img.shields.io/cocoapods/v/ExCodable.svg)](https://cocoapods.org/pods/ExCodable)
[![LICENSE](https://img.shields.io/github/license/iwill/ExCodable.svg)](./LICENSE)
[![@minglq](https://img.shields.io/twitter/url?url=https%3A%2F%2Fgithub.com%2Fiwill%2FExCodable)](https://twitter.com/minglq)

En | [中文](https://iwill.im/ExCodable/)

**ExCodable** - Key-Mapping Extensions for Swift Codable.

## Contents

- [Features](#features)
- [Usage](#usage)
- [Requirements](#requirements)
- [Installation](#installation)
- [Credits](#credits)
- [License](#license)

## Features

- Supports Key-Mapping with `KeyPath` and JSON-Key:
    - ExCodable did not read/write memory via unsafe pointers;
    - No need to encode/decode properties one by one;
    - Just requires using `var` to declare properties and provide default values;
    - In most cases, the `CodingKey` type is no longer necessary, because it will only be used once, `String` literals may be better.
- Supports multiple Alternative-Keys via `Array` for decoding;
- Supports Nested-Keys via `String` with dot syntax;
- Supports custom encode/decode handlers via closures;
- Supports encode/decode via subscripts;
- Supports builtin and custom Type-Conversions;
- Supports `struct`, `class` and subclass;
- Uses JSON encoder/decoder by default, and supports PList;
- Uses Type-Inference, supports JSON `Data`, `String` and `Object`;
- Returns `Optional` values instead of throwing errors, to avoid frequent use of `try?`.

## Usage

### 1. Key-Mapping for `struct`:

> Requires using `var` to declare properties and provide default values.

```swift
struct TestStruct: Equatable {
    private(set) var int: Int = 0
    private(set) var string: String = ""
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

### 2. Key-Mapping for `class`:

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

### 3. Key-Mapping for subclass:

> Requires declaring another static Key-Mapping for subclass.

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

### 4. Alternative-Keys:

```swift
static var keyMapping: [KeyMap<Self>] = [
    KeyMap(\.int, to: "int", "i"),
    KeyMap(\.string, to: "string", "str", "s")
]
```

### 5. Nested-Keys:

```swift
static var keyMapping: [KeyMap<Self>] = [
    KeyMap(\.int, to: "nested.int"),
    KeyMap(\.string, to: "nested.nested.string")
]
```

### 6. Custom encode/decode handlers

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

### 8. Custom Type-Conversions:

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

- iOS 8.0+ | tvOS 9.0+ | macOS X 10.10+ | watchOS 2.0+
- Xcode 12.0+
- Swift 5.0+

## Installation

- [Swift Package Manager](https://swift.org/package-manager/):

```swift
.package(url: "https://github.com/iwill/ExCodable", from: "0.2")
```

- [CocoaPods](http://cocoapods.org):

```ruby
pod 'ExCodable', '~> 0.2'
```

- Code Snippets:

> Language: Swift  
> Platform: All  
> Completion: excodable  
> Availability: Top Level  

```swift
<#extension/struct/class#> <#Type#>: ExCodable {
    
    static var <#keyMapping#>: [KeyMap<<#Type#>>] = [
        KeyMap(\.<#property#>, to: <#"key"#>),
        <#...#>
    ]
    
    init(from decoder: Decoder) throws {
        decode(with: Self.<#keyMapping#>, using: decoder)
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
