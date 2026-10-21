[![ExCodable](https://iwill.im/images/ExCodable-1.x-1920x500.png)](#readme)

[![Swift 6.4](https://img.shields.io/badge/Swift-6.4-orange.svg)](https://swift.org/)
[![Swift Package Manager](https://img.shields.io/badge/spm-compatible-brightgreen.svg?style=flat)](https://swift.org/package-manager/)
[![Platforms](https://img.shields.io/cocoapods/p/ExCodable.svg)](#readme)
<br />
[![Build and Test](https://github.com/ExCodable/ExCodable/actions/workflows/build-and-test.yml/badge.svg)](https://github.com/ExCodable/ExCodable/actions/workflows/build-and-test.yml)
[![GitHub Releases (latest SemVer)](https://img.shields.io/github/v/release/ExCodable/ExCodable.svg?sort=semver)](https://github.com/ExCodable/ExCodable/releases)
[![Deploy to CocoaPods](https://github.com/ExCodable/ExCodable/actions/workflows/deploy_to_cocoapods.yml/badge.svg)](https://github.com/ExCodable/ExCodable/actions/workflows/deploy_to_cocoapods.yml)
[![Cocoapods](https://img.shields.io/cocoapods/v/ExCodable.svg)](https://cocoapods.org/pods/ExCodable)
<br />
[![LICENSE](https://img.shields.io/github/license/ExCodable/ExCodable.svg)](https://github.com/ExCodable/ExCodable/blob/master/LICENSE)
[![GitHub stars](https://badgen.net/github/stars/ExCodable/ExCodable)](https://github.com/ExCodable/ExCodable/stargazers/)
[![@minglq](https://img.shields.io/twitter/url?url=https%3A%2F%2Fgithub.com%2Fiwill%2FExCodable)](https://twitter.com/minglq)

En | [中文](https://excodable.iwill.im/)

## What's New in ExCodable 2.0

- Uses `@ExCodable` and `@ExCodableKey` to generate `init(from:)` and `encode(to:)`.
- Properties can be declared with `let`.
- Keeps alternative keys, nested keys, type conversions, `default`, and `nonnull` / `throws`.

## Documentations

- [Features](#features)
- [Usage](#usage)
- [Requirements](#requirements)
- [Installation](#installation)
- [Migration](#migration)

## Features

```swift
@ExCodable
struct TestExCodable {
    @ExCodableKey
    let int: Int
    @ExCodableKey("nested.nested.string", "string", "str", "s")
    let string: String?
}

```

- Converts between JSON and models.
- Based on and Extends Swift **`Codable`**.
- Associates JSON keys to properties via **macros**:
    - `@ExCodable` generates `init(from:)`, `encode(to:)`, and a memberwise `init` for a struct.
    - Only properties marked with `@ExCodableKey` are encoded and decoded.
    - `let` is supported. A `let` cannot also have `= value`, because the generated initializer assigns it. Use `@ExCodableKey(default:)` when a missing or null JSON value should fall back to a value.
    - `ExCodable` did not read/write memory via unsafe pointers.
    - No need to encode and decode properties one by one.
    - In most cases, the `CodingKey` types are no longer necessary, `String` literals are preferred.
- Supports **alternative keys** for decoding.
- Supports **nested keys** via `String` with dot syntax.
- Supports builtin and custom **type conversions**, including **nested optionals** as well.
- Supports manual encoding/decoding using **subscripts**.
- Supports `return nil` or `throw error` when encoding/decoding failed.
- Supports `struct`, `class` and subclasses. `RawRepresentable` properties, including `enum` and optional `enum`, are decoded from their raw values.
- Supports JSON `Data`, `String`, `Array` and `Dictionary`.
- Supports **type inference**.
- Uses JSON encoder/decoder by default, supports PList and custom encoder/decoder.
- Super lightweight.

## Usage

<!--

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
@ExCodable
struct TestExCodable {
    @ExCodableKey
    let int: Int
    @ExCodableKey("nested.nested.string", "string", "s")
    let string: String?
}

```

-->

### 1. ExCodable

`@ExCodable` generates `Codable` for a struct or class. Mark each coded property with `@ExCodableKey`. Declare those properties with `let` and without `= value`. A decode fallback belongs on `@ExCodableKey(default:)`.

```swift
@ExCodable
struct TestStruct {
    @ExCodableKey
    let int: Int
    @ExCodableKey("string")
    let string: String?
}

```

### 2. Alternative Keys

```swift
@ExCodable
struct TestAlternativeKeys {
    @ExCodableKey("string", "str", "s")
    let string: String!
}

```

### 3. Nested Keys

```swift
@ExCodable
struct TestNestedKeys {
    @ExCodableKey("nested.nested.string")
    let string: String!
}

```

### 4. `enum`

```swift
enum TestEnum: Int, Codable {
    case zero = 0, one = 1
}

@ExCodable
struct TestStructWithEnum {
    @ExCodableKey("enum")
    let `enum`: TestEnum
}

```

### 5. Custom Encoding/Decoding

```swift
@ExCodable
struct TestManualEncodeDecode {
    @ExCodableKey(encode: { encoder, value in
        encoder["int"] = value <= 0 ? 0 : value
    }, decode: { decoder in
        if let int: Int = decoder["int"], int > 0 {
            return int
        }
        return 0
    })
    let int: Int
}

```

### 6. Type Conversions

ExCodable builtin type conversions:

- boolean:
    - `Bool`
    - `Int`, `Int8`, `Int16`, `Int32`, `Int64`
    - `UInt`, `UInt8`, `UInt16`, `UInt32`, `UInt64`
    - `String`
- integer:
    - `Bool`
    - `Int`, `Int8`, `Int16`, `Int32`, `Int64`
    - `UInt`, `UInt8`, `UInt16`, `UInt32`, `UInt64`
    - `Double`, `Float`
    - `String`
- float:
    - `Int`, `Int8`, `Int16`, `Int32`, `Int64`
    - `UInt`, `UInt8`, `UInt16`, `UInt32`, `UInt64`
    - `Double`, `Float`
    - `String`
- string:
    - `Bool`
    - `Int`, `Int8`, `Int16`, `Int32`, `Int64`
    - `UInt`, `UInt8`, `UInt16`, `UInt32`, `UInt64`
    - `Double`, `Float`
    - `String`

Custom type conversions for specific properties:

If a closure does not mention its value type, write the return type explicitly, for example `decode: { decoder -> Bool? in ... }`.

```swift
@ExCodable
struct TestCustomEncodeDecode {
    @ExCodableKey(decode: { decoder in
        if let string: String = decoder["string"] {
            return string.count
        }
        return 0
    })
    let int: Int
}

```

Custom type conversions for specific model:

```swift
@ExCodable
struct TestCustomTypeConverter {
    @ExCodableKey
    let doubleFromBool: Double?
    @ExCodableKey
    let floatFromBool: Double?
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
@ExCodable
struct TestCustomGlobalTypeConverter: Equatable {
    @ExCodableKey("boolFromDouble")
    let boolFromDouble: Bool?
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

### 7. Manual Encoding/Decoding using Subscripts

A type without `ExCodable`:

```swift
struct TestManualEncodingDecoding {
    let int: Int
    let string: String
}

```

Manual encoding/decoding using subscripts:

```swift
extension TestManualEncodingDecoding: Codable {
    
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

### 8. `default`

`@ExCodableKey` parameters are ordered `key`, `default`, `nonnull`, `throws`, `encode`, `decode`. `default` is the value assigned when decoding returns `nil`: the key is missing, the JSON value is `null`, or a type mismatch is ignored.

```swift
@ExCodable
struct TestDefault: Equatable {
    @ExCodableKey("int", default: 0)
    let int: Int
    @ExCodableKey("string", default: "default")
    let string: String
}

let missing = try TestDefault.decoded(from: Data(#"{}"#.utf8))
// TestDefault(int: 0, string: "default")

let nulls = try TestDefault.decoded(from: Data(#"{"int":null,"string":null}"#.utf8))
// TestDefault(int: 0, string: "default")

let values = try TestDefault.decoded(from: Data(#"{"int":418,"string":"I'm a teapot"}"#.utf8))
// TestDefault(int: 418, string: "I'm a teapot")

```

A missing key and JSON `null` are the same absence, so both use `default`. `@ExCodableKey` rejects `default` written together with `nonnull` or `throws`.

### 9. `return nil` or `throw error`

Without `default`, a `nil` decode result becomes `nil` for an optional and throws `DecodingError.valueNotFound` for a non-optional `let`.

While encoding/decoding, ExCodable ignores the `keyNotFound`, `valueNotFound`, `invalidValue` and `typeMismatch` errors and `return nil` by default, only throws JSON errors.

ExCodable also supports throw errors:

- Use `nonnull: true` to throw `EncodingError.invalidValue` and `DecodingError.keyNotFound`. A missing key and JSON `null` both throw `keyNotFound`.
- Use `throws: true` to throw `DecodingError.typeMismatch`.

```swift
@ExCodable
struct TestNonnullAndThrows {
    @ExCodableKey(nonnull: true, throws: true)
    let int: Int!
}

```

### 10. `class` and Subclasses

```swift
@ExCodable
class TestClass {
    @ExCodableKey
    let int: Int
    @ExCodableKey
    let string: String?
    required init() {
        (self.int, self.string) = (0, nil)
    }
    init(int: Int, string: String?) {
        (self.int, self.string) = (int, string)
    }
}

```

```swift
@ExCodable
class TestSubclass: TestClass {
    @ExCodableKey
    let bool: Bool
    required init() {
        self.bool = false
        super.init()
    }
    required init(int: Int, string: String, bool: Bool) {
        self.bool = bool
        super.init(int: int, string: string)
    }
}

```

If a class implements `==`, declare `Equatable` in an extension. Writing `Equatable` on the class itself can make `==` ambiguous once `@ExCodable` adds its extension.

### 11. Type Inference

```swift
@ExCodable
struct TestStruct: Equatable {
    @ExCodableKey
    let int: Int
    @ExCodableKey
    let string: String?
}

let json = Data(#"{"int":200,"string":"OK"}"#.utf8)
let model = try? TestStruct.decoded(from: json)

let dict = try? model.encoded() as [String: Any]
let copy = try? dict.decoded() as TestStruct

```

> See the tests for more examples.

## Requirements

- iOS 15.0+ | tvOS 15.0+ | macOS 12.0+ | watchOS 9.0+
- Xcode 27+
- Swift 6.4+

## Installation

Swift Package Manager:

```swift
.package(url: "https://github.com/ExCodable/ExCodable", from: "2.0.0")

```

`@ExCodable` and `@ExCodableKey` are macros. Swift Package Manager loads the compiler plugin. CocoaPods does not, so the macros are not expanded in a CocoaPods build.

## Migration

### 0.x to 1.x

When you update to ExCodable 1.0.

Step 1: Update your code to use the old API - **DEPRECATED** but quick.

- Replace protocol `ExCodable` with `ExCodableDEPRECATED`.
- Add `static` to func `decodeForTypeConversion(_:codingKey:as:)` of protocol `KeyedDecodingContainerCustomTypeConversion`.

```swift
struct TestExCodable {
    private(set) var int: Int = 0
    private(set) var string: String?
}

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

Step 2: Upgrade your models to the current API one by one - SUGGESTED:

- Replace `protocol` `ExCodable` with `@ExCodable`.
- Remove initializer `init(from decoder: Decoder) throws`.
- Remove `static` properties `keyMapping`.
- Use `@ExCodableKey("<key>", "<alt-key>", ...)` on `let` properties.
- See [Usage](#usage) for more details.

```swift
@ExCodable
struct TestExCodable {
    @ExCodableKey
    let int: Int
    @ExCodableKey("nested.nested.string", "string", "str", "s")
    let string: String?
}

```

### 1.x to 2.x

- Replace `struct Model: ExAutoCodable` with `@ExCodable struct Model`.
- Change `@ExCodable var property: T = fallback` to `@ExCodableKey(default: fallback) let property: T`. The `let` has no `=`.
- Put `@ExCodable` on subclasses as well.
- A class initializer must assign every `let` that no longer has a default value.
- A custom `decode` closure may need an explicit return type, for example `{ decoder -> Bool? in ... }`.

## Stars

<a href="#">
    <img alt="Star Chart" src="https://starchart.cc/ExCodable/ExCodable.svg" width="600px">
</a>

Hope ExCodable will help you! [Make a star](https://github.com/ExCodable/ExCodable/#repository-container-header) ⭐️ 🤩

## Thanks to

- John Sundell ([@JohnSundell](https://github.com/JohnSundell)) and the ideas from his [Codextended](https://github.com/JohnSundell/Codextended)
- ibireme ([@ibireme](https://github.com/ibireme)) and the features from his [YYModel](https://github.com/ibireme/YYModel)

## About Me

- Míng ([@iwill](https://github.com/iwill)) | i+ExCodable@iwill.im

## License

**ExCodable** is released under the MIT license. See [LICENSE](./LICENSE) for details.
