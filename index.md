ExCodable
========

[![ExCodable](https://iwill.im/images/ExCodable-1.x-1920x500.png)](https://github.com/ExCodable/ExCodable#readme)

[![Swift 5.10](https://img.shields.io/badge/Swift-5.10-orange.svg)](https://swift.org/)
[![Swift Package Manager](https://img.shields.io/badge/spm-compatible-brightgreen.svg?style=flat)](https://swift.org/package-manager/)
[![Platforms](https://img.shields.io/cocoapods/p/ExCodable.svg)](#)
<br />
[![Build and Test](https://github.com/ExCodable/ExCodable/actions/workflows/build-and-test.yml/badge.svg)](https://github.com/ExCodable/ExCodable/actions/workflows/build-and-test.yml)
[![GitHub Releases (latest SemVer)](https://img.shields.io/github/v/release/ExCodable/ExCodable.svg?sort=semver)](https://github.com/ExCodable/ExCodable/releases)
[![Deploy to CocoaPods](https://github.com/ExCodable/ExCodable/actions/workflows/deploy_to_cocoapods.yml/badge.svg)](https://github.com/ExCodable/ExCodable/actions/workflows/deploy_to_cocoapods.yml)
[![Cocoapods](https://img.shields.io/cocoapods/v/ExCodable.svg)](https://cocoapods.org/pods/ExCodable)
<br />
[![LICENSE](https://img.shields.io/github/license/ExCodable/ExCodable.svg)](https://github.com/ExCodable/ExCodable/blob/master/LICENSE)
[![@minglq](https://img.shields.io/twitter/url?url=https%3A%2F%2Fgithub.com%2Fiwill%2FExCodable)](https://twitter.com/minglq)

[En](https://github.com/ExCodable/ExCodable) | 中文

ExCodable 是一个 Swift 版 JSON-Model 转换工具，现在迎来重要升级，发布 1.0 版本。

「若非必要，勿造轮子」。但显然，我又造了一个，所以它一定是必要的：

- Swift 内置的 `Codable` 可以满足刚需，但也有官方框架的通病 —— 繁琐
- [Codextended](https://github.com/JohnSundell/Codextended) 想法特别好，对 `Codable` 做了大量的简化，但还是要逐个属性 encode/decode
- 其它 star 较多的 [ObjectMapper](https://github.com/tristanhimmelman/ObjectMapper)、[HandyJSON](https://github.com/alibaba/HandyJSON)、[KakaJSON](https://github.com/kakaopensource/KakaJSON) 等（不知道最近两年有没有新的），不兼容 `Codable`，语法奇怪、繁琐，甚至还有读写内存的，说实话 —— 丑得要死！

ObjC 时代，最好的 JSON-Model 转换非 [YYModel](https://github.com/ibireme/YYModel) 莫属，可惜没有 Swift 版，所以 [自己写一个吧](./0.x.md/#excodable-是我在春节期间带娃之余用了几个晚上完成的一个-swift-版的-json-model-转换工具)。

## 主要特性

```swift
struct TestExCodable: ExAutoCodable {
    @ExCodable
    var int: Int = 0
    @ExCodable("string", "s", "nested.nested.string")
    var string: String? = nil
}

```

上面代码虽少，但足可以体现 ExCodable 的强大。

主要特性：

- ExCodable 是对 Swift 内置的 `Codable` 的扩展，因此可以享受到诸多便利，比如与 `NSCoding`、[SwiftyJSON](https://github.com/SwiftyJSON/SwiftyJSON)、[GenericJSON](https://github.com/iwill/generic-json-swift)、[Alamofire](https://github.com/Alamofire/Alamofire) 等都能无缝对接
- 在属性上添加注解（`@propertyWrapper`）绑定 JSON key，非常简单、直观，JSON key 与属性同名时，可以简写为 `@ExCodable`
- 支持多个候选 JSON key，依次解析
- 使用 `.` 连接多层嵌套的 JSON key
- 需要手动 encode/decode 时，可以使用便捷的 subscript 语法
- 支持常见的数据类型转换，以及灵活的自定义转换
- 支持更灵活的异常处理，出错时默认返回 `nil`，也支持设置抛出 `error`
- 支持 `struct`、`enum`、`class` 以及子类
- 支持 `Data`、`String`、`Array`、`Dictionary` 等 JSON 类型
- 支持类型推断
- 声明实现 `ExAutoCodable` 协议，即可自动获得 `Codable` 方法的默认实现，无需对属性逐个 encode/decode
- 支持 JSON、PList 以及自定义 encoder/decoder，默认使用 JSON
- 非常轻量

## 使用方法

### 1、ExCodable

目前，使用 ExCodable 定义属性需要使用 `var`（可以使用 `private(set)` 避免属性被意外修改），并且要提供默认值。

```swift
struct TestStruct: ExAutoCodable {
    @ExCodable private(set)
    var int: Int = 0
    @ExCodable("string") private(set)
    var string: String? = nil
}

```

### 2、支持多个候选 JSON key

```swift
struct TestAlternativeKeys: ExAutoCodable {
    @ExCodable("string", "str", "s") private(set)
    var string: String! = nil
}

```

### 3、多层嵌套的 JSON 数据

```swift
struct TestNestedKeys: ExAutoCodable {
    @ExCodable("nested.nested.string") private(set)
    var string: String! = nil
}

```

### 4、自动支持 `RawRepresentable` 类型的 `enum`

```swift
enum TestEnum: Int, Codable {
    case zero = 0, one = 1
}

struct TestStructWithEnum: ExAutoCodable {
    @ExCodable private(set)
    var `enum` = TestEnum.zero
}

```

支持非 `RawRepresentable` 类型的 `enum`，需要自定义 encode/decode。

### 5、自定义 Encode/Decode

`@ExCodable` 支持自定义 `encode` 和 `decode`，并且 `encoder`、`decoder` 支持使用 subscript 方式访问。

```swift
struct TestManualEncodeDecode: ExAutoCodable {
    @ExCodable("int", encode: { encoder, value in
        encoder["int"] = value <= 0 ? 0 : value
    }, decode: { decoder in
        if let int: Int = decoder["int"], int > 0 {
            return int
        }
        return 0
    }) private(set)
    var int: Int = 0
}

```

### 6、自动类型转换

ExCodable 支持灵活的类型转换，兼容多层嵌套的 `Optional` 类型，例如 `Int???`。并且这些转换同样适用于 `RawRepresentable` 类型的属性，自动转换到 `RawValue` 类型并调用 `init(rawValue:)`。

A、内置支持的类型转换：

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

B、针对单个属性的自定义类型转换：

```swift
struct TestCustomEncodeDecode: ExAutoCodable {
    @ExCodable("int", decode: { decoder in
        if let string: String = decoder["string"],
           let int = Int(string) {
            return int
        }
        return 0
    }) private(set)
    var int: Int = 0
}

```

C、针对某个 model 的自定义类型转换：

```swift
struct TestCustomTypeConverter: ExAutoCodable {
    @ExCodable("doubleFromBool") private(set)
    var doubleFromBool: Double? = nil
    @ExCodable("floatFromBool") private(set)
    var floatFromBool: Double? = nil
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

D、全局的自定义类型转换：

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

### 7、使用 Subscript 手动 Encode/Decode

对于一个未使用 `ExCodable` 的类型：

```swift
struct TestManualEncodingDecoding {
    let int: Int
    let string: String
}

```

使用 Subscript 手动 encode/decode，要比 Swift 原生语法简单得多：

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

### 8、支持更灵活的异常处理

ExCodable 会默认忽略 JSON-Model 转换时遇到的 `EncodingError.invalidValue`、`DecodingError.keyNotFound`、`DecodingError.valueNotFound` 和 `DecodingError.typeMismatch` 等错误，出错的属性使用默认值。只有 JSON 数据本身有问题时才会抛出错误。

ExCodable 也支持抛出异常：

- 设置 `nonnull: true` 允许抛出 `EncodingError.invalidValue`、`DecodingError.keyNotFound` 和 `DecodingError.valueNotFound`
- 设置 `throws: true` 允许抛出 `DecodingError.typeMismatch`

```swift
struct TestNonnullAndThrows: ExAutoCodable {
    @ExCodable("int", nonnull: true, throws: true) private(set)
    var int: Int! = 0
}

```

### 9、`class` 以及子类

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

### 10、支持类型推断

```swift
struct TestStruct: ExAutoCodable, Equatable {
    @ExCodable("int") private(set)
    var int: Int = 0
    @ExCodable("string") private(set)
    var string: String? = nil
}

let json = Data(#"{"int":200,"string":"OK"}"#.utf8)
let model = try? TestStruct.decoded(from: json)

let dict = try? model.encoded() as [String: Any]
let copy = try? dict.decoded() as TestStruct

```

## 安装

Swift Package Manager:

```swift
.package(url: "https://github.com/ExCodable/ExCodable", from: "1.0.0")

```

CocoaPods:

```ruby
pod 'ExCodable', '~> 1.0.0'

```

## 升级

如果你用过 0.x 版本，非常感谢！但是时候升级了，升级到 1.0 版本有两种方式。

A、继续使用废弃的 API —— 快速、工作量小：

- 全局搜索 `ExCodable`，替换成 `ExCodableDEPRECATED`
- 如果你实现了 `KeyedDecodingContainerCustomTypeConversion` 的 `decodeForTypeConversion(_:codingKey:as:)` 方法，在前面添加一个 `static`

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

B、升级：

- 使用 `ExAutoCodable` 协议替代 `ExCodable`
- 删除 `init(from decoder: Decoder) throws` 方法
- 删除 `keyMapping` 静态属性
- 改用 `@ExCodable("<key>", "<alt-key>", ...)` 绑定 JSON key
- 具体参考上面 [使用方法](#使用方法)、以及代码中的单元测试

## 未来

Swift 5.9 终于引入了 [Macros](https://docs.swift.org/swift-book/documentation/the-swift-programming-language/macros/)，并且非常及时地出现了基于 Macros 的 [MetaCodable](https://github.com/SwiftyLab/MetaCodable)，这是目前最好的实现方式。这让我一度想放弃维护 ExCodable。但是仔细看了一下，调用方式我还是喜欢 ExCodable。

未来 ExCodable 也考虑使用 Macros 实现，在保持目前良好特性的同时，突破 Swift 语法对目前方案的各种限制，敬请期待 —— 不确定多久 🫣

## 感谢

在此，再次，要特别感谢 John Sundell 的 [Codextended](https://github.com/JohnSundell/Codextended) 的非凡创意、以及 ibireme 的 [YYModel](https://github.com/ibireme/YYModel) 的丰富特性给我的极大的启发。

如果你喜欢 ExCodable，欢迎 [给个星星](https://github.com/ExCodable/ExCodable/#repository-container-header) ⭐️ 🤩

使用中遇到任何问题，欢迎 [反馈](https://github.com/iwill/ExCodable/issues/new) / [i+ExCodable@iwill.im](mailto:i+ExCodable@iwill.im)。
