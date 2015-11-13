Mojo-Webqq v1.6.1 [![Build Status](https://travis-ci.org/sjdy521/Mojo-Webqq.svg?branch=master)](https://travis-ci.org/sjdy521/Mojo-Webqq)
========================
使用Perl语言编写的Smartqq客户端框架，基于Mojolicious，要求Perl版本5.10.1+

###插件列表
``` 
  名称                 优先级   当前状态    github作者    功能说明
  ------------------------------------------------------------------------------
  ShowMsg              100      已发布      sjdy521       打印客户端接收和发送的消息
  MsgSync              99       已发布      sjdy521       实现qq群和irc消息同步
  IRCShell             99       已发布      sjdy521       Linux环境下通过irc客户端使用qq
  Openqq               98       已发布      sjdy521       提供qq发送消息api接口
  Perlcode             97       已发布      sjdy521       通过qq消息执行perl代码
  Perldoc              96       已发布      sjdy521       通过qq消息查询perl文档
  StockInfo            95       已发布      shalk         查询股票信息
  ProgrameCode         94       已发布      limengyu1990  通过qq消息执行代码，支持26种语言
  KnowledgeBase        2        已发布      sjdy521       通过qq消息自定义问答知识库
  FuckDaShen           1        已发布      sjdy521       对消息中的"大神"关键词进行鄙视
  PostImgVerifycode    0        已发布      sjdy521       登录验证码发送到邮箱实现远程登录
  PostQRcode           0        已发布      sjdy521       登录二维码发送到邮箱实现远程扫码
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

![IRCShell](screenshot/IRCShell.png)

###安装方法

推荐使用[cpanm](https://metacpan.org/pod/distribution/App-cpanminus/bin/cpanm)在线安装[Mojo::Webqq](https://metacpan.org/pod/distribution/Mojo-Webqq/doc/Webqq.pod)模块 

    $ cpan -i App::cpanminus #安装cpanm工具
    $ cpanm -v Mojo::Webqq   #在线安装Mojo::Webqq模块 

###核心依赖模块

* Mojolicious
* Encode::Locale

###相关文档

* [更新日志](https://github.com/sjdy521/Mojo-Webqq/blob/master/Changes)
* [开发文档](https://github.com/sjdy521/Mojo-Webqq/blob/master/doc/Webqq.pod)

###官方交流

* [QQ群](http://jq.qq.com/?_wv=1027&k=kjVJzo)
* [IRC](http://irc.perfi.wang/?channel=#Mojo-Webqq)

###COPYRIGHT 和 LICENCE

Copyright (C) 2014 by sjdy521

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.1 or,
at your option, any later version of Perl 5 you may have available.
