Mojo-Webqq v1.7.6 [![Build Status](https://travis-ci.org/sjdy521/Mojo-Webqq.svg?branch=master)](https://travis-ci.org/sjdy521/Mojo-Webqq)
========================
使用Perl语言编写的Smartqq客户端框架，基于Mojolicious，要求Perl版本5.14+，可通过插件提供基于HTTP协议的api接口供其他语言或系统调用

###郑重声明

本项目完全遵循网页QQ官方提供的原始聊天功能，不包含任何破解、偷盗等行为，本项目完全开源，目的是为了促进技术交流学习，禁止任何商业盈利目的以及一切非法用途传播，否则后果自负

###插件列表
``` 
  名称                 优先级   当前状态    github作者    功能说明
  ------------------------------------------------------------------------------
  ShowMsg              100      已发布      sjdy521       打印客户端接收和发送的消息
  GroupManage          100      已发布      sjdy521       群管理，入群欢迎、限制发图频率等
  MsgSync              99       已发布      sjdy521       实现qq群和irc消息同步
  IRCShell             99       已发布      sjdy521       Linux环境下通过irc客户端使用qq
  Openqq               98       已发布      sjdy521       提供qq发送消息api接口
  Perlcode             97       已发布      sjdy521       通过qq消息执行perl代码
  Perldoc              96       已发布      sjdy521       通过qq消息查询perl文档
  StockInfo            95       已发布      shalk         查询股票信息
  ProgramCode          94       已发布      limengyu1990  通过qq消息执行代码，支持26种语言
  Translation          93       已发布      sjdy521       多国语言翻译功能
  MobileInfo           93       已发布      limengyu1990  手机号码归属地查询
  Riddle               92       已发布      limengyu1990  输入"猜谜"关键字进行猜谜游戏
  GasPrice             91       已发布      hyvinlam      输入"油价"关键字查询油价
  KnowledgeBase        2        已发布      sjdy521       通过qq消息自定义问答知识库
  FuckDaShen           1        已发布      sjdy521       对消息中的"大神"关键词进行鄙视
  PostImgVerifycode    0        已发布      sjdy521       登录验证码发送到邮箱实现远程登录
  PostQRcode           0        已发布      sjdy521       登录二维码发送到邮箱实现远程扫码
  ShowQRcode           0        已发布      autodataming  调用系统图片查看程序来示二维码（仅支持win）
  SmartReply           0        已发布      sjdy521       智能聊天回复
```
###效果展示
```
[15/09/30 15:11:59] [info] 初始化 smartqq 客户端参数...
[15/09/30 15:11:59] [info] 检查验证码...
[15/09/30 15:11:59] [info] 检查结果: 很幸运，本次登录不需要验证码
[15/09/30 15:11:59] [info] 正在获取登录二维码...
[15/09/30 15:11:59] [info] 二维码已下载到本地[ /tmp/mojo_webqq_qrcode_xxx.png ]
[15/09/30 15:12:00] [info] 登录二维码已经发送到邮箱: ******
[15/09/30 15:12:00] [info] 等待手机QQ扫描二维码...
[15/09/30 15:12:43] [info] 手机QQ扫码成功，请在手机上点击[允许登录smartQQ]按钮...
[15/09/30 15:12:46] [info] 检查安全代码...
[15/09/30 15:12:47] [info] 设置登录验证参数...
[15/09/30 15:12:47] [info] 尝试进行登录(2)...
[15/09/30 15:12:47] [info] 登录成功
[15/09/30 15:12:47] [info] 更新个人信息...
[15/09/30 15:12:47] [info] 更新好友信息...
[15/09/30 15:12:47] [info] 更新[ PERL学习交流 ]信息
[15/09/30 15:12:52] [info] 更新[ Mojolicious ]信息
[15/09/30 15:12:55] [info] 开始接收消息...
[15/09/30 14:09:20] [群消息] 小灰|PERL学习交流 : Mojo::Webqq不错哦
[15/09/30 14:10:20] [群消息] 我->PERL学习交流 : 多谢多谢
```
###通过irc客户端在linux终端上使用QQ

```

    +-------------------+                      +----------------+  
    |  Tencent          |                      | Any IRC Client |
    |  SmartQQ Server   |                      | wechat、irssi  |
    +---v-------------^-+                      +-v------------^-+     
        |             |                          |            |
        | QQ协议交互  |                          |IRC协议交互 |
+-- --- |--  - -  --  | - - -   --   -  -   ---  | ---  ----- | --+
|   +---v-------------^--+                  +----v------------^-+ |   
|   |                    <——————————————————<                   | |
|   |   SmartQQ Client   |     QQ - IRC     |  IRC Server       | |
|   |                    |     协议转换     |  监听本机6667端口 | |
|   |                    >——————————————————>                   | | 
|   +--------------------+                  +-------------------+ |
|                                                                 |
|                                       我们程序实现的部分        | 
+---  - - - -  -- - --  ----  ------  -------  ------  ---    ----+

```

![IRCShell](screenshot/IRCShell.png)

###安装方法

推荐使用[cpanm](https://metacpan.org/pod/distribution/App-cpanminus/bin/cpanm)在线安装或升级[Mojo::Webqq](https://metacpan.org/pod/distribution/Mojo-Webqq/doc/Webqq.pod)模块 

1. *安装perl*
  
    安装之前请先确认下你的系统是否已经安装了Perl，因为除了windows，其他大部分的平台默认都可能已经预装过

    [Perl官网下载页面](https://www.perl.org/get.html) 有包含Unix/Linux、Mac OS X、Windows多平台比较全面详细的安装说明

    建议大家尽量选择**Binaries**（二进制预编译）的版本，安装即可使用，比较方便

  |平台   |推荐选择|下载地址
  |-------|--------|-------------|
  |Windows|1. **StrawberryPerl**<br>2. ActivePerl<br>|[StrawberryPerl下载地址](http://strawberryperl.com/)<br>[ActivePerl下载地址](http://www.activestate.com/activeperl/downloads)|
  |Linux  |1. **ActivePerl**<br>2. 官方源码<br>3. yum/apt等包管理器<br>4. Mojo-ActivePerl|[ActivePerl下载地址](http://www.activestate.com/activeperl/downloads)<br>[Mojo-ActivePerl下载地址](https://github.com/sjdy521/Mojo-ActivePerl)|
  |Mac    |1. **ActivePerl**|[ActivePerl下载地址](http://www.activestate.com/activeperl/downloads)
  
    注意：[Mojo-ActivePerl](https://github.com/sjdy521/Mojo-ActivePerl)是我基于ActivePerl打包的而成
  
    已经包含perl-5.22+cpanm+Mojo-Webqq+Mojo-Weixin的完整运行环境，适用于linux x86_64系统，并且系统glibc 2.15+

2. *安装cpanm包管理工具*（如果系统已经安装了cpanm可以忽略此步骤）

    方法a： 通过cpan安装cpanm

        $ cpan -i App::cpanminus
    
    方法b： 直接在线安装cpanm

        $ curl -kL http://cpanmin.us | perl - App::cpanminus

3. *使用cpanm在线安装 Mojo::Webqq 模块*（如果系统已经安装了该模块，执行此步骤会对模块进行升级）

        $ cpanm -v Mojo::Webqq

4. *安装失败可能有帮助的解决方法*
        
    如果你运气不佳，通过cpanm没有一次性安装成功，这里提供了一些可能有用的信息

    在安装 Mojo::Webqq 的过程中，cpan或者cpanm会帮助我们自动安装很多其他的依赖模块
    
    在众多的依赖模块中，安装经常容易出现问题的主要是 IO::Socket::SSL
    
    IO::Socket::SSL 主要提供了 https 支持，在安装过程中可能会涉及到SSL相关库的编译

    对于 Linux 用户，通常采用的是编译安装的方式，系统缺少编译安装必要的环境，则会导致编译失败
    
    对于 Windows 用户，由于不具备良好的编译安装环境，推荐采用一些已经打包比较全面的Perl运行环境
    
    例如比较流行的 strawberryperl 或者 activeperl 的最新版本都默认包含 Mojo::Webqq 的核心依赖模块

    RedHat/Centos:

        $ yum install -y openssl-devel
        
    Ubuntu:

        $ sudo apt-get install libssl-dev
    
    搞定了编译和运行环境之后，再重新回到 步骤2 安装Mojo::Webqq即可
        

###如何使用

1. *我对Perl很熟悉，是一个专业的Perler*

    该项目是一个纯粹的Perl模块，已经发布到了cpan上，请仔细阅读 `Mojo::Weqq` 模块的[使用文档](https://metacpan.org/pod/distribution/Mojo-Webqq/doc/Webqq.pod)

    除此之外，你可以看下 [demo](https://github.com/sjdy521/Mojo-Webqq/tree/master/demo) 目录下的更多代码示例

2. *我是对Perl不熟悉，是一个其他语言的开发者，只对提供的消息发送/接收接口感兴趣*

    可以直接把如下代码保存成一个源码文件（必须是UTF-8编码），使用 perl 解释器来运行
    
        #!/usr/bin/env perl
        use Mojo::Webqq;
        my ($qq,$host,$port,$post_api);
        
        $qq = 12345678;    #修改为你自己的实际QQ号码
        $host = "0.0.0.0"; #发送消息接口监听地址，修改为自己希望监听的地址
        $port = 5000;      #发送消息接口监听端口，修改为自己希望监听的端口
        #$post_api = 'http://xxxx';  #接收到的消息上报接口，如果不需要接收消息上报，可以删除或注释此行
        
        my $client = Mojo::Webqq->new(qq=>$qq);
        $client->login();
        $client->load("ShowMsg");
        $client->load("Openqq",data=>{listen=>[{host=>$host,port=>$port}], post_api=>$post_api});
        $client->run();
    
    上述代码保存成 xxxx.pl 文件，然后使用 perl 来运行，就会完成 QQ 登录并在本机产生一个监听指定地址端口的 http server
    
        $ perl xxxx.pl
    
    发送好友消息的接口调用示例
    
        http://127.0.0.1:5000/openqq/send_message?qq=xxxxx&content=hello
        
        * About to connect() to 127.0.0.1 port 5000 (#0)
        *   Trying 127.0.0.1...
        * Connected to 127.0.0.1 (127.0.0.1) port 5000 (#0)
        > GET /openqq/send_message?qq=>xxxxx&content=hello HTTP/1.1
        > User-Agent: curl/7.29.0
        > Host: 127.0.0.1:5000
        > Accept: */*
        > 
        < HTTP/1.1 200 OK
        < Content-Type: application/json;charset=UTF-8
        < Date: Sun, 13 Dec 2015 04:54:38 GMT
        < Content-Length: 52
        < Server: Mojolicious (Perl)
        <
        * Connection #0 to host 127.0.0.1 left intact
        
        {"status":"发送成功","msg_id":23910327,"code":0}
    
    更多接口参数说明参加[Openqq插件使用文档](https://metacpan.org/pod/distribution/Mojo-Webqq/doc/Webqq.pod#Mojo::Webqq::Plugin::Openqq)
    
3.  *我是一个极客，我只想能够在命令行上通过  IRC 的方式来玩转 QQ 聊天*

    请阅读[IRCShell插件使用步骤](IRC.md)

4. *我是一个 QQ 群主或管理员，我想给自己的群加个机器人群管理功能*

    请关注 [GroupManage 插件使用文档](https://metacpan.org/pod/distribution/Mojo-Webqq/doc/Webqq.pod#Mojo::Webqq::Plugin::GroupManage)   


###核心依赖模块

* [Mojolicious](https://metacpan.org/pod/Mojolicious)
* [Encode::Locale](https://metacpan.org/pod/Encode::Locale)

###相关文档

* [更新日志](https://github.com/sjdy521/Mojo-Webqq/blob/master/Changes)
* [开发文档](https://metacpan.org/pod/distribution/Mojo-Webqq/doc/Webqq.pod)

###官方交流

* [QQ群](http://jq.qq.com/?_wv=1027&k=kjVJzo)
* [IRC](http://irc.perfi.wang/?channel=#Mojo-Webqq)

###COPYRIGHT 和 LICENCE

Copyright (C) 2014 by sjdy521

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.1 or,
at your option, any later version of Perl 5 you may have available.

