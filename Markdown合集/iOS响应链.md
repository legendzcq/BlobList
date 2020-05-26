## iOS响应链 

### 前言

当我们的手指点击屏幕的时候我们的app是怎么响应的呢，当我们点击一个不规则的view的时候怎么能给这个view的不同区域设置热区呢，让我们来一起了解iOS的响应链机制。

### 基本概念 

当用户的手指点击屏幕的时候，iOS操作系统通过触摸屏获取用户的点击行为，然后把这个点击信息包装成UITouch和UIEvent形式的实例，然后找到当前运行的程序，在这个程序中逐级寻找能够响应这个事件的所有对象，然后把这些对象放入一个链表，这个链表就是iOS的响应链。

下图是一个事件响传递顺序从上向下传递：

![img](https:////upload-images.jianshu.io/upload_images/2433938-3e67d46f16a3d6e9.png?imageMogr2/auto-orient/strip|imageView2/2/w/851)


UIResponder提供了四个方法来响应点击事件：





```objectivec
- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event;
- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event;
- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event;
- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event;
```

所以iOS中的对象想要响应事件都需要直接或间接的继承UIResponder，AppDelegate,UIApplication,UIWindow,ViewController都直接或者间接的继承了UIResponder，所以它们可以作为响应链中的对象来处理我们用户的点击事件。

### 响应链形成 

假设我们有下面的页面：

![img](https:////upload-images.jianshu.io/upload_images/2433938-6dfc30f18af43273.png?imageMogr2/auto-orient/strip|imageView2/2/w/376)





AView上面添加了BView和CView，CView上面添加了DView，现在用户点击了DView，然后系统会接收到这个点击事件，然后调用



```objectivec
- (BOOL)pointInside:(CGPoint)point withEvent:(nullable UIEvent *)event;   
```

方法，该方法是判断点击的点是够在本对象内，如果返回true则继续调用



```objectivec
- (nullable UIView *)hitTest:(CGPoint)point withEvent:(nullable UIEvent *)event;
```

，返回当前的这个对象，在我们上图的这歌机构中判断顺序是这样的：

1.触摸的这个点坐标在AView上吗？true，然后AView加入响应链，继续遍历AView的子页面BView和CView。

2.在BView上吗？false。该分支结束。

3.在CView上吗？true，CView加入响应链，继续遍历CView的子视图DView。

3.在DView上吗？在,DView加入响应链，DView没有子页面，这个检测结束。

经过以上检测就形成了这样一个链：AView -->CView -->DView。

需要注意的是，响应链的建立一定是在一个subview的关系，如果只是一个页面在另一个页面上面，没有包含关系的话，这个响应链就不会传递。
证实我们的以上猜测我们可以打印一下我们这个当前页面的响应者链。

### 举例证明 

我们上面讲过UIResponder其中有一个方法



```objectivec
- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event;
```

我们在DView中重写这个方法：



```objectivec
- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    UIResponder * next = [self nextResponder];
    NSMutableString * prefix = @"--".mutableCopy;
    NSLog(@"%@", [self class]);
    
    while (next != nil) {
        NSLog(@"%@%@", prefix, [next class]);
        [prefix appendString: @"--"];
        next = [next nextResponder];
    }
}
```

打印结果如下:



![img](https:////upload-images.jianshu.io/upload_images/2433938-b708379a54fc8b62.png?imageMogr2/auto-orient/strip|imageView2/2/w/214)



这就是我们刚才点击事件的响应链，第一响应者就是DView。



### 事件响应 

事件的传递是从上到下的，事件的响应是从下到上的。

响应链已经建立起来，那么下面就该响应用户刚才的那次点击了，首先找到第一响应者DView，看他有没有处理这次点击事件，如果DView不处理就通过响应链找到它的nextResponder-CView，CView如果也不处理就会一直向上寻找，如果最终找到响应链的最后一个响应者AppDelegate也不处理，就会丢弃这次点击事件。

### 响应链的应用 

现在我们知道了响应链的生成过程以后我们都可以做哪些事情呢：

1.更改一个对象的响应热区，通过重写对象的



```objectivec
- (BOOL)pointInside:(CGPoint)point withEvent:(UIEvent *)event
```

方法可以给对象的其中一块区域添加热区。

2.实现一次点击的多次响应
我们可以让当前响应对象和它的下一个响应对象同时对一次点击对象作出处
理：



```objectivec
- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event{
    NSLog(@"我是d我响应le");
    //调用下一响应者的响应方法
    [super touchesBegan:touches withEvent:event];
}
```

还有很多其他的例如点击事件不响应我们的排错方法啦，等等用处可以根据我们项目的具体需求来使用。

首先，当发生事件响应时，必须知道由谁来响应事件。在IOS中，由响应者链来对事件进行响应，所有事件响应的类都是UIResponder的子类，响应者链是一个由不同对象组成的层次结构，其中的每个对象将依次获得响应事件消息的机会。当发生事件时，事件首先被发送给第一响应者，第一响应者往往是事件发生的视图，也就是用户触摸屏幕的地方。事件将沿着响应者链一直向下传递，直到被接受并做出处理。一般来说，第一响应者是个视图对象或者其子类对象，当其被触摸后事件被交由它处理，如果它不处理，事件就会被传递给它的视图控制器对象viewcontroller（如果存在），然后是它的父视图（superview）对象（如果存在），以此类推，直到顶层视图。接下来会沿着顶层视图（top view）到窗口（UIWindow对象）再到程序（UIApplication对象）。如果整个过程都没有响应这个事件，该事件就被丢弃。一般情况下，在响应者链中只要由对象处理事件，事件就停止传递。

一个典型的相应路线图如：

First Responser -- > The Window -- >The Application -- > App Delegate

 

正常的响应者链流程经常被委托（delegation）打断，一个对象（通常是视图）可能将响应工作委托给另一个对象来完成（通常是视图控制器ViewController），这就是为什么做事件响应时在ViewController中必须实现相应协议来实现事件委托。在iOS中，存在UIResponder类，它定义了响应者对象的所有方法。UIApplication、UIView等类都继承了UIResponder类，UIWindow和UIKit中的控件因为继承了UIView，所以也间接继承了UIResponder类，这些类的实例都可以当作响应者。

 

 

 

##一、事件分类

对于IOS设备用户来说，他们操作设备的方式主要有三种：触摸屏幕、晃动设备、通过遥控设施控制设备。对应的事件类型有以下三种：

1、触屏事件（Touch Event）

2、运动事件（Motion Event）

3、远端控制事件（Remote-Control Event）

今天以触屏事件（Touch Event）为例，来说明在Cocoa Touch框架中，事件的处理流程。首先不得不先介绍响应者链这个概念：

##二、响应者链（Responder Chain）

先来说说响应者对象（Responder Object），顾名思义，指的是有响应和处理事件能力的对象。响应者链就是由一系列的响应者对象构成的一个层次结构。

UIResponder是所有响应对象的基类，在UIResponder类中定义了处理上述各种事件的接口。我们熟悉的UIApplication、 UIViewController、UIWindow和所有继承自UIView的UIKit类都直接或间接的继承自UIResponder，所以它们的实例都是可以构成响应者链的响应者对象。图一展示了响应者链的基本构成：

![技术分享](SouthEast.jpeg)

​            																		 图一

从图一中可以看到，响应者链有以下特点：

1、响应者链通常是由视图（UIView）构成的；

2、一个视图的下一个响应者是它视图控制器（UIViewController）（如果有的话），然后再转给它的父视图（Super View）；

3、视图控制器（如果有的话）的下一个响应者为其管理的视图的父视图；

4、单例的窗口（UIWindow）的内容视图将指向窗口本身作为它的下一个响应者

需要指出的是，Cocoa Touch应用不像Cocoa应用，它只有一个UIWindow对象，因此整个响应者链要简单一点；

5、单例的应用（UIApplication）是一个响应者链的终点，它的下一个响应者指向nil，以结束整个循环。

##三、事件分发（Event Delivery）

第一响应者（First responder）指的是当前接受触摸的响应者对象（通常是一个UIView对象），即表示当前该对象正在与用户交互，它是响应者链的开端。整个响应者链和事件分发的使命都是找出第一响应者。

UIWindow对象以消息的形式将事件发送给第一响应者，使其有机会首先处理事件。如果第一响应者没有进行处理，系统就将事件（通过消息）传递给响应者链中的下一个响应者，看看它是否可以进行处理。

iOS系统检测到手指触摸(Touch)操作时会将其打包成一个UIEvent对象，并放入当前活动Application的事件队列，单例的UIApplication会从事件队列中取出触摸事件并传递给单例的UIWindow来处理，UIWindow对象首先会使用`hitTest:withEvent:`方法寻找此次Touch操作初始点所在的视图(View)，即需要将触摸事件传递给其处理的视图，这个过程称之为hit-test view。

UIWindow实例对象会首先在它的内容视图上调用`hitTest:withEvent:`，此方法会在其视图层级结构中的每个视图上调用`pointInside:withEvent:`（该方法用来判断点击事件发生的位置是否处于当前视图范围内，以确定用户是不是点击了当前视图），如果pointInside:withEvent:返回YES，则继续逐级调用，直到找到touch操作发生的位置，这个视图也就是要找的hit-test view。
`hitTest:withEvent:`方法的处理流程如下:
首先调用当前视图的`pointInside:withEvent:`方法判断触摸点是否在当前视图内；
若返回NO,则hitTest:withEvent:返回nil;
若返回YES,则向当前视图的所有子视图(subviews)发送hitTest:withEvent:消息，所有子视图的遍历顺序是从最顶层视图一直到到最底层视图，即从subviews数组的末尾向前遍历，直到有子视图返回非空对象或者全部子视图遍历完毕；
若第一次有子视图返回非空对象，则`hitTest:withEvent:`方法返回此对象，处理结束；

如所有子视图都返回非，则`hitTest:withEvent:`方法返回自身(self)。

![技术分享](SouthEast.png)

​      																	      图二

加入用户点击了View E，下面结合图二介绍hit-test view的流程：

1、A是UIWindow的根视图，因此，UIWindwo对象会首相对A进行hit-test；

2、显然用户点击的范围是在A的范围内，因此，`pointInside:withEvent:`返回了YES，这时会继续检查A的子视图；

3、这时候会有两个分支，B和C：

点击的范围不再B内，因此B分支的`pointInside:withEvent:`返回NO，对应的hitTest:withEvent:返回nil；

点击的范围在C内，即C的`pointInside:withEvent`:返回YES；

4、这时候有D和E两个分支：

点击的范围不再D内，因此D的`pointInside:withEvent:`返回NO，对应的`hitTest:withEvent:`返回nil；

点击的范围在E内，即E的`pointInside:withEvent:`返回YES，由于E没有子视图（也可以理解成对E的子视图进行hit-test时返回了nil），因此，E的hitTest:withEvent:会将E返回，再往回回溯，就是C的`hitTest:withEvent`:返回E--->>A的`hitTest:withEvent:`返回E。

至此，本次点击事件的第一响应者就通过响应者链的事件分发逻辑成功的找到了。

不难看出，这个处理流程有点类似二分搜索的思想，这样能以最快的速度，最精确地定位出能响应触摸事件的UIView。

##四、说明

1、如果最终hit-test没有找到第一响应者，或者第一响应者没有处理该事件，则该事件会沿着响应者链向上回溯，如果UIWindow实例和UIApplication实例都不能处理该事件，则该事件会被丢弃；

2、`hitTest:withEvent:`方法将会忽略隐藏(hidden=YES)的视图，禁止用户操作(userInteractionEnabled=YES)的视图，以及alpha级别小于0.01(alpha<0.01)的视图。如果一个子视图的区域超过父视图的bound区域(父视图的clipsToBounds 属性为NO，这样超过父视图bound区域的子视图内容也会显示)，那么正常情况下对子视图在父视图之外区域的触摸操作不会被识别,因为父视图的`pointInside:withEvent`:方法会返回NO,这样就不会继续向下遍历子视图了。当然，也可以重写`pointInside:withEvent:`方法来处理这种情况。

3、我们可以重写hitTest:withEvent:来达到某些特定的目的，实际应用中很少用到这些。