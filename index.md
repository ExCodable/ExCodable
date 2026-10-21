---
layout: default
title: ExCodable
---

ExCodable 2.0
========

[![ExCodable](https://iwill.im/images/ExCodable-1.x-1920x500.png)](https://github.com/ExCodable/ExCodable#readme)

[![Swift 6.4](https://img.shields.io/badge/Swift-6.4-orange.svg)](https://swift.org/)
[![Swift Package Manager](https://img.shields.io/badge/spm-compatible-brightgreen.svg?style=flat)](https://swift.org/package-manager/)
[![Platforms](https://img.shields.io/cocoapods/p/ExCodable.svg)](#)
<br />
[![Build and Test](https://github.com/ExCodable/ExCodable/actions/workflows/build-and-test.yml/badge.svg)](https://github.com/ExCodable/ExCodable/actions/workflows/build-and-test.yml)
[![GitHub Releases (latest SemVer)](https://img.shields.io/github/v/release/ExCodable/ExCodable.svg?sort=semver)](https://github.com/ExCodable/ExCodable/releases)
[![Deploy to CocoaPods](https://github.com/ExCodable/ExCodable/actions/workflows/deploy_to_cocoapods.yml/badge.svg)](https://github.com/ExCodable/ExCodable/actions/workflows/deploy_to_cocoapods.yml)
[![Cocoapods](https://img.shields.io/cocoapods/v/ExCodable.svg)](https://cocoapods.org/pods/ExCodable)
<br />
[![LICENSE](https://img.shields.io/github/license/ExCodable/ExCodable.svg)](https://github.com/ExCodable/ExCodable/blob/master/LICENSE)
[![GitHub stars](https://badgen.net/github/stars/ExCodable/ExCodable)](https://github.com/ExCodable/ExCodable/stargazers/)
[![@minglq](https://img.shields.io/twitter/url?url=https%3A%2F%2Fgithub.com%2Fiwill%2FExCodable)](https://twitter.com/minglq)

[En](https://github.com/ExCodable/ExCodable) \| 中文

--------

ExCodable 是一个 Swift 版 JSON-Model 转换工具。2.0 用 Macros 生成 `init(from:)` 和 `encode(to:)`，属性可以声明为 `let`。备选 key、嵌套 key、类型转换、`default`、`nonnull` / `throws` 都还在。

「若非必要，勿造轮子」。但显然，我又造了一个，所以它一定是必要的：

- Swift 内置的 `Codable` 能用，但也有官方框架的通病 —— 繁琐
- [Codextended](https://github.com/JohnSundell/Codextended) 想法特别好，对 `Codable` 做了大量的简化，但还是要逐个属性 encode/decode
- 其它 star 较多的 [ObjectMapper](https://github.com/tristanhimmelman/ObjectMapper)、[HandyJSON](https://github.com/alibaba/HandyJSON)、[KakaJSON](https://github.com/kakaopensource/KakaJSON) 等等，都不兼容 `Codable`，语法奇怪、繁琐，甚至还有读写内存的

ObjC 时代，最好的 JSON-Model 转换非 [YYModel](https://github.com/ibireme/YYModel) 莫属，可惜没有 Swift 版，所以 [自己写一个吧](./0.x.md/#excodable-是我在春节期间带娃之余用了几个晚上完成的一个-swift-版的-json-model-转换工具)。

## 主要特性

```swift
@ExCodable
struct TestExCodable {
    @ExCodableKey
    let int: Int
    @ExCodableKey("nested.nested.string", "string", "str", "s")
    let string: String?
}

```

上面代码虽少，但足可以体现 ExCodable 的强大。

主要特性：

- ExCodable 是对 Swift 内置的 `Codable` 的扩展，因此可以享受到诸多便利，比如与 `NSCoding`、[SwiftyJSON](https://github.com/SwiftyJSON/SwiftyJSON)、[GenericJSON](https://github.com/iwill/generic-json-swift)、[Alamofire](https://github.com/Alamofire/Alamofire) 等都能无缝对接。
- 在类型上添加 `@ExCodable`，生成 `init(from:)`、`encode(to:)`。`struct` 还会生成成员初始化方法。
- 在属性上添加 `@ExCodableKey` 绑定 JSON key。只有带这个注解的属性会参与 encode/decode。key 与属性同名时，可以简写为 `@ExCodableKey`。
- 属性使用 `let`，并且不能写 `= value`，因为生成的初始化方法会给它赋值。缺 key 或 JSON `null` 需要兜底时，写在 `@ExCodableKey(default:)` 上。
- 不通过 unsafe pointer 读写内存。
- 支持多个候选 JSON key，依次解析。编码使用第一个 key。
- 使用 `.` 拼接多层嵌套的 JSON key。
- 需要手动 encode/decode 时，可以使用便捷的 subscript 语法。
- 支持常见的数据类型转换，以及灵活的自定义转换，包括多层嵌套的 `Optional`。
- 灵活的异常处理，出错时默认得到 `nil`，也支持设置抛出 `error`。
- 支持 `struct`、`class` 以及子类。`RawRepresentable` 属性（包括 `enum`）按 raw value 解析。
- 支持 `Data`、`String`、`Array`、`Dictionary` 等 JSON 格式。
- 支持类型推断。
- 多数情况下不再需要 `CodingKey`，直接写 `String`。
- 支持 JSON、PList 以及自定义 encoder/decoder，默认使用 JSON。
- 非常轻量！

## 使用方法

### 1、ExCodable

`@ExCodable` 为 `struct` 或 `class` 生成 `Codable`。需要参与转换的属性标记 `@ExCodableKey`，用 `let` 声明，不要写 `= value`。解码兜底写在 `@ExCodableKey(default:)` 上。

```swift
@ExCodable
struct TestStruct {
    @ExCodableKey
    let int: Int
    @ExCodableKey("string")
    let string: String?
}

```

### 2、多个候选 JSON key

```swift
@ExCodable
struct TestAlternativeKeys {
    @ExCodableKey("string", "str", "s")
    let string: String!
}

```

### 3、多层嵌套的 JSON key

```swift
@ExCodable
struct TestNestedKeys {
    @ExCodableKey("nested.nested.string")
    let string: String!
}

```

### 4、`RawRepresentable` 类型的 `enum`

根类型不能是 `enum`。`RawRepresentable` 属性（包括 `enum`）会从 raw value 解码。

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

非 `RawRepresentable` 类型的 `enum` 需要自定义的 encode/decode。

### 5、自定义 Encode/Decode

`@ExCodableKey` 支持自定义 `encode` 和 `decode`，并且 `encoder`、`decoder` 支持使用 subscript 方式访问。

如果闭包里没有写出值的类型，需要标明返回类型，例如 `decode: { decoder -> Bool? in ... }`。

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

B、单个属性的自定义类型转换：

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

C、model 中的自定义类型转换：

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
        
        // for nested optionals, e.g. `let int: Int???`
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
@ExCodable
struct TestCustomGlobalTypeConverter: Equatable {
    @ExCodableKey("boolFromDouble")
    let boolFromDouble: Bool?
}

extension ExCodableGlobalDecodingTypeConverter: ExCodableDecodingTypeConverter {
    
    public static func decode<T: Decodable, _K: CodingKey>(_ container: KeyedDecodingContainer<_K>, codingKey: _K, as type: T.Type) -> T? {
        
        // for nested optionals, e.g. `let int: Int???`
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

使用 subscript 手动 encode/decode，要比 Swift 原生语法简单得多：

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

### 8、默认值

`@ExCodableKey` 的参数顺序是 key、`default`、`nonnull`、`throws`、`encode`、`decode`。`default` 用在解码结果为 `nil` 的时候：key 不存在、JSON 值是 `null`，或者类型不匹配被忽略。

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

缺 key 和 JSON `null` 是同一种缺失，都会使用 `default`。`default` 不能和 `nonnull` 或 `throws` 写在一起，宏会直接报错。

### 9、更灵活的异常处理

ExCodable 默认忽略 JSON-Model 转换时遇到的 `EncodingError.invalidValue`、`DecodingError.keyNotFound`、`DecodingError.valueNotFound` 和 `DecodingError.typeMismatch`，结果为 `nil`。只有 JSON 数据本身有问题时才会抛出错误。

没有 `default` 时，缺 key 不会退回属性声明上的值：

- 可选属性（包括隐式解包可选）没有解析到值时为 `nil`
- 非可选属性没有解析到值时抛出 `DecodingError.valueNotFound`

也可以在出错时终止转换：

- 设置 `nonnull: true` 允许抛出 `EncodingError.invalidValue` 和 `DecodingError.keyNotFound`。缺 key 和 JSON `null` 都抛出 `keyNotFound`
- 设置 `throws: true` 允许抛出 `DecodingError.typeMismatch`

```swift
@ExCodable
struct TestNonnullAndThrows {
    @ExCodableKey(nonnull: true, throws: true)
    let int: Int!
}

```

### 10、`class` 以及子类

`class` 的初始化方法要给这些 `let` 赋值。子类同样加上 `@ExCodable`。

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

如果 `class` 自己实现了 `==`，把 `Equatable` 声明在 extension 里。写在类型声明上时，`@ExCodable` 增加的 extension 可能让 `==` 产生歧义。

### 11、类型推断

```swift
@ExCodable
struct TestStruct: Equatable {
    @ExCodableKey
    let int: Int
    @ExCodableKey
    let string: String?
}

// 正常的转换
let json = Data(#"{"int":200,"string":"OK"}"#.utf8)
let model = try? TestStruct.decoded(from: json)

// 类型推断
let dict = try? model.encoded() as [String: Any]
let copy = try? dict.decoded() as TestStruct

```

> 更多用法参考代码中的单元测试。

## 系统要求

- iOS 15.0+ | tvOS 15.0+ | macOS 12.0+ | watchOS 9.0+
- Xcode 27+
- Swift 6.4+

## 安装

Swift Package Manager:

```swift
.package(url: "https://github.com/ExCodable/ExCodable", from: "2.0.0")
```

`@ExCodable` 和 `@ExCodableKey` 是宏。Swift Package Manager 会加载编译器插件。CocoaPods 不会，所以 CocoaPods 集成时这些宏不会展开。

## 升级

### 1.x 到 2.x

- 把 `struct Model: ExAutoCodable` 改成 `@ExCodable struct Model`
- 把 `@ExCodable var property: T = fallback` 改成 `@ExCodableKey(default: fallback) let property: T`。`let` 上不再写 `=`
- 子类同样加上 `@ExCodable`
- `class` 的初始化方法要给不再有默认值的 `let` 赋值
- 自定义 `decode` 闭包可能要写明返回类型，例如 `{ decoder -> Bool? in ... }`

### 0.x 到 2.x

2.0 不再包含 `KeyMap`、`ExCodableDEPRECATED` 和 `ExAutoCodable`。直接改成当前写法：

- 删除 `init(from decoder: Decoder) throws`
- 删除 `keyMapping`
- 类型加上 `@ExCodable`
- 用 `@ExCodableKey("<key>", "<alt-key>", ...)` 标记 `let` 属性，不要默认值
- 具体参考上面 [使用方法](#使用方法)

```swift
@ExCodable
struct TestExCodable {
    @ExCodableKey
    let int: Int
    @ExCodableKey("nested.nested.string", "string", "str", "s")
    let string: String?
}

```

## 星星

如果你喜欢 ExCodable，欢迎 [给个星星](https://github.com/ExCodable/ExCodable#repository-container-header) ⭐️ 🤩

## 致敬

在此，再次，致敬 John Sundell 和 ibireme，[Codextended](https://github.com/JohnSundell/Codextended) 的非凡创意和 [YYModel](https://github.com/ibireme/YYModel) 的丰富特性给了我的极大的启发！

## 关于

我是 [Míng](https://github.com/iwill)，使用中遇到任何问题，欢迎 [反馈](https://github.com/ExCodable/ExCodable/issues) / [i+ExCodable@iwill.im](mailto:i+ExCodable@iwill.im)。

## 开源

[代码](https://github.com/ExCodable/ExCodable) 在 [MIT](https://github.com/ExCodable/ExCodable/blob/master/LICENSE) 协议下开源。
