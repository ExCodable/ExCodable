[ExCodable](https://github.com/iwill/ExCodable) 是我在春节期间、带娃之余、用了几个晚上完成的一个 Swift 版的 JSON-Model 转换工具。

别走！你可能会想“嗷，又一个轮子”，但是这个真的有点不一样：
- `ExCodable` 是在 Swift `Codable` 基础上的扩展，可以享受到诸多遍历，比如与 [Alamofire](https://github.com/Alamofire/Alamofire) 无缝对接，参考 [Response Decodable Handler](https://github.com/Alamofire/Alamofire/blob/master/Documentation/Usage.md#response-decodable-handler)；
- 基于 `KeyPath` 实现 Key-Mapping，无需逐个属性 Encode/Decode；
- 支持丰富的特性，差不多实现了 Objective-C 版的 [YYModel](https://github.com/ibireme/YYModel) 的所有特性；
- 轻量，1 个文件、不到 500 行代码。

当然我不是一开始就决定要造轮子的。近期我们团队准备开始使用 Swift，节前开始寻找一些开源框架。网络请求用 [Alamofire](https://github.com/Alamofire/Alamofire)、自动布局用 [SnapKit](https://github.com/SnapKit/SnapKit)，这都毫无悬念，但是 JSON-Model 转换并没有找到合适的。

GitHub 上 Star 比较多的有几种类型：
- [SwiftyJSON](https://github.com/SwiftyJSON/SwiftyJSON) 仅用于读写 JSON，至于 Model 是不管的 —— 仅适用于没有 Model 或者 Model 很简单的情况；
- Swift 内置的 `Codable` 可以满足刚需，但也有官方框架的通病 —— 繁琐，[Codextended](https://github.com/JohnSundell/Codextended) 对其做了大量的简化，但还是要逐个属性 Encode/Decode —— 适用于 Model 比较简单的场景；
- [ObjectMapper](https://github.com/tristanhimmelman/ObjectMapper)、[HandyJSON](https://github.com/alibaba/HandyJSON)、[KakaJSON](https://github.com/kakaopensource/KakaJSON) 等各有所长，他们都各自构建了整套的序列化、反序列化机制，略复杂，甚至还有直接读写内存的（“依赖于从 Swift Runtime 源码中推断的内存规则，任何变动我们将随时跟进”），这就不大靠谱了，至少不够优雅。

写 Objective-C 时一直享受着 [YYModel](https://github.com/ibireme/YYModel) 带来的便利，相比之下以上多少都欠了点意思。调研一番之后倾向于用 Codextended，因为抱上官方 `Codable` 的大腿。

起初有考虑直接基于它做扩展来实现 Key-Mapping，但是受到限制较多，只能自己动手了。Codextended 最欠缺的是 Key-Mapping，经过各种摸索、尝试，确定 `KeyPath` 方式可行。解决掉关键问题后面就简单了，很快差不多实现了 YYModel 的所有特性；同时借鉴了 Codextended，重新写了关键部分的实现，有些调整、也有些舍弃。

主要特性：
- 使用 `KeyPath` 映射到 Coding-Key，实现 Key-Mapping；
- 支持多个候选 Coding-Key；
- 支持 Coding-Key 嵌套；
- 支持使用 Subscript 进行自定义 Encode/Decode；
- 支持数据类型自动转换以及自定义转换；
- 支持 `struct`、`class`、subclass；
- 支持 JSON、PList 以及自定义 Encoder/Decoder，默认使用 JSON；
- 使用类型推断，支持 `Data`、`String`、`Array`、`Object` 类型 JSON 数据；
- 使用 `Optional` 类型取代抛出没什么用的 `error`，避免到处写 `try?`，有时还要套上括号。

> 这里要多说两句：一般情况下抛出错误是有用的，但是在 JSON-Model 转换的场景略有不同。经常遇到的错误无非就是字段少了、类型错了。如果是关键数据有问题抛出错误也还好，但是有时不痛不痒的字段出错（这种更容易出错），导致整个解析都失败就不好了。确实这样可以及时发现返回结果中的问题，但是大家可能也知道经常有新“发现”是什么样的体验。老司机可以回忆一下 YYModel 出现之前的岁月。所以我认为，永远不要相信 API 的任何承诺，不管它返回什么，App 不要动不动就崩给人看，这会严重影响一个开发者的名声！可能有人会问，它真的给你返回一坨🍦怎么办？可以加个关键数据校验环节，只校验关键数据。

抱歉废话有点多，代码上晚了：

定义 `struct`，使用 `var` 声明变量、并设置默认值，可以使用 `private(set)` 来防止属性被外部修改；

> `Optional` 类型不需要默认值；
> 想用 `let` 也不是不可以，参考 [Usage](https://github.com/iwill/ExCodable#usage)；

```swift
struct TestStruct: Equatable {
    private(set) var int: Int = 0
    private(set) var string: String?
}
```

实现 `ExCodable` 协议，通过 `keyMapping` 设置 `KeyPath` 到 Coding-Key 的映射，`init` 和 `encode` 方法都只要一行代码；

> 当 `encode` 方法只有这一行代码时它也是可以省略的，`ExCodable` 提供了默认实现。但是受 Swift 对初始化过程的严格限制，`init` 方法不能省略。

```swift
extension TestStruct: ExCodable {
    static var keyMapping: [KeyMap<Self>] = [
        KeyMap(\.int, to: "int", "i"),
        KeyMap(\.string, to: "nested.string")
    ]
    init(from decoder: Decoder) throws {
        decode(with: Self.keyMapping, using: decoder)
    }
    // func encode(to encoder: Encoder) throws {
    //     encode(with: Self.keyMapping, using: encoder)
    // }
}
```

Encode、Decode 也很方便；

```swift
let test = TestStruct(int: 100, string: "Continue")
let data = test.encoded() as Data? // Model encode to JSON

let copy1 = data?.decoded() as TestStruct? // decode JSON to Model
let copy2 = TestStruct.decoded(from: data) // or Model decode from JSON

XCTAssertEqual(copy1, test)
XCTAssertEqual(copy2, test)
```

更多示例可参考 [Usage](https://github.com/iwill/ExCodable#usage) 以及单元测试代码。

另外可以将下面代码片段添加到 Xcode，只要记住 `ExCodable` 就可以了：

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

## 感谢

在此，要特别感谢 John Sundell 的 [Codextended](https://github.com/JohnSundell/Codextended) 的非凡创意、以及 ibireme 的 [YYModel](https://github.com/ibireme/YYModel) 的丰富特性，他们给了我极大的启发。
