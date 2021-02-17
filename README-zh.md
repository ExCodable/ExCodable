# ExCodable

[En](https://github.com/iwill/ExCodable) | 中文

**ExCodable** - Swift `Codable` 扩展。

## 为什么要造轮子

公司一直在用 Objective-C，一直享受着 [YYModel](https://github.com/ibireme/YYModel) 给予的便利。终于，我们要用 Swift 了，但是没找到合适的轮子（我真的没有首先想到要造轮子，我真的努力地找了，可是真的没有找到）。
- Swift 内置的 Codable 用着有点麻烦，否则也就不会有各种轮子了。
- [Codextended](https://github.com/JohnSundell/Codextended) 在 Codable 的基础上做了易用性扩展，不到 200 行代码很好很强大，但没有解决掉最后一公里 —— 还是要逐个属性 Encode/Decode。
- 有个朋友叫 Handy（不知作者是不是他 😆😆），他所在的某厂有个和他同名的 framework 实现了 Key-Mapping，但是要粗暴地读写内存，这很不好，而且很复杂，代码多到不想读。
- ExCodable —— 1 个文件、500 行代码，基于 `KeyPath` 实现 Key-Mapping，差不多实现了 YYModel 支持的所有特性。

**插播声明**：
- **ExCodable 部分地借鉴了 [Codextended](https://github.com/JohnSundell/Codextended) 的设计，因为它“真的很棒”**，开始有考虑直接基于它做扩展的，但是后来发现受到限制较多，于是重新写了关键部分的实现，有些调整、也有些舍弃。
- 在 JSON 转 Model 的场景，我们关心的只是解析结果有或没有，解析失败时抛出的错误并没有什么实际用途（除了 Debug，比如一个 Key 不存在和它存在但是类型错了对于结果有什么分别），所以为了避免到处写 `try?`，ExCodable 吞掉了所有的错误，返回值基本上都是 `Optional` 类型。
- 没有像 Codextended 一样直接地支持 Date 格式转换，但是 ExCodable 支持全局的自定义类型转换、以及每个属性的自定义 Encode/Decode-Handler，可以很好地满足这个需求。
- 目前，我只跑过 TestCase，暂时没有在实际项目中用到过 ExCodable，问题很可能是有的，如果遇到了，辛苦提交 Issue 或 Pull Request，我会尽快解决和完善。

## 特性

通过 `KeyPath` 和 `CodingKey` 支持 Key-Mapping：
- 无需逐个属性 Encode/Decode；
- 没有使用 `UnsafePointer` 读写内存；
- 只是要求使用 `var` 声明属性并设置默认值；
- 多数情况下无需再声明 `CodingKey`，因为只会用到一次，直接写字符串更方便。

Encode/Decode：
- 支持多个候选 Key；
- 支持 Key 嵌套；
- 支持自定义 Encode/Decode Handler；
- 支持使用 Subscript 进行 Encode/Decode；
- 支持类型自动转换以及自定义转换。

简约且灵活的 API：
- 支持多种 Encoder/Decoder，默认使用 JSON；
- 使用类型推断；
- 使用 `Optional` 类型取代抛出没什么 用的错误。

示例代码参考 [Usage](./#usage) 或 [ExCodableTests](./Tests/ExCodableTests/ExCodableTests.swift)。
