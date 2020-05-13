# UIKit性能的一些重要方面

正如我们从[Google](https://think.storage.googleapis.com/images/micromoments-guide-to-winning-shift-to-mobile-download.pdf)关于微时刻的[报告中](https://think.storage.googleapis.com/images/micromoments-guide-to-winning-shift-to-mobile-download.pdf)了解到的那样，当加载时间太长时，有70％的人会放弃应用程序。这就是为什么您的应用程序必须流畅，流畅的原因。UIKit性能优化是确保这一点的主要方法之一。
 
在本文中，我们将讨论如何提高iOS应用程序（以及iOS开发人员）的UIKit性能。我们将考虑快速凉爽的UI所依赖的最关键的事情和最佳实践。准备？我们走吧！

## UIKit的主要问题是什么？

我们将要讨论的第一个问题是颜色混合。混合是帧渲染的阶段，在此阶段中将计算最终的像素颜色。如果将一组属性（例如**alpha**，**backgroundColor**，**opaque**和所有重叠的视图）组合在一起，则每个**UIView**（更精确地说，每个**CALayer**）都会影响最终像素的颜色。让我们从最常用的UIView属性开始：**UIView.alpha**，**UIView.opaque**和**UIView.backgroundColor**。
 

### 不透明与透明

**UIView.opaque**告诉渲染器将视图视为完全不透明的图块，从而提高了绘图性能。不透明选项允许渲染器在生成最终颜色时跳过绘制基础视图以及进行颜色混合。正确只使用视图的最上面的颜色。

### Α

如果alpha属性的值小于1，则不透明标志将被忽略（即使其值为**YES**）。

```objectivec
    let purpleRect = UIView(frame: purpleRectFrame)
    purpleRect.backgroundColor = .purple
    purpleRect.alpha = 0.5

    view.addSubview(purpleRect)
```

![混合层](https://yalantis.com/uploads/ckeditor/pictures/4413/color-blending.png)

尽管opaque的默认值为YES，但我们可以进行颜色混合，因为我们通过将alpha属性的值设置为**小于1**来使视图透明。

## 如何找到混合图层？

免责声明：如果需要有关实际性能的准确信息，则应在真实的iOS设备（而不是模拟器）上测试UIKit应用程序。iOS CPU比Mac CPU慢，并且iOS设备中的GPU与Mac中的GPU有很大不同。对于我们的测试，我们使用： 

- 具有iOS 13.2的iPhone 7（17B84）
- Xcode 11.3.1（11C504）
- 装有macOS 10.15.2（19C57）的MacBook Pro


让我们转到Xcode iOS模拟器中的“ **调试”菜单**，找到一个名为“ **Color Blended Layers”**的项目。它告诉调试器显示多个半透明层重叠的混合视图层。突出显示为红色的层是多个视图层，它们在启用混合的情况下彼此叠加。绿色突出显示的图层是绘制的多个视图图层，没有融合。

要在iOS设备上为混合图层着色，请在Xcode中转到**调试–>查看调试–>渲染–>混合图层**。

![核心动画界面](https://yalantis.com/uploads/ckeditor/pictures/4470/debug-dropdown-menu.png)

下面，我们将说明测试时使用混合图层的情况。

### 图片中的Alpha通道

当Alpha通道影响UIImageView透明度（以及UIImageView的alpha属性）时，就会发生颜色混合。让我们为[UIImage](https://stackoverflow.com/questions/5084845/how-to-set-the-opacity-alpha-of-a-uiimage )使用一个类别，以使用自定义Alpha通道接收图像：

```swift
extension UIImage {
  func image(withAlpha value: CGFloat) -> UIImage? {
    UIGraphicsBeginImageContextWithOptions(size, false, 0)
 
    let ctx = UIGraphicsGetCurrentContext()
    let area = CGRect.init(origin: .zero, size: size)
 
    ctx?.scaleBy(x: 1, y: -1)
    ctx?.translateBy(x: 0, y: -area.height)
    ctx?.setBlendMode(.multiply)
    ctx?.setAlpha(value)
    ctx?.draw(cgImage!, in: area)
 
    let newImage = UIGraphicsGetImageFromCurrentImageContext()
    UIGraphicsEndImageContext()
 
    return newImage
  }
}
```

我们将考虑Alpha通道的四种可能的透明度组合：

1. UIImageView具有alpha属性的默认值（1.0），并且图像没有alpha通道。
2. UIImageView的默认值为alpha属性（1.0），并且图像的alpha通道已修改为0.5。
3. UIImageView的alpha属性的值已修改，并且图像没有alpha通道。
4. UIImageView的alpha属性的值已修改，并且图像的alpha通道已修改为0.5。

```swift
  override func viewDidLoad() {
    super.viewDidLoad()
    createImageViews()

    let flowerImage = UIImage(named: "flower")
    let flowerImageWithAlpha = UIImage(named: "flower")?.image(withAlpha: 0.5)

    imageView1.image = flowerImage

    imageView2.image = flowerImageWithAlpha

    imageView3.image = flowerImage
    imageView3.alpha = 0.5

    imageView4.image = flowerImageWithAlpha
    imageView4.alpha = 0.5
  }
```

![色彩融合示例](https://yalantis.com/uploads/ckeditor/pictures/4548/color-blending-example.png)

**另请参阅**： [通过单独的数据源实现轻量级iOS View Controller](https://yalantis.com/blog/lightweight-ios-view-controllers-separate-data-sources-guided-mvc/)

iOS模拟器向我们显示了混合视图层。因此，即使我们的UIImageView实例具有默认值为1.0的alpha属性，并且图像具有修改后的alpha通道，我们也会得到一个混合层。这可能就是为什么Apple官方文档鼓励我们在选择此选项以最大程度地提高性能时减少应用程序中的红色数量的原因。该文档还指出，混合视图图层通常是导致表格滚动缓慢的原因。

要渲染透明层，您需要执行其他计算。系统必须将图层与下面的图层混合，以计算其颜色并绘制图像。

### 屏幕外渲染

屏幕外渲染是无法使用GPU完成的绘制，而应在CPU上执行。从低层次看，它看起来像这样：当渲染需要屏幕外渲染的图层时，GPU会停止渲染管道并将控制权传递给CPU。接下来，CPU执行所有必要的操作，并将控制权与渲染层一起返回给GPU。GPU渲染该层，并且渲染管道不断进行。此外，屏幕外渲染需要为所谓的后备存储分配额外的内存。但是，硬件加速层不需要此功能。

![屏幕渲染](https://yalantis.com/uploads/ckeditor/pictures/4416/onscreen-rendering.png)

### ![屏幕外渲染](https://yalantis.com/uploads/ckeditor/pictures/4417/offscreen-rendering.png)

以下是发生屏幕外渲染的情况：
自定义**drawRect**（即使
**仅用**颜色填充背景）**CALayer**角半径
**CALayer**阴影
**CALayer**遮罩
使用**CGContext的**任何自定义图形

我们可以使用Xcode或iOS模拟器中的“ **调试”**菜单轻松检测屏幕外渲染。屏幕外渲染发生的每个地方都将被黄色覆盖。

![核心动画混合层](https://yalantis.com/uploads/ckeditor/pictures/4465/debug-menu-color-blending.png)

在进行测试之前，您应该牢记一件重要的事情：不要滥用覆盖-drawRect的内容。这样做很容易导致屏幕外渲染，即使是在需要用颜色填充背景的简单情况下。

-drawRect方法不合理有两个原因。首先，系统视图可能会实现私有的绘制方法来呈现其内容，很明显，Apple致力于优化绘制。另外，我们应该记住后备存储区-视图的新后备图像，其像素尺寸等于视图大小乘以**contentsScale**，它将被缓存直到视图需要更新它为止。

其次，如果避免重写**-drawRect**，则无需为后备存储分配额外的内存（我们可以最大限度地减少内存占用），并且在每次执行新的绘制周期时将其归零。

![支持商店计划](https://yalantis.com/uploads/ckeditor/pictures/4419/backing-store-scheme.png)

## 如何测试UIKit性能？ 

我们将从几个屏幕外渲染案例开始，然后测试性能。我们将尝试找到合适的解决方案，以改善性能并以出色的设计实现您的愿景。

### 圆角

让我们使用自定义单元格创建一个简单的tableView，并将**UIImageView**和**UILabel**放入我们的单元格原型中。还记得按钮圆滑的美好时光吗？为了在**tableView中**实现这种奇特效果，我们需要将**CALayer.cornerRadius**和**CALayer.maskToBounds**设置为**YES**。

```swift
  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: UITableViewCell.self), for: indexPath)

    cell.textLabel?.text = "Cell: \(indexPath.row)"

    cell.imageView?.layer.cornerRadius = 22
    cell.imageView?.layer.masksToBounds = true
    cell.imageView?.image = UIImage(named: "flower")

    return cell
  }
```

 ![圆角按钮](https://yalantis.com/uploads/ckeditor/pictures/4420/rounded-corner.png)

尽管在没有使用Instruments的情况下我们已经达到了预期的效果，但性能与建议的每秒60帧（FPS）的差距仍然很大。这就是为什么我们将使用Instruments测试性能。

首先，启用“ **屏幕外渲染的黄色”**选项。这样，所有的UIImageView实例都将被黄色覆盖。

![带阴影效果的圆角](https://yalantis.com/uploads/ckeditor/pictures/4421/adding-the-shadow-effect.png)

现在，我们应该使用乐器中的“核心动画”工具检查性能。

![核心动画测试结果](https://yalantis.com/uploads/ckeditor/pictures/4656/core-animation-test-results.png)

显然，我们需要另一种方法来达到预期的效果并提高性能。让我们使用**UIImage**的类别来使圆角变圆，而不是使用**cornerRadius**属性。

```swift
extension UIImage {
  func yal_imageWithRoundedCorners(and size: CGSize) -> UIImage? {
    let rect = CGRect(origin: .zero, size: size)

    UIGraphicsBeginImageContextWithOptions(size, false, UIScreen.main.scale)

    let ctx = UIGraphicsGetCurrentContext()
    ctx?.addPath(UIBezierPath(roundedRect: rect, cornerRadius: size.width).cgPath)
    ctx?.clip()

    draw(in: rect)

    let output = UIGraphicsGetImageFromCurrentImageContext()
    UIGraphicsEndImageContext()

    return output
  }
}
```

另外，让我们修改**dataSource**方法**cellForRowAtIndexPath的实现**。

```swift
  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: UITableViewCell.self), for: indexPath)

    cell.textLabel?.text = "Cell: \(indexPath.row)"

    let image = UIImage(named: "flower")
    let imageSize = CGSize(width: 66.0, height: 66.0)
    cell.imageView?.image = image?.yal_imageWithRoundedCorners(and: imageSize)

    return cell
  }
```

当对象首次放置在屏幕上时，绘图代码仅被调用一次。它被缓存在视图的**CALayer中**，无需附加图形即可进行动画处理。尽管这种方法比Core Animation方法要慢，但它使我们能够将每帧成本转换为一次性成本。

在回到衡量性能之前，让我们再检查一次屏幕外渲染。

![对UIImage使用类别](https://yalantis.com/uploads/ckeditor/pictures/4423/shadow-added.png)

好极了！现在我们获得了两倍的FPS：59到60！ 

![带有UIImage类别的核心动画测试结果](https://yalantis.com/uploads/ckeditor/pictures/4424/core-animation-test-results-with-category.png)

### CALayer.shouldRasterize

加快屏幕外渲染性能的另一种方法是使用CALayer.shouldRasterize属性。它告诉绘图系统一次渲染该图层并缓存其内容，直到需要重新绘制该图层为止。
 
但是，如果iOS必须过于频繁地重绘图层，则缓存将变得无用，因为每次绘制后系统都会栅格化图层。最后，CALayer.shouldRasterize的用法取决于特定的用例和Instruments中的分析结果。

### 阴影和shadowPath

阴影可以使UI更加美观。在iOS上，添加阴影效果很容易：

```objectivec
    cell.imageView?.layer.shadowOpacity = 0.5
    cell.imageView?.layer.shadowRadius = 30
```

![阴影离屏](https://yalantis.com/uploads/ckeditor/pictures/4425/adding-the-shadow-effect.png)

启用屏幕外渲染后，阴影会添加屏幕外渲染，并默认使Core Animation实时计算阴影路径。这导致较低的FPS。
 
苹果实际上[警告我们](https://developer.apple.com/library/archive/documentation/Cocoa/Conceptual/CoreAnimation_guide/ImprovingAnimationPerformance/ImprovingAnimationPerformance.html)添加阴影的成本：*让Core Animation确定*阴影
 
*的形状可能会很昂贵，并影响应用程序的性能。而不是让Core Animation确定阴影的形状，而是使用**CALayer**的shadowPath属性显式指定阴影形状。当您为此属性指定路径对象时，Core Animation将使用该形状绘制并缓存阴影效果。对于形状从未改变或很少改变的图层，这可以通过减少Core Animation完成的渲染量来极大地提高性能。*
 
因此，基本上我们需要为CoreAnimation 提供一个缓存的阴影路径（**CGPath**），这很容易做到：

 

```objectivec
if let rect = cell.imageView?.bounds {
  cell.imageView?.layer.shadowPath = UIBezierPath(rect: rect).cgPath
}
```

![影子不离谱](https://yalantis.com/uploads/ckeditor/pictures/4426/shadow-added.png)

现在要了解的是，我们仅使用了一行代码即可删除屏幕外渲染并提高性能数英里。老实说，有许多与UI相关的性能问题可以通过库，某些框架和一些技巧轻松解决。因此，UIKit框架开发人员（以及其他开发人员）也请继续关注更简单的解决方案和建议，以提高应用程序性能。而且，不要忘记在优化前后都评估性能！



[原文](https://yalantis.com/blog/mastering-uikit-performance/)

