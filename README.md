[![ExCodable](https://iwill.im/images/ExCodable-1920x500.png)](#readme)

[![Swift 5.0](https://img.shields.io/badge/Swift-5.0-orange.svg)](https://swift.org/)
[![Swift Package Manager](https://img.shields.io/badge/spm-compatible-brightgreen.svg?style=flat)](https://swift.org/package-manager/)
[![Platforms](https://img.shields.io/cocoapods/p/ExCodable.svg)](#readme)
<br />
[![Build and Test](https://github.com/ExCodable/ExCodable/actions/workflows/build-and-test.yml/badge.svg)](https://github.com/ExCodable/ExCodable/actions/workflows/build-and-test.yml)
[![GitHub Releases (latest SemVer)](https://img.shields.io/github/v/release/ExCodable/ExCodable.svg?sort=semver)](https://github.com/ExCodable/ExCodable/releases)
[![Deploy to CocoaPods](https://github.com/ExCodable/ExCodable/actions/workflows/deploy_to_cocoapods.yml/badge.svg)](https://github.com/ExCodable/ExCodable/actions/workflows/deploy_to_cocoapods.yml)
[![Cocoapods](https://img.shields.io/cocoapods/v/ExCodable.svg)](https://cocoapods.org/pods/ExCodable)
<br />
[![LICENSE](https://img.shields.io/github/license/ExCodable/ExCodable.svg)](https://github.com/ExCodable/ExCodable/blob/master/LICENSE)
[![@minglq](https://img.shields.io/twitter/url?url=https%3A%2F%2Fgithub.com%2Fiwill%2FExCodable)](https://twitter.com/minglq)

En | [中文](https://iwill.im/ExCodable/)

## What's New in ExCodable 1.0

- Uses `@propertyWrapper` instead of key-mapping, the new syntax is more concise, elegant and easier to use.
- Optimized type conversions.
- Fix bugs.

## Documentations

- [Features](#features)
- [Usage](#usage)
- [Requirements](#requirements)
- [Installation](#installation)
- [Migration](#migration)

## Features

```swift
struct TestExCodable: ExAutoCodable {
    @ExCodable private(set)
    var int: Int = 0
    @ExCodable("nested.nested.string", "string", "str", "s") private(set)
    var string: String? = nil
}

```

- Converts between JSON and models.
- Based on and Extends Swift **`Codable`**.
- Associates JSON keys to properties via **annotations** - `@propertyWrapper`:
    - `ExCodable` did not read/write memory via unsafe pointers.
    - No need to encode and decode properties one by one.
    - In most cases, the `CodingKey` types are no longer necessary, `String` literals are preferred.
    - Currently, requires declaring properties with `var` and provide default values.
- Supports `struct`, `enum`, `class` and subclasses.
- Supports **alternative keys** for decoding.
- Supports **nested keys** via `String` with dot syntax.
- Supports builtin and custom **type conversions**, including **nested optionals** as well.
- Supports manual encoding/decoding using **subscripts**.
- Supports **continue or abort** if error encountered - returns nil or throws error.
- Supports **type inference**, including JSON `Data`, `String` and objects.
- Uses JSON encoder/decoder by default, supports PList and custom encoder/decoder.

<mark>TODO:</mark>

- [ ] Supports `let`.
- [ ] Supports `var` without default values.
- [ ] Replacing `ExAutoCodable` with `Codable`.

## Usage

### 0. `Codable` vs `ExCodable`:

Swift builtin `Codable` is quite convenient, you just need:

```swift
struct TestAutoCodable: Codable {
    private(set) var int: Int = 0
    private(set) var string: String?
    // the case `int` can be omitted, since the key is the same as its property name
    enum CodingKeys: String, CodingKey {
        case int = "int", string = "s"
    }
}

```

But, if you need some advanced features, e.g. alternative keys, nested keys or type conversions, you have to:

```swift
struct TestManualCodable {
    private(set) var int: Int = 0
    private(set) var string: String?
}

extension TestManualCodable: Codable {
    
    enum Keys: CodingKey {
        case int
        case nested, string, s
    }
    
    init(from decoder: Decoder) throws {
        if let container = try? decoder.container(keyedBy: Keys.self) {
            if let int = try? container.decodeIfPresent(Int.self, forKey: Keys.int) {
                self.int = int
            }
            if let nestedContainer = try? container.nestedContainer(keyedBy: Keys.self, forKey: Keys.nested),
               let nestedNestedContainer = try? nestedContainer.nestedContainer(keyedBy: Keys.self, forKey: Keys.nested),
               let string = try? nestedNestedContainer.decodeIfPresent(String.self, forKey: Keys.string) {
                self.string = string
            }
            else if let string = (try? container.decodeIfPresent(String.self, forKey: Keys.string))
                        ?? (try? container.decodeIfPresent(String.self, forKey: Keys.s)) {
                self.string = string
            }
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: Keys.self)
        try? container.encodeIfPresent(int, forKey: Keys.int)
        var nestedContainer = container.nestedContainer(keyedBy: Keys.self, forKey: Keys.nested)
        var nestedNestedContainer = nestedContainer.nestedContainer(keyedBy: Keys.self, forKey: Keys.nested)
        try? nestedNestedContainer.encodeIfPresent(string, forKey: Keys.string)
    }
}

```

🤯

Fortunately, you can use **`ExCodable`**:

```swift
struct TestExCodable: ExAutoCodable {
    @ExCodable private(set)
    var int: Int = 0
    @ExCodable("nested.nested.string", "string", "s") private(set)
    var string: String? = nil
}

```

### 1. `struct`

`ExCodable` requires declaring properties with `var` and provide default values.

```swift
// Equatable for Assertions
struct TestStruct: ExAutoCodable, Equatable {
    @ExCodable("int") private(set)
    var int: Int = 0
    @ExCodable("string") private(set)
    var string: String? = nil
}

```

### 2. Alternative Keys

```swift
struct TestAlternativeKeys: ExAutoCodable {
    @ExCodable("int", "i") private(set)
    var int: Int = 0
    @ExCodable("string", "str", "s") private(set)
    var string: String! = nil
}

```

### 3. Nested Keys

```swift
struct TestNestedKeys: ExAutoCodable {
    @ExCodable private(set)
    var int: Int = 0
    @ExCodable("nested.nested.string") private(set)
    var string: String! = nil
}

```

### 4. `enum`

```swift
enum TestEnum: Int, Codable {
    case zero = 0, one = 1
}

struct TestStructWithEnum: ExAutoCodable {
    @ExCodable("enum") private(set)
    var `enum` = TestEnum.zero
}

```

### 5. Type Conversions

ExCodable builtin type conversions:

- Decoding `Bool` **from** `Int`, `String`
- Decoding `Int`, `Int8`, `Int16`, `Int32`, `Int64` **from** `Bool`, `Double`, `String`
- Decoding `UInt`, `UInt8`, `UInt16`, `UInt32`, `UInt64` **from** `Bool`, `String`
- Decoding `Double`, `Float` **from** `Int64`, `String`
- Decoding `String` **from** `Bool`, `Int64`, `Double`

Custom type conversions for specific properties:

```swift
struct TestCustomEncodeDecode: ExAutoCodable {
    
    @ExCodable private(set)
    var int: Int = 0
    
    @ExCodable(encode: { encoder, value in
        // skip encoding
    }, decode: { decoder in
        // custom decoding
        if let int: Int = decoder["int"] {
            return message(for: int)
        }
        return nil
    }) private(set)
    var string: String? = nil
}

```

Custom type conversions for specific type:

```swift
struct TestCustomTypeConverter: ExAutoCodable {
    @ExCodable("doubleFromBool") private(set)
    var doubleFromBool: Double? = nil
}

extension TestCustomTypeConverter: ExCodableDecodingTypeConverter {
    public static func decode<T: Decodable, K: CodingKey>(_ container: KeyedDecodingContainer<K>, codingKey: K, as type: T.Type) -> T? {
        
        // for nested optionals, e.g. `var int: Int??? = nil`
        let wrappedType = T?.wrappedType
        
        // decode Double from Bool
        if type is Double.Type || wrappedType is Double.Type {
            if let bool = try? container.decodeIfPresent(Bool.self, forKey: codingKey) {
                return (bool ? 1.0 : 0.0) as? T
            }
        }
        // decode Float from Bool
        else if type is Float.Type || wrappedType is Float.Type {
            if let bool = try? container.decodeIfPresent(Bool.self, forKey: codingKey) {
                return (bool ? 1.0 : 0.0) as? T
            }
        }
        
        return nil
    }
}

```

Custom type conversions for global:

```swift
struct TestCustomGlobalTypeConverter: ExAutoCodable, Equatable {
    @ExCodable("boolFromDouble") private(set)
    var boolFromDouble: Bool? = nil
}

extension ExCodableGlobalDecodingTypeConverter: ExCodableDecodingTypeConverter {
    public static func decode<T: Decodable, _K: CodingKey>(_ container: KeyedDecodingContainer<_K>, codingKey: _K, as type: T.Type) -> T? {
        
        // for nested optionals, e.g. `var int: Int??? = nil`
        let wrappedType = T?.wrappedType
        
        // decode Bool from Double
        if type is Bool.Type || wrappedType is Bool.Type {
            if let double = try? container.decodeIfPresent(Double.self, forKey: codingKey) {
                return (double != 0) as? T
            }
        }
        
        return nil
    }
}

```

### 6. Constants, Manual Encoding/Decoding using Subscripts

Declaring constants without default values:

```swift
struct TestSubscript {
    let int: Int
    let string: String
}

```

Manual encoding/decoding using subscripts:

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

### 7. `class` and Subclasses

```swift
class TestClass: ExAutoCodable {
    @ExCodable private(set)
    var int: Int = 0
    @ExCodable private(set)
    var string: String? = nil
    
    required init() {}
    init(int: Int, string: String?) {
        (self.int, self.string) = (int, string)
    }
}

```

```swift
class TestSubclass: TestClass {
    
    @ExCodable private(set)
    var bool: Bool = false
    
    required init() { super.init() }
    required init(int: Int, string: String, bool: Bool) {
        self.bool = bool
        super.init(int: int, string: string)
    }
    
}

```

### 8. Continue or Abort

```swift
encoding/decoding
nonnull || `throws`

```

### 9. Type Inference

```swift
let test = TestStruct(int: 304, string: "Not Modified"),
    test2 = TestStruct(int: 304, string: "Not Modified")
// type of `data` inferenced from `Data`
// types of `copy` and `copy2` inferenced from `TestStruct`
if let data = try? test.encoded() as Data,
   let copy = try? data.decoded() as TestStruct,
   let copy2 = try? TestStruct.decoded(from: data) {
    XCTAssertEqual(copy, test)
    XCTAssertEqual(copy2, test2)
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
.package(url: "https://github.com/ExCodable/ExCodable", from: "1.0.0")

```

- [CocoaPods](http://cocoapods.org):

```ruby
pod 'ExCodable', '~> 1.0.0'

```

- Code Snippets:

> Title: ExCodable
> Summary: Adopt to ExCodable protocol
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

## Migration

### 0.x to 1.x

Quickly, but **DEPRECATED**:

- Replace protocol `ExCodable` with `ExCodableDEPRECATED`.
- Add `static` to func `decodeForTypeConversion(_:codingKey:as:)` of protocol `KeyedDecodingContainerCustomTypeConversion`.

```swift
struct TestExCodable {
    private(set) var int: Int = 0
    private(set) var string: String?
}

// replacing protocol `ExCodable`(0.x) with `ExCodableDEPRECATED`(1.x)
extension TestExCodable: ExCodableDEPRECATED {
    static let keyMapping: [KeyMap<Self>] = [
        KeyMap(\.int, to: "int"),
        KeyMap(\.string, to: "nested.nested.string", "string", "str", "s")
    ]
    init(from decoder: Decoder) throws {
        try decode(from: decoder, with: Self.keyMapping)
    }
}

```

Upgrade, SUGGESTED:

- Replace `ExCodable` with `ExAutoCodable`.
- Remove `static` properties `keyMapping`.
- Remove initializer `init(from decoder: Decoder) throws`.
- Use `@ExCodable("<key>", "<alt-key>")`.
- See [Usage](#usage) for more details.

```swift
struct TestExCodable: ExAutoCodable {
    @ExCodable private(set)
    var int: Int = 0
    @ExCodable("nested.nested.string", "string", "str", "s") private(set)
    var string: String?
}

```

## Stars

<a href="#">
    <img alt="Star Chart" src="https://starchart.cc/iwill/ExCodable.svg" width="600px">
</a>

Hope ExCodable will help you! [Make a star](https://github.com/ExCodable/ExCodable/#repository-container-header) ⭐️ 🤩

## Thanks to

- John Sundell ([@JohnSundell](https://github.com/JohnSundell)) and the ideas from his [Codextended](https://github.com/JohnSundell/Codextended)
- ibireme ([@ibireme](https://github.com/ibireme)) and the features from his [YYModel](https://github.com/ibireme/YYModel)

## About Me

- Míng ([@iwill](https://github.com/iwill)) | i+ExCodable@iwill.im

## License

**ExCodable** is released under the MIT license. See [LICENSE](./LICENSE) for details.
