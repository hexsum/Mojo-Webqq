###如何在终端上使用IRC玩转QQ

项目自带一个`IRCShell的插件`，只需要在代码中加载该插件就能够轻松的实现在终端上利用IRC来聊QQ

实现原理：

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

###操作步骤

1.先安装 IRC 依赖模块

```$ cpanm -v Mojo::IRC::Server::Chinese```

2.代码中指定加载IRCShell插件，代码如下：

```
#!/usr/bin/env perl
use Mojo::Webqq;
my $client = Mojo::Webqq->new();
$client->load("ShowMsg");
$client->load("IRCShell"); #加载IRCShell插件
$client->run();
```
3.将上述代码保存成 `xxxx.pl` 文件（必须UTF8编码），使用perl解释器运行

```perl xxxx.pl```  #执行的结果是完成QQ的登录、同时本机启动一个监听6667端口的IRC Server

4.使用任意支持IRC协议的客户端连接127.0.0.1:6667的IRC Server即可开始聊天

常见的irc客户端有weechat、irssi等，这里以irssi为例

```
#建立服务端
irssi -c 127.0.0.1 -p 6667

IRC客户端常用操作命令

/nick 你的QQ昵称          #设置irc的昵称，建议和自己的QQ昵称相同
/user 123456(你的QQ号码)  #/user指令不是必须的，设置user为自己的QQ号是为了方便irc server区分主人
/list                     #列出自己加入的QQ群
/join #我的QQ群名称       #加入指定的某个QQ群
/part                     #退出该QQ群
```
更多irc的使用方就不一一列举了，自行百度即可

5.更多插件自定义参数，参见[IRCShell插件文档](https://metacpan.org/pod/distribution/Mojo-Webqq/doc/Webqq.pod#Mojo::Webqq::Plugin::IRCShell)
