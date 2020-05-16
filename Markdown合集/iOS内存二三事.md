# iOS内存二三事

简单总结下iOS内存方面的一些知识

### 一、内存基础概念

#### 1、物理内存 & 虚拟内存

- **物理内存（Physical Memory）**: 指通过物理内存条而获得的内存空间，和虚拟内存对应；主要作用是：设备运行时为操作系统和各种程序提供临时储存空间；iPhone 6 和 6 Plus 及之前都是1G 内存，目前比较新的iPhone XS和XS Max是4GB内存；
- **虚拟内存(Virtual Memory)**：是计算机系统内存管理的一种技术，为每一个进程提供了一个**一致的、私有的地址空间**；其主要作用是：保护了每个进程的地址空间不会被其他进程破坏，降低内存管理的复杂性；32位设备虚拟内存大小是4GB，64位设备（5s以后的设备）是 4GB * 4GB；
- 虚拟内存是进程运行时所有内存空间的总和，并且可能有一部分不在物理内存中；

#### 2、段页式存储

- 目前，大部分通用的计算机的内存管理使用**段页式存储结构**；用户程序先分段，每个段内再分页；而**页是存储的最基本单位**，iOS设备的arm64架构后，页大小是16KB；
- 利用**逻辑地址**(段号 + 段内页号 + 页内地址) 进行地址变化，获得物理地址；这样的话，在段页式结构中，须**三次访问**内存才能获取数据或指令；
- 当进程访问一个虚拟内存的页时，而对应的物理内存却不存在时，会触发一次**Page Fault**（**缺页中断**），将需要的数据 or 指令从磁盘加载到物理内存页中，建立映射关系，然后再恢复现场，程序本身是无感知的；

#### 3、Swap In/Out & Page In/Out

- 磁盘内部有一个区域叫做**交换空间**(Swap Space)，MMU(内存管理单元) 会将**暂时不用的内存块内容**写在交互空间上(硬盘)，这就是**Swap Out**；当需要时候再从Swap Space中读取到内存中，这就是**Swap In**；Swap in和swap out的操作都是比较耗时的, 频繁的Swap in和Swap out操作非常影响系统性能；
- **Page In/Out**和 **Swap In/Out** 概念类似，只不过Page In/Out是将**某些页**的数据写到内存/从内存写回磁盘交互区；而Swap In/Out是将**整个地址空间**的数据写到内存/从内存写回磁盘交互区；本质都是交互机制。
- macOS支持这类交换机制，但是iOS不支持；主要有两方面考虑吧：
  - 移动设备的闪存读写次数有限，频繁写会降低寿命；
  - 相比PC机，移动设备闪存空间有限(15年6s最小存储空间16GB、最大128GB；19年XS Max最小64GB，最大521GB)

#### 4、to be continued

- 通用的计算机（*大型机和专用计算机不在此范围*）的存储器一般设置为多层，从最靠近CPU的Cache一直到磁盘，速度越来越慢，价格也越来越便宜。
- 为了充分利用好硬件资源，Cache和Swap机制应运而生，Cache机制是一种用空间换时间的机制；而Swap机制是使用时间换空间的；
- 但是，iOS系统舍弃交换机制，取而代之的是**压缩内存（Compressed memory）机制**；

### 二、iOS内存管理基础概念

#### 1、iOS的内存分区

从高地址到低地址各区域如下：

- **栈区(stack)**： 由编译器⾃动分配，存放函数的参数值，局部变量的值等，作用域执行完毕之后，就会被系统收回；(栈区的地址从高到低分配)

- **堆区(heap)**：一般由程序员分配和释放，用于存放程序运行中被动态分配的内存段；iOS中的Objective-C对象存放在这里，由ARC管理；（堆区的地址是从低到高分配）

- 全局区静态区

  ：由编译器分配，主要是存放全局变量 和 静态变量，程序结束后由系统释放；主要分两个区：

  - **BSS区**：**未初始化**的全局变量 和 静态变量；
  - **数据区**：**已初始化**的全局变量 和 静态变量；

- **常量区：** 存放的是常量，如常量字符串，程序结束后由系统释放；

- **代码区**：存放函数体的二进制代码，程序结束后由系统释放；



![内存分区示意](https://user-gold-cdn.xitu.io/2020/4/9/1715e3aff4615a4d)







#### 2、内存页类型：Clean和Dirty

- 内存页按照各自的**分配和使用**状态，分为 `Clean` 和 `Dirty` 两类。其中`Clean Page`是可以被回收的，`Dirty Page`不能；

  ```objective-c
  int *array = malloc(20000 * sizeof(int)); // 第1步
  array[0] = 32                             // 第2步
  array[19999] = 64                         // 第3步
  
  ```

- 第一步，申请一块长度为80000 字节的内存空间，按照一页 16KB 来计算，就需要 6 页内存来存储。当这些内存页开辟出来的时候，它们都是 Clean 的；

- 第二步，向处于第一页的内存写入数据时，第一页内存会变成 Dirty；

- 第三步，当向处于最后一页的内存写入数据时，这一页也会变成 Dirty；

#### 3、VM Region

- iOS进程中所有内存就是由许许多多的`VM Region`组成的；

- `VM Region`指**一段连续的内存页（在虚拟地址空间里）**，[VM Region](https://opensource.apple.com/source/xnu/xnu-792/osfmk/mach/vm_region.h)的结构如下

  ```objective-c
  struct vm_region_submap_info_64 {
  	vm_prot_t		protection;     /* present access protection */
  	vm_prot_t		max_protection; /* max avail through vm_prot */
  	vm_inherit_t		inheritance;/* behavior of map/obj on fork */
  	memory_object_offset_t	offset;		/* offset into object/map */
    unsigned int            user_tag;	/* user tag on map entry */
    unsigned int            pages_resident;	/* only valid for objects */
    unsigned int            pages_shared_now_private; /* only for objects */
    unsigned int            pages_swapped_out; /* only for objects */
    unsigned int            pages_dirtied;   /* only for objects */
    unsigned int            ref_count;	 /* obj/map mappers, etc */
    unsigned short          shadow_depth; 	/* only for obj */
    unsigned char           external_pager;  /* only for obj */
    unsigned char           share_mode;	/* see enumeration */
  	boolean_t		is_submap;	/* submap vs obj */
  	vm_behavior_t		behavior;	/* access behavior hint */
  	vm_offset_t		object_id;	/* obj/map name, not a handle */
  	unsigned short		user_wired_count; 
  };
  
  ```

- VM Region包含的重要信息有：

  - **pages_resident**：在用的物理内存页数
  - **pages_dirtied**：Dirty的内存页数
  - **pages_swapped_out**：Swapped的内存页数（**实际指的是被Compressed Memory页数**）

- 可以通过了解**pages_dirtied**和**pages_swapped_out**来了解`VM Region`的真实物理内存使用。

### 三、iOS内存管理机制

#### 1、OC的内存管理

- Objective-C提供两种方式的内存管理方式：**MRC**（手动管理引用计数）和 **ARC**（自动引用计数）
- Objective-C内存管理的基本原则：谁创建，谁释放，谁引用，谁管理；
- iOS 5之后提出的ARC被广泛接收，毕竟不需要管理引用计数是个很爽的事情；有了ARC，开开心心写OC；但是**ARC只管理Objective-C对象的内存**，CoreFoundation对象、CoreGraphics对象、还有C/C++的内存分配还是需要开发者自己管理。



![OC的内存管理图](https://user-gold-cdn.xitu.io/2020/4/9/1715e39230e29f4a)



#### 2、系统内存分类

 从 iOS7 开始，系统开始采用`Compressed Memory`机制优化内存使用，内存类型可以分为三类：

- `Clean Memory`：可以被释放或重建的，主要包括：

  - Code
  - framework，每个 framework都有 `_DATA_CONST` 段，当 App 在运行时使用到了某个 framework，它所对应的 `_DATA_CONST` 的内存就会由 Clean 变为 Dirty。
  - memory-mapped files（已被加载到内存中的文件）

- `Dirty Memory`：指那些被写入过数据的内存，主要包括：

  - 所有堆区中的对象（Heap allocations）
  - 图像解码缓冲区（Decoded image buffers）
  - frameworks（framework中 `_DATA` 段和 `_DATA_DIRTY` 段）

  ```
  	在使用 framework 的过程中会产生Dirty Memory，使用单例或者全局初始化方法是减少Dirty Memory；这是因为单例一旦创建就不会销毁，全局初始化方法会在 class 加载时执行。
  
  ```

- `Compressed Memory`：

  - 在内存吃紧时，系统会将不使用的内存进行压缩(Compresses unaccessed pages)
  - 在需要的时候，进行解压 （Decompresses pages upon access）
  - 优势：减少了不活跃内存占用；减少磁盘IO带来的损耗；压缩/解压十分迅速，能够尽可能减少 CPU 的时间开销；支持多核操作。
  - **举例**：当我们使用 `NSDictionary` 去缓存数据的时候，假设现在已经使用了 3 页内存，当不访问的时候可能会被压缩为 1 页，再次使用到时候又会解压成 3 页。

- 介绍`Clear Memory`和 `Dirty Memory` 的Code如下：

  ```objective-c
  //堆分配的内存 Dirty Memory
  NSString *str1 = [NSString stringWithString:@"Welcome!"]; 
  //常量字符串, 存放在一个只读数据段里面,这段内存释放后,还可以在读取重建 Clear Memory
  NSString *str2 = @"Welcome!"; 
  //分配100M虚拟内存,当没有用时没有建立映射,Clear Memory
  char *buf = malloc(100 * 1024 *1024); 关系
  for (int i = 0; i < 3 * 1024 * 1024; ++i) {
      //写入数据了,Dirty Memory
  		buf[i] = rand();									
  }
  
  ```

- **说明**：在内存吃紧的情况下，释放`Clean Memory`，不能释放`Dirty Memory` ，所以`Dirty Memory` 的内存越多，App的稳定性越差。

#### 3、`Jetsam`机制

- Jetsam机制是操作系统为了控制内存资源过度使用而采用的一种管理机制；Jetsam是一个独立运行的进程，会把一些**优先级不高或者占用内存过大的**App杀掉；在杀掉App后会记录一些数据信息并保存到日志。

- App优先级可以这么简单理解：前台App > 后台App; 占用内存少 > 占用内存多；

- Jetsam产生的这些日志可以在**手机设置->隐私->分析**中找到，日志是以`JetsamEvent`开头，日志中有内存页大小(pageSize)，CPU时间(cpuTime)等字段。

- 查看`设置->隐私->分析`中以JetsamEvent开头的系统日志，关注两个重要的信息；

  ```
  "pageSize" : 16384,
  //内存页达到上限
  "rpages" : 948,      //App 占用的内存页数量
  "reason" : "per-process-limit",  //App 占用的内存超过了系统对单个 App 的内存限制。
  ```

  - **说明**：该内存“上限”计算：pageSize *rpages = 16384* 948 /1024/1014 = 14.8MB，这个App应该是因优先级不高而被强杀，毕竟App内存使用上限不可能不到15MB。

#### 4、内存警告

- 内存警告（Memory Warning）三种通知方式:
  - **UIApplicationDelegate**的`applicationDidReceiveMemoryWarning:`
  - 视图控制器**UIViewController**的`didReceiveMemoryWarning`
  - **UIApplicationDidReceiveMemoryWarningNotification**通知
- 出现OOM前不一定出现内存警告；有可能是瞬间申请了大量内存，而恰好此时主线程在忙于其他事情，导致可能没有经历过Memory Warning就发生了OOM；也可能即便出现了多次Memory Warning后，也不见得会在最后一次Memory Warning的几秒钟后出现OOM(可能是1-2分钟后)；
- 并非所有内存警告都是由 App 造成的，例如在内存较小的设备上，当你接听电话的时候也有可能发生内存警告。

### 四、常见的内存类问题

#### 1、FOOM

- FOOM（Foreground Out Of Memory），是指App**在前台**因消耗内存过多引起系统强杀。对用户而言，表现跟Crash一样。
- Facebook早在2015年8月提出FOOM检测办法，大致原理是排除各种情况后，剩余的情况是FOOM；Facebook如何判定上一次启动是否出现FOOM方法：
  - 1.App没有升级
  - 2.App没有调用exit()或abort()退出
  - 3.App没有出现Crash (依赖于自身CrashReport组件的Crash回调)
  - 4.用户没有强退App
  - 5.系统没有升级/重启
  - 6.App当时没有后台运行（依赖于ApplicationState和前后台切换通知）
  - 7.App出现FOOM （依赖于ApplicationState和前后台切换通知）
- 排查法有误报的可能，因为有些被系统强杀case，但是我们捕获不到信息，也可能被归类到OOM；已知被系统强杀的case是：OOM和watchdog(Code 0x8badf00d)。
- 发现FOOM问题的关键：监控App使用内存增长，在收到内存警告通知时，dump 内存信息，获取对象名称、对象个数、各对象的内存值，并在合适的时机上报到服务器；加强对大内存的分配监控。

#### 2、内存泄露

- 内存泄露(Memory Leak)：指申请的内存空间使用完毕之后**未回收**，内存泄露问题多的话，对App质量影响很大；
- 目前引起内存泄露的主要原因是循环引用(堆内存中对象相互引用，彼此都得不到释放的机会)，目前，调试阶段使用Instrument的Leaks工具发现，线上利用MLeaksFinder发现后上报；
- 如何避免内存泄露在后面有介绍

#### 3、WKWebview白屏

- WKWebview白屏问题，严格来说，是一种内存方面的问题；之前的UIWebview因为内存使用过大会Crash，而WKWebview不会Crash，会白屏；

- WKWebView是一个多进程组件，`Network Loading`以及`UI Rendering`在其它进程中执行，当WKWebView总体的内存占用比较大时，`WebContent Process`会Crash，从而出现白屏现象。

- **解决办法**：

  - KVO监听URL, 当URL为nil，重新reload

  - 在进程被终止回调中，重新reload

    ```objective-c
    // 此方法适用iOS9.0以上 
    - (void)webViewWebContentProcessDidTerminate:(WKWebView *)webView NS_AVAILABLE(10_11, 9_0){
    		//reload
    }
    
    ```

#### 4、野指针问题

- **野指针**：指向一个已删除的对象 或 受限内存区域的指针；目前此类问题很少了，主要来自两个方面
  - MRC时代 到 ARC时代，OC对象管理极大方便了，ARC解决大部分野指针问题
  - iOS 9开始，系统库中部分遗留的被`assign(unsafe_unretain)`修饰的 `delegate`和`target-action`修改成了weak，内存被回收的时候，这些指针设为nil，这也大幅度减少了野指针的出现。
- 目前绝大部分App都是iOS 9起步，野指针少了很多，但是工程中依然会有野指针问题，本质还是内存使用不当；
- `Mach Exception`大多数都是野指针的问题，崩溃日志里最多见`objc_msgSend`和`unrecognized selector sent to`等等。
- 对于野指针问题，最好能复现，使用`Zombie Object` 帮助调试，`Zombie Object` 实现原理就是 hook 住了对象的`dealloc`方法，通过调用自己的`__dealloc_zombie`方法来把对象进行僵尸化，当这个对象再次收到消息,`objc_msgsend`的时候，调用abort()崩溃并打印出调用的方法。。

> **iOS 9以后NSNotificationCenter不需要手动移除观察者**
>
> - 在iOS9之前，通知中心使用 **unsafe_unretained**修饰引用观察者，如果观察者被回收时，若不手动移除，指针会指向被回收的内存区域，变为野指针，如果再发送消息会造成Crash；
> - 而iOS 9之后，通知中心使用**weak**修饰引用观察者 ，即使不手动移除观察者，weak指针也会在观察者被回收后自动置nil。之后发送消息，是不会有问题的。

#### 5、iOS 10 nano_free Crash

- 在iOS 10.0 - 10.1，苹果bug引入nano_free Crash问题，这些Crash发生`libsystem_malloc.dylib`中的 `nano zone`内的；

- `libsystem_malloc.dylib`中，对内存的管理有两个实现：`nano zone`和`scalable zone`。他们分别管理不同大小的内存块：

  - 内存分配函数malloc和calloc等默认使用的是nano_zone，nao_zone是 256B 以下小内存的分配，
  - 大于 256B 的时候会使用 **scalable_zone** 来分配。

- 当时微信团队提出的几种解决思路，最后给的解决方案是**不使用nano zone**，具体描述

  - 创建一个自己的zone，命名为`guard zone`。

  - 修改nano zone的函数指针，重定向到guard zone(通过

    ```
    malloc_zone_create
    ```

    创建的)。

    - 对于没有传入指针的函数，直接重定向到guard zone
    - 对于有传入指针的函数，先用size判断所属的zone，再进行分发。

- 更多见：

  - [聊聊苹果的Bug - iOS 10 nano_free Crash](https://cloud.tencent.com/developer/article/1031006)
  - [libsystem_malloc.dylib 源码](https://opensource.apple.com/tarballs/libmalloc/)

#### 6、to be continued

- 内存类问题排查难度大，复杂。需要对内存有更深入的理解
- 为了避免内存问题：根本上是优化内存使用，主要表现在：减少大块内存使用，降低内存峰值，避免内存泄露，处理内存警告;

### 五、优化内存使用

#### 1、降低图片解码和渲染开销

- 将图片渲染显示在屏幕上，需要先将其解码成位图；而位图大小：**像素高 \* 像素宽 \* 4字节**(*4字节对应一个像素点，4个通道的大小*)；图片解码会造成内存使用上升，尤其是高分辨率图解码可能导致内存暴涨；
- 代码优化建议：
  - 善待"大"图（位图大小大于60MB）解码：将原图裁剪成多个小图，然后依次绘制到目标位图context中，具体可见SDWebImage中和关于**decodedAndScaledDownImageWithImage:**的实现；
  - 限制并发解码图片的个数；
    - 图片大小调整和显示大小一样，以此避免重采样(重采样也很消耗资源，放大图像称为上采样/插值（upsamping），缩小图像为小采样（downsampling));
    - 使用 ImageIO直接读取图像大小和元数据信息，减少内存开销。
    - iOS10后使用 `UIGraphicsImageRenderer` 创建 image 上下文，而不是`UIGraphicsBeginImageContextWithOptions`，因为前者的性能更好、更高效，并且支持广色域；

#### 2、其他降低内存峰值办法

- 合理使用`autorealsepool`，降低内存峰值，避免 OOM
  - 基于引用计数,Pool执行drain方法会release所有该Pool中的autorelease对象
  - 可以嵌套多个AutoReleasePool
  - 每个线程并没有设置默认的AutoReleasePool,需要手动创建,避免内存泄露
  - 在一段内存分配频繁的代码中嵌套AutoReleasePool有利于降低整体内存峰值
- 复用大内存对象，如UITableViewCell对象；懒加载大的内存对象
- imageNamed 和 imageWithContentOfFile 的选择
  - imageNamed使用系统缓存，适用于频繁使用的小图片
  - imageWithContentOfFile不带缓存机制,适用于大图片,使用完就释放
- 建议NSData读取文件方式
  - 建议使用`[NSData dataWithContentsOfFile:path options:NSDataReadingMappedIfSafe error:&error]`;
  - 该API映射文件到虚拟内存, 只有读取操作的时候才会读取相应页的内容到物理内存页中；
- 用 `NSCache` 代替 `NSMutableDictionary`， 因为 `NSCache` 可以自动清理内存，在内存吃紧的时候会更加合理。
  - NSCache有2种界限条件:totalCostLimt & countLimit，超过这两种界限后系统会去释放一些旧的资源.
  - 监听到内存警告消息后移除所有Cache
- 使用 NSPurgableData 代替NSData，主要原因如下：
  - 当系统处于低内存的时候会自动移除
  - 适用于大数据
- **栈内存分配**：`alloca(size_t)`
  - 栈分配仅仅修改栈指针寄存器，比malloc遍历并修改空闲列表要快得多
  - 栈内存一般都已经在物理内存中，不用担心页错误
  - 函数返回的时候栈分配的空间都会自动释放
  - 但仅适合小空间的分配,并且函数嵌套不宜过深
- **堆内存分配**：**calloc** **VS** **malloc + memset**
  - `calloc(size_t num,size_t size)`分配内存时是虚拟内存，只有在访问的时候才会发生物理页的映射关系；
  - `malloc + memset` 会产生`Dirty Memory`
  - `calloc`函数得到的内存空间是经过初始化的，其内容全为0，而`malloc`函数得到的内存空间是未初始化的，必须使用memset函数来初始化；

#### 3、避免循环引用，减少内存泄露

- 代码优化建议
  - 申明代理(delegate)为weak；
  - 使用 `weak strong dance` 来解决 block 中的循环引用问题；
  - 实现NSProxy(虚拟类)的子类，然后在子类中定义weak修饰的target，然后实现消息转发方法，使target处理业务逻辑；一般用于解决NSTimer、CADisplayLink的循环引用；
  - CoreFoundation对象、CoreGraphics对象、还有C/C++的内存分配需要管理好，有malloc就要有free
- 善用工具：**MLeaksFinder + Instrument** 或 **FBMemoryProfiler + Instrument**组合使用。通过MLeaksFinder/FBMemoryProfiler发现后。然后使用Instrument再验证；

#### 4、处理内存警告

- Memory Warning时，尽可能释放多资源，尤其图片等占内存多的资源，等需要用的时候再重建；
- Memory Warning时，部分单例对象可考虑释放掉；
- **Memory Warning时，不建议self.view = nil**：iOS 6之后，系统发出 Memory Warning 时，**系统会自动回收CALayer的CABackingStore对象(bitmap 内容)**；虽然没有回收 UIView 和 CALayer 类，但是也回收了大部分内存，在需要 bitmap 类时，通过调用 UIView 的 drawRect: 方法重建。
- 最佳的实践还是**减少大块内存使用，降低内存峰值，避免内存泄露**。

### 历史文章

**之前对内存问题一些整理**

- [OC对象内存小记](http://nanhuacoder.top/2018/01/30/iOS-iOSMemory)
- [OOM问题小记](http://nanhuacoder.top/2019/04/17/iOS-OOM/)

**之前对图片解码和图片优化一些总结**

- [篇1：SDWebImage源码看图片解码](https://www.jianshu.com/p/728f71b9fe28)
- [iOS实录17：网络图片的优化显示](https://www.jianshu.com/p/a38a7c7bccbb)
- [图片解码小记](http://nanhuacoder.top/2019/03/13/iOS-PicDecode)

### 参考文章

[深入了解iOS中的OOM(低内存崩溃)](https://blog.csdn.net/TuGeLe/article/details/104004692)

[WWDC 2018：iOS 内存深入研究](https://juejin.im/post/5b23dafee51d4558e03cbf4f#heading-3)

[page fault带来的性能问题](https://yq.aliyun.com/articles/55820)

[iOS微信内存监控](https://wetest.qq.com/lab/view/367.html)

[iOS野指针定位总结](https://juejin.im/post/5c23397f6fb9a049ca376534)

[iOS中的内存管理](https://www.jianshu.com/p/8e764d05275b)

[iOS 内存管理研究](https://zhuanlan.zhihu.com/p/49829766)

[Linux对内存的管理, 以及page fault的概念](https://www.jianshu.com/p/f9b8c139c2ed)

[iOS内存管理和malloc源码解读](https://yq.aliyun.com/articles/3065)

[libmalloc源码分析之初始化](https://turingh.github.io/2016/06/28/libmalloc源码分析之初始化/)

关注下面的标签，发现更多相似文章