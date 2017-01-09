#### 1. *打印到终端的日志乱码*

程序默认会自动检测终端的编码，如果你发现乱码，可能是自动检测失败，这种情况下你可以尝试手动设置下输出编码

    $client = Mojo::Webqq->new(log_encoding=>"utf8");
    
#### 2. *如何运行多个QQ账号*

使用[Controller-API](Controller-API.md)轻松实现多账号管理

如果你只是希望简单的跑起来一两个帐号，并不想或者不会使用API，可以参考如下方法：

多账号登录主要的问题是需要把每个账号的cookie等数据保存到单独的路径，避免互相影响

在客户端初始化时提供了一个account的参数用于为每个登陆的客户端设置单独的标识，这个参数并不是真正的QQ账号，可以自由定义

每个账号的代码保存到不同的pl文件中,并设置好account参数
    
##### acb.pl文件

    use Mojo::Webqq;
    my $client = Mojo::Webqq->new(account=>"abc"); 
    $client->load("ShowMsg");
    $client->run();
    
##### def.pl文件

    use Mojo::Webqq;
    my $client = Mojo::Webqq->new(account=>"def"); 
    $client->load("ShowMsg");
    $client->run();
    
单独运行abc.pl和def.pl即可

或者不想搞很多个pl文件，可以只使用一份代码，然后运行时通过环境变量`MOJO_WEBQQ_ACCOUNT`来传递account

    use Mojo::Webqq;
    my $client = Mojo::Webqq->new(); #这里不设置account参数，而是从环境变量获取
    $client->load("ShowMsg");
    $client->run();

#### 3. *如何使用github上最新的代码进行测试*

github上的代码迭代比较频繁，定期打包发布一个稳定版本上传到cpan(Perl官方库)

通过`cpanm Mojo::Webqq`在线下载或更新的都是来自cpan的稳定版本，如果你迫不及待的想要尝试github上的最新代码，

可以手动从github下载最新源码，然后在你的 `xxxx.pl` 文件的开头

通过 `use lib 'github源码解压路径/lib/'` 来指定你要使用该路径下的`Mojo::Webqq`模块

而不是之前通过cpanm安装到系统其他路径上的`Mojo::Webqq`模块，操作步骤演示：

a. 下载最新源码的zip文件 https://github.com/sjdy521/Mojo-Webqq/archive/master.zip

b. 解压master.zip到指定路径，比如Windows C盘根目录 c:/

c. 在你的perl程序开头加上 `use lib 'c:/Mojo-Webqq-master/lib';`

d. 正常执行你的程序即可

```
#!/usr/bin/env perl
use lib 'c:/Mojo-Webqq-master/lib'; #指定加载模块时优先加载的路径
use Mojo::Webqq;
my ($host,$port,$post_api);

$host = "0.0.0.0"; #发送消息接口监听地址，没有特殊需要请不要修改
$port = 5000;      #发送消息接口监听端口，修改为自己希望监听的端口
#$post_api = 'http://xxxx';  #接收到的消息上报接口，如果不需要接收消息上报，可以删除或注释此行

my $client = Mojo::Webqq->new(log_level=>"info",http_debug=>0);
$client->load("ShowMsg");
$client->load("Openqq",data=>{listen=>[{host=>$host,port=>$port}], post_api=>$post_api});
$client->run();
```
#### 4. 日志中为什么会打印很多 “504 Gateway Time-out”

你可能会在日志中看到很多类似如下的日志

`[17/01/09 16:55:45] [warn] http://d1.web2.qq.com/channel/poll2 请求失败: 504 Gateway Time-out`

这个主要是腾讯官方接口本身的问题，即便使用网页浏览器访问w.qq.com，也会碰到这种情况

好在目前看这种错误并不会影响到消息接收，可以无视

#### 5. 扫码后可以保持多长时间在线

受限于腾讯官方服务端的限制，目前扫码成功登陆后只能保持1~2天在线，登录状态失效后会强制重新扫码登录

`Openqq`插件会上报`input_qrcode`事件

也可以通过`PostQRcode`插件把登录二维码发送到指定邮箱实现手机随时随地扫码，除此之外，也没有更好的办法避免掉线

#### 6. 发送消息为什么会出现“无法判断是否发送成功”

腾讯的SmartQQ服务非常不稳定，另外，基于Web的方式发送消息，对消息内容会进行很多限制

比如不能够重复发送大量相似内容，不能够包含敏感词汇等

发送消息过程中经常会碰到完全发不出去或者腾讯服务端提示发送失败（返回1202状态码）却对方又收到消息

总之，腾讯的脾气摸不清楚，这种情况下，真的是无法判断是否发送成功

只能给出“无法判断是否发送成功”的标识，这种消息发送结果在程序内容默认会认为也算发送成功，因此不会再次重试

你可以通过设置 `Mojo::Webqq->new(ignore_1202=>0)` 的方式，不忽略1202的状态码，认为这种发送结果也是失败的

客户端会自动尝试5次，但可能也会导致对方收到很多重复的消息

#### 7. PHP如何获取达到Openqq插件上报的json数据

由于上报的json数据属于 application/json类型，而非application/x-www-form-urlencoded类型

因此使用常规的`$_POST`的方式是行不通的（`$_POST` 只适合获取形式为 a=1&b=2&c=3 的数据形式）

需要使用`$GLOBALS['HTTP_RAW_POST_DATA']`来直接获取http请求body中携带的原始json数据

或者使用 `$http_request_body = file_get_contents('php://input');`

再通过 php提供的`json_decode` 函数将原始json字符串转换为php对应的数据结构

php相关文档说明：

http://us3.php.net/manual/en/function.json-decode.php

http://us3.php.net/manual/en/reserved.variables.httprawpostdata.php
