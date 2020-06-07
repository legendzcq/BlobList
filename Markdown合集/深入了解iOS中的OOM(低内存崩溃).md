# 深入了解iOS中的OOM(低内存崩溃)

原文：https://blog.csdn.net/TuGeLe/article/details/104004692





在iOS开发过程或者用户反馈中，可能会经常看到这样的情况，用着用着就崩溃了，而在后台查看崩溃栈的时候，找不到崩溃日志。其实这大多数的可能是系统产生了低内存崩溃，也就是OOM(还有一种可能是主线程卡死，导致watchdog杀掉了应用)，而低内存崩溃的日志，往往都是以JetsamEvent开头的，日志中有内存页大小(pageSize)，CPU时间(cpuTime)等字段。



## 什么是OOM？
什么是OOM呢，它是out-of-memory的缩写，字面意思就是内存超过了限制。它是由于 iOS 的 Jetsam机制造成的一种“另类” Crash，它不同于常规的Crash，通过Signal捕获等Crash监控方案无法捕获到OOM事件。

当然还会有FOOM这样的词，代表的是Foreground-out-of-memory，是指App在前台因消耗内存过多引起系统强杀。这也就是本文要讨论的。后台出现OOM不一定都是app本身造成的，大多数是因为当前在前台的App占用内存过大，系统为了保证前台应用正常运行，把后台应用清理掉了。

## 什么是Jetsam机制
Jetsam机制可以理解为操作系统为了控制内存资源过度使用而采用的一种管理机制。Jetsam是一个独立运行的进程，每一个进程都有一个内存阈值，一旦超过这个阈值Jetsam就会立刻杀掉这个进程。

## 为什么要设计Jetsam机制
首先设备的内存是有限制的，并不是无限大的，所以内存资源非常重要。系统进程及用户使用的其他app的进程都会争抢这个资源。由于iOS不支持交换空间，一旦触发低内存事件，Jetsam就会尽可能多的释放应用占用的内存，这样在iOS系统上出现系统内存不足时，应用就会被系统终止。

## 交换空间
物理内存不够使用该怎么办呢？像一些桌面操作系统，会有内存交换空间，在window上称为虚拟内存。它的机制是，在需要时能将物理内存中的一部分交换到硬盘上去，利用硬盘空间扩展内存空间。

## iOS不支持交换空间
但iOS并不支持交换空间，大多数移动设备都不支持交换空间。移动设备的大容量存储器通常是闪存，它的读写速度远远小于电脑所使用的硬盘，这就导致在移动设备上就算使用了交换空间，也并不能提升性能。其次，移动设备的容量本身就经常短缺、内存的读写寿命也有限，所以在这种情况下还拿闪存来做内存交换，就有点奢侈了。

需要注意的是，网上有少出文章说iOS没有虚拟内存机制，实际上指的是iOS没有交换空间机制。

## 典型app内存类型
当内存不足的时候，系统会按照一定策略来腾出更多空间供使用，比较常见的做法是将一部分低优先级的数据挪到磁盘上，这个操作称为Page Out。之后当再次访问到这块数据的时候，系统会负责将它重新搬回内存空间中，这个操作称为Page In。

## Clean Memory
Clean Memory是指那些可以用以Page Out的内存，只读的内存映射文件，或者是App所用到的frameworks。每个frameworks都有_DATA_CONST段，通常他们都是Clean的，但如果用runtime进行swizzling，那么他们就会变Dirty。

## Dirty Memory
Dirty Memory是指那些被App写入过数据的内存，包括所有堆区的对象、图像解码缓冲区，同时，类似Clean memory，也包括App所用到的frameworks。每个framework都会有_DATA段和_DATA_DIRTY段，它们的内存是Dirty的。

值得注意的是，在使用framework的过程中会产生Dirty Memory，使用单例或者全局初始化方法是减少Dirty Memory不错的方法，因为单例一旦创建就不会销毁，全局初始化方法会在类加载时执行。

## Compressed Memory
由于闪存容量和读写寿命的限制，iOS 上没有交换空间机制，取而代之使用Compressed memory。

Compressed memory是在内存紧张时能够将最近使用过的内存占用压缩至原有大小的一半以下，并且能够在需要时解压复用。它在节省内存的同时提高了系统的响应速度，特点总结起来如下：

Shrinks memory usage 减少了不活跃内存占用
Improves power efficiency 改善电源效率，通过压缩减少磁盘IO带来的损耗
Minimizes CPU usage 压缩/解压十分迅速，能够尽可能减少 CPU 的时间开销
Is multicore aware 支持多核操作
例如，当我们使用Dictionary去缓存数据的时候，假设现在已经使用了3页内存，当不访问的时候可能会被压缩为1页，再次使用到时候又会解压成3页。

> 本质上，Compressed memory也是Dirty memory。
> 因此， memory footprint = dirty size + compressed size ，这也就是我们需要并且能够尝试去减少的内存占用。

## Memory Warning
相信对于MemoryWarning并不陌生，每一个UIViewController都会有一个didReceivedMemoryWarning的方法。

当使用的内存是一点点上涨时，而不是一下子直接把内存撑爆。在达到内存临界点之前，系统会给各个正在运行的应用发出内存警告，告知app去清理自己的内存。而内存警告，并不总是由于自身app导致的。

内存压缩技术使得释放内存变得复杂。内存压缩技术在操作系统层面实现，对进程无感知。有趣的是如果当前进程收到了内存警告，进程这时候准备释放大量的误用内存，如果访问到过多的压缩内存，再解压缩内存的时候反而会导致内存压力更大，然后出现OOM，被系统杀掉。

我们对数据进行缓存的目的是想减少 CPU 的压力，但是过多的缓存又会占用过大的内存。在一些需要缓存数据的场景下，可以考虑使用NSCache代替NSDictionary，NSCache分配的内存实际上是Purgeable Memory，可以由系统自动释放。这点在Effective Objective 2.0一书中也有推荐NSCache与NSPureableData的结合使用既能让系统根据情况回收内存，也可以在内存清理的同时移除相关对象。

出现OOM前一定会出现Memory Warning么？ 答案是不一定，有可能瞬间申请了大量内存，而恰好此时主线程在忙于其他事情，导致可能没有经历过Memory Warning就发生了OOM。当然即便出现了多次Memory Warning后，也不见得会在最后一次Memory Warning的几秒钟后出现OOM。之前做extension开发的时候，就经常会出现Memory Warnning，但是不会出现OOM，再操作一两分钟后，才出现OOM，而在这一两分钟内，没有再出现过Memory Warning。

当然在内存警告时，处理内存，可以在一定程度上避免出现OOM。

## 如何确定OOM的阈值
有经验的同学，肯定知道不同设备OOM的阈值是不同的。那我们该如何知道OOM的阈值呢？

### 方法1
当我们的App被Jetsam机制杀死的时候，在手机中会生成系统日志，在手机系统设置-隐私-分析中，可以得到JetSamEvent开头的日志。这些日志中就可以获取到一些关于App的内存信息，例如我当前用的iPhone8(iOS11.4.1)，在日志中的前部分看到了pageSize，而查找per-process-limit一项(并不是所有日志都有，可以找有的)，用该项的rpages * pageSize即可得到OOM的阈值。

```
{"bug_type":"298","timestamp":"2020-01-03 04:11:13.65 +0800","os_version":"iPhone OS 11.4.1 (15G77)","incident_id":"2723B2EA-7FB8-49A6-B2FC-49F10C748D8A"}
{
  "crashReporterKey" : "a6ad027ba01b1e66d0b3d8446aaef5dbd75dd732",
  "kernel" : "Darwin Kernel Version 17.7.0: Mon Jun 11 19:06:27 PDT 2018; root:xnu-4570.70.24~3\/RELEASE_ARM64_T8015",
  "product" : "iPhone10,1",
  "incident" : "2723B2EA-7FB8-49A6-B2FC-49F10C748D8A",
  "date" : "2020-01-03 04:11:13.65 +0800",
  "build" : "iPhone OS 11.4.1 (15G77)",
  "timeDelta" : 4,
  "memoryStatus" : {
  "compressorSize" : 39010,
  "compressions" : 2282594,
  "decompressions" : 1071238,
  "zoneMapCap" : 402653184,
  "largestZone" : "APFS_4K_OBJS",
  "largestZoneSize" : 35962880,
  "pageSize" : 16384,
  "uncompressed" : 105360,
  "zoneMapSize" : 118865920,
  "memoryPages" : {
    "active" : 39800,
    "throttled" : 0,
    "fileBacked" : 28778,
    "wired" : 19947,
    "anonymous" : 32084,
    "purgeable" : 543,
    "inactive" : 19877,
    "free" : 2935,
    "speculative" : 1185
  }
},
...
  {
    "uuid" : "a2f9f2db-a110-3896-a0ec-d82c156055ed",
    "states" : [
      "frontmost",
      "resume"
    ],
    "killDelta" : 11351,
    "genCount" : 0,
    "age" : 361742447,
    "purgeable" : 0,
    "fds" : 50,
    "coalition" : 2694,
    "rpages" : 89600,
    "reason" : "per-process-limit",
    "pid" : 2541,
    "cpuTime" : 1.65848,
    "name" : "MemoryTest",
    "lifetimeMax" : 24126
  },
```



那么当前这个MemoryTest的内存阈值就是16384 * 89600 / 1024 / 1024 = 1400MB。

### 方法2
当前网络上已经有人很多人整理的OOM内存对应表，我这边根据实际情况比较倾向于该版本。

```
I created one more list by sorting Jaspers list by device RAM (I made my own tests with Split's tool and fixed some results - check my comments in Jaspers thread).

device RAM: percent range to crash

256MB: 49% - 51%
512MB: 53% - 63%
1024MB: 57% - 68%
2048MB: 68% - 69%
3072MB: 63% - 66%
4096MB: 77%
6144MB: 81%

Special cases:

iPhone X (3072MB): 50%
iPhone XS/XS Max (4096MB): 55%
iPhone XR (3072MB): 63%
iPhone 11/11 Pro Max (4096MB): 54% - 55%

Device RAM can be read easily:

[NSProcessInfo processInfo].physicalMemory
From my experience it is safe to use 45% for 1GB devices, 50% for 2/3GB devices and 55% for 4GB devices. Percent for macOS can be a bit bigger.
```
### 方法3
首先，我们可以通过方法得到当前应用程序占用的内存。代码如下

```c
- (int)usedSizeOfMemory {
    task_vm_info_data_t taskInfo;
    mach_msg_type_number_t infoCount = TASK_VM_INFO_COUNT;
    kern_return_t kernReturn = task_info(mach_task_self(), TASK_VM_INFO, (task_info_t)&taskInfo, &infoCount);

    if (kernReturn != KERN_SUCCESS) {
        return 0;
    }
    return (int)(taskInfo.phys_footprint / 1024 / 1024);

}
```

也有其他一些代码使用过的是taskInfo.resident_size，但该值并不准确。我对比Xcode Debug，发现taskInfo.phys_footprint值基本上与Xcode Debug的值一致。而在XNU的task.c中，也找到了该值是如何计算的。
```c
/*
 * phys_footprint
 *   Physical footprint: This is the sum of:
 *     + (internal - alternate_accounting)
 *     + (internal_compressed - alternate_accounting_compressed)
 *     + iokit_mapped
 *     + purgeable_nonvolatile
 *     + purgeable_nonvolatile_compressed
 *     + page_table
 */
 本地测试了一下：
 iOS11上，phys_footprint值与Xcode DEBUG的值相差不到1M，
 而在iOS13上，phys_footprint值与Xcode DEBUG值完全一致。
 有强迫症的同学可以在iOS11上使用
 （(taskInfo.internal + taskInfo.compressed - taskInfo.purgeable_volatile_pmap)）来代替phys_footprint。
```
那么我们可以得到这个值之后，就可以开一个线程，循环申请1MB的内存，直至到达第一次内存警告，以及OOM。
```objective-c
#import "ViewController.h"
#import <mach/mach.h>

#define kOneMB  1048576

@interface ViewController ()
{
    NSTimer *timer;

    int allocatedMB;
    Byte *p[10000];
    
    int physicalMemorySizeMB;
    int memoryWarningSizeMB;
    int memoryLimitSizeMB;
    BOOL firstMemoryWarningReceived;
}

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    physicalMemorySizeMB = (int)([[NSProcessInfo processInfo] physicalMemory] / kOneMB);
    firstMemoryWarningReceived = YES;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
        
    if (firstMemoryWarningReceived == NO) {
        return ;
    }
    memoryWarningSizeMB = [self usedSizeOfMemory];
    firstMemoryWarningReceived = NO;
}

- (IBAction)startTest:(UIButton *)button {
    [timer invalidate];
    timer = [NSTimer scheduledTimerWithTimeInterval:0.01 target:self selector:@selector(allocateMemory) userInfo:nil repeats:YES];
}

- (void)allocateMemory {
  
    p[allocatedMB] = malloc(1048576);
    memset(p[allocatedMB], 0, 1048576);
    allocatedMB += 1;
    
    memoryLimitSizeMB = [self usedSizeOfMemory];
    if (memoryWarningSizeMB && memoryLimitSizeMB) {
        NSLog(@"----- memory warnning:%dMB, memory limit:%dMB", memoryWarningSizeMB, memoryLimitSizeMB);
    }
}

- (int)usedSizeOfMemory {
    task_vm_info_data_t taskInfo;
    mach_msg_type_number_t infoCount = TASK_VM_INFO_COUNT;
    kern_return_t kernReturn = task_info(mach_task_self(), TASK_VM_INFO, (task_info_t)&taskInfo, &infoCount);

    if (kernReturn != KERN_SUCCESS) {
        return 0;
    }
    return (int)(taskInfo.phys_footprint / kOneMB);
}

@end
```

这样我们debug，查看控制台最后一条log即可。
```
2020-01-03 11:52:26.353765+0800 MemoryTest[2561:599014] ----- memory warnning:1289MB, memory limit:1397MB
2020-01-03 11:52:26.363799+0800 MemoryTest[2561:599014] ----- memory warnning:1289MB, memory limit:1398MB
2020-01-03 11:52:26.373895+0800 MemoryTest[2561:599014] ----- memory warnning:1289MB, memory limit:1399MB
```
我们发现，内存警告是1289MB，我们有记录的OOM的log到1399MB，那么也说明OOM值为1400MB。

方法4（适用于iOS13系统）
iOS13系统os/proc.h中提供了新的API，可以查看当前可用内存
```c
#import <os/proc.h>

extern size_t os_proc_available_memory(void);

+ (CGFloat)availableSizeOfMemory {
    if (@available(iOS 13.0, *)) {
        return os_proc_available_memory() / 1024.0 / 1024.0;
    }
    // ...
}
```
有了这个值，我们就可以计算出当前应用的内存限制。用了一个iPhone Xs Max测试了一下。通过方法1获取到的内存限制值为134278 * 16384 / 1024 / 1024 = 2098M。通过方法3获取到的内存值为2098M。
```c
- (int)limitSizeOfMemory {
    if (@available(iOS 13.0, *)) {
        task_vm_info_data_t taskInfo;
        mach_msg_type_number_t infoCount = TASK_VM_INFO_COUNT;
        kern_return_t kernReturn = task_info(mach_task_self(), TASK_VM_INFO, (task_info_t)&taskInfo, &infoCount);

        if (kernReturn != KERN_SUCCESS) {
            return 0;
        }
        return (int)((taskInfo.phys_footprint + os_proc_available_memory()) / 1024.0 / 1024.0);
    }
    return 0;
}
```
通过这个方法，得到的值也为2098M。

以上就是几种可以获取到不同应用OOM值的方法。无论是应用还是应用扩展，都可以通过以上几个方法测试。但应用扩展的内存限制十分严格，要远低于普通的应用程序。例如，iPhone XS Max的应用内存限制为2098M，而同设备的自定义键盘，内存限制为66M（少的太可怜了）。

源码探究
我们知道，iOS/MacOS的内核都是XNU，同时XNU是开源的。我们可以在开源的XNU内核源码中，窥探苹果Jetsam的具体实现。

XNU的内核内层为Mach层，Mach作为微内核，是仅提供基础服务的一个薄层，如处理器管理和调度及IPC(进程间通信)。XNU的第二个主要部分是BSD层。我们可以将其看成围绕mach层的一个外环，BSD为最终用户的应用程序提供变成接口，其职责包括进程管理，文件系统和网络。

内存管理中各种常见的JetSam时间也是由BSD产生的，所以，我们从bsd_init这个函数作为入口，来探究一下原理。

bsd_init中基本都是在初始化各种子系统，比如虚拟内存管理等等。

BSD初始化bsd_init
跟内存相关的包括如下几步：
```c
//1. 初始化BSD内存Zone，这个Zone是基于Mach内核的zone
kmeminit();

//2.iOS上独有的特性，内存和进程的休眠的常驻监控线程
#if CONFIG_FREEZE
#ifndef CONFIG_MEMORYSTATUS
    #error "CONFIG_FREEZE defined without matching CONFIG_MEMORYSTATUS"
#endif
	/* Initialise background freezing */
	bsd_init_kprintf("calling memorystatus_freeze_init\n");
	memorystatus_freeze_init();
#endif

//3.iOS独有，JetSAM（即低内存事件的常驻监控线程）
#if CONFIG_MEMORYSTATUS
	/* Initialize kernel memory status notifications */
	bsd_init_kprintf("calling memorystatus_init\n");
	memorystatus_init();
#endif /* CONFIG_MEMORYSTATUS */
```

这里面的memorystatus_freeze_init()和memorystatus_init()两个方法都是调用kern_memorystatus.c里面暴露的接口，主要的作用就是从内核中开启两个优先级最高的线程，来监控整个系统的内存情况。

CONFIG_FREEZE涉及到的功能，当启用这个宏时，内核会对进程进行冷冻而不是Kill。涉及到进程休眠相关的代码，暂时不在本文讨论范围内。

回到iOS的OOM崩溃话题上，我们只需要关注memorystatus_init()方法即可。

知识点介绍
内核里面对于所有的进程都有一个优先级的分布，通过一个数组维护，数组的每一项是一个进程的列表。这个数组的大小则是JETSAM_PRIORITY_MAX + 1。
#define MEMSTAT_BUCKET_COUNT (JETSAM_PRIORITY_MAX + 1)
```c
typedef struct memstat_bucket {
    TAILQ_HEAD(, proc) list;    //  一个TAILQ_HEAD的双向链表，用来存放这个优先级下面的进程
    int count;  //  进程的个数
} memstat_bucket_t;
```
memstat_bucket_t memstat_bucket[MEMSTAT_BUCKET_COUNT];//优先级队列(里面包含不同优先级的结构)

https://opensource.apple.com/source/xnu/xnu-4570.31.3/bsd/sys/kern_memorystatus.h.auto.html

```c
在kern_memorystatus.h中，我们可以找到JETSAM_PRIORITY_MAX值以及进程优先级相关的定义：
#define JETSAM_PRIORITY_REVISION                  2

#define JETSAM_PRIORITY_IDLE_HEAD                -2
/* The value -1 is an alias to JETSAM_PRIORITY_DEFAULT */
#define JETSAM_PRIORITY_IDLE                      0
#define JETSAM_PRIORITY_IDLE_DEFERRED		  1 /* Keeping this around till all xnu_quick_tests can be moved away from it.*/
#define JETSAM_PRIORITY_AGING_BAND1		  JETSAM_PRIORITY_IDLE_DEFERRED
#define JETSAM_PRIORITY_BACKGROUND_OPPORTUNISTIC  2
#define JETSAM_PRIORITY_AGING_BAND2		  JETSAM_PRIORITY_BACKGROUND_OPPORTUNISTIC
#define JETSAM_PRIORITY_BACKGROUND                3
#define JETSAM_PRIORITY_ELEVATED_INACTIVE	  JETSAM_PRIORITY_BACKGROUND
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

/* TODO - tune. This should probably be lower priority */
#define JETSAM_PRIORITY_DEFAULT                  18
#define JETSAM_PRIORITY_TELEPHONY                19
```

其中数值越大，优先级越高。后台应用程序优先级JETSAM_PRIORITY_BACKGROUND是3，低于前台应用程序优先级JETSAM_PRIORITY_FOREGROUND10，而SpringBoard(桌面程序)位于JETSAM_PRIORITY_HOME16。
```c
JetSam出现的原因：
//kern_memorystatus.h
/*
 * Jetsam exit reason definitions - related to memorystatus
 *
 * When adding new exit reasons also update:
 *	JETSAM_REASON_MEMORYSTATUS_MAX
 *	kMemorystatusKilled... Cause enum
 *	memorystatus_kill_cause_name[]
 */
#define JETSAM_REASON_INVALID								0
#define JETSAM_REASON_GENERIC								1
#define JETSAM_REASON_MEMORY_HIGHWATER						2
#define JETSAM_REASON_VNODE									3
#define JETSAM_REASON_MEMORY_VMPAGESHORTAGE					4
#define JETSAM_REASON_MEMORY_PROCTHRASHING					5
#define JETSAM_REASON_MEMORY_FCTHRASHING					6
#define JETSAM_REASON_MEMORY_PERPROCESSLIMIT				7
#define JETSAM_REASON_MEMORY_DISK_SPACE_SHORTAGE			8
#define JETSAM_REASON_MEMORY_IDLE_EXIT						9
#define JETSAM_REASON_ZONE_MAP_EXHAUSTION					10
#define JETSAM_REASON_MEMORY_VMCOMPRESSOR_THRASHING			11
#define JETSAM_REASON_MEMORY_VMCOMPRESSOR_SPACE_SHORTAGE	12

#define JETSAM_REASON_MEMORYSTATUS_MAX	JETSAM_REASON_MEMORY_VMCOMPRESSOR_SPACE_SHORTAGE

/*
 * Jetsam exit reason definitions - not related to memorystatus
 */
#define JETSAM_REASON_CPULIMIT			100

/* Cause */
enum {
	kMemorystatusInvalid							= JETSAM_REASON_INVALID,
	kMemorystatusKilled								= JETSAM_REASON_GENERIC,
	kMemorystatusKilledHiwat						= JETSAM_REASON_MEMORY_HIGHWATER,
	kMemorystatusKilledVnodes						= JETSAM_REASON_VNODE,
	kMemorystatusKilledVMPageShortage				= JETSAM_REASON_MEMORY_VMPAGESHORTAGE,
	kMemorystatusKilledProcThrashing				= JETSAM_REASON_MEMORY_PROCTHRASHING,
	kMemorystatusKilledFCThrashing					= JETSAM_REASON_MEMORY_FCTHRASHING,
	kMemorystatusKilledPerProcessLimit				= JETSAM_REASON_MEMORY_PERPROCESSLIMIT,
	kMemorystatusKilledDiskSpaceShortage			= JETSAM_REASON_MEMORY_DISK_SPACE_SHORTAGE,
	kMemorystatusKilledIdleExit						= JETSAM_REASON_MEMORY_IDLE_EXIT,
	kMemorystatusKilledZoneMapExhaustion			= JETSAM_REASON_ZONE_MAP_EXHAUSTION,
	kMemorystatusKilledVMCompressorThrashing		= JETSAM_REASON_MEMORY_VMCOMPRESSOR_THRASHING,
	kMemorystatusKilledVMCompressorSpaceShortage	= JETSAM_REASON_MEMORY_VMCOMPRESSOR_SPACE_SHORTAGE,
};

//kern_memorystatus.m
/* For logging clarity */
static const char *memorystatus_kill_cause_name[] = {
	""								,		/* kMemorystatusInvalid							*/
	"jettisoned"					,		/* kMemorystatusKilled							*/
	"highwater"						,		/* kMemorystatusKilledHiwat						*/
	"vnode-limit"					,		/* kMemorystatusKilledVnodes					*/
	"vm-pageshortage"				,		/* kMemorystatusKilledVMPageShortage			*/
	"proc-thrashing"				,		/* kMemorystatusKilledProcThrashing				*/
	"fc-thrashing"					,		/* kMemorystatusKilledFCThrashing				*/
	"per-process-limit"				,		/* kMemorystatusKilledPerProcessLimit			*/
	"disk-space-shortage"			,		/* kMemorystatusKilledDiskSpaceShortage			*/
	"idle-exit"						,		/* kMemorystatusKilledIdleExit					*/
	"zone-map-exhaustion"			,		/* kMemorystatusKilledZoneMapExhaustion			*/
	"vm-compressor-thrashing"		,		/* kMemorystatusKilledVMCompressorThrashing		*/
	"vm-compressor-space-shortage"	,		/* kMemorystatusKilledVMCompressorSpaceShortage	*/
};
```

memorystatus_init 内存状态初始化
接下里让我们看一下memorystatus_init()函数中，初始化JETSAM线程的关键部分代码。
```c
__private_extern__ void
memorystatus_init(void)
{
    ... 
	/* Initialize the jetsam_threads state array */
	jetsam_threads = kalloc(sizeof(struct jetsam_thread_state) * max_jetsam_threads);

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

在这里会根据内核启动参数和设备性能，开启max_jetsam_threads个JetSam线程(性能差的设备为1个，其余为3个)，这些线程的优先级是内核所能分配的最高级(95, MAXPRI_KERNEL)。并且为每个线程增加了次序（注意:前文的-2~19是进程优先级区间，而这里的95是线程优先级，XNU的线程优先级范围是0~127）。

memorystatus_thread 内存状态管理线程
系统中专门有一个线程用来管理内存状态，当内存状态出现问题或者内存压力过大时，将会通过一定的策略，干掉一些 App 回收内存。

继续看memorystatus_thread内存状态管理线程的代码：
```c
static void
memorystatus_thread(void *param __unused, wait_result_t wr __unused)
{
	boolean_t post_snapshot = FALSE;
	uint32_t errors = 0;
	uint32_t hwm_kill = 0;
	boolean_t sort_flag = TRUE;
	boolean_t corpse_list_purged = FALSE;
	int	jld_idle_kills = 0;
	struct jetsam_thread_state *jetsam_thread = jetsam_current_thread();

	if (jetsam_thread->inited == FALSE) {
		/* 
		 * It's the first time the thread has run, so just mark the thread as privileged and block.
		 * This avoids a spurious pass with unset variables, as set out in <rdar://problem/9609402>.
		 */
	
		char name[32];
		thread_wire(host_priv_self(), current_thread(), TRUE);
		snprintf(name, 32, "VM_memorystatus_%d", jetsam_thread->index + 1);
	
		if (jetsam_thread->index == 0) {
			if (vm_pageout_state.vm_restricted_to_single_processor == TRUE) {
				thread_vm_bind_group_add();
			}
		}
		thread_set_thread_name(current_thread(), name);
		jetsam_thread->inited = TRUE;
		memorystatus_thread_block(0, memorystatus_thread);
	}
	
	KERNEL_DEBUG_CONSTANT(BSDDBG_CODE(DBG_BSD_MEMSTAT, BSD_MEMSTAT_SCAN) | DBG_FUNC_START,
			      memorystatus_available_pages, memorystatus_jld_enabled, memorystatus_jld_eval_period_msecs, memorystatus_jld_eval_aggressive_count,0);
	
	/*
	 * Jetsam aware version.
	 *
	 * The VM pressure notification thread is working it's way through clients in parallel.
	 *
	 * So, while the pressure notification thread is targeting processes in order of 
	 * increasing jetsam priority, we can hopefully reduce / stop it's work by killing 
	 * any processes that have exceeded their highwater mark.
	 *
	 * If we run out of HWM processes and our available pages drops below the critical threshold, then,
	 * we target the least recently used process in order of increasing jetsam priority (exception: the FG band).
	 */
	while (memorystatus_action_needed()) {
		boolean_t killed;
		int32_t priority;
		uint32_t cause;
		uint64_t jetsam_reason_code = JETSAM_REASON_INVALID;
		os_reason_t jetsam_reason = OS_REASON_NULL;
	
		cause = kill_under_pressure_cause;
		switch (cause) {
			case kMemorystatusKilledFCThrashing:
				jetsam_reason_code = JETSAM_REASON_MEMORY_FCTHRASHING;
				break;
			case kMemorystatusKilledVMCompressorThrashing:
				jetsam_reason_code = JETSAM_REASON_MEMORY_VMCOMPRESSOR_THRASHING;
				break;
			case kMemorystatusKilledVMCompressorSpaceShortage:
				jetsam_reason_code = JETSAM_REASON_MEMORY_VMCOMPRESSOR_SPACE_SHORTAGE;
				break;
			case kMemorystatusKilledZoneMapExhaustion:
				jetsam_reason_code = JETSAM_REASON_ZONE_MAP_EXHAUSTION;
				break;
			case kMemorystatusKilledVMPageShortage:
				/* falls through */
			default:
				jetsam_reason_code = JETSAM_REASON_MEMORY_VMPAGESHORTAGE;
				cause = kMemorystatusKilledVMPageShortage;
				break;
		}
	
		/* Highwater */
		boolean_t is_critical = TRUE;
		if (memorystatus_act_on_hiwat_processes(&errors, &hwm_kill, &post_snapshot, &is_critical)) {
			if (is_critical == FALSE) {
				/*
				 * For now, don't kill any other processes.
				 */
				break;
			} else {
				goto done;
			}
		}
	
		jetsam_reason = os_reason_create(OS_REASON_JETSAM, jetsam_reason_code);
		if (jetsam_reason == OS_REASON_NULL) {
			printf("memorystatus_thread: failed to allocate jetsam reason\n");
		}
	
		if (memorystatus_act_aggressive(cause, jetsam_reason, &jld_idle_kills, &corpse_list_purged, &post_snapshot)) {
			goto done;
		}
	
		/*
		 * memorystatus_kill_top_process() drops a reference,
		 * so take another one so we can continue to use this exit reason
		 * even after it returns
		 */
		os_reason_ref(jetsam_reason);
	
		/* LRU */
		killed = memorystatus_kill_top_process(TRUE, sort_flag, cause, jetsam_reason, &priority, &errors);
		sort_flag = FALSE;
	
		if (killed) {
			if (memorystatus_post_snapshot(priority, cause) == TRUE) {
	
	    			post_snapshot = TRUE;
			}
	
			/* Jetsam Loop Detection */
			if (memorystatus_jld_enabled == TRUE) {
				if ((priority == JETSAM_PRIORITY_IDLE) || (priority == system_procs_aging_band) || (priority == applications_aging_band)) {
					jld_idle_kills++;
				} else {
					/*
					 * We've reached into bands beyond idle deferred.
					 * We make no attempt to monitor them
					 */
				}
			}
	
			if ((priority >= JETSAM_PRIORITY_UI_SUPPORT) && (total_corpses_count() > 0) && (corpse_list_purged == FALSE)) {
				/*
				 * If we have jetsammed a process in or above JETSAM_PRIORITY_UI_SUPPORT
				 * then we attempt to relieve pressure by purging corpse memory.
				 */
				task_purge_all_corpses();
				corpse_list_purged = TRUE;
			}
			goto done;
		}
		
		if (memorystatus_avail_pages_below_critical()) {
			/*
			 * Still under pressure and unable to kill a process - purge corpse memory
			 */
			if (total_corpses_count() > 0) {
				task_purge_all_corpses();
				corpse_list_purged = TRUE;
			}
	
			if (memorystatus_avail_pages_below_critical()) {
				/*
				 * Still under pressure and unable to kill a process - panic
				 */
				panic("memorystatus_jetsam_thread: no victim! available pages:%llu\n", (uint64_t)memorystatus_available_pages);
			}
		}

done:		

		/*
		 * We do not want to over-kill when thrashing has been detected.
		 * To avoid that, we reset the flag here and notify the
		 * compressor.
		 */
		if (is_reason_thrashing(kill_under_pressure_cause)) {
			kill_under_pressure_cause = 0;
#if CONFIG_JETSAM
			vm_thrashing_jetsam_done();
#endif /* CONFIG_JETSAM */
		} else if (is_reason_zone_map_exhaustion(kill_under_pressure_cause)) {
			kill_under_pressure_cause = 0;
		}

		os_reason_free(jetsam_reason);
	}
	
	kill_under_pressure_cause = 0;
	
	if (errors) {
		memorystatus_clear_errors();
	}
	
	if (post_snapshot) {
		proc_list_lock();
		size_t snapshot_size = sizeof(memorystatus_jetsam_snapshot_t) +
			sizeof(memorystatus_jetsam_snapshot_entry_t) * (memorystatus_jetsam_snapshot_count);
		uint64_t timestamp_now = mach_absolute_time();
		memorystatus_jetsam_snapshot->notification_time = timestamp_now;
		memorystatus_jetsam_snapshot->js_gencount++;
		if (memorystatus_jetsam_snapshot_count > 0 && (memorystatus_jetsam_snapshot_last_timestamp == 0 ||
				timestamp_now > memorystatus_jetsam_snapshot_last_timestamp + memorystatus_jetsam_snapshot_timeout)) {
			proc_list_unlock();
			int ret = memorystatus_send_note(kMemorystatusSnapshotNote, &snapshot_size, sizeof(snapshot_size));
			if (!ret) {
				proc_list_lock();
				memorystatus_jetsam_snapshot_last_timestamp = timestamp_now;
				proc_list_unlock();
			}
		} else {
			proc_list_unlock();
		}
	}
	
	KERNEL_DEBUG_CONSTANT(BSDDBG_CODE(DBG_BSD_MEMSTAT, BSD_MEMSTAT_SCAN) | DBG_FUNC_END,
		memorystatus_available_pages, 0, 0, 0, 0);
	
	memorystatus_thread_block(0, memorystatus_thread);
}
```

代码较多，我们来逐一分析。

判断条件
我们可以看到核心的代码在while (memorystatus_action_needed())循环里，memorystatus_action_needed()是触发OOM的核心判断条件。
```c
/* Does cause indicate vm or fc thrashing? */
static boolean_t 
is_reason_thrashing(unsigned cause)
{
	switch (cause) {
	case kMemorystatusKilledFCThrashing:
	case kMemorystatusKilledVMCompressorThrashing:
	case kMemorystatusKilledVMCompressorSpaceShortage:
		return TRUE;
	default:
		return FALSE;
	}
}

/* Is the zone map almost full? */
static boolean_t 
is_reason_zone_map_exhaustion(unsigned cause)
{
	if (cause == kMemorystatusKilledZoneMapExhaustion)
		return TRUE;
	return FALSE;
}

static boolean_t memorystatus_action_needed(void)
{
	return (is_reason_thrashing(kill_under_pressure_cause) ||
			is_reason_zone_map_exhaustion(kill_under_pressure_cause) ||
	       memorystatus_available_pages <= memorystatus_available_pages_pressure);
}
```

这里通过接受vm_pageout守护程序（实际上是一个线程）发送的内存压力来判断当前内存资源是否紧张。内存紧张的情况可能为：操作系统的抖动(Thrashing，频繁的内存页面(page)换进换出占用CPU过度)，虚拟内存耗尽（比如有人从硬盘向ZFS(动态文件系统)池中拷贝1TB的数据），或者内存可用页低于阈值memorystatus_available_pages_pressure。

high-water
判断条件通过之后，也就是当前内存紧张，首先走到memorystatus_act_on_hiwat_processes逻辑中。
```c
/* Highwater */
boolean_t is_critical = TRUE;
if (memorystatus_act_on_hiwat_processes(&errors, &hwm_kill, &post_snapshot, &is_critical)) {
	if (is_critical == FALSE) {
		/*
		 * For now, don't kill any other processes.
		 */
		break;
	} else {
		goto done;
	}
}
```

这是触发high-water类型OOM的关键方法。
```c
static boolean_t
memorystatus_act_on_hiwat_processes(uint32_t *errors, uint32_t *hwm_kill, boolean_t *post_snapshot, __unused boolean_t *is_critical)
{
	boolean_t purged = FALSE;
	boolean_t killed = memorystatus_kill_hiwat_proc(errors, &purged);

	if (killed) {
		*hwm_kill = *hwm_kill + 1;
		*post_snapshot = TRUE;
		return TRUE;
	} else {
		if (purged == FALSE) {
			/* couldn't purge and couldn't kill */
			memorystatus_hwm_candidates = FALSE;
		}
	}

#if CONFIG_JETSAM
	/* No highwater processes to kill. Continue or stop for now? */
	if (!is_reason_thrashing(kill_under_pressure_cause) &&
		!is_reason_zone_map_exhaustion(kill_under_pressure_cause) &&
	    (memorystatus_available_pages > memorystatus_available_pages_critical)) {
		/*
		 * We are _not_ out of pressure but we are above the critical threshold and there's:
		 * - no compressor thrashing
		 * - enough zone memory
		 * - no more HWM processes left.
		 * For now, don't kill any other processes.
		 */
	
		if (*hwm_kill == 0) {
			memorystatus_thread_wasted_wakeup++;
		}
	
		*is_critical = FALSE;
	
		return TRUE;
	}
#endif /* CONFIG_JETSAM */

	return FALSE;
}
```

memorystatus_act_on_hiwat_processes会直接调用memorystatus_kill_hiwat_proc。
```c
static boolean_t
memorystatus_kill_hiwat_proc(uint32_t *errors, boolean_t *purged)
{
	pid_t aPid = 0;
	proc_t p = PROC_NULL, next_p = PROC_NULL;
	boolean_t new_snapshot = FALSE, killed = FALSE, freed_mem = FALSE;
	unsigned int i = 0;
	uint32_t aPid_ep;
	os_reason_t jetsam_reason = OS_REASON_NULL;
	KERNEL_DEBUG_CONSTANT(BSDDBG_CODE(DBG_BSD_MEMSTAT, BSD_MEMSTAT_JETSAM_HIWAT) | DBG_FUNC_START,
		memorystatus_available_pages, 0, 0, 0, 0);
	
	jetsam_reason = os_reason_create(OS_REASON_JETSAM, JETSAM_REASON_MEMORY_HIGHWATER);
	if (jetsam_reason == OS_REASON_NULL) {
		printf("memorystatus_kill_hiwat_proc: failed to allocate exit reason\n");
	}
	
	proc_list_lock();
	
	next_p = memorystatus_get_first_proc_locked(&i, TRUE);
	while (next_p) {
		uint64_t footprint_in_bytes = 0;
		uint64_t memlimit_in_bytes  = 0;
		boolean_t skip = 0;
	
		p = next_p;
		next_p = memorystatus_get_next_proc_locked(&i, p, TRUE);
		
		aPid = p->p_pid;
		aPid_ep = p->p_memstat_effectivepriority;
		
		if (p->p_memstat_state  & (P_MEMSTAT_ERROR | P_MEMSTAT_TERMINATED)) {
			continue;
		}
		
		/* skip if no limit set */
		if (p->p_memstat_memlimit <= 0) {
			continue;
		}
	
		footprint_in_bytes = get_task_phys_footprint(p->task);
		memlimit_in_bytes  = (((uint64_t)p->p_memstat_memlimit) * 1024ULL * 1024ULL);	/* convert MB to bytes */
		skip = (footprint_in_bytes <= memlimit_in_bytes);

#if CONFIG_JETSAM && (DEVELOPMENT || DEBUG)
		if (!skip && (memorystatus_jetsam_policy & kPolicyDiagnoseActive)) {
			if (p->p_memstat_state & P_MEMSTAT_DIAG_SUSPENDED) {
				continue;
			}
		}
#endif /* CONFIG_JETSAM && (DEVELOPMENT || DEBUG) */

#if CONFIG_FREEZE
		if (!skip) {
			if (p->p_memstat_state & P_MEMSTAT_LOCKED) {
				skip = TRUE;
			} else {
				skip = FALSE;
			}				
		}
#endif

		if (skip) {
			continue;
		} else {
	
			if (memorystatus_jetsam_snapshot_count == 0) {
				memorystatus_init_jetsam_snapshot_locked(NULL,0);
				new_snapshot = TRUE;
			}
	
			if (proc_ref_locked(p) == p) {
				/*
				 * Mark as terminated so that if exit1() indicates success, but the process (for example)
				 * is blocked in task_exception_notify(), it'll be skipped if encountered again - see
				 * <rdar://problem/13553476>. This is cheaper than examining P_LEXIT, which requires the
				 * acquisition of the proc lock.
				 */
				p->p_memstat_state |= P_MEMSTAT_TERMINATED;
	
				proc_list_unlock();
			} else {
				/*
				 * We need to restart the search again because
				 * proc_ref_locked _can_ drop the proc_list lock
				 * and we could have lost our stored next_p via
				 * an exit() on another core.
				 */
				i = 0;
				next_p = memorystatus_get_first_proc_locked(&i, TRUE);
				continue;
			}
		
			freed_mem = memorystatus_kill_proc(p, kMemorystatusKilledHiwat, jetsam_reason, &killed); /* purged and/or killed 'p' */
	
			/* Success? */
			if (freed_mem) {
				if (killed == FALSE) {
					/* purged 'p'..don't reset HWM candidate count */
					*purged = TRUE;
	
					proc_list_lock();
					p->p_memstat_state &= ~P_MEMSTAT_TERMINATED;
					proc_list_unlock();
				}
				proc_rele(p);
				goto exit;
			}
			/*
			 * Failure - first unwind the state,
			 * then fall through to restart the search.
			 */
			proc_list_lock();
			proc_rele_locked(p);
			p->p_memstat_state &= ~P_MEMSTAT_TERMINATED;
			p->p_memstat_state |= P_MEMSTAT_ERROR;
			*errors += 1;
	
			i = 0;
			next_p = memorystatus_get_first_proc_locked(&i, TRUE);
		}
	}
	
	proc_list_unlock();

exit:
	os_reason_free(jetsam_reason);

	/* Clear snapshot if freshly captured and no target was found */
	if (new_snapshot && !killed) {
		proc_list_lock();
		memorystatus_jetsam_snapshot->entry_count = memorystatus_jetsam_snapshot_count = 0;
		proc_list_unlock();
	}
	
	KERNEL_DEBUG_CONSTANT(BSDDBG_CODE(DBG_BSD_MEMSTAT, BSD_MEMSTAT_JETSAM_HIWAT) | DBG_FUNC_END, 
			      memorystatus_available_pages, killed ? aPid : 0, 0, 0, 0);
	
	return killed;
}
```

首先通过memorystatus_get_first_proc_locked(&i, TRUE)去优先级队列里面取出优先级最低的进程。如果这个进程内存小于阈值(footprint_in_bytes <= memlimit_in_bytes)，则继续寻找下一个优先级次低的进程memorystatus_get_next_proc_locked，直到找到内存超过阈值的进程，将通过memorystatus_do_kill杀掉这个进程，并结束循环。

normal kill
不过high-water的阈值较高，一般不容易触发。如果通过high-water相关代码不能结束任何进程，将走到memorystatus_act_aggressive()函数中，也就是大部分OOM发生的地方。
```c
static boolean_t
memorystatus_act_aggressive(uint32_t cause, os_reason_t jetsam_reason, int *jld_idle_kills, boolean_t *corpse_list_purged, boolean_t *post_snapshot)
{
	if (memorystatus_jld_enabled == TRUE) {

		boolean_t killed;
		uint32_t errors = 0;
	
		/* Jetsam Loop Detection - locals */
		memstat_bucket_t *bucket;
		int		jld_bucket_count = 0;
		struct timeval	jld_now_tstamp = {0,0};
		uint64_t 	jld_now_msecs = 0;
		int		elevated_bucket_count = 0;
	
		/* Jetsam Loop Detection - statics */
		static uint64_t  jld_timestamp_msecs = 0;
		static int	 jld_idle_kill_candidates = 0;	/* Number of available processes in band 0,1 at start */
		static int	 jld_eval_aggressive_count = 0;		/* Bumps the max priority in aggressive loop */
		static int32_t   jld_priority_band_max = JETSAM_PRIORITY_UI_SUPPORT;
		/*
		 * Jetsam Loop Detection: attempt to detect
		 * rapid daemon relaunches in the lower bands.
		 */
		
		microuptime(&jld_now_tstamp);
	
		/*
		 * Ignore usecs in this calculation.
		 * msecs granularity is close enough.
		 */
		jld_now_msecs = (jld_now_tstamp.tv_sec * 1000);
	
		proc_list_lock();
		switch (jetsam_aging_policy) {
		case kJetsamAgingPolicyLegacy:
			bucket = &memstat_bucket[JETSAM_PRIORITY_IDLE];
			jld_bucket_count = bucket->count;
			bucket = &memstat_bucket[JETSAM_PRIORITY_AGING_BAND1];
			jld_bucket_count += bucket->count;
			break;
		case kJetsamAgingPolicySysProcsReclaimedFirst:
		case kJetsamAgingPolicyAppsReclaimedFirst:
			bucket = &memstat_bucket[JETSAM_PRIORITY_IDLE];
			jld_bucket_count = bucket->count;
			bucket = &memstat_bucket[system_procs_aging_band];
			jld_bucket_count += bucket->count;
			bucket = &memstat_bucket[applications_aging_band];
			jld_bucket_count += bucket->count;
			break;
		case kJetsamAgingPolicyNone:
		default:
			bucket = &memstat_bucket[JETSAM_PRIORITY_IDLE];
			jld_bucket_count = bucket->count;
			break;
		}
	
		bucket = &memstat_bucket[JETSAM_PRIORITY_ELEVATED_INACTIVE];
		elevated_bucket_count = bucket->count;
	
		proc_list_unlock();
	
		/*
		 * memorystatus_jld_eval_period_msecs is a tunable
		 * memorystatus_jld_eval_aggressive_count is a tunable
		 * memorystatus_jld_eval_aggressive_priority_band_max is a tunable
		 */
		if ( (jld_bucket_count == 0) || 
		     (jld_now_msecs > (jld_timestamp_msecs + memorystatus_jld_eval_period_msecs))) {
	
			/* 
			 * Refresh evaluation parameters 
			 */
			jld_timestamp_msecs	 = jld_now_msecs;
			jld_idle_kill_candidates = jld_bucket_count;
			*jld_idle_kills		 = 0;
			jld_eval_aggressive_count = 0;
			jld_priority_band_max	= JETSAM_PRIORITY_UI_SUPPORT;
		}
	
		if (*jld_idle_kills > jld_idle_kill_candidates) {
			jld_eval_aggressive_count++;

#if DEVELOPMENT || DEBUG
			printf("memorystatus: aggressive%d: beginning of window: %lld ms, : timestamp now: %lld ms\n",
					jld_eval_aggressive_count,
					jld_timestamp_msecs,
					jld_now_msecs);
			printf("memorystatus: aggressive%d: idle candidates: %d, idle kills: %d\n",
					jld_eval_aggressive_count,
					jld_idle_kill_candidates,
					*jld_idle_kills);
#endif /* DEVELOPMENT || DEBUG */

			if ((jld_eval_aggressive_count == memorystatus_jld_eval_aggressive_count) &&
			    (total_corpses_count() > 0) && (*corpse_list_purged == FALSE)) {
				/*
				 * If we reach this aggressive cycle, corpses might be causing memory pressure.
				 * So, in an effort to avoid jetsams in the FG band, we will attempt to purge
				 * corpse memory prior to this final march through JETSAM_PRIORITY_UI_SUPPORT.
				 */
				task_purge_all_corpses();
				*corpse_list_purged = TRUE;
			}
			else if (jld_eval_aggressive_count > memorystatus_jld_eval_aggressive_count) {
				/* 
				 * Bump up the jetsam priority limit (eg: the bucket index)
				 * Enforce bucket index sanity.
				 */
				if ((memorystatus_jld_eval_aggressive_priority_band_max < 0) || 
				    (memorystatus_jld_eval_aggressive_priority_band_max >= MEMSTAT_BUCKET_COUNT)) {
					/*
					 * Do nothing.  Stick with the default level.
					 */
				} else {
					jld_priority_band_max = memorystatus_jld_eval_aggressive_priority_band_max;
				}
			}
	
			/* Visit elevated processes first */
			while (elevated_bucket_count) {
	
				elevated_bucket_count--;
	
				/*
				 * memorystatus_kill_elevated_process() drops a reference,
				 * so take another one so we can continue to use this exit reason
				 * even after it returns.
				 */
	
				os_reason_ref(jetsam_reason);
				killed = memorystatus_kill_elevated_process(
					cause,
					jetsam_reason,
					JETSAM_PRIORITY_ELEVATED_INACTIVE,
					jld_eval_aggressive_count,
					&errors);
	
				if (killed) {
					*post_snapshot = TRUE;
					if (memorystatus_avail_pages_below_pressure()) {
						/*
						 * Still under pressure.
						 * Find another pinned processes.
						 */
						continue;
					} else {
						return TRUE;
					}
				} else {
					/*
					 * No pinned processes left to kill.
					 * Abandon elevated band.
					 */
					break;
				}
			}
	
			/*
			 * memorystatus_kill_top_process_aggressive() allocates its own
			 * jetsam_reason so the kMemorystatusKilledProcThrashing cause
			 * is consistent throughout the aggressive march.
			 */
			killed = memorystatus_kill_top_process_aggressive(
				kMemorystatusKilledProcThrashing,
				jld_eval_aggressive_count, 
				jld_priority_band_max, 
				&errors);
				
			if (killed) {
				/* Always generate logs after aggressive kill */
				*post_snapshot = TRUE;
				*jld_idle_kills = 0;
				return TRUE;
			} 
		}
	
		return FALSE;
	}
	
	return FALSE;
}
```

首先有一个jld_bucket_count,这里包含可以直接干掉的低优先级进程的数量。根据jetsam_aging_policy确定哪些优先级类型的进程需要被直接杀掉(正常情况下就是优先级极低的进程和一些正常情况下随时可回收的进程：JETSAM_PRIORITY_IDLE、system_procs_aging_band、applications_aging_band)。

如果内存压力依然存在，则通过memorystatus_kill_elevated_process杀掉后台进程。每杀掉一个后台进程，通过memorystatus_available_pages检测一下内存压力。如果memorystatus_available_pages还是小于阈值，则继续杀掉下一个进程。

如果杀掉了所有低优先级的进程，还有内存压力，再通过memorystatus_kill_top_process_aggressive杀掉优先级最低的进程。这里是触发FOOM的关键，如果当前前台进程已经是最低优先级的进程了，那就会发生FOOM。

LRU杀死top process
如果上面memorystatus_act_aggressive函数没有杀死任何进程，那么就需要通过LRU来杀死Jetsam队列中的第一个进程。
```c
/*
 * memorystatus_kill_top_process() drops a reference,
 * so take another one so we can continue to use this exit reason
 * even after it returns
 */
os_reason_ref(jetsam_reason);

/* LRU */
killed = memorystatus_kill_top_process(TRUE, sort_flag, cause, jetsam_reason, &priority, &errors);
sort_flag = FALSE;

if (killed) {
	if (memorystatus_post_snapshot(priority, cause) == TRUE) {

			post_snapshot = TRUE;
	}
	
	/* Jetsam Loop Detection */
	if (memorystatus_jld_enabled == TRUE) {
		if ((priority == JETSAM_PRIORITY_IDLE) || (priority == system_procs_aging_band) || (priority == applications_aging_band)) {
			jld_idle_kills++;
		} else {
			/*
			 * We've reached into bands beyond idle deferred.
			 * We make no attempt to monitor them
			 */
		}
	}
	
	if ((priority >= JETSAM_PRIORITY_UI_SUPPORT) && (total_corpses_count() > 0) && (corpse_list_purged == FALSE)) {
		/*
		 * If we have jetsammed a process in or above JETSAM_PRIORITY_UI_SUPPORT
		 * then we attempt to relieve pressure by purging corpse memory.
		 */
		task_purge_all_corpses();
		corpse_list_purged = TRUE;
	}
	goto done;
}

if (memorystatus_avail_pages_below_critical()) {
	/*
	 * Still under pressure and unable to kill a process - purge corpse memory
	 */
	if (total_corpses_count() > 0) {
		task_purge_all_corpses();
		corpse_list_purged = TRUE;
	}

	if (memorystatus_avail_pages_below_critical()) {
		/*
		 * Still under pressure and unable to kill a process - panic
		 */
		panic("memorystatus_jetsam_thread: no victim! available pages:%llu\n", (uint64_t)memorystatus_available_pages);
	}
}
```

当所有流程执行完毕，则做一些收尾的工作。

```c
		/*
		 * We do not want to over-kill when thrashing has been detected.
		 * To avoid that, we reset the flag here and notify the
		 * compressor.
		 */
		if (is_reason_thrashing(kill_under_pressure_cause)) {
			kill_under_pressure_cause = 0;
#if CONFIG_JETSAM
			vm_thrashing_jetsam_done();
#endif /* CONFIG_JETSAM */
		} else if (is_reason_zone_map_exhaustion(kill_under_pressure_cause)) {
			kill_under_pressure_cause = 0;
		}

		os_reason_free(jetsam_reason);
	}
	
	kill_under_pressure_cause = 0;
	
	if (errors) {
		memorystatus_clear_errors();
	}
	
	if (post_snapshot) {
		proc_list_lock();
		size_t snapshot_size = sizeof(memorystatus_jetsam_snapshot_t) +
			sizeof(memorystatus_jetsam_snapshot_entry_t) * (memorystatus_jetsam_snapshot_count);
		uint64_t timestamp_now = mach_absolute_time();
		memorystatus_jetsam_snapshot->notification_time = timestamp_now;
		memorystatus_jetsam_snapshot->js_gencount++;
		if (memorystatus_jetsam_snapshot_count > 0 && (memorystatus_jetsam_snapshot_last_timestamp == 0 ||
				timestamp_now > memorystatus_jetsam_snapshot_last_timestamp + memorystatus_jetsam_snapshot_timeout)) {
			proc_list_unlock();
			int ret = memorystatus_send_note(kMemorystatusSnapshotNote, &snapshot_size, sizeof(snapshot_size));
			if (!ret) {
				proc_list_lock();
				memorystatus_jetsam_snapshot_last_timestamp = timestamp_now;
				proc_list_unlock();
			}
		} else {
			proc_list_unlock();
		}
	}
	
	KERNEL_DEBUG_CONSTANT(BSDDBG_CODE(DBG_BSD_MEMSTAT, BSD_MEMSTAT_SCAN) | DBG_FUNC_END,
		memorystatus_available_pages, 0, 0, 0, 0);
	
	memorystatus_thread_block(0, memorystatus_thread);
```

当检测到颠簸时，系统并不想过度杀戮。为避免这种情况，系统在此处重置标志并通知compressor。如果需要记录当前内存快照，记录后挂起当前线程，等待之后遇到OOM时再次唤醒。

如何触发OOM检测
当memorystatus_thread初始化后，会立刻检测一次OOM。

在task.c中，当物理内存达到限制时，触发回调，会调用memorystatus_on_ledger_footprint_exceeded，来同步触发per-process-limit类型的OOM。

与上一个类似的，如：memorystatus_kill_on_vnode_limit也是同步触发的。也就是最终调用了memorystatus_kill_process_sync方法，直接杀死对应的进程，如果pid为-1则杀死队列头部的进程。
```c
static boolean_t 
memorystatus_kill_process_sync(pid_t victim_pid, uint32_t cause, os_reason_t jetsam_reason) {
	boolean_t res;

	uint32_t errors = 0;
	
	if (victim_pid == -1) {
		/* No pid, so kill first process */
		res = memorystatus_kill_top_process(TRUE, TRUE, cause, jetsam_reason, NULL, &errors);
	} else {
		res = memorystatus_kill_specific_process(victim_pid, cause, jetsam_reason);
	}
	
	if (errors) {
		memorystatus_clear_errors();
	}
	
	if (res == TRUE) {
		/* Fire off snapshot notification */
		proc_list_lock();
		size_t snapshot_size = sizeof(memorystatus_jetsam_snapshot_t) + 
			sizeof(memorystatus_jetsam_snapshot_entry_t) * memorystatus_jetsam_snapshot_count;
		uint64_t timestamp_now = mach_absolute_time();
		memorystatus_jetsam_snapshot->notification_time = timestamp_now;
		if (memorystatus_jetsam_snapshot_count > 0 && (memorystatus_jetsam_snapshot_last_timestamp == 0 ||
				timestamp_now > memorystatus_jetsam_snapshot_last_timestamp + memorystatus_jetsam_snapshot_timeout)) {
			proc_list_unlock();
			int ret = memorystatus_send_note(kMemorystatusSnapshotNote, &snapshot_size, sizeof(snapshot_size));
			if (!ret) {
				proc_list_lock();
				memorystatus_jetsam_snapshot_last_timestamp = timestamp_now;
				proc_list_unlock();
			}
		} else {
			proc_list_unlock();
		}
	}
	
	return res;
}
```

而memorystatus_kill_on_VM_compressor_space_shortage、memorystatus_kill_on_VM_compressor_thrashing、memorystatus_kill_on_FC_thrashing都是异步触发的，也就是说他们调用的是memorystatus_kill_process_sync方法。
```c
static boolean_t 
memorystatus_kill_process_async(pid_t victim_pid, uint32_t cause) {
	/*
	 * TODO: allow a general async path
	 *
	 * NOTE: If a new async kill cause is added, make sure to update memorystatus_thread() to
	 * add the appropriate exit reason code mapping.
	 */
	if ((victim_pid != -1) ||
			(cause != kMemorystatusKilledVMPageShortage &&
			cause != kMemorystatusKilledVMCompressorThrashing &&
			cause != kMemorystatusKilledVMCompressorSpaceShortage &&
			cause != kMemorystatusKilledFCThrashing &&
			cause != kMemorystatusKilledZoneMapExhaustion)) {
		return FALSE;
	}
    
	kill_under_pressure_cause = cause;
	memorystatus_thread_wake();
	return TRUE;
}
```
也就是最终唤醒了memorystatus_thread，来执行刚刚咱们查看源码的那套流程。

memorystatus_kill_on_zone_map_exhaustion(pid_t pid)中，如果pid为-1，则调用异步方法；否则调用同步方法。

梳理源码逻辑流程
JetSam线程初始化完毕，从外部接收到内存压力
如果接收到的内存压力是当前物理内存达到限制时，同步触发per-process-limit类型的OOM，退出流程
如果接受到的内存压力是其他类型时，则唤醒JetSam线程，判断kill_under_pressure_cause值为kMemorystatusKilledVMThrashing，kMemorystatusKilledFCThrashing，kMemorystatusKilledZoneMapExhaustion时，或者当前可用内存memorystatus_available_pages小于阈值memorystatus_available_pages_pressure时，进入OOM逻辑。
遍历优先级最低的每个进程，根据phys_footprint，判断当前进程是否高于阈值，如果没有超过阈值的，则据需查找下一个次低优先级的进程，直到找到后，触发high-water类型OOM
此时先回一个收优先级较低的进程或正常情况下随时可回收的进程，再次走到4的判断逻辑
当所有低优先级进程或正常情况下课随时回收的进程都被杀掉后，如果memorystatus_available_pages依然小于阈值，先杀掉后台的进程，每杀掉一个进程，判断一下memorystatus_available_pages是否还小于阈值，如果已经小于阈值了，则挂起线程，等待唤醒
当所有后台进程都被杀掉后，调用memorystatus_kill_top_process_aggressive，杀掉前台的进程，挂起线程，等待唤醒
如果上面的memorystatus_kill_top_process_aggressive没有杀掉任何进程，就通过LRU杀死Jetsam队列中的第一个进程，挂起线程，等待唤醒
如何判定发生了OOM
facebook和微信的Matrix都是采用的排除法。在Matrix初始化的时候调用checkRebootType方法，来判定是否发生了OOM，具体流程如下：

如果当前设备正在DEBUG，则直接返回，不继续执行。
上次打开app是否发生了普通的崩溃，如果不是继续执行
上次打开app后，是用户是否主动退出的应用（监听UIApplicationWillTerminateNotification消息），如果不是继续执行
上次打开app后，是否调用exit相关的函数（通过atexit函数监控），如果不是继续执行
上次打开app后，app是否挂起suspend或者执行backgroundFetch，如果此时没有被看门狗杀死，则是一种OOM，Matrix起名叫Suspend OOM，如果不是继续执行
app的uuid是否变化了，如果不是继续执行
上次打开app后，系统是否升级了，如果不是继续执行
上次打开app后，设备是否重启了，如果不是继续执行
上次打开app时，app是否处于后台，如果是，则触发了Background OOM，如果不是继续执行
上次打开app后，app是否处于前台，是否主线程卡死了，如果没有卡死，则说明触发了Foreground OOM。
我们平时谈论的OOM，其实大部分都是FOOM。因为如果我们的程序在后台，优先级很低，即便我们不占用大量的内存，也可能会由于前台应用程序占用了大量的内存，而把我们在后台的程序杀掉。这是系统的机制，我们没有太多的办法。

所以主要关注FOOM。而针对于FOOM，我们需要着重关注dirty pages和IOKit mappings，当然注意系统做的缓存，例如图片、字体等。针对于OOM问题监控与解决，可以参考Matrix和OOMDetector两个开源库。目前针对OOM的监控也处于探索阶段，日后如果在监控及处理OOM上有了一些经验后，也会主动分享给大家。

参考资料
OOM探究：XNU 内存状态管理

你真的了解OOM吗？——京东iOS APP内存优化实录

（译）Handling low memory conditions in iOS and Mavericks

iOS Out-Of-Memory 原理阐述及方案调研

iOS微信内存监控
