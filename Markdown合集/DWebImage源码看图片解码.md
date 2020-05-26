# DWebImage源码看图片解码

**导语**：这是**SDWebImage源码理解**的第一篇，本篇先介绍图片解码相关的背景知识，然后介绍SDWebImage中解码的源码及其解码相关的问题。

> #### 一、背景知识

在SDWebImage中处理图片解码的是**SDWebImageDecoder**。

##### 1、图片加载

- iOS 提供了两种加载图片方法，分别是UIIImage的**imageNamed:** 和 UIIImage的**imageWithContentsOfFile:**。

- 其中，**imageNamed:** 方法的特点在于**可以缓存已经加载的图片**；使用时，先根据文件名在系统缓存中寻找图片，如果找到了就返回；如果没有，从Bundle内找到该文件，在渲染到屏幕时才**解码**图片，并将解码结果保留到缓存中；当收到内存警告时，缓存会被清空。当频繁加载同一张图片时，使用**imageNamed:** 效果比较好。而**imageWithContentsOfFile：**仅加载图片，不缓存图像数据。

- 虽然**imageNamed:** 方法利用缓存优化了图片的加载性能，但是第一次加载图片时，只在渲染的时候才在主线程**解码**，性能并不高效，尤其是在列表中加载多张高分辨率的图片（大图），可能会造成卡顿；

  **说明**：这里抛出**图片解码**的概念，SDWebImageDecoder这个类是为了优化解码效率存在的。

##### 2、图片解码

- 图像可以分为**矢量图**和**位图**，显示到屏幕中的图像是**位图图像**，位图图片格式有RGB、CMYK等颜色模式；其中RGB是最常用的颜色模式，它通过红(R)、绿(G)、蓝(B)三个颜色通道的数值表示颜色。手机显示屏使用自带Aphal通道(**RGBA**)的**RGB32**格式。

- 在项目中，通常使用的图片是JPG或PNG压缩格式，它们是经过**编码压缩**后的图片格式；而图片显示到屏幕之前，需要将JPG/PNG格式的图片**解码**成**位图图像**；这个解码工作是比较耗时的，而且不能使用GPU硬解码，只能通过**CPU软解码**实现（*硬解码是通过解码电路实现，软解码是通过解码算法、CPU的通用计算等方式实现软件层面的解码，效率不如GPU硬解码*）。

- iOS**默认**会在**UI主线程**对图像进行**解码**，解码后的图像大小和图片的宽高像素有关，宽高像素越大，位图图像就越大。假设一个3MB的图片，其宽高像素为2048 * 2048的图片，解码后的位图图像大小是**16MB**（2048 * 2048 * 4）。

  

  ```cpp
  //位图大小的计算公式，其中bytesPerPixel = 4B
  bitmap_size = imageSize.width * imageSize.height * bytesPerPixel
  ```

- 优化解码耗时的思路是：**将耗时的解码工作放在子线程中完成**。SDWebImage和FastImageCache就是这么做的。具体的解码工作就是SDWebImageDecoder负责的。

##### 3、图片重采样

- 在图片显示到屏幕前，除了要在主线程中**解码**，还会在主线程中完成**重采样**的工作。重采样算法一般有： **Nearest Neighbour Resampling** （最邻近重采样）、 **Bilinear Resampling**（双线性/两次线性重采样）、**Bicubic Resampling**  （双立方/两次立方重采样）等。
- **Nearest Neighbour Resampling**比较简单暴力，根据目标图像的宽高 与源图像的宽高比值，取源图像**相对位置的像素点的值**作为目标像素点的值；而**Bilinear Resampling**参考源像素位置周围4个点的值，按一定权重获得目标图像像素点的值；而**Bicubic Resampling**参考源像素点周围4*4个点的值，按一定权重获得目标图像像素点的值。
- 图像的放大和缩小都会引起重采样，放大图像称为**上采样/插值**（upsamping），缩小图像称为**小采样**（downsampling）。当图片的size和imageView的size不同时，发生重采样。

##### 4、总结

- **总结1**：**SDWebImage** 利用空间换时间的做法，在子线程中解码图片并缓存位图结果，避免图片的重复解码，提升图片展示性能。如果列表中需要展示很多网络图片，SDWebImage这种做法，有利于提高列表的流畅度。
- **总结2**：SDWebImage中下载的图片，即使解码缩放(decodedAndScaledDownImageWithImage:)后，图片大小 未必 和imageView的大小相同，这会引发**重采样**，我们可以在图片显示前，将图片裁剪成和imageView的大小相同，提升性能（一个小的优化点）。

> #### 二、源码说明

SDWebImageDecoder的源码有200多行，重要的函数两个。其一是：（默认）解码图片办法decodedImageWithImage: ；其二是：处理大图缩放和解码办法decodedAndScaledDownImageWithImage：。

##### 1、decodedImageWithImage:函数

- decodedImageWithImage实现了PNG、GIF、TIFF三类图片解码的问题，这是SDWebImage默认的解码操作；当它解码高分辨率图片，会导致内存暴增，甚至Crash。它造成的问题就是网上很多博客说的，“SDWebImage加载大图（高分辨率图），内存暴涨，导致加载失败的问题”。

- decodedImageWithImage函数很简单，主要步骤可以看成：先过滤掉不符合解码条件；再获得图片的信息；最后绘制出位图图片。

  

  ```objectivec
  1）shouldDecodeImage:过滤点不适合解码的image，分别是：image为nil、animated images 或 有透明度的图片
  2）获取图片的像素宽高(width、height)、颜色空间(colorspaceRef) 、行字节数（bytesPerRow，4 * width）等数据。
  3）使用创建CGBitmapContextCreate没有透明度的位图上下文，然后在该上下文中绘制出图像。
  ```

**说明**：解码操作在@autoreleasepool中，可以使得局部变量能尽早释放掉，避免内存峰值过高。

##### 2、decodedAndScaledDownImageWithImage:函数处理流程

- decodedAndScaledDownImageWithImage解决了PNG、GIF、TIFF三类高分辨率图片因解码导致内存暴增的问题，采用办法是：将大的原图缩放成指定大小的图片（个人感觉，思路应该来自苹果的[LargeImageDownsizing](https://link.jianshu.com?t=https://developer.apple.com/library/ios/samplecode/LargeImageDownsizing/Introduction/Intro.html)）。

- decodedAndScaledDownImageWithImage: 函数中主要步骤可以看成：先过滤掉不符合解码条件，位图大小不达标的（小于60MB）；再将原图按照固定大小分割，然后依次绘制到目标画布上（这部分最关键）。

- 在裁剪绘制过程中，主要步骤如下：

  

  ```cpp
  1）根据sourceTotalPixels（原图像素大小）和kDestTotalPixels（60MB对应的像素大小）获取imageScale；
  2）根据imageScale和原图的像素宽高获取 目标图的大小destResolution.size, 并创建目标位图上下文；
  3）获得原图分割图的size(sourceTile.size)，宽度和原图宽一样，高度是 (int)(kTileTotalPixels / sourceTile.size.width )，其中 kTileTotalPixels为20MB
  4）获取目标分割图的size(destTile.size)，宽度和目标图宽一样，高度是sourceTile.size.height * imageScale
  5）根据原图高（sourceResolution.height）除以原图分割图的高（sourceTile.size.height）获得获取分割块的个数iterations，如果还有余数，分割块个数（iterations）载累加1。
  6）从原图中裁剪出指定大小的分割图，然后绘制到目标上下文的指定位置。
  ```

  **注意**：Core Graphics的坐标系则是y轴向上的，UIKit框架坐标系是y轴向下的；使用CGContextDrawImage将sourceTileImageRef绘制到destContext中，为了避免图片上下文颠倒，**注意destTile.origin.y和sourceTile.origin.y的计算方式**。

  

  ```objectivec
  for( int y = 0; y < iterations; ++y ) {
      @autoreleasepool {
          //注意sourceTile.origin.y和destTile.origin.y的计算
          sourceTile.origin.y = y * sourceTileHeightMinusOverlap + sourceSeemOverlap;
          destTile.origin.y = destResolution.height - (( y + 1 ) * sourceTileHeightMinusOverlap * imageScale + kDestSeemOverlap);
          sourceTileImageRef = CGImageCreateWithImageInRect( sourceImageRef, sourceTile );
          if( y == iterations - 1 && remainder ) {
              float dify = destTile.size.height;
              destTile.size.height = CGImageGetHeight( sourceTileImageRef ) * imageScale;
              dify -= destTile.size.height;
              destTile.origin.y += dify;
          }
          CGContextDrawImage( destContext, destTile, sourceTileImageRef );
          CGImageRelease( sourceTileImageRef );
      }
  }
  ```

##### 3、CGBitmapContextCreate创建位图上下文

**函数原型**：*CGBitmapContextCreate(void \*data,size_t width,size_t height,size_t bitsPerComponent,size_t bytesPerRow,CGColorSpaceRef colorspace,CGBitmapInfo bitmapInfo)*

- 参数data：渲染目标的内存地址，内存块大小至少是(bytesPerRow * height) 个字节；一般传递NULL，让系统去分配和释放内存空间，避免内存泄漏问题。
- 参数width和height分别是：位图的宽高像素；
- 参数bitsPerComponent是：位图像素中每个组件的位数（number of bits）。对于32位像素格式和RGB 颜色空间，这个值是8；
- 参数bytesPerRow：在内存中，位图每一行所占的字节数。
- 参数 colorspace：位图的颜色空间。
- 参数 bitmapInfo：指出该位图是否包含 alpha 通道和它是如何产生的(RGB/RGBA/RGBX…)，还有每个通道应该用整数标识还是浮点数。值为kCGBitmapByteOrderDefault | kCGImageAlphaNoneSkipLast，表示着新的位图图像不使用后面8位的 alpha 通道的。

**说明**：一个新的位图上下文的像素格式由三个参数决定：每个组件的位数（bitsPerComponent），颜色空间（colorspace），alpha选项（bitmapInfo），alpha值决定了绘制像素的透明性。

> #### 三、解码高分辨率图的担忧

##### 1、“被嫌弃”的解码

- 网络上，很多博客都说到了使用SDWebImage加载（高分辨率）图片，发生内存暴涨，甚至导致Crash的问题；提出的解决的办法是，关闭解码操作。

  

  ```csharp
  // 关闭解码操作
  [[SDImageCache sharedImageCache] setShouldDecompressImages:NO];
  [[SDWebImageDownloader sharedDownloader] setShouldDecompressImages:NO];
  ```

- 关闭解码操作，将decodedImageWithImage解码高分辨率图的内存问题避开了，但是这意味着：如果大图多次加载显示，意味着在主线程要多次重复解码（这好像不是什么好事）；此外显示大图时，App依然会占用大量的内存，还可能造成卡顿；放弃SDWebImage解码并不能保证能应对所有高分辨图。所以说，**关闭解码操作并不是一个很好的选择**。

##### 2、加载高分辨率图问题

- 项目中，加载高分辨率图不可避免，如后台下发给我们一张大图（高分辨率图）；主线程解码（默认）可能导致卡顿；子线程解码可能因内存暴涨而Crash。解决办法可以参考 [LargeImageDownsizing](https://link.jianshu.com?t=https://developer.apple.com/library/ios/samplecode/LargeImageDownsizing/Introduction/Intro.html)。该Demo展示加载显示一个高分辨率（7033 × 10110 像素，位图大小271MB）图片的做法；其主要优化思路是：将大的原图缩放成指定大小的图片。decodedAndScaledDownImageWithImage就是采用这种思路。

- 在**decodedAndScaledDownImageWithImage:**函数中，为了避免内存暴增，将原图裁剪成多个小图，然后依次绘制到目标位图context中。项目中，我更愿意decodedAndScaledDownImageWithImage方法去解码高清晰图片，而不愿意禁止解码操作。

  

  ```objectivec
  //SDWebImageOptions选择SDWebImageScaleDownLargeImages，处理网络高分辨率图
  [self.imageView sd_setImageWithURL:url placeholderImage:nil options:SDWebImageScaleDownLargeImages];
  ```

- Apple提供了一个异步绘制内容的图层CATiledLayer，不需要加载全部图片，可以将大图分解成小图片，然后再载入显示，具体参考下[CATiledLayer](https://link.jianshu.com?t=https://zsisme.gitbooks.io/ios-/content/chapter6/catiledLayer.html)

##### 3、需要考虑的问题

凭心而论，后台不经处理，任意下发高分辨率大图这类事发生可能性很少；绝大部分场景下，iOS设备上不需要分辨率过高的图（iPhone X的屏幕尺寸也不过是1125px × 2436px），那我们应该考虑什么呢。

- **考虑1**：因为SDWebImage支持并发的解码操作，同时解码多张分辨率中等图片，占用的内存空间比较大，可能会给内存带来压力（小图不必担心）。可行的处理办法是，**限制并发解码的个数**。
- **考虑2**：如果后台下发的图片是带透明度的图片，SDWebImage并不会去做解码，这样的图片只能让iOS系统去解码。我能想到的办法：**尽可能让后台下发不透明的图片**。

> #### 四、解码中的小问题

SDWebImageDecoder的解码工作中，有两个小问题值得留意一下。

##### 1、颜色空间的问题

- 在创建位图，选用颜色空间时，如果图片的颜色空间模式是kCGColorSpaceModelUnknown（未知）、kCGColorSpaceModelMonochrome、kCGColorSpaceModelCMYK和kCGColorSpaceModelIndexed，默认使用**设备RGB颜色空间**(通过CGColorSpaceCreateDeviceRGB获得)，详见代码：

  

  ```objectivec
  + (CGColorSpaceRef)colorSpaceForImageRef:(CGImageRef)imageRef {
    // current
    CGColorSpaceModel imageColorSpaceModel = CGColorSpaceGetModel(CGImageGetColorSpace(imageRef));
    CGColorSpaceRef colorspaceRef = CGImageGetColorSpace(imageRef);  
    BOOL unsupportedColorSpace = (imageColorSpaceModel == kCGColorSpaceModelUnknown ||
                                  imageColorSpaceModel == kCGColorSpaceModelMonochrome ||
                                  imageColorSpaceModel == kCGColorSpaceModelCMYK ||
                                  imageColorSpaceModel == kCGColorSpaceModelIndexed);
    if (unsupportedColorSpace) {
        colorspaceRef = CGColorSpaceCreateDeviceRGB();
        CFAutorelease(colorspaceRef);
    }
    return colorspaceRef;
  }
  ```

**这么做的原因，我认为只要有两点**：

- RGB颜色模式几乎包括了人类视力所能感知的所有颜色，而SDWebImageDecoder中主要支持PNG、JPG、TIFF常见图片格式的解码，它们大部分采用RGB色彩模式；目前手机屏、电脑显示屏大都采用了RGB颜色模式。
- 对应Monochrome、CMYK和Indexed这样的模式，使用设备RGB颜色空间(device color space)，其结果是可以接受的。一张灰度图片，颜色空间模式是kCGColorSpaceModelMonochrome，使用**设备灰度颜色空间**和**设备RGB颜色空间**都可以，只是使用**设备灰度颜色空间**内存上效果会好一些。

##### 2、解码不透明图片的问题

- SDWebImage中不解码透明的图片，猜测原因是：在UI渲染视图时，如果某个layer透明时，需要叠加计算下方多层的像素；如果某个layer不透明，可以忽略掉下方的图层，减少了GPU像素混合计算。使用CGBitmapContextCreate 时 bitmapInfo 参数设置为忽略掉 alpha 通道，绘制出不透明的位图图片，在渲染视图，能减少GPU的计算，提高性能。

> #### End

- **参考资料**

  [一张图片引发的深思](https://link.jianshu.com?t=http://honglu.me/2016/09/02/一张图片引发的深思/?utm_source=tuicool&utm_medium=referral)
   [绘制像素到屏幕上](https://link.jianshu.com?t=https://objccn.io/issue-3-1/)

  

