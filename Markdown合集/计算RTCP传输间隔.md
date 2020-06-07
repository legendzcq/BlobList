## 计算RTCP传输间隔

中文论文：https://wenku.baidu.com/view/b3a6878084868762caaed5ed.html

为了保持可伸缩性，来自
   参加会议的参与者应随小组人数而定。这个间隔
   称为计算间隔。通过组合一个
   上述状态数。经计算
   然后确定间隔T如下：
1.如果发件人数量小于或等于发件人数量的25％
      成员（成员），间隔取决于是否
      参与者是否是发送者（基于we_sent的值）。
      如果参与者是发送者（we_sent为true），则常数C为
      设置为平均RTCP数据包大小（avg_rtcp_size）除以25％
      RTCP带宽（rtcp_bw）的整数，常数n设置为
      发件人数量。如果we_sent不为真，则设置常量C
      到平均RTCP数据包大小除以RTCP的75％
      带宽。常数n设置为接收器数
      （成员-发送者）。如果发件人数量大于
      25％的发送者和接收者一并处理。常数C
      设置为平均RTCP数据包大小除以总RTCP
      带宽，n设置为成员总数。就像声明的那样
      在第6.2节中，RTP配置文件可以指定RTCP带宽
      可以由两个单独的参数明确定义（称为S
      和R）对于发送者和
      不是。在这种情况下，25％的分数变为S /（S + R），并且
      75％的分数变为R /（S + R）。请注意，如果R为零，则
      发件人百分比永远不会大于S /（S + R），并且
      实现必须避免被零除。

   2.如果参与者尚未发送RTCP数据包（变量
      （initial为true），常数Tmin设为2.5秒，否则
      设置为5秒。

   3.确定性计算间隔Td被设置为max（Tmin，n * C）。

   4.将计算出的间隔T设定为均匀分布的数
      确定性计算间隔的0.5到1.5倍之间。

   5. T的结果值除以e-3 / 2 = 1.21828以进行补偿
      计时器重新考虑算法收敛到
      RTCP带宽的值低于预期的平均值。

   此过程会导致一个随机间隔，但是
   平均而言，至少将25％的RTCP带宽提供给发送方和
   休息给接收者。如果发件人构成四分之一以上
   的成员身份，此过程将带宽平均分配给
   平均而言，所有参与者。

```
To maintain scalability, the average interval between packets from a
   session participant should scale with the group size.  This interval
   is called the calculated interval.  It is obtained by combining a
   number of the pieces of state described above.  The calculated
   interval T is then determined as follows:
    1. If the number of senders is less than or equal to 25% of the
      membership (members), the interval depends on whether the
      participant is a sender or not (based on the value of we_sent).
      If the participant is a sender (we_sent true), the constant C is
      set to the average RTCP packet size (avg_rtcp_size) divided by 25%
      of the RTCP bandwidth (rtcp_bw), and the constant n is set to the
      number of senders.  If we_sent is not true, the constant C is set
      to the average RTCP packet size divided by 75% of the RTCP
      bandwidth.  The constant n is set to the number of receivers
      (members - senders).  If the number of senders is greater than
      25%, senders and receivers are treated together.  The constant C
      is set to the average RTCP packet size divided by the total RTCP
      bandwidth and n is set to the total number of members.  As stated
      in Section 6.2, an RTP profile MAY specify that the RTCP bandwidth
      may be explicitly defined by two separate parameters (call them S
      and R) for those participants which are senders and those which
      are not.  In that case, the 25% fraction becomes S/(S+R) and the
      75% fraction becomes R/(S+R).  Note that if R is zero, the
      percentage of senders is never greater than S/(S+R), and the
      implementation must avoid division by zero.

   2. If the participant has not yet sent an RTCP packet (the variable
      initial is true), the constant Tmin is set to 2.5 seconds, else it
      is set to 5 seconds.

   3. The deterministic calculated interval Td is set to max(Tmin, n*C).

   4. The calculated interval T is set to a number uniformly distributed
      between 0.5 and 1.5 times the deterministic calculated interval.

   5. The resulting value of T is divided by e-3/2=1.21828 to compensate
      for the fact that the timer reconsideration algorithm converges to
      a value of the RTCP bandwidth below the intended average.

   This procedure results in an interval which is random, but which, on
   average, gives at least 25% of the RTCP bandwidth to senders and the
   rest to receivers.  If the senders constitute more than one quarter
   of the membership, this procedure splits the bandwidth equally among
   all participants, on average.
```



```
6.3.4接收RTCP BYE数据包

   RTCP BYE为6.3.7的情况除外
   待发送，如果接收到的分组是RTCP BYE分组，则
   根据成员表检查SSRC。如果存在，则输入为
   从表中删除，并更新成员的值。的
   然后对照发件人表检查SSRC。如果存在，则该条目
   从表中删除，并更新发件人的值。

   进一步提高RTCP报文的传输速率
   适应组成员身份的变化，以下“
   重新考虑”算法应在BYE数据包被
   收到的将会员价值降低到小于pmembers的信息：

   o tn的值根据以下公式更新：

         tn = tc +（成员/成员）*（tn-tc）

   o tp的值根据以下公式更新：

         tp = tc-（成员/成员）*（tc-tp）。
   
   o下一个RTCP数据包被重新安排在时间tn进行传输，
      现在更早了。

   o pmembers的值设置为等于members。

   该算法不会阻止组大小估计
   由于过早而在短时间内错误地降至零
   大多数会议的大多数参与者一次离开但超时的超时
   一些仍然存在。该算法确实使估算值返回到
   更正确地校正值。这种情况很不寻常，
   结果是完全无害的，因此可以认为此问题
   仅次要的。
         
      o成员设置为成员。

   如果发送了RTCP数据包，则将initial的值设置为
   假。此外，avg_rtcp_size的值也会更新：

      avg_rtcp_size =（1/16）*数据包大小+（15/16）* avg_rtcp_size

   其中packet_size是刚发送的RTCP数据包的大小。
   
   
   
         
   Except as described in Section 6.3.7 for the case when an RTCP BYE is
   to be transmitted, if the received packet is an RTCP BYE packet, the
   SSRC is checked against the member table.  If present, the entry is
   removed from the table, and the value for members is updated.  The
   SSRC is then checked against the sender table.  If present, the entry
   is removed from the table, and the value for senders is updated.

   Furthermore, to make the transmission rate of RTCP packets more
   adaptive to changes in group membership, the following "reverse
   reconsideration" algorithm SHOULD be executed when a BYE packet is
   received that reduces members to a value less than pmembers:

   o  The value for tn is updated according to the following formula:

         tn = tc + (members/pmembers) * (tn - tc)

   o  The value for tp is updated according the following formula:

         tp = tc - (members/pmembers) * (tc - tp).

```





```
6.3.9源描述带宽的分配

   该规范定义了以下几个源描述（SDES）项
   除了必填的CNAME项，例如NAME（个人名称）
   和EMAIL（电子邮件地址）。它还提供了一种定义新
   特定于应用程序的RTCP数据包类型。申请应行使
   在为此分配额外的控制带宽时要谨慎
   信息，因为它会减慢接收速度
   报告和CNAME被发送，从而损害了
   协议。建议不超过RTCP的20％
   分配给单个参与者的带宽用于承载
   附加信息。此外，并不打算全部
   SDES项将包含在每个应用程序中。那些是
   应该根据
   他们的效用。与其动态估算这些分数，不如说是
   建议将百分比静态转换为
   报告间隔计数基于项目的典型长度。

   例如，应用程序可能设计为仅发送CNAME，NAME
   和EMAIL，而不是其他任何人。NAME可能会获得更高的排名
   优先于EMAIL，因为该名称将连续显示
   在应用程序的用户界面中，而EMAIL将显示
   仅在要求时。在每个RTCP间隔，一个RR数据包和一个
   将发送带有CNAME项目的SDES数据包。一小节
```

```
相对传输时间是数据包的RTP之间的差
      到达时的时间戳和接收者的时钟，
      以相同单位测量。

      如果Si是来自数据包i的RTP时间戳，而Ri是
      到达数据包i的RTP时间戳单位，然后到达两个数据包
      i和j，D可以表示为

         D（i，j）=（Rj-Ri）-（Sj-Si）=（Rj-Sj）-（Ri-Si）

      每次到达间隔抖动应连续计算
      使用此命令从源SSRC_n接收数据包i
      该数据包与先前数据包i-1的差D
      的到达时间（不一定是顺序的），根据公式

         J（i）= J（i-1）+（| D（i-1，i）|-J（i-1））/ 16

      每当发布接收报告时，J的当前值为
      采样。
      抖动计算必须符合此处指定的公式
      为了允许独立于配置文件的监视器有效
      来自不同实现的报告的解释。
      该算法是最优的一阶估计器和增益
      参数1/16可提供良好的降噪比，而
      保持合理的收敛速度[22]。一个样品
      具体实现见附录A.8。参见6.4.4节
      讨论分组持续时间和延迟变化的影响
      传输之前。
```