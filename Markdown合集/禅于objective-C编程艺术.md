# 条件语句



## 尤达表达式

**推荐:**

```obj-c
if ([myValue isEqual:@42]) { ...
```

**不推荐:**

```objective-c
if ([@42 isEqual:myValue]) { ...
```

## nil 和 BOOL 检查

类似于 Yoda 表达式，nil 检查的方式也是存在争议的。一些 notous 库像这样检查对象是否为 nil：

```obj-c
if (nil == myValue) { ...
```

或许有人会提出这是错的，因为在 nil 作为一个常量的情况下，这样做就像 Yoda 表达式了。 但是一些程序员这么做的原因是为了避免调试的困难，看下面的代码：

```obj-c
if (myValue == nil) { ...
```

如果程序员敲错成这样：

```obj-c
if (myValue = nil) { ...
```

这是合法的语句，但是即使你是一个丰富经验的程序员，即使盯着眼睛瞧上好多遍也很难调试出错误。但是如果把 nil 放在左边，因为它不能被赋值，所以就不会发生这样的错误。 如果程序员这样做，他/她就可以轻松检查出可能的原因，比一遍遍检查敲下的代码要好很多。

## 黄金大道

在使用条件语句编程时，代码的左边距应该是一条“黄金”或者“快乐”的大道。 也就是说，不要嵌套 `if` 语句。使用多个 return 可以避免增加循环的复杂度，并提高代码的可读性。因为方法的重要部分没有嵌套在分支里面，并且你可以很清楚地找到相关的代码。

**推荐:**

```obj-c
- (void)someMethod {
  if (![someOther boolValue]) {
      return;
  }

  //Do something important
}
```

**不推荐:**

```obj-c
- (void)someMethod {
  if ([someOther boolValue]) {
    //Do something important
  }
}
```

## 复杂的表达式

当你有一个复杂的 if 子句的时候，你应该把它们提取出来赋给一个 BOOL 变量，这样可以让逻辑更清楚，而且让每个子句的意义体现出来。

```objective-c
BOOL nameContainsSwift  = [sessionName containsString:@"Swift"];
BOOL isCurrentYear      = [sessionDateCompontents year] == 2014;
BOOL isSwiftSession     = nameContainsSwift && isCurrentYear;

if (isSwiftSession) {
    // Do something very cool
}
```

## 三元运算符

三元运算符 ? 应该只用在它能让代码更加清楚的地方。 一个条件语句的所有的变量应该是已经被求值了的。类似 if 语句，计算多个条件子句通常会让语句更加难以理解。或者可以把它们重构到实例变量里面。

**推荐:**

```obj-c
result = a > b ? x : y;
```

**不推荐:**

```obj-c
result = a > b ? x = c > d ? c : d : y;
```

当三元运算符的第二个参数（if 分支）返回和条件语句中已经检查的对象一样的对象的时候，下面的表达方式更灵巧：

**推荐:**

```obj-c
result = object ? : [self createObject];
```

**不推荐:**

```obj-c
result = object ? object : [self createObject];
```

## 错误处理

有些方法通通过参数返回 error 的引用，使用这样的方法时应当检查方法的返回值，而非 error 的引用。

**推荐:**

```obj-c
NSError *error = nil;
if (![self trySomethingWithError:&error]) {
    // Handle Error
}
```

此外，一些苹果的 API 在成功的情况下会对 error 参数（如果它非 NULL）写入垃圾值（garbage values），所以如果检查 error 的值可能导致错误 （甚至崩溃）。

# Case语句

除非编译器强制要求，括号在 case 语句里面是不必要的。但是当一个 case 包含了多行语句的时候，需要加上括号。

```obj-c
switch (condition) {
    case 1:
        // ...
        break;
    case 2: {
        // ...
        // Multi-line example using braces
        break;
       }
    case 3:
        // ...
        break;
    default: 
        // ...
        break;
}
```

有时候可以使用 fall-through 在不同的 case 里面执行同一段代码。一个 fall-through 是指移除 case 语句的 “break” 然后让下面的 case 继续执行。

```obj-c
switch (condition) {
    case 1:
    case 2:
        // code executed for values 1 and 2
        break;
    default: 
        // ...
        break;
}
```

当在 switch 语句里面使用一个可枚举的变量的时候，`default` 是不必要的。比如：

```obj-c
switch (menuType) {
    case ZOCEnumNone:
        // ...
        break;
    case ZOCEnumValue1:
        // ...
        break;
    case ZOCEnumValue2:
        // ...
        break;
}
```

此外，为了避免使用默认的 case，如果新的值加入到 enum，程序员会马上收到一个 warning 通知

```
Enumeration value 'ZOCEnumValue3' not handled in switch.（枚举类型 'ZOCEnumValue3' 没有被 switch 处理）
```

### 枚举类型

当使用 `enum` 的时候，建议使用新的固定的基础类型定义，因它有更强大的的类型检查和代码补全。 SDK 现在有一个 宏来鼓励和促进使用固定类型定义 - `NS_ENUM()`

**例子:**

```obj-c
typedef NS_ENUM(NSUInteger, ZOCMachineState) {
    ZOCMachineStateNone,
    ZOCMachineStateIdle,
    ZOCMachineStateRunning,
    ZOCMachineStatePaused
};
```

# 命名

## 通用的约定

尽可能遵守 Apple 的命名约定，尤其是和 [内存管理规则](https://developer.apple.com/library/mac/#documentation/Cocoa/Conceptual/MemoryMgmt/Articles/MemoryMgmt.html) ([NARC](http://stackoverflow.com/a/2865194/340508)) 相关的地方。

推荐使用长的、描述性的方法和变量名。

**推荐:**

```obj-c
UIButton *settingsButton;
```

**不推荐:**

```obj-c
UIButton *setBut;
```

## Constants 常量

常量应该以驼峰法命名，并以相关类名作为前缀。

**推荐:**

```obj-c
static const NSTimeInterval ZOCSignInViewControllerFadeOutAnimationDuration = 0.4;
```

**不推荐:**

```obj-c
static const NSTimeInterval fadeOutTime = 0.4;
```

推荐使用常量来代替字符串字面值和数字，这样能够方便复用，而且可以快速修改而不需要查找和替换。常量应该用 `static` 声明为静态常量，而不要用 `#define`，除非它明确的作为一个宏来使用。

**推荐:**

```obj-c
static NSString * const ZOCCacheControllerDidClearCacheNotification = @"ZOCCacheControllerDidClearCacheNotification";
static const CGFloat ZOCImageThumbnailHeight = 50.0f;
```

**不推荐:**

```obj-c
#define CompanyName @"Apple Inc."
#define magicNumber 42
```

常量应该在头文件中以这样的形式暴露给外部：

```obj-c
extern NSString *const ZOCCacheControllerDidClearCacheNotification;
```

并在实现文件中为它赋值。

只有公有的常量才需要添加命名空间作为前缀。尽管实现文件中私有常量的命名可以遵循另外一种模式，你仍旧可以遵循这个规则。

## 方法

方法名与方法类型 (`-`/`+` 符号)之间应该以空格间隔。方法段之间也应该以空格间隔（以符合 Apple 风格）。参数前应该总是有一个描述性的关键词。

尽可能少用 "and" 这个词。它不应该用来阐明有多个参数，比如下面的 `initWithWidth:height:` 这个例子：

**推荐:**

```obj-c
- (void)setExampleText:(NSString *)text image:(UIImage *)image;
- (void)sendAction:(SEL)aSelector to:(id)anObject forAllCells:(BOOL)flag;
- (id)viewWithTag:(NSInteger)tag;
- (instancetype)initWithWidth:(CGFloat)width height:(CGFloat)height;
```

**不推荐:**

```obj-c
- (void)setT:(NSString *)text i:(UIImage *)image;
- (void)sendAction:(SEL)aSelector :(id)anObject :(BOOL)flag;
- (id)taggedView:(NSInteger)tag;
- (instancetype)initWithWidth:(CGFloat)width andHeight:(CGFloat)height;
- (instancetype)initWith:(int)width and:(int)height;  // Never do this.
```

## 字面值

使用字面值来创建不可变的 `NSString`, `NSDictionary`, `NSArray`, 和 `NSNumber` 对象。注意不要将 `nil` 传进 `NSArray` 和 `NSDictionary` 里，因为这样会导致崩溃。

**例子：**

```obj-c
NSArray *names = @[@"Brian", @"Matt", @"Chris", @"Alex", @"Steve", @"Paul"];
NSDictionary *productManagers = @{@"iPhone" : @"Kate", @"iPad" : @"Kamal", @"Mobile Web" : @"Bill"};
NSNumber *shouldUseLiterals = @YES;
NSNumber *buildingZIPCode = @10018;
```

**不要这样:**

```obj-c
NSArray *names = [NSArray arrayWithObjects:@"Brian", @"Matt", @"Chris", @"Alex", @"Steve", @"Paul", nil];
NSDictionary *productManagers = [NSDictionary dictionaryWithObjectsAndKeys: @"Kate", @"iPhone", @"Kamal", @"iPad", @"Bill", @"Mobile Web", nil];
NSNumber *shouldUseLiterals = [NSNumber numberWithBool:YES];
NSNumber *buildingZIPCode = [NSNumber numberWithInteger:10018];
```

如果要用到这些类的可变副本，我们推荐使用 `NSMutableArray`, `NSMutableString` 这样的类。

**应该避免**下面这样:

```obj-c
NSMutableArray *aMutableArray = [@[] mutableCopy];
```

上面这种书写方式的效率和可读性的都存在问题。

效率方面，一个不必要的不可变对象被创建后立马被废弃了；虽然这并不会让你的 App 变慢（除非这个方法被频繁调用），但是确实没必要为了少打几个字而这样做。

可读性方面，存在两个问题：第一个问题是当你浏览代码并看见 `@[]` 的时候，你首先联想到的是 `NSArray` 实例，但是在这种情形下你需要停下来深思熟虑的检查；

另一个问题是，一些新手以他的水平看到你的代码后可能会对这是一个可变对象还是一个不可变对象产生分歧。他/她可能不熟悉可变拷贝构造的含义（这并不是说这个知识不重要）。

当然，不存在绝对的错误，我们只是讨论代码的可用性（包括可读性)。

# 类

## 类名

类名应该以**三**个大写字母作为前缀（双字母前缀为 Apple 的类预留）。尽管这个规范看起来有些古怪，但是这样做可以减少 Objective-c 没有命名空间所带来的问题。

一些开发者在定义模型对象时并不遵循这个规范（对于 Core Data 对象，我们更应该遵循这个规范）。我们建议在定义 Core Data 对象时严格遵循这个约定，因为最终你可能需要把你的 Managed Object Model（托管对象模型）与其他（第三方库）的 MOMs（Managed Object Model）合并。

你可能注意到了，这本书里类的前缀（不仅仅是类，也包括公开的常量、Protocol 等的前缀）是`ZOC`。

另一个好的类的命名规范：当你创建一个子类的时候，你应该把说明性的部分放在前缀和父类名的在中间。

举个例子：如果你有一个 `ZOCNetworkClient` 类，子类的名字会是`ZOCTwitterNetworkClient` (注意 "Twitter" 在 "ZOC" 和 "NetworkClient" 之间); 按照这个约定， 一个`UIViewController` 的子类会是 `ZOCTimelineViewController`.



## Initializer 和 dealloc 初始化

推荐的代码组织方式是将 `dealloc` 方法放在实现文件的最前面（直接在 `@synthesize` 以及 `@dynamic` 之后），`init` 应该跟在 `dealloc` 方法后面。如果有多个初始化方法， 指定初始化方法 (designated initializer) 应该放在最前面，间接初始化方法 (secondary initializer) 跟在后面，这样更有逻辑性。

如今有了 ARC，dealloc 方法几乎不需要实现，不过把 init 和 dealloc 放在一起可以从视觉上强调它们是一对的。通常，在 init 方法中做的事情需要在 dealloc 方法中撤销。

`init` 方法应该是这样的结构：

```obj-c
- (instancetype)init
{
    self = [super init]; // call the designated initializer
    if (self) {
        // Custom initialization
    }
    return self;
}
```

为什么设置 `self` 为 `[super init]` 的返回值，以及中间发生了什么呢？这是一个十分有趣的话题。

我们退一步讲：我们常常写 `[[NSObject alloc] init]` 这样的代码，从而淡化了 `alloc` 和 `init` 的区别。Objective-C 的这个特性叫做 *两步创建* 。 这意味着申请分配内存和初始化被分离成两步，`alloc` 和 `init`。

- `alloc` 负责创建对象，这个过程包括分配足够的内存来保存对象，写入 `isa` 指针，初始化引用计数，以及重置所有实例变量。
- `init` 负责初始化对象，这意味着使对象处于可用状态。这通常意味着为对象的实例变量赋予合理有用的值。

`alloc` 方法将返回一个有效的未初始化的对象实例。每一个对这个实例发送的消息会被转换成一次 `objc_msgSend()` 函数的调用，形参 `self` 的实参是 `alloc` 返回的指针；这样 `self` 在所有方法的作用域内都能够被访问。 按照惯例，为了完成两步创建，新创建的实例第一个被调用的方法将是 `init` 方法。注意，`NSObject` 在实现 `init` 时，只是简单的返回了 `self`。

关于 `init` 的约定还有一个重要部分：这个方法可以（并且应该）通过返回 `nil` 来告诉调用者，初始化失败了；初始化可能会因为各种原因失败，比如一个输入的格式错误了，或者另一个需要的对象初始化失败了。 这样我们就能理解为什么总是需要调用 `self = [super init]`。如果你的父类说初始化自己的时候失败了，那么你必须假定你正处于一个不稳定的状态，因此在你的实现里不要继续你自己的初始化并且也返回 `nil`。如果不这样做，你可能会操作一个不可用的对象，它的行为是不可预测的，最终可能会导致你的程序崩溃。

`init` 方法在被调用的时候可以通过重新给 `self` 重新赋值来返回另一个实例，而非调用的那个实例。例如[类簇](https://objc-zen-book.books.yourtion.com/Chapter05/02-initializer-and-dealloc.html#类簇)，还有一些 Cocoa 类为相等的（不可变的）对象返回同一个实例。

### Designated 和 Secondary 初始化方法

Objective-C 有指定初始化方法(designated initializer)和间接(secondary initializer)初始化方法的观念。 designated 初始化方法是提供所有的参数，secondary 初始化方法是一个或多个，并且提供一个或者更多的默认参数来调用 designated 初始化的初始化方法。

```obj-c
@implementation ZOCEvent

- (instancetype)initWithTitle:(NSString *)title
                         date:(NSDate *)date
                     location:(CLLocation *)location
{
    self = [super init];
    if (self) {
        _title    = title;
        _date     = date;
        _location = location;
    }
    return self;
}

- (instancetype)initWithTitle:(NSString *)title
                         date:(NSDate *)date
{
    return [self initWithTitle:title date:date location:nil];
}

- (instancetype)initWithTitle:(NSString *)title
{
    return [self initWithTitle:title date:[NSDate date] location:nil];
}

@end
```

`initWithTitle:date:location:` 就是 designated 初始化方法，另外的两个是 secondary 初始化方法。因为它们仅仅是调用类实现的 designated 初始化方法

#### Designated Initializer

一个类应该有且只有一个 designated 初始化方法，其他的初始化方法应该调用这个 designated 的初始化方法（虽然这个情况有一个例外）

这个分歧没有要求那个初始化函数需要被调用。

在类继承中调用任何 designated 初始化方法都是合法的，而且应该保证 *所有的* designated initializer 在类继承中是从祖先（通常是 `NSObject` ）到你的类向下调用的。

实际上这意味着第一个执行的初始化代码是最远的祖先，然后从顶向下的类继承，所有类都有机会执行他们特定初始化代码。这样，你在做特定初始化工作前，所有从超类继承的东西都是不可用的状态。 虽然这没有明确的规定，但是所有 Apple 的框架都保证遵守这个约定，你的类也应该这样做。

当定义一个新类的时候有三个不同的方式：

1. 不需要重载任何初始化函数
2. 重载 designated initializer
3. 定义一个新的 designated initializer

第一个方案是最简单的：你不需要增加类的任何初始化逻辑，只需要依照父类的designated initializer。

当你希望提供额外的初始化逻辑的时候，你可以重载 designated initializer。你只需要重载直接超类的 designated initializer 并且确认你的实现调用了超类的方法。

一个典型的例子是你创造 `UIViewController` 子类的时候重载 `initWithNibName:bundle:` 方法。

```obj-c
@implementation ZOCViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    // call to the superclass designated initializer
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization （自定义的初始化过程）
    }
    return self;
}

@end
```

在 `UIViewController` 子类的例子里面如果重载 `init` 会是一个错误，这个情况下调用者会尝试调用 `initWithNib:bundle` 初始化你的类，你的类实现不会被调用。这同样违背了它应该是合法调用任何 designated initializer 的规则。

在你希望提供你自己的初始化函数的时候，你应该遵守这三个步骤来保证获得正确的行为：

1. 定义你的 designated initializer，确保调用了直接超类的 designated initializer。
2. 重载直接超类的 designated initializer。调用你的新的 designated initializer。
3. 为新的 designated initializer 写文档。

很多开发者忽略了后两步，这不仅仅是一个粗心的问题，而且这样违反了框架的规则，可能导致不确定的行为和bug。

让我们看看正确的实现的例子：

```obj-c
@implementation ZOCNewsViewController

- (id)initWithNews:(ZOCNews *)news
{
    // call to the immediate superclass's designated initializer （调用直接超类的 designated initializer）
    self = [super initWithNibName:nil bundle:nil];
    if (self) {
        _news = news;
    }
    return self;
}

// Override the immediate superclass's designated initializer （重载直接父类的  designated initializer）
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    // call the new designated initializer
    return [self initWithNews:nil];
}

@end
```

如果你没重载 `initWithNibName:bundle:` ，而且调用者决定用这个方法初始化你的类(这是完全合法的)。 `initWithNews:` 永远不会被调用，所以导致了不正确的初始化流程，你的类的特定初始化逻辑没有被执行。

即使可以推断那个方法是 designate initializer，也最好清晰地明确它（未来的你或者其他开发者在改代码的时候会感谢你的）。你应该考虑来用这两个策略（不是互斥的）：第一个是你在文档中明确哪一个初始化方法是 designated 的，你可以用编译器的指令 `__attribute__((objc_designated_initializer))` 来标记你的意图。

用这个编译指令的时候，编译器会来帮你。如果你的新的 designate initializer 没有调用超类的 designated initializer，那么编译器会发出警告。

然而，当没有调用类的 designated initializer 的时候（并且依次提供必要的参数），并且调用其他父类中的 designated initialize 的时候，会变成一个不可用的状态。参考之前的例子，当实例化一个 `ZOCNewsViewController` 展示一个新闻而那条新闻没有展示的话，就会毫无意义。这个情况下你应该只需要让其他的 designated initializer 失效，来强制调用一个非常特别的 designated initializer。通过使用另外一个编译器指令 `__attribute__((unavailable("Invoke the designated initializer")))` 来修饰一个方法，通过这个属性，会让你在试图调用这个方法的时候产生一个编译错误。

这是之前的例子相关的实现的头文件(这里使用宏来让代码没有那么啰嗦)

```obj-c
@interface ZOCNewsViewController : UIViewController

- (instancetype)initWithNews:(ZOCNews *)news ZOC_DESIGNATED_INITIALIZER;
- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil ZOC_UNAVAILABLE_INSTEAD(initWithNews:);
- (instancetype)init ZOC_UNAVAILABLE_INSTEAD(initWithNews:);

@end
```

上述的一个推论是：你应该永远不从 designated initializer 里面调用一个 secondary initializer （如果secondary initializer 遵守约定，它会调用 designated initializer）。如果这样，调用很可能会调用一个子类重写的 init 方法并且陷入无限递归之中。

不过一个例外是一个对象是否遵守 `NSCoding` 协议，并且它通过方法 `initWithCoder:` 初始化。

我们应该看超类是否符合 `NSCoding` 协议来区别对待。

符合的时候，如果你只是调用 `[super initWithCoder:]` ，你可能需要在 designated initializer 里面写一些通用的初始化代码，处理这种情况的一个好方法是把这些代码放在私有方法里面(比如 `p_commonInit` )。

当你的超类不符合 `NSCoding` 协议的时候，推荐把 `initWithCoder:` 作为 secondary initializer 来对待，并且调用 `self` 的 designated initializer。 注意这违反了 Apple 写在 [Archives and Serializations Programming Guide](https://developer.apple.com/library/mac/documentation/cocoa/Conceptual/Archiving/Articles/codingobjects.html#//apple_ref/doc/uid/20000948-BCIHBJDE) 上面的规定：

> the object should first invoke its superclass's designated initializer to initialize inherited state（对象总是应该首先调用超类的 designated initializer 来初始化继承的状态）

如果你的类不是 `NSObject` 的直接子类，这样做的话，会导致不可预测的行为。

#### Secondary Initializer

正如之前的描述，secondary initializer 是一种提供默认值、行为到 designated initializer的方法。也就是说，在这样的方法里面你不应该有初始化实例变量的操作，并且你应该一直假设这个方法不会得到调用。我们保证的是唯一被调用的方法是 designated initializer。

这意味着你的 secondary initializer 总是应该调用 Designated initializer 或者你自定义(上面的第三种情况：自定义Designated initializer)的 `self`的 designated initializer。有时候，因为错误，可能打成了 `super`，这样会导致不符合上面提及的初始化顺序（在这个特别的例子里面，是跳过当前类的初始化）

##### 参考

- https://developer.apple.com/library/ios/Documentation/General/Conceptual/DevPedia-CocoaCore/ObjectCreation.html
- https://developer.apple.com/library/ios/documentation/General/Conceptual/CocoaEncyclopedia/Initialization/Initialization.html
- https://developer.apple.com/library/ios/Documentation/General/Conceptual/DevPedia-CocoaCore/MultipleInitializers.html
- https://blog.twitter.com/2014/how-to-objective-c-initializer-patterns

### instancetype

我们经常忽略 Cocoa 充满了约定，并且这些约定可以帮助编译器变得更加聪明。无论编译器是否遭遇 `alloc` 或者 `init` 方法，他会知道，即使返回类型都是 `id` ，这些方法总是返回接受到的类类型的实例。因此，它允许编译器进行类型检查。（比如，检查方法返回的类型是否合法）。Clang的这个好处来自于 [related result type](http://clang.llvm.org/docs/LanguageExtensions.html#related-result-types)， 意味着：

> messages sent to one of alloc and init methods will have the same static type as the instance of the receiver class （发送到 alloc 或者 init 方法的消息会有同样的静态类型检查是否为接受类的实例。）

更多的关于这个自动定义相关返回类型的约定请查看 Clang Language Extensions guide 的[appropriate section](https://objc-zen-book.books.yourtion.com/Chapter05/(http:/clang.llvm.org/docs/LanguageExtensions.html#related-result-types))

一个相关的返回类型可以明确地规定用 `instancetype` 关键字作为返回类型，并且它可以在一些工厂方法或者构造器方法的场景下很有用。它可以提示编译器正确地检查类型，并且更加重要的是，这同时适用于它的子类。

```obj-c
@interface ZOCPerson
+ (instancetype)personWithName:(NSString *)name;
@end
```

虽然如此，根据 clang 的定义，`id` 可以被编译器提升到 `instancetype` 。在 `alloc` 或者 `init` 中，我们强烈建议对所有返回类的实例的类方法和实例方法使用 `instancetype` 类型。

在你的 API 中要构成习惯以及保持始终如一的，此外，通过对你代码的小调整你可以提高可读性：在简单的浏览的时候你可以区分哪些方法是返回你类的实例的。你以后会感谢这些注意过的小细节的。

##### 参考

- http://tewha.net/2013/02/why-you-should-use-instancetype-instead-of-id/
- http://tewha.net/2013/01/when-is-id-promoted-to-instancetype/
- http://clang.llvm.org/docs/LanguageExtensions.html#related-result-types
- http://nshipster.com/instancetype/

### 初始化模式

#### 类簇 （class cluster)

类簇在Apple的文档中这样描述：

> an architecture that groups a number of private, concrete subclasses under a public, abstract superclass. （一个在共有的抽象超类下设置一组私有子类的架构）

如果这个描述听起来很熟悉，说明你的直觉是对的。 Class cluster 是 Apple 对[抽象工厂](http://en.wikipedia.org/wiki/Abstract_factory_pattern)设计模式的称呼。

class cluster 的想法很简单: 使用信息进行(类的)初始化处理期间，会使用一个抽象类（通常作为初始化方法的参数或者判定环境的可用性参数）来完成特定的逻辑或者实例化一个具体的子类。而这个"Public Facing（面向公众的）"类，必须非常清楚他的私有子类，以便在面对具体任务的时候有能力返回一个恰当的私有子类实例。对调用者来说只需知道对象的各种API的作用即可。这个模式隐藏了他背后复杂的初始化逻辑，调用者也不需要关心背后的实现。

Class clusters 在 Apple 的Framework 中广泛使用：一些明显的例子比如 `NSNumber` 可以返回不同类型给你的子类，取决于 数字类型如何提供 (Integer, Float, etc...) 或者 `NSArray` 返回不同的最优存储策略的子类。

这个模式的精妙的地方在于，调用者可以完全不管子类，事实上，这可以用在设计一个库，可以用来交换实际的返回的类，而不用去管相关的细节，因为它们都遵从抽象超类的方法。

我们的经验是使用类簇可以帮助移除很多条件语句。

一个经典的例子是如果你有为 iPad 和 iPhone 写的一样的 UIViewController 子类，但是在不同的设备上有不同的行为。

比较基础的实现是用条件语句检查设备，然后执行不同的逻辑。虽然刚开始可能不错，但是随着代码的增长，运行逻辑也会趋于复杂。 一个更好的实现的设计是创建一个抽象而且宽泛的 view controller 来包含所有的共享逻辑，并且对于不同设备有两个特别的子例。

通用的 view controller 会检查当前设备并且返回适当的子类。

```obj-c
@implementation ZOCKintsugiPhotoViewController

- (id)initWithPhotos:(NSArray *)photos
{
    if ([self isMemberOfClass:ZOCKintsugiPhotoViewController.class]) {
        self = nil;

        if ([UIDevice isPad]) {
            self = [[ZOCKintsugiPhotoViewController_iPad alloc] initWithPhotos:photos];
        }
        else {
            self = [[ZOCKintsugiPhotoViewController_iPhone alloc] initWithPhotos:photos];
        }
        return self;
    }
    return [super initWithNibName:nil bundle:nil];
}

@end
```

这个子例程展示了如何创建一个类簇。

1. 使用`[self isMemberOfClass:ZOCKintsugiPhotoViewController.class]`防止子类中重载初始化方法，避免无限递归。当`[[ZOCKintsugiPhotoViewController alloc] initWithPhotos:photos]`被调用时，上面条件表达式的结果将会是True。
2. `self = nil`的目的是移除`ZOCKintsugiPhotoViewController`实例上的所有引用，实例(抽象类的实例)本身将会解除分配（ 当然ARC也好MRC也好dealloc都会发生在Main Runloop这一次的结束时）。
3. 接下来的逻辑就是判断哪一个私有子类将被初始化。我们假设在iPhone上运行这段代码并且`ZOCKintsugiPhotoViewController_iPhone`没有重载`initWithPhotos:`方法。这种情况下，当执行`self = [[ZOCKintsugiPhotoViewController_iPhone alloc] initWithPhotos:photos];`,`ZOCKintsugiPhotoViewController`将会被调用，第一次检查将会在这里发生，鉴于`ZOCKintsugiPhotoViewController_iPhone`不完全是`ZOCKintsugiPhotoViewController`，表达式`[self isMemberOfClass:ZOCKintsugiPhotoViewController.class]`将会是False,于是就会调用`[super initWithNibName:nil bundle:nil]`，于是就会进入`ZOCKintsugiPhotoViewController`的初始化过程，这时候因为调用者就是`ZOCKintsugiPhotoViewController`本身，这一次的检查必定为True,接下来就会进行正确的初始化过程。(NOTE：这里必须是完全遵循Designated initializer 以及Secondary initializer的设计规范的前提下才会其效果的!不明白这个规范的可以后退一步熟悉这种规范在回头来看这个说明)

> NOTE: 这里的意思是，代码是在iPhone上调试的，程序员使用了`self = [[ZOCKintsugiPhotoViewController_iPhone alloc] initWithPhotos:photos];`来初始化某个view controller的对象，当代码运行在iPad上时，这个初始化过程也是正确的，因为无论程序员的代码中使用`self = [[ZOCKintsugiPhotoViewController_iPhone alloc] initWithPhotos:photos];`来初始化viewController(iPhone上编写运行在iPad上)，还是使用`self = [[ZOCKintsugiPhotoViewController_iPad alloc] initWithPhotos:photos];`来初始化viewController(iPad上编写，运行在iPhone上)，都会因为ZOCKintsugiPhotoViewController的`initWithPhotos:`方法的存在而变得通用起来。

#### 单例

如果可能，请尽量避免使用单例而是依赖注入。

然而，如果一定要用，请使用一个线程安全的模式来创建共享的实例。对于 GCD，用 `dispatch_once()` 函数就可以咯。

```obj-c
+ (instancetype)sharedInstance
{
   static id sharedInstance = nil;
   static dispatch_once_t onceToken = 0;
   dispatch_once(&onceToken, ^{
      sharedInstance = [[self alloc] init];
   });
   return sharedInstance;
}
```

使用 dispatch_once()，来控制代码同步，取代了原来的约定俗成的用法。

```obj-c
+ (instancetype)sharedInstance
{
    static id sharedInstance;
    @synchronized(self) {
        if (sharedInstance == nil) {
            sharedInstance = [[MyClass alloc] init];
        }
    }
    return sharedInstance;
}
```

`dispatch_once()` 的优点是，它更快，而且语法上更干净，因为dispatch_once()的意思就是 “把一些东西执行一次”，就像我们做的一样。 这样同时可以避免 [possible and sometimes prolific crashes](http://cocoasamurai.blogspot.com/2011/04/singletons-your-doing-them-wrong.html).

经典的单例对象是：一个设备的GPS以及它的加速度传感器(也称动作感应器)。

虽然单例对象可以子类化，但这种方式能够有用的情况非常少见。

必须有证据表明，给定类的接口趋向于作为单例来使用。

所以，单例通常公开一个`sharedInstance`的类方法就已经足够了，没有任何的可写属性需要被暴露出来。

尝试着把单例作为一个对象的容器，在代码或者应用层面上共享，是一个糟糕和丑陋的设计。

> NOTE：单例模式应该运用于类及类的接口趋向于作为单例来使用的情况 （译者注）



## 属性

属性应该尽可能描述性地命名，避免缩写，并且是小写字母开头的驼峰命名。我们的工具可以很方便地帮我们自动补全所有东西（嗯。。几乎所有的，Xcode 的 Derived Data 会索引这些命名）。所以没理由少打几个字符了，并且最好尽可能在你源码里表达更多东西。

**例子 :**

```obj-c
NSString *text;
```

**不要这样 :**

```obj-c
NSString* text;
NSString * text;
```

（注意：这个习惯和常量不同，这是主要从常用和可读性考虑。 C++ 的开发者偏好从变量名中分离类型，作为类型它应该是 `NSString*` （对于从堆中分配的对象，对于C++是能从栈上分配的）格式。）

使用属性的自动同步 (synthesize) 而不是手动的 `@synthesize` 语句，除非你的属性是 protocol 的一部分而不是一个完整的类。如果 Xcode 可以自动同步这些变量，就让它来做吧。否则只会让你抛开 Xcode 的优点，维护更冗长的代码。

你应该总是使用 setter 和 getter 方法访问属性，除了 `init` 和 `dealloc` 方法。通常，使用属性让你增加了在当前作用域之外的代码块的可能所以可能带来更多副作用。

你总应该用 getter 和 setter ，因为：

- 使用 setter 会遵守定义的内存管理语义(`strong`, `weak`, `copy` etc...) ，这个在 ARC 之前就是相关的内容。举个例子，`copy` 属性定义了每个时候你用 setter 并且传送数据的时候，它会复制数据而不用额外的操作。
- KVO 通知(`willChangeValueForKey`, `didChangeValueForKey`) 会被自动执行。
- 更容易debug：你可以设置一个断点在属性声明上并且断点会在每次 getter / setter 方法调用的时候执行，或者你可以在自己的自定义 setter/getter 设置断点。
- 允许在一个单独的地方为设置值添加额外的逻辑。

你应该倾向于用 getter：

- 它是对未来的变化有扩展能力的（比如，属性是自动生成的）。
- 它允许子类化。
- 更简单的debug（比如，允许拿出一个断点在 getter 方法里面，并且看谁访问了特别的 getter
- 它让意图更加清晰和明确：通过访问 ivar `_anIvar` 你可以明确的访问 `self->_anIvar`.这可能导致问题。在 block 里面访问 ivar （你捕捉并且 retain 了 self，即使你没有明确的看到 self 关键词）。
- 它自动产生KVO 通知。
- 在消息发送的时候增加的开销是微不足道的。更多关于性能问题的介绍你可以看 [Should I Use a Property or an Instance Variable?](http://blog.bignerdranch.com/4005-should-i-use-a-property-or-an-instance-variable/)。

#### Init 和 Dealloc

有一个例外：永远不要在 init 方法（以及其他初始化方法）里面用 getter 和 setter 方法，你应当直接访问实例变量。这样做是为了防止有子类时，出现这样的情况：它的子类最终重载了其 setter 或者 getter 方法，因此导致该子类去调用其他的方法、访问那些处于不稳定状态，或者称为没有初始化完成的属性或者 ivar 。记住一个对象仅仅在 init 返回的时候，才会被认为是达到了初始化完成的状态。

同样在 dealloc 方法中（在 dealloc 方法中，一个对象可以在一个 不确定的状态中）这是同样需要被注意的。

- [Advanced Memory Management Programming Guide](https://developer.apple.com/library/mac/documentation/Cocoa/Conceptual/MemoryMgmt/Articles/mmPractical.html#//apple_ref/doc/uid/TP40004447-SW6) under the self-explanatory section "Don't Use Accessor Methods in Initializer Methods and dealloc";
- [Migrating to Modern Objective-C](http://adcdownload.apple.com//wwdc_2012/wwdc_2012_session_pdfs/session_413__migrating_to_modern_objectivec.pdf) at WWDC 2012 at slide 27;
- in a [pull request](https://github.com/NYTimes/objective-c-style-guide/issues/6) form Dave DeLong's.

此外，在 init 中使用 setter 不会很好执行 `UIAppearence` 代理（参见 [UIAppearance for Custom Views](http://petersteinberger.com/blog/2013/uiappearance-for-custom-views/) 看更多相关信息)。

#### 点符号

当使用 setter getter 方法的时候尽量使用点符号。应该总是用点符号来访问以及设置属性。

**例子:**

```Objective-C
view.backgroundColor = [UIColor orangeColor];
[UIApplication sharedApplication].delegate;
```

**不要这样:**

```Objective-C
[view setBackgroundColor:[UIColor orangeColor]];
UIApplication.sharedApplication.delegate;
```

使用点符号会让表达更加清晰并且帮助区分属性访问和方法调用

### 属性定义

推荐按照下面的格式来定义属性

```obj-c
@property (nonatomic, readwrite, copy) NSString *name;
```

属性的参数应该按照下面的顺序排列： 原子性，读写 和 内存管理。 这样做你的属性更容易修改正确，并且更好阅读。(译者注：习惯上修改某个属性的修饰符时，一般从属性名从右向左搜索需要修动的修饰符。最可能从最右边开始修改这些属性的修饰符，根据经验这些修饰符被修改的可能性从高到底应为：内存管理 > 读写权限 >原子操作)

你必须使用 `nonatomic`，除非特别需要的情况。在iOS中，`atomic`带来的锁特别影响性能。

属性可以存储一个代码块。为了让它存活到定义的块的结束，必须使用 `copy` （block 最早在栈里面创建，使用 `copy`让 block 拷贝到堆里面去）

为了完成一个共有的 getter 和一个私有的 setter，你应该声明公开的属性为 `readonly` 并且在类扩展总重新定义通用的属性为 `readwrite` 的。

```obj-c
//.h文件中
@interface MyClass : NSObject
@property (nonatomic, readonly, strong) NSObject *object;
@end
//.m文件中
@interface MyClass ()
@property (nonatomic, readwrite, strong) NSObject *object;
@end

@implementation MyClass
//Do Something cool
@end
```

描述`BOOL`属性的词如果是形容词，那么setter不应该带`is`前缀，但它对应的 getter 访问器应该带上这个前缀，如：

```obj-c
@property (assign, getter=isEditable) BOOL editable;
```

文字和例子引用自 [Cocoa Naming Guidelines](https://developer.apple.com/library/mac/#documentation/Cocoa/Conceptual/CodingGuidelines/Articles/NamingIvarsAndTypes.html#//apple_ref/doc/uid/20001284-BAJGIIJE)。

在实现文件中应避免使用`@synthesize`,因为Xcode已经自动为你添加了。

#### 私有属性

私有属性应该定义在类的实现文件的类的扩展 (class extensions) 中。不允许在有名字的的 category(如 `ZOCPrivate`）中定义私有属性，除非你扩展其他类。

**例子:**

```obj-c
@interface ZOCViewController ()
@property (nonatomic, strong) UIView *bannerView;
@end
```

### 可变对象

任何可以用来用一个可变的对象设置的（(比如 `NSString`,`NSArray`,`NSURLRequest`)）属性的的内存管理类型必须是 `copy` 的。

这是为了确保防止在不明确的情况下修改被封装好的对象的值(译者注：比如执行 array(定义为 copy 的 NSArray 实例) = mutableArray，copy 属性会让 array 的 setter 方法为 array = [mutableArray copy], [mutableArray copy] 返回的是不可变的 NSArray 实例，就保证了正确性。用其他属性修饰符修饰，容易在直接赋值的时候，array 指向的是 NSMuatbleArray 的实例，在之后可以随意改变它的值，就容易出错)。

你应该同时避免暴露在公开的接口中可变的对象，因为这允许你的类的使用者改变类自己的内部表示并且破坏类的封装。你可以提供可以只读的属性来返回你对象的不可变的副本。

```objective-c
/* .h */
@property (nonatomic, readonly) NSArray *elements

/* .m */
- (NSArray *)elements {
  return [self.mutableElements copy];
}
```

### 懒加载（Lazy Loading）

当实例化一个对象需要耗费很多资源，或者配置一次就要调用很多配置相关的方法而你又不想弄乱这些方法时，我们需要重写 getter 方法以延迟实例化，而不是在 init 方法里给对象分配内存。通常这种操作使用下面这样的模板：

```obj-c
- (NSDateFormatter *)dateFormatter {
  if (!_dateFormatter) {
    _dateFormatter = [[NSDateFormatter alloc] init];
        NSLocale *enUSPOSIXLocale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"];
        [_dateFormatter setLocale:enUSPOSIXLocale];
        [_dateFormatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss.SSS"];//毫秒是SSS，而非SSSSS
  }
  return _dateFormatter;
}
```

即使这样做在某些情况下很不错，但是在实际这样做之前应当深思熟虑。事实上，这样的做法是可以避免的。下面是使用延迟实例化的争议。

- getter 方法应该避免副作用。看到 getter 方法的时候，你不会想到会因此创建一个对象或导致副作用，实际上如果调用 getter 方法而不使用其返回值编译器会报警告 “Getter 不应该仅因它产生的副作用而被调用”。

> 副作用指当调用函数时，除了返回函数值之外，还对主调用函数产生附加的影响。例如修改全局变量（函数外的变量）或修改参数。函数副作用会给程序设计带来不必要的麻烦，给程序带来十分难以查找的错误，并且降低程序的可读性。（译者注）

- 你在第一次访问的时候改变了初始化的消耗，产生了副作用，这会让优化性能变得困难（以及测试）
- 这个初始化可能是不确定的：比如你期望属性第一次被一个方法访问，但是你改变了类的实现，访问器在你预期之前就得到了调用，这样可以导致问题，特别是初始化逻辑可能依赖于类的其他不同状态的时候。总的来说最好明确依赖关系。
- 这个行为不是 KVO 友好的。如果 getter 改变了引用，他应该通过一个 KVO 通知来通知改变。当访问 getter 的时候收到一个改变的通知很奇怪。

