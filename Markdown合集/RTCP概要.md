
RTCP协议介绍

# **RTCP概要**

实时传输控制协议(**R**eal-**t**ime **C**ontrol**P**rotocol，RTCP)与RTP共同定义在1996年提出的RFC 1889中，是和 RTP一起工作的控制协议。**RTCP单独运行在低层协议上，由低层协议提供数据与控制包的复用。在RTP会话期间，每个会话参与者周期性地向所有其他参与者发送RTCP控制信息包**，如下图所示。**对于RTP会话或者广播，通常使用单个多目标广播地址，属于这个会话的所有RTP和RTCP信息包都使用这个多目标广播地址，通过使用不同的端口号可把RTP信息包和RTCP信息包区分开来。**

![img](https://img-blog.csdn.net/20151225090240910)
图 每个参与者周期性地发送RTCP控制信息包

# **RTCP功能**

1、为应用程序提供会话质量或者广播性能质量的信息　

**RTCP的主要功能是为应用程序提供会话质量或者广播性能质量的信息。**每个RTCP信息包不封装声音数据或者电视数据，而是封装发送端（和 / 或者）接收端的统计报表。这些信息包括**发送的信息包数目、丢失的信息包数目和信息包的抖动等情况**，这些反馈信息反映了当前的网络状况，对发送端、接收端或者网络管理员都非常有用。RTCP规格没有指定应用程序应该使用这些反馈信息做什么，这完全取决于应用程序开发人员。例如，发送端可以根据反馈信息来调整传输速率，接收端可以根据反馈信息判断问题是本地的、区域性的还是全球性的，网络管理员也可以使用RTCP信息包中的信息来评估网络用于多目标广播的性能。

2、确定 RTP用户源　

RTCP为每个RTP用户提供了一个全局唯一的**规范名称 (Canonical Name)标志符 CNAME**，**接收者使用它来追踪一个RTP进程的参加者。**当发现冲突或程序重新启动时，RTP中的同步源标识符SSRC可能发生改变，接收者可利用CNAME来跟踪参加者。同时，接收者也需要利用CNAME在相关RTP连接中的几个数据流之间建立联系。当 RTP需要进行音视频同步的时候，接受者就需要使用 CNAME来使得同一发送者的音视频数据相关联，然后根据*RTCP包中的计时信息\*(Network time protocol)来实现音频和视频的同步。**

3、控制 RTCP传输间隔

由于每个对话成员定期发送RTCP信息包，随着参加者不断增加，RTCP信息包频繁发送将占用过多的网络资源，为了防止拥塞，必须限制RTCP信息包的流量，**控制信息所占带宽一般不超过可用带宽的 5%**，因此就需要调整 RTCP包的发送速率。由于任意两个RTP终端之间都互发 RTCP包，因此终端的总数很容易估计出来，**应用程序根据参加者总数就可以调整RTCP包的发送速率。**

4、传输最小进程控制信息　

这项功能对于**参加者可以任意进入和离开的松散会话进程**十分有用，参加者可以自由进入或离开，没有成员控制或参数协调。

# **RTCP信息包**

*RTCP也是用\*UDP来传送的，但\*RTCP封装的仅仅是一些控制信息，因而分组很短，所以可以将多个\*RTCP分组封装在一个\*UDP包中。
*****

**类似于RTP信息包，每个RTCP信息包以固定部分开始，紧接着的是可变长结构单元，最后以一个32位边界结束。**

**根据所携带的控制信息不同RTCP信息包可分为RR（接收者报告包）、SR（源报告包）、SEDS（源描述包）、BYE（离开申明）和APP（特殊应用包）五类5类：**

 

| 类型 | 缩写表示                         | 用途       |
| ---- | -------------------------------- | ---------- |
| 200  | SR（Sender Report）              | 发送端报告 |
| 201  | RR（Receiver Report）            | 接收端报告 |
| 202  | SDES（Source Description Items） | 源点描述   |
| 203  | BYE                              | 结束传输   |
| 204  | APP                              | 特定应用   |



 

 

| Type      | Description                               | References                                                   |
| :-------- | :---------------------------------------- | :----------------------------------------------------------- |
| 0 - 191   |                                           |                                                              |
| 192       | FIR, full INTRA-frame request.            | [RFC 2032](http://www.networksorcery.com/enp/rfc/rfc2032.txt) |
| 193       | NACK, negative acknowledgement.           | [RFC 2032](http://www.networksorcery.com/enp/rfc/rfc2032.txt) |
| 194       | SMPTETC, SMPTE time-code mapping.         | RFC5484                                                      |
| 195       | IJ, extended inter-arrival jitter report. | [RFC 5450](http://www.networksorcery.com/enp/rfc/rfc5450.txt) |
| 196 - 199 |                                           |                                                              |
| 200       | SR, sender report.                        | [RFC 3550](http://www.networksorcery.com/enp/rfc/rfc3550.txt) |
| 201       | RR, receiver report.                      | [RFC 3550](http://www.networksorcery.com/enp/rfc/rfc3550.txt) |
| 202       | SDES, source description.                 | [RFC 3550](http://www.networksorcery.com/enp/rfc/rfc3550.txt) |
| 203       | BYE, goodbye.                             | [RFC 3550](http://www.networksorcery.com/enp/rfc/rfc3550.txt) |
| 204       | APP, application defined.                 | [RFC 3550](http://www.networksorcery.com/enp/rfc/rfc3550.txt) |
| 205       | RTPFB, Generic RTP Feedback.              |                                                              |
| 206       | PSFB, Payload-specific Feedback.          |                                                              |
| 207       | XR, RTCP extension.                       | [RFC 3611](http://www.networksorcery.com/enp/rfc/rfc3611.txt) |
| 208       | AVB, AVB RTCP packet.                     | IEEE 1733                                                    |
| 209       | RSI, Receiver Summary Information.        | RFC 5760                                                     |
| 210 - 255 |                                           |                                                              |



 

## 1、SR：

发送端报告包，用于发送和接收活动源的统计信息；