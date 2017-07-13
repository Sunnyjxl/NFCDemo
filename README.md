# CoreNFC

---

 - 关于NFC
 - CoreNFC
 - 集成
 - 示例代码

## 关于NFC

NFC 为 Near Field Communication（近程通信）的缩写。
功能就是字面意思，近距离无线通讯。

下图为WWDC2017中的图文解释：
![Near Field Communication(NFC).jpeg-103.8kB][1]

不懂各个标签类型什么意思？请[阅读此文](http://www.jianshu.com/p/9242c886148a)，内有对各种卡片和NFC Tag 类型的介绍与区分，还算详细。

copy了文内相关内容，如下：

![tag type.png-189.6kB][2]

关于NFC的工作原理请[阅读此文](http://blog.csdn.net/eager7/article/details/8525659)来了解。

copy了些文内的段落方便查看，如下:

        关于NFC模式的选择，完全是由上层的应用程序来决定。
        比如说你的NFC手机运行一个读公交卡的应用程序，那么这时候NFC模块或NFC芯片就工作在读卡器模式；
        如果运行一个Google wallet的应用程序，那么NFC芯片就被设置成卡模拟的模式；
        如果运行一个文件传输的应用程序，如File expert，那么你的NFC芯片就会被设置成为点对点通信的模式。
        所以说，NFC的模式选择，完全取决于上层的应用程序，这里我就简单的从NFC协议的角度来分析如何进行模式的设置。

        1. 初始化
        当手机中的NFC模块（芯片）被开启时，会初始化一些参数，这个时候NFC芯片处于一个IDLE的状态，该状态下，NFC芯片不会产生射频场，此时它处于侦听模式下。但是需要注意的是，此时的NFC芯片并不会工作在上述三种模式中的任何一种。

        2. 模式的配置
        当相应的应用程序启动后，NFC芯片会得到相应的模式配置，这里描述几个比较重要的参数：
        （1） 技术：该词是NFC规范中的专有名词，NFC-A/B/F，对应着ISO14443 A/B及Felica
        （2）通信模式：主动通信和被动通信
        （3）工作模式：Poll，Listen
        
        这三个参数的组合对应着不同的模式，
        如（NFC-A，POLL，被动通信）表示，此时NFC工作在一个读卡器模式下（主动模式）；
        如（NFC-A，Listen，被动通信）表示NFC工作在卡模拟的模式（被动模式）；
        如（NFC-F，Poll，主动通信），表示NFC工作在点对点的模式下（双向模式）。
        当然了，可以给NFC芯片配置多个这样的参数组。除了这三个参数外，还有其它的参数，比如RF协议（ISO-DEP/NFC-DEP等），传输速率，所能支持的最大负载长度等，这里就不详细说明了。

        3.发现
        当NFC芯片的模式配置好后，如果NFC芯片被配置为POLL下，那么NFC芯片将会打开射频场，并根据配置模式进行发现过程，来发现周围的NFC设备。在NFC规范中，发现的顺序为NFC-A->NFC-B->NFC-F->私有技术。当周围有多个目标设备或一个目标设备却支持多种RF协议的话，那么NFC芯片将会向上层应用通告目标设备，让上层应用来决定如何选择。如果NFC芯片被配置为LISTEN下，那么NFC芯片就会等待对方设备发来的POLL命令，如SENS_REQ/SENSF_REQ等。

        4.激活
        当目标设备被选中后，将会进行设备/协议的激活，如使用NFC-DEP的传输协议，那么就需要ATR_REQ/RES的流程；

        5.链路激活
        这一步是针对点对点通信的，如果使用LLCP的话，还需要对LLCP链路进行激活。

        当底层链路建立好后，那么NFC设备间就可以进行通信了。

        这里再说明一下，第一步初始化，也有可能不同芯片有不同的实现方式，初始化就会进入某一个模式；第二步配置和第三步发现，实际上在NFC的规范中，被合成了一步。通过一个发现命令，其中包括了模式的参数，就完成了发现过程。


##CoreNFC

使用NFC前需要注意以下几点：

 - 此库仅支持iPhone7 & iPhone7Plus 以后的机型
 - 支持的标签类型1 - 5（支持市面上所有类型）
 - 标签数据格式为NDEF
 - 需要修改证书配置
 - 需要用户同意隐私权限
 - 需要App完全在前台模式
 - 需要开启一个session，与其他session类似，同时只能开启一个，如果有多个，会在列队里等待上一个完成。
 - 每个session最多扫描60s，超时需再次开启新session
 - 配置读取单个或多个Tag，配置为单个时，会在读取到第一个Tag时自动结束session

##集成

 1. 在developer网站选择Certificates, Identifiers & Profiles
 2. 在identifies中选择App IDs，在选择项目对应的ID
 3. 点击Edit，勾选NFC Tag Reading，完成
 4. 这时，此ID对应的Provisioning Profiles就会失效
 5. 点击Provisioning Profiles中的All，选择失效的profiles，编辑使其从新变为Active
 
回到xcode，点选对应TARGETS的Capabilities开启NFC Tag Reading（注意此处，我的XCODE版本为beta3，之前的版本貌似没有这个选项，只能手动添加.entitlements文件的内容）
![Capabilities.jpeg-77.1kB][3]

 然后在INFO里添加NFC的隐私权限
 ![权限配置.jpeg-99kB][4]

##示例代码

首先来看下目录结构
![framework.jpeg-42.1kB][5]

库头文件引用
```
#import <CoreNFC/CoreNFC.h>
```

协议
```
<NFCNDEFReaderSessionDelegate, NFCReaderSessionDelegate>
```

初始化并启用NFC扫描
```
[self.session invalidateSession];
self.session = [[NFCNDEFReaderSession alloc] initWithDelegate:self queue:nil invalidateAfterFirstRead:NO];
if (NFCNDEFReaderSession.readingAvailable) {
    self.session.alertMessage = @"把TAG放到手机背面";
    [self.session beginSession];
} else {
    [self showAlertMsg:@"此设备不支持NFC" title:@""];
}

```

扫描回调结果
```
#pragma mark - NFCReaderSessionDelegate
- (void)readerSessionDidBecomeActive:(NFCReaderSession *)session
{
    NSLog(@"NFC会话已激活");
    if (session.isReady) {
        NSLog(@"NFC已准备好");
    } else {
        [self showAlertMsg:@"NFC还没有准备好" title:@""];
    }
}

- (void)readerSession:(NFCReaderSession *)session
        didDetectTags:(NSArray<__kindof id<NFCTag>> *)tags
{
    NSLog(@"扫描到TAG数据");
}

#pragma mark - NFCNDEFReaderSessionDelegate

- (void)readerSession:(NFCNDEFReaderSession *)session didInvalidateWithError:(NSError *)error
{
    // 读取失败
    NSLog(@"%@",error);
    if (error.code == 201) {
        NSLog(@"扫描超时");
        [self showAlertMsg:error.userInfo[NSLocalizedDescriptionKey] title:@"扫描超时"];
    }
    
    if (error.code == 200) {
        NSLog(@"取消扫描");
        [self showAlertMsg:error.userInfo[NSLocalizedDescriptionKey] title:@"取消扫描"];
    }
}

- (void)readerSession:(NFCNDEFReaderSession *)session didDetectNDEFs:(NSArray<NFCNDEFMessage *> *)messages
{
    // 读取成功
    for (NFCNDEFMessage *msg in messages) {
        
        NSArray *ary = msg.records;
        for (NFCNDEFPayload *rec in ary) {
            
            NFCTypeNameFormat typeName = rec.typeNameFormat;
            NSData *payload = rec.payload;
            NSData *type = rec.type;
            NSData *identifier = rec.identifier;
            
            NSLog(@"TypeName : %d",typeName);
            NSLog(@"Payload : %@",payload);
            NSLog(@"Type : %@",type);
            NSLog(@"Identifier : %@",identifier);
        }
    }
    
    [self.dataAry addObject:messages];
    [self.tableView reloadData];
}
```

我的调试设备是iPhone7Plus + iOS11 beta 3

PS：最后我尝试扫描各种NFC卡片（公交卡、门禁卡、小米手机上的公交卡、塞尔达传说的amiibo）没有一个可以扫出结果的。反观项目，虽然添加了NFC隐私，但启动APP后并没有弹出用户是否同意读取NFC隐私的提示，而且在系统设置的隐私选项里也没有找到NFC的选项，所以我想可能需要等待更新一个beta版吧。
或者你有别的发现，可以issues给我，感激不尽～

  [1]: http://static.zybuluo.com/lucifer001/3sid9e09ooynu3qq0r7bban6/Near%20Field%20Communication%28NFC%29.jpeg
  [2]: http://static.zybuluo.com/lucifer001/adciocq4m9vv1gfjjaljqhc2/tag%20type.png
  [3]: http://static.zybuluo.com/lucifer001/nusk1066d1xru2m1sms4dwzz/Capabilities.jpeg
  [4]: http://static.zybuluo.com/lucifer001/mdbmep4bhmdw5nctwt41wzbu/%E6%9D%83%E9%99%90%E9%85%8D%E7%BD%AE.jpeg
  [5]: http://static.zybuluo.com/lucifer001/wawale4gnrj8gemgxab73ar3/framework.jpeg
