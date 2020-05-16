# [[NSObject alloc] init]占用多少空间？

### Objective-C的本质

Objective-C代码底层实现其实都是C\C++代码。

![编译流程](https://user-gold-cdn.xitu.io/2020/5/11/17200d2ec592e67a)

编译流程

- Objective-C的面向对象都是基于C\C++的`结构体`这种数据结构实现的。

### 将Objective-C转为C/C++

> clang -rewrite-objc main.m -o main.cpp

在`main.m`文件所在的目录执行上面的命令，将Objective-C代码转为C++代码，输出文件为`main.cpp`。这个命令并没有指定编辑的平台与架构，针对iOS系统，我们可以用下面这个命令：

> xcrun -sdk iphoneos clang -arch arm64 -rewrite-objc main.m -o main-arm64.cpp

指定sdk为`iphoneos`，针对iOS系统，-arch `arm64` 表示针对arm64架构进行编译，输出文件为`main-arm64.cpp`。

**注：** iOS架构：模拟器`i386` 32bit`armv7` 64bit`arm64`

`xcrun` 是Xcode的命令，如果无法执行可能是因为装了两个版本的Xcode。在命令行指定一下Xcode路径：

> sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer/

### NSObject底层实现

在`NSObject.h` 文件中，我们可以看到NSObject的声明如下图左， 在`main-arm64.cpp` 中可以发现NSObject的实现如下图右。可以得出结论，NSObject的底层是使用了C/C++的结构体来实现的。

![OC->C/C++](https://user-gold-cdn.xitu.io/2020/5/11/17200d2ea7fad7a1)

OC->C/C++

接下来，我们继续查看`Class`的声明，如下，可以看到，Class是一个指向结构体变量的指针。因为在64位的系统中，一个指针占用8个字节，所有上图中的`isa`占用8个字节。

```c
typedef struct objc_class *Class;

```

为了获取NSOject对象所占的内存空间，我们可以通过`malloc_size` 函数获取对象所占用内存空间的大小。注意，需要导入库 `malloc/malloc.h`

```objective-c
#import <malloc/malloc.h>

NSObject *obj = [[NSObject alloc] init];
//获得obj指针所指向内存的大小 输出结果为 16
NSLog(@"%zd", malloc_size((__bridge const void*)obj)); 

```

另外，我们还可以通过`class_getInstanceSize`方法获取对象的所有成员变量所占用的内存空间。注意，需要导入库`objc/runtime.h`。在上面的分析中，我们已经确认`NSObject`内部只有一个`isa`成员变量，它是一个指向`Class`结构体的指针变量。

```objective-c
#import <objc/runtime.h>

//获得NSObject实例对象的成员变量所占用的大小。 输出结果为 8
NSLog(@"%zd", class_getInstanceSize([NSObject class]));

```

我们也可以分析一下`class_getInstanceSize`的源码实现，如下：

```objective-c
//源码版本：objc4-723

size_t class_getInstanceSize(Class cls)
{
    if (!cls) return 0;
    return cls->alignedInstanceSize();
}

//Class's ivar size rounded up to a pointer-size boundary.
//类的成员变量的大小，word_align 对齐操作
uint32_t alignedInstanceSize() {
  return word_align(unalignedInstanceSize());
}

// May be unaligned depending on class's ivars.
// 类的成员变量的未对齐的大小
uint32_t unalignedInstanceSize() {
  return data()->ro->instanceSize;
}

//对齐函数实现
static inline size_t word_align(size_t x) {
    return (x + WORD_MASK) & ~WORD_MASK;
}

#ifdef __LP64__
#   define WORD_SHIFT 3UL
#   define WORD_MASK 7UL
#   define WORD_BITS 64
#else
#   define WORD_SHIFT 2UL
#   define WORD_MASK 3UL
#   define WORD_BITS 32
#endif
```

`alloc` 源码：

```objective-c
//源码版本：objc4-723

+ (id)alloc {
    return _objc_rootAlloc(self);
}

//Base class implementation of +alloc. cls is not nil.
// Calls [cls allocWithZone:nil].
id _objc_rootAlloc(Class cls)
{
    return callAlloc(cls, false/*checkNil*/, true/*allocWithZone*/);
}

// Call [cls alloc] or [cls allocWithZone:nil], with appropriate 
// shortcutting optimizations.
static ALWAYS_INLINE id callAlloc(Class cls, bool checkNil, bool allocWithZone=false)
{
    if (slowpath(checkNil && !cls)) return nil;
    if (fastpath(!cls->ISA()->hasCustomAWZ())) {
        if (fastpath(cls->canAllocFast())) {
            // No ctors, raw isa, etc. Go straight to the metal.
            bool dtor = cls->hasCxxDtor();
            id obj = (id)calloc(1, cls->bits.fastInstanceSize());
            if (slowpath(!obj)) return callBadAllocHandler(cls);
            obj->initInstanceIsa(cls, dtor);
            return obj;
        }
        else {
            // Has ctor or raw isa or something. Use the slower path.
            id obj = class_createInstance(cls, 0);
            if (slowpath(!obj)) return callBadAllocHandler(cls);
            return obj;
        }
    }
    if (allocWithZone) return [cls allocWithZone:nil];
    return [cls alloc];
}

//创建实例
id class_createInstance(Class cls, size_t extraBytes)
{
    return _class_createInstanceFromZone(cls, extraBytes, nil);
}

static __attribute__((always_inline)) id
_class_createInstanceFromZone(Class cls, size_t extraBytes, void *zone, 
                              bool cxxConstruct = true, 
                              size_t *outAllocatedSize = nil)
{
    if (!cls) return nil;

    assert(cls->isRealized());

    // Read class's info bits all at once for performance
    bool hasCxxCtor = cls->hasCxxCtor();
    bool hasCxxDtor = cls->hasCxxDtor();
    bool fast = cls->canAllocNonpointer();

  	//获取size
    size_t size = cls->instanceSize(extraBytes);
    if (outAllocatedSize) *outAllocatedSize = size;

    id obj;
    if (!zone  &&  fast) {
        obj = (id)calloc(1, size);
        if (!obj) return nil;
        obj->initInstanceIsa(cls, hasCxxDtor);
    } 
    else {
        if (zone) {
            obj = (id)malloc_zone_calloc ((malloc_zone_t *)zone, 1, size);
        } else {
            obj = (id)calloc(1, size);
        }
        if (!obj) return nil;
        obj->initIsa(cls);
    }

    if (cxxConstruct && hasCxxCtor) {
        obj = _objc_constructOrFree(obj, cls);
    }

    return obj;
}

size_t instanceSize(size_t extraBytes) {
  //alignedInstanceSize 就是 class_getInstanceSize 也就是内部变量所占用的空间大小
  size_t size = alignedInstanceSize() + extraBytes;
  // CF requires all objects be at least 16 bytes.
  //最小为16
  if (size < 16) size = 16;
  return size;
}

```

我们可以画出`[[NSObject alloc] init]` 执行后的内存结构图。

![image-20200505220829847](https://user-gold-cdn.xitu.io/2020/5/11/17200d2ea8ec5eb3)

至此，我们分析得到结论，NSObject对象占用16个字节的内存空间，其中前8个字节是`isa`变量，它是一个指向`Class`结构体的指针。

#### 查看内存布局

1. Debug —> Debug Workflow —> View Memory

![查看内存](https://user-gold-cdn.xitu.io/2020/5/11/17200d2eb00174ac)

查看内存

1. 通过LLDB查看内存布局：

通过`memory read` 指令可以读取内存地址。简写为`x`。其后面可以跟上数量/格式/字节数。

如：**x/4xg 0x10312b010** 表示 读写每次读取8个字节，读写4组数据，并以16进制的形式表示。

格式：`x`是16进制，`f`是浮点数，`d`是10进制。

字节大小：`b` byte是1字节， `h` half world 是2字节，`w` world是4字节， `g` giant world是8字节。

> **(lldb)** **po obj**
>
> <NSObject: 0x10312b010>
>
> **(lldb)** **memory read 0x10312b010**
>
> 0x10312b010: 19 91 62 98 ff ff 1d 00 00 00 00 00 00 00 00 00 ..b.............
>
> 0x10312b020: 2d 5b 4e 53 54 61 62 50 69 63 6b 65 72 56 69 65 -[NSTabPickerVie
>
> **(lldb)** **x 0x10312b010**
>
> 0x10312b010: 19 91 62 98 ff ff 1d 00 00 00 00 00 00 00 00 00 ..b.............
>
> 0x10312b020: 2d 5b 4e 53 54 61 62 50 69 63 6b 65 72 56 69 65 -[NSTabPickerVie
>
> **(lldb)** **x/3xg 0x10312b010**
>
> 0x10312b010: 0x001dffff98629119 0x0000000000000000
>
> 0x10312b020: 0x50626154534e5b2d
>
> **(lldb)** **x/4xg 0x10312b010**
>
> 0x10312b010: 0x001dffff98629119 0x0000000000000000
>
> 0x10312b020: 0x50626154534e5b2d 0x65695672656b6369

#### 修改内存中的值

使用 `memory write` 命令可以修改内存中某个位置所表示的内容。下面命令是要修改0x10312b010起始第9个字节，将其内容从0改为8。

> **(lldb)** **memory read 0x10312b010**
>
> 0x10312b010: 19 91 62 98 ff ff 1d 00 **00** 00 00 00 00 00 00 00 ..b.............
>
> 0x10312b020: 2d 5b 4e 53 54 61 62 50 69 63 6b 65 72 56 69 65 -[NSTabPickerVie
>
> **(lldb)** **memory write 0x10312b018 8**
>
> **(lldb)** **memory read 0x10312b010**
>
> 0x10312b010: 19 91 62 98 ff ff 1d 00 **08** 00 00 00 00 00 00 00 ..b.............
>
> 0x10312b020: 2d 5b 4e 53 54 61 62 50 69 63 6b 65 72 56 69 65 -[NSTabPickerVie

### 复杂的模型

定义一个类继承自`NSObject`。

```objective-c
@interface Student : NSObject {
    @public
    int _no;
    int _age;
}
@end

@implementation Student
@end
```

将该类编译成C/C++代码，其实现如下：

```objective-c
struct NSObject_IMPL {
 Class isa;
};

struct Student_IMPL {
 struct NSObject_IMPL NSObject_IVARS;
 int _no;
 int _age;
};

```

`Student`将其父类`NSObject`的成员变量都继承过来了，相当于:

```objective-c
struct Student_IMPL {
 Class isa;
 int _no;
 int _age;
};
```

在这个结构中，`isa`占用8个字节，`_no`与`_age`各占用4个字节，所以，Student内部的成员变量一共占用16个字节的空间。

即：`NSLog(@"%zd", class_getInstanceSize([Student class]));` 输出结果为16。

`NSLog(@"%zd", malloc_size((__bridge const void *)student));` 输出结果也为16，因为内部成语变量的大小为16，刚好为alloc创建出来的最小空间相等。

`Student`的内存结构如下:

![image-20200506124926322](https://user-gold-cdn.xitu.io/2020/5/11/17200d2eb044f029)

我们可以构造一个结构体，将`student`对象强制转换为结构体，如下：我们就可以通过结构体正确的访问到内部变量。

```objective-c
struct Student_Impl {
    Class isa;
    int _no;
    int _age;
};

struct Student_Impl *impl = (__bridge struct Student_Impl *)student;
NSLog(@"no=%d, age=%d", impl->_no, impl->_age);
```

我们可以进一步证实`isa`的起始地址就是`student`指向的地址。

> **(lldb)** **po &impl->isa**
>
> <Student: 0x103905a40>
>
> **(lldb)** **po student**
>
> <Student: 0x103905a40>

### 更为复杂的模型

```objective-c
@interface Person : NSObject {
    @public
    int _age;
}
@end

@implementation Person
@end

@interface Student : Person {
    @public
    int _no;
}
@end

@implementation Student
@end
复制代码
```

转换为C/C++为：

```objective-c
struct Student_IMPL {
    struct Person_IMPL Person_IVARS;
    int _no;
};
 
struct Person_IMPL {
  struct NSObject_IMPL NSObject_IVARS;
  int _age;
};
struct NSObject_IMPL {
  Class isa;
};
```

内存分布：

![image-20200506132936304](https://user-gold-cdn.xitu.io/2020/5/11/17200d2eb119afcc)

```objective-c
Person *person = [[Person alloc] init];
//16 虽然真实大小为12，由于内存对齐，为16
NSLog(@"%zd", class_getInstanceSize([person class])); 
NSLog(@"%zd", malloc_size((__bridge const void *)person)); //16

Student *student = [[Student alloc] init];
NSLog(@"%zd", class_getInstanceSize([student class])); //16
NSLog(@"%zd", malloc_size((__bridge const void *)student)); //16
```

注，内存对齐：结构体的大小必须是最大成员大小的倍数。

### 开辟内存空间大小规则

```objective-c
@interface Person : NSObject {
    @public
    int _age;
    int _no;
}
@end

@implementation Person
@end

@interface Student : Person{
     @public
    int data;
}
@end
```

在上面这种类的结构中，我们打印出变量空间大小和内存大小。

```objective-c
NSLog(@"%zd", class_getInstanceSize([Student class])); //24
NSLog(@"%zd", malloc_size((__bridge const void *)student)); //32
```

`class_getInstanceSize` 这个大小是16+8(int 4, 内存对齐为8) = 24，应该不难理解。

`malloc_size` 这个为32 就有点难理解了，原因是操作系统在开辟内存的时候不是你需要多少就开辟多少，而是要根据一定的规则，为了方便内存管理与寻址，iOS系统开辟内存的空间都是16的倍数，所有我们需要24个字节的大小，操作系统给我们分配了32个字节。具体开辟方式可以参考资料一。

### 参考

参考一：https://yq.aliyun.com/articles/3065

参考二：MJ底层原理