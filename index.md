[ExCodable](https://github.com/iwill/ExCodable) 是作者在春节期间、带娃之余、用了几个晚上完成的一个 Swift 版的 JSON-Model 转换工具。

别走！看到前面的介绍大家心里可能想“嗷，又一个轮子”，但是 ExCodable 真的有点不一样：
- 它是在 Swift Codable 基础上的扩展；
- 基于 `KeyPath` 读写属性，实现了 Key-Mapping；
- 差不多实现了 YYModel 的所有特性；
- 1 个文件、500 行代码。

----

近期我们团队准备开始使用 Swift，第一选择当然是站上巨人的肩膀。节前开始寻找一些开源框架，比如网络请求用 [Alamofire](https://github.com/Alamofire/Alamofire)、自动布局用 [SnapKit](https://github.com/SnapKit/SnapKit)，毫无悬念。但是 JSON-Model 转换并没有找到一个合适的。

GitHub 上 Star 比较多的有几种类型：
- 刀耕火种型：这种框架用于读写 JSON，至于 Model 是不管的，比如 [SwiftyJSON](https://github.com/SwiftyJSON/SwiftyJSON) —— 适用于少量使用、Model 很简单甚至没有的情况。
- 优雅绅士型：Swift 内置的 Codable 是可以满足刚需的，但也有官方框架的通病 —— 繁琐，[Codextended](https://github.com/JohnSundell/Codextended) 对其做了大量的简化，但还是要逐个属性 Encode/Decode —— 适用于 Model 相对简单的场景。
- 八仙过海型：[ObjectMapper](https://github.com/tristanhimmelman/ObjectMapper)、[HandyJSON](https://github.com/alibaba/HandyJSON)、[KakaJSON](https://github.com/kakaopensource/KakaJSON) 等各有所长，他们都各自构建了整套的序列化、反序列化机制，略复杂，甚至还有直接读写内存的（“依赖于从 Swift Runtime 源码中推断的内存规则，任何变动我们将随时跟进”），这就不大好了，至少不够优雅。

写 Objective-C 时一直享受着 [YYModel](https://github.com/ibireme/YYModel) 带来的便利，相比之下以上多少都欠了点。调研一番之后倾向于用 Codextended，因为能享受到官方的 Codable。

起初有考虑直接基于它做扩展来实现 Key-Mapping，但是后来发现受到限制较多，于是重新写了关键部分的实现，有些调整、也有些舍弃。

Codextended 最欠缺的是 Key-Mapping，经过各种摸索、尝试，发现 `KeyPath` 方式可行。解决掉关键问题后面就简单了，很快差不多实现了 YYModel 的所有特性。

主要特性：
- 通过 `KeyPath` 读写属性、`CodingKey` 读写 JSON，实现 Key-Mapping；
- 支持多个候选 Key；
- 支持 Key 嵌套；
- 支持自定义 Encode/Decode Handler；
- 支持使用 Subscript 进行 Encode/Decode；
- 支持类型自动转换以及自定义转换；
- 支持多种 Encoder/Decoder，默认使用 JSON，支持读写 `Data`、`String`、`Object` 类型 JSON 数据；
- 使用类型推断；
- 使用 `Optional` 类型取代抛出没什么用的错误；
- 支持 `struct`、`class`、`subclass`。

示例：

定义 `struct`，使用 `var` 声明变量、并设置默认值，可以使用 `private(set)` 来防止属性被外部修改；

```swift
struct TestStruct: Equatable {
    private(set) var int: Int = 0
    private(set) var string: String = ""
}
```

实现 `ExCodable` 协议，通过 `keyMapping` 设置 `KeyPath` 到 `CodingKey` 的映射，`init` 和 `encode` 方法里只需一行代码；

```swift
extension TestStruct: ExCodable {
    
    static var keyMapping: [KeyMap<Self>] = [
        KeyMap(\.int, to: "int", "i"),
        KeyMap(\.string, to: "nested.string")
    ]
    
    init(from decoder: Decoder) throws {
        decode(with: Self.keyMapping, using: decoder)
    }
    func encode(to encoder: Encoder) throws {
        encode(with: Self.keyMapping, using: encoder)
    }
    
}
```

Encode、Decode 使用类型推断，使代码更具可读性；

```swift
let test = TestStruct(int: 100, string: "Continue")
let data = test.encoded() as Data? // Model -> JSON Data (or String, [String: Any])
let copy1 = data?.decoded() as TestStruct? // JSON Data -> Model
let copy2 = TestStruct.decoded(from: data) // or Model <- JSON Data
XCTAssertEqual(copy1, test)
XCTAssertEqual(copy2, test)
```

更多示例可参考 [Usage](https://github.com/iwill/ExCodable#usage) 以及单元测试代码。

另外可以将下面代码片段添加到 Xcode，只要记住 `ExCodable` 就可以了：

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

在此，要特别感谢 John Sundell 的 [Codextended](https://github.com/JohnSundell/Codextended) 的非凡创意、以及 ibireme 的 [YYModel](https://github.com/ibireme/YYModel) 的丰富特性，他们给了我极大的启发。
