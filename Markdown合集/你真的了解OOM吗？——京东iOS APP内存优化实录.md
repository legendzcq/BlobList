

### 你真的了解OOM吗？——京东iOS APP内存优化实录

我们都知道手机的物理内存是有限的，App的内存优化不仅能使其自身更少出现内存耗尽（OOM，Out-Of-Memory）崩溃，同时也能让系统后台“保留”更多应用（包括自己的App），以便更快地被唤起，提升用户移动设备的整体使用体验。

为此，我们对京东iOS App整体进行了一次内存使用优化，使京东App的OOM发生概率下降了50%左右，现在将前期调研学习到的一些知识和具体的优化方案分享出来。

### OOM崩溃从何而来

在Linux系统中，交换空间（swap space）可以用来存放内存中不常用的临时数据。而iOS因为闪存容量和读写寿命的原因并没有引入交换空间，取而代之的是Compressed memory技术，既当内存紧张时压缩一些内存内容，并在需要时解压。但这样会造成较高的CPU占用甚至卡顿，手机耗电量也会随之增加。因此iOS的内存空间显得更为珍贵。

**为此苹果设计了Jetsam机制。**

其实之前不太了解这个名词的同学，可以在我们手机的“设置->隐私->分析->分析数据”中，看到一些"JetsamEvent-"开头的日志，这些都是由于OOM问题而上报的。打开一份日志，点击屏幕右上角分享按钮，将日志分享到电脑中，搜索"reason"可以看到：

```
 {
    "uuid" : "7682d50d-b09e-38ac-bd5c-a99c8fde1a8c",
    "states" : [
      "frontmost"
    ],
    "killDelta" : 2941,
    "genCount" : 0,
    "age" : 4630423870208,
    "purgeable" : 1,
    "fds" : 100,
    "coalition" : 70,
    "rpages" : 17928,
    "reason" : "highwater",
    "pid" : 57,
    "cpuTime" : 2622.5295529999999,
    "name" : "SpringBoard",
    "lifetimeMax" : 17929
  }
```

笔者手机这次OOM是大名鼎鼎的SpringBoard（相当于Windows的“桌面”进程）被杀掉，而对应的原因"highwater"会在后文中进行介绍。

在苹果官方文档中，关于Low Memory Reports有下面一段介绍：

> When a low-memory condition is detected, the virtual memory system in iOS relies on the cooperation of applications to release memory. Low-memory notifications are sent to all running applications and processes as a request to free up memory, hoping to reduce the amount of memory in use. If memory pressure still exists, the system may terminate background processes to ease memory pressure. If enough memory can be freed up, your application will continue to run. If not, your application will be terminated by iOS because there isn't enough memory to satisfy the application's demands, and a low memory report will be generated and stored on the device. 

大意是当内存不足时，系统会先通知各个运行中的App去释放内存（既 - (void)applicationDidReceiveMemoryWarning:(UIApplication *)application;方法和UIApplicationDidReceiveMemoryWarningNotification通知），如果内存压力依然存在，将会终止一些后台进程。最终内存还不够的话，就会杀掉当前App并且上报日志。

**我们也可以在开源的iOS XNU内核源码中，窥探苹果Jetsam的具体实现。**

内存资源监测相关主要在kern_memorystatus.h 和 kern_memorystatus.c中，这里只贴几处较为关键的部分，感兴趣的同学可以去整体阅读一下源码。

OS X和iOS实现了一个低内存情形的处理机制，称为Jetsam，或者叫做Memorystatus。Jetsam的名字来源于杀掉消耗内存最多的进程并且抛弃（jettison）这些进程占用的内存页面的过程。它在内核中维护了一个快照，这个快照包含系统中所有进程的状态以及消耗的内存页面数。同时还维护了一个优先级数组，用以在内存不足时按顺序结束进程，数组每一项是一个包含进程链表list的结构体。结构体定义如下：

```c
#define MEMSTAT_BUCKET_COUNT (JETSAM_PRIORITY_MAX + 1)

typedef struct memstat_bucket {
    TAILQ_HEAD(, proc) list;
    int count;
} memstat_bucket_t;

memstat_bucket_t memstat_bucket[MEMSTAT_BUCKET_COUNT];复制代码
```

在kern_memorystatus.h文件中，我们可以找到这个数组长度JETSAM_PRIORITY_MAX和进程优先级相关的定义：



```c
#define JETSAM_PRIORITY_IDLE_HEAD                -2
/* The value -1 is an alias to JETSAM_PRIORITY_DEFAULT */
#define JETSAM_PRIORITY_IDLE                      0
#define JETSAM_PRIORITY_IDLE_DEFERRED         1 /* Keeping this around till all xnu_quick_tests can be moved away from it.*/
#define JETSAM_PRIORITY_AGING_BAND1       JETSAM_PRIORITY_IDLE_DEFERRED
#define JETSAM_PRIORITY_BACKGROUND_OPPORTUNISTIC  2
#define JETSAM_PRIORITY_AGING_BAND2       JETSAM_PRIORITY_BACKGROUND_OPPORTUNISTIC
#define JETSAM_PRIORITY_BACKGROUND                3
#define JETSAM_PRIORITY_ELEVATED_INACTIVE     JETSAM_PRIORITY_BACKGROUND
#define JETSAM_PRIORITY_MAIL                      4
#define JETSAM_PRIORITY_PHONE                     5
#define JETSAM_PRIORITY_UI_SUPPORT                8
#define JETSAM_PRIORITY_FOREGROUND_SUPPORT        9
#define JETSAM_PRIORITY_FOREGROUND               10
#define JETSAM_PRIORITY_AUDIO_AND_ACCESSORY      12
#define JETSAM_PRIORITY_CONDUCTOR                13
#define JETSAM_PRIORITY_HOME                     16
#define JETSAM_PRIORITY_EXECUTIVE                17
#define JETSAM_PRIORITY_IMPORTANT                18
#define JETSAM_PRIORITY_CRITICAL                 19

#define JETSAM_PRIORITY_MAX                      21
```

其中数值越大，优先级越高。可以关注：后台应用程序优先级JETSAM_PRIORITY_BACKGROUND 是3，低于前台应用程序优先级JETSAM_PRIORITY_FOREGROUND 10，而SpringBoard位于JETSAM_PRIORITY_HOME 16。

在kern_memorystatus.c文件开头，能看到所有OOM日志中可能出现的原因：

```c
/* For logging clarity */
static const char *memorystatus_kill_cause_name[] = {
    ""                              ,       /* kMemorystatusInvalid                         */
    "jettisoned"                    ,       /* kMemorystatusKilled                          */
    "highwater"                     ,       /* kMemorystatusKilledHiwat                     */
    "vnode-limit"                   ,       /* kMemorystatusKilledVnodes                    */
    "vm-pageshortage"               ,       /* kMemorystatusKilledVMPageShortage            */
    "proc-thrashing"                ,       /* kMemorystatusKilledProcThrashing             */
    "fc-thrashing"                  ,       /* kMemorystatusKilledFCThrashing               */
    "per-process-limit"             ,       /* kMemorystatusKilledPerProcessLimit           */
    "disk-space-shortage"           ,       /* kMemorystatusKilledDiskSpaceShortage         */
    "idle-exit"                     ,       /* kMemorystatusKilledIdleExit                  */
    "zone-map-exhaustion"           ,       /* kMemorystatusKilledZoneMapExhaustion         */
    "vm-compressor-thrashing"       ,       /* kMemorystatusKilledVMCompressorThrashing     */
    "vm-compressor-space-shortage"  ,       /* kMemorystatusKilledVMCompressorSpaceShortage */
};
```

不过这里不要被这里的"disk-space-shortage"迷惑，只有MacOS的OOM才有可能上报这种类型（iOS没有交换空间）。还有一些是虚拟内存导致的OOM，篇幅限制这里就不展开讨论了。

接下来让我们看看memorystatus_init这个函数里面初始化JETSAM线程的关键部分代码：

```c
__private_extern__ void
memorystatus_init(void)
{
    ... 
    /* Initialize all the jetsam threads */
    for (i = 0; i < max_jetsam_threads; i++) {
        result = kernel_thread_start_priority(memorystatus_thread, NULL, 95 /* MAXPRI_KERNEL */, &jetsam_threads[i].thread);
        if (result == KERN_SUCCESS) {
            jetsam_threads[i].inited = FALSE;
            jetsam_threads[i].index = i;
            thread_deallocate(jetsam_threads[i].thread);
        } else {
            panic("Could not create memorystatus_thread %d", i);
        }
    }
}
```

①首先，在这里会根据内核启动参数和设备性能，开启max_jetsam_threads个（一般为1。特殊情况开启fast jetsam且设备允许时，可能为3个）jetsam线程，这些线程的优先级是内核所能分配的最高级（95 /* MAXPRI_KERNEL */）。在版本老一些的源码中，这里只创建了一个名为"VM_memorystatus"的线程，而现在每个线程名后面加上了它被创建的次序。（注意:前文的-2~19是进程优先级区间，而这里的95是线程优先级，XNU的线程优先级范围是0~127）。

②继续看memorystatus_thread这个线程启动的初始化函数：

```c
static void
memorystatus_thread(void *param __unused, wait_result_t wr __unused)
{
    ...
    while (memorystatus_action_needed()) {
        cause = kill_under_pressure_cause;
        switch (cause) {
            ...
        }
    ...
}
```

可以看到memorystatus_init开启了一个memorystatus_action_needed控制的while循环持续释放内存：

```c
static boolean_t
memorystatus_action_needed(void)
{
    ...
    return (is_reason_thrashing(kill_under_pressure_cause) ||
            is_reason_zone_map_exhaustion(kill_under_pressure_cause) ||
           memorystatus_available_pages <= memorystatus_available_pages_pressure);
    ...
}
```

这里通过接受vm_pageout守护程序（实际上是一个线程）发送的内存压力来判断当前内存资源是否紧张。内存紧张的情况可能是：操作系统的抖动（Thrashing，频繁的内存页面（page）换进换出并占用CPU过度），虚拟内存耗尽（比如有人从硬盘向ZFS池中拷贝1TB的数据），或者内存可用页低于阈值memorystatus_available_pages_pressure。

③如果内存紧张，将先触发High-water类型的OOM。这种类型的OOM会在某个进程使用内存超过了其最高内存使用限制"high water mark"(HWM)时发生。在memorystatus_act_on_hiwat_processes(),通过memorystatus_kill_hiwat_proc()，在上文提到的memstat_bucket中查找优先级最低的进程，如果进程的内存小于阈值（footprint_in_bytes <= memlimit_in_bytes），则继续寻找下一个优先级次低的进程，直到找到占用内存超过阈值的，并将其杀掉，函数返回。

```c
    
        /* Highwater */
        boolean_t is_critical = TRUE;
        if (memorystatus_act_on_hiwat_processes(&errors, &hwm_kill, &post_snapshot, &is_critical)) {
            if (is_critical == FALSE) {
                break;
            } else {
                goto done;
            }
        }
       
```

④不过High-water的阈值较高，一般不容易触发。如果通过其不能结束任何进程，将走入memorystatus_act_aggressive()函数里，也就是大部分OOM发生的地方。

```c
   
    if (memorystatus_act_aggressive(cause, jetsam_reason, &jld_idle_kills, &corpse_list_purged, &post_snapshot)) {
        goto done;
    }
    
```

在这里，将分三步释放内存：

1.先回收优先级极低的进程和一些正常情况下随时可回收的进程。

2.如果内存压力依然存在，继续杀掉后台进程。

3.最终走投无路，就会发生FOOM（Foreground Out-Of-Memory），即前台进程被系统结束(memorystatus_kill_top_process_aggressive())。

**了解OOM发生的原理后其实可以发现，优化自身App内存不仅能降低OOM崩溃率，同时当大家的App都非常“自律”地使用内存时，即使应用间互相切换，App们依然能在后台保留用户的使用状态，随时“热启动”，体验较好。**

### 我们能做些什么

* 图片内存使用优化

1.使用适当尺寸的图片

我们知道，解压后的图片是由一个个像素点组成的。每个像素点一般有R、G、B、A（红绿蓝透明度）四个通道，每个通道是8位，因此一个像素通常占用4字节。对于一张图片，如果同样是300*300分辨率的jpeg和png两张图，文件大小可能差几倍，但是渲染后的内存开销是完全一样的。

而由于机型的不同，下载的图片经常与最终展示在界面上的尺寸不同。如果我们将一张矩形图片展示在很小的view里，原图解压会消耗大量内存，但最终大部分像素最终都被丢掉浪费了。或者将图片手动缩放成合适大小，处理过程中仍然可能会多占用一部分内存。

因此，我们与服务端共同制定了一套方案，在服务端将图片裁剪成控件的精确尺寸（记得乘上屏幕缩放比例[UIScreen mainScreen].scale）下发到不同机型，从根本上将内存使用降低。

2.及时回收图片

单张图片占用内存不多，累计起来却非常可观。因此，当页面pop掉时，有必要清理页面内图片的内存缓存。其次，列表类的页面在滑动时，可以及时清理那些滑出屏幕图片的内存缓存。

3.注意图片缩放方式

参考Apple的 WWDC18 Session 416 —— iOS Memory Deep Dive，处理图片缩放时，直接使用UIImage会在解码时读取文件占用一部分内存，还会生成中间位图bitmap消耗大量内存，而ImageIO不存在上述两种内存消耗，只会占用最终图片大小的内存。（此处可以参考Linux的mmap内存映射）

常见的UIimage缩放写法： 

```objective-c
- (UIImage *)scaleImage:(UIImage *)image newSize:(CGSize)newSize{
    UIGraphicsBeginImageContextWithOptions(newSize, NO, 0);
    [image drawInRect:CGRectMake(0, 0, newSize.width, newSize.height)];
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    　
    return newImage;
}
```

节约内存的ImageIO缩放写法：

```objective-c
+ (UIImage *)scaledImageWithData:(NSData *)data withSize:(CGSize)size scale:(CGFloat)scale orientation:(UIImageOrientation)orientation{
    CGFloat maxPixelSize = MAX(size.width, size.height);
    CGImageSourceRef sourceRef = CGImageSourceCreateWithData((__bridge CFDataRef)data, nil);
    NSDictionary *options = @{(__bridge id)kCGImageSourceCreateThumbnailFromImageAlways : (__bridge id)kCFBooleanTrue,
                              (__bridge id)kCGImageSourceThumbnailMaxPixelSize : [NSNumber numberWithFloat:maxPixelSize]};
    CGImageRef imageRef = CGImageSourceCreateThumbnailAtIndex(sourceRef, 0, (__bridge CFDictionaryRef)options);
    UIImage *resultImage = [UIImage imageWithCGImage:imageRef scale:scale orientation:orientation];
    CGImageRelease(imageRef);
    CFRelease(sourceRef);
　
    return resultImage; 
}
```

* 合理使用自动释放池



自动释放池（autoreleasePool）相信大家一定很熟悉，它的实现可以称得上苹果“代码的艺术”，网上资料也非常多。但其实在实际开发中，可能并没有引起我们的足够重视，在一些该加的地方没有加。通常autoreleased对象在runloop结束时才释放。如果在一些体循环中，或者很复杂的逻辑中产生大量autoreleased对象，内存峰值会猛涨，容易触发OOM。

其实，自动释放池的效果非常显著，能够让对象更及时释放，降低内存峰值，我们的线上数据也证明其能非常有效地降低OOM发生。当然了，这与APP的类型、代码实际处理的业务也密切相关。 

* 对象按需创建

页面内除最主要的展示外，其他控件尽量采用懒加载的方式，待数据返回后或者需要展示时再进行加载。需要注意的还有包含元素过多、size过大的界面，会消耗大量内存，同时也会造成卡顿，应尽量优化其结构，降低页面复杂度。还可以排查代码的逻辑，将不必要的单例对象改为懒加载的普通对象，使用完也能及时释放掉。

* 避免内存泄露

每个版本发布前，我们都会对基础页面和有新增改动的页面进行内存泄漏检测。开发和Review时也应注意是否存在循环引用，CF类型内存是否释放，UIGraphicsBeginImageContext和UIGraphicsEndImageContext是否成对出现等问题。

### 最后

App的发展和手机的进化，其实是一个动态博弈的过程。用户想要更流畅顺滑的操作体验，手机可用资源也在增加，但总归有限。CPU与内存在某一方资源不足时会去补足，某一方资源充足时又可以分担对方的负担，也就是常说的是去“时间换空间”还是“空间换时间”。我们每一个开发工程师就是在这样的平衡之间“跳舞”，争取用现成的最少的资源，实现最佳的效果。

参考资料

1.《深入解析Mac OS X & iOS操作系统》 Jonathan 清华大学出版社

2.《No pressure，Mon! —— Handling low memory conditions in iOS and Mavericks》 Jonathan Levin

3.《Understanding and Analyzing Application Crash Reports》 Apple

4.WWDC18 Session 416 —— iOS Memory Deep Dive Apple

5.《iOS内存abort（jetsam）原理探究》 SatanWoo

6.《iOS内存管理研究》 即刻技术团队

7.《iOS微信内存监控》 杨津