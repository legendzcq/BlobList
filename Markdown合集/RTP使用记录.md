# RTP使用记录

**概念**

R = Real-Time

T = Transport

P = Protocol

实时传输协议**，**一般用于音视频数据的传输。



**特征**

1）一般使用UDP传输，而不是TCP。因为用户观看收听音视频，可容忍少1,2画面，但不能容忍卡顿。

2）RTP 本身并没有提供按时发送机制或其它服务质量（QoS）保证，它依赖于底层服务去实现这一过程。所以代码中对RTP发送需要控制发送时间，如果发送过快播放也就过快了。一般设置的每次发送160字节，间隔19500000纳秒。

19,500,000 = 19.5毫秒

**组成**

RTP标准定义了两个子协议，RTP和RTCP。

数据传输协议RTP，用于实时传输数据。该协议提供的信息包括：时间戳（用于同步）、序列号（用于丢包和重排序检测）、以及负载格式（用于说明数据的编码格式）。

控制协议RTCP，用于QoS反馈和同步媒体流。相对于RTP来说，RTCP所占的带宽非常小，通常只有5%。



RTP协议定义于RFC3551，RFC4733。更加详细的资料查看文档。



RTP类的封装

```c++
public class RtpPacket {

    private int version;
    private boolean padding;
    private boolean extension;
    private int csrcCount;
    private boolean marker;
    private int payloadType;
    private int sequenceNumber;
    private long timestamp;
    private long ssrc;
    private long[] csrcList;
    private byte[] data;
}
```



RTP包的解析

```c++
// RFC 3550
public class RtpParser {

    private Logger logger;

    public RtpParser(Logger logger) {
        this.logger = logger;
    }

    public RtpPacket decode(byte[] packet) {
        if (packet.length < 12) {
            logger.error("RTP packet too short");
            return null;
        }
        RtpPacket rtpPacket = new RtpPacket();
        int b = (int)(packet[0] & 0xff);
        rtpPacket.setVersion((b & 0xc0) >> 6);
        rtpPacket.setPadding((b & 0x20) != 0);
        rtpPacket.setExtension((b & 0x10) != 0);
        rtpPacket.setCsrcCount(b & 0x0f);
        b = (int)(packet[1] & 0xff);
        rtpPacket.setMarker((b & 0x80) != 0);
        rtpPacket.setPayloadType(b & 0x7f);
        b = (int)(packet[2] & 0xff);
        rtpPacket.setSequenceNumber(b * 256 + (int)(packet[3] & 0xff));
        b = (int)(packet[4] & 0xff);
        rtpPacket.setTimestamp(b * 256 * 256 * 256
                + (int)(packet[5] & 0xff) * 256 * 256
                + (int)(packet[6] & 0xff) * 256
                + (int)(packet[7] & 0xff));
        b = (int)(packet[8] & 0xff);
        rtpPacket.setSsrc(b * 256 * 256 * 256
                + (int)(packet[9] & 0xff) * 256 * 256
                + (int)(packet[10] & 0xff) * 256
                + (int)(packet[11] & 0xff));
        long[] csrcList = new long[rtpPacket.getCsrcCount()];
        for (int i = 0; i < csrcList.length; ++i)
            csrcList[i] = (int)(packet[12 + i] & 0xff) << 24
                + (int)(packet[12 + i + 1] & 0xff) << 16
                + (int)(packet[12 + i + 2] & 0xff) << 8
                + (int)(packet[12 + i + 3] & 0xff);
        rtpPacket.setCsrcList(csrcList);
        int dataOffset = 12 + csrcList.length * 4;
        int dataLength = packet.length - dataOffset;
        byte[] data = new byte[dataLength];
        System.arraycopy(packet, dataOffset, data, 0, dataLength);
        rtpPacket.setData(data);
        return rtpPacket;
    }

    public byte[] encode(RtpPacket rtpPacket) {
        byte[] data = rtpPacket.getData();
        int packetLength = 12 + rtpPacket.getCsrcCount() * 4 + data.length;
        byte[] packet = new byte[packetLength];
        int b = (rtpPacket.getVersion() << 6)
            + ((rtpPacket.isPadding() ? 1 : 0) << 5)
            + ((rtpPacket.isExtension() ? 1 : 0) << 4)
            + (rtpPacket.getCsrcCount());
        packet[0] = new Integer(b).byteValue();
        b = ((rtpPacket.isMarker() ? 1 : 0) << 7)
            + rtpPacket.getPayloadType();
        packet[1] = new Integer(b).byteValue();
        b = rtpPacket.getSequenceNumber() >> 8;
        packet[2] = new Integer(b).byteValue();
        b = rtpPacket.getSequenceNumber() & 0xff;
        packet[3] = new Integer(b).byteValue();
        b = (int)(rtpPacket.getTimestamp() >> 24);
        packet[4] = new Integer(b).byteValue();
        b = (int)(rtpPacket.getTimestamp() >> 16);
        packet[5] = new Integer(b).byteValue();
        b = (int)(rtpPacket.getTimestamp() >> 8);
        packet[6] = new Integer(b).byteValue();
        b = (int)(rtpPacket.getTimestamp() & 0xff);
        packet[7] = new Integer(b).byteValue();
        b = (int)(rtpPacket.getSsrc() >> 24);
        packet[8] = new Integer(b).byteValue();
        b = (int)(rtpPacket.getSsrc() >> 16);
        packet[9] = new Integer(b).byteValue();
        b = (int)(rtpPacket.getSsrc() >> 8);
        packet[10] = new Integer(b).byteValue();
        b = (int)(rtpPacket.getSsrc() & 0xff);
        packet[11] = new Integer(b).byteValue();
        for (int i = 0; i < rtpPacket.getCsrcCount(); ++i) {
            b = (int)(rtpPacket.getCsrcList()[i] >> 24);
            packet[12 + i * 4] = new Integer(b).byteValue();
            b = (int)(rtpPacket.getCsrcList()[i] >> 16);
            packet[12 + i * 4 + 1] = new Integer(b).byteValue();
            b = (int)(rtpPacket.getCsrcList()[i] >> 8);
            packet[12 + i * 4 + 2] = new Integer(b).byteValue();
            b = (int)(rtpPacket.getCsrcList()[i] & 0xff);
            packet[12 + i * 4 + 3] = new Integer(b).byteValue();
        }
        System.arraycopy(data, 0, packet, 12 + rtpPacket.getCsrcCount() * 4,
                data.length);
        return packet;
    }

}
```

