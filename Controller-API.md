### QQ多账号管理API

* 支持多账号客户端的管理（启动、停止、状态查询）
* 兼容全部的[单帐号API](API.md)，仅在原有的单帐号API地址中增加 `client=xxx` 参数来识别不同帐号客户端

### API列表汇总

|API地址                                                   |API说明          |
|:---------------------------------------------------------|:----------------|
|[/openqq/start_client](Controller-API.md#启动一个qq客户端)|启动一个QQ客户端 |
|[/openqq/stop_client](Controller-API.md#停止一个qq客户端) |停止一个QQ客户端 |
|[/openqq/check_client](Controller-API.md#查询qq客户端状态)|查询QQ客户端状态 |
|[/openqq/get_qrcode](Controller-API.md#获取登录二维码文件)  |获取登录二维码文件 |
|[兼容其他QQ单帐号API](Controller-API.md#兼容其他qq单帐号api) |兼容其他QQ单帐号API |

### 首先要启动一个Controller API Server：

可以直接把如下代码保存成一个源码文件(必须使用UTF8编码)，使用 perl 解释器来运行

```
    #!/usr/bin/env perl
    use Mojo::Webqq::Controller;
    my ($host,$port,$post_api,$poll_api);

    $host = "0.0.0.0"; #Controller API server 监听地址，没有有特殊需要请不要修改
    $port = 4000;      #Controller API server 监听端口，修改为自己希望监听的端口
    #$post_api = 'http://xxxx';  #每个QQ帐号接收到的消息上报接口，如果不需要接收消息上报，可以删除或注释此行
    #$poll_api = 'http://xxxx';  #可选，参见单帐号API文档中关于内网穿透的说明，不需要可以删除或注释此行

    my $controller = Mojo::Webqq::Controller->new(
        listen              =>[{host=>$host,port=>$port} ], #监听的地址端口
        backend_start_port  =>5000, #可选，后端QQ帐号分配的端口最小值
        post_api            => $post_api, #每个QQ帐号上报的api地址
        poll_api            => $poll_api, #可选，Controller心跳请求的api地址
        poll_interval       => 5, #可选，Controller自身心跳请求时间间隔，不是Controller下面管理的客户端
    #   tmpdir              => '/tmp', #可选，临时目录位置
    #   pid_path            => '/tmp/mojo_webqq_controller_process.pid', #可选，Controller进程的pid信息，默认tmpdir目录
    #   backend_path        => '/tmp/mojo_webqq_controller_backend.dat', #可选，后端QQ帐号信息，默认tmpdir目录
    #   check_interval      => 5, #可选，检查后端QQ帐号状态的时间间隔
    #   log_level           => 'debug',#可选,debug|info|msg|warn|error|fatal
    #   log_path            => '/tmp/mojo_webqq_controller.log', #可选，运行日志路径，默认输出到终端
    #   log_encoding        => 'utf8', #可选，打印到终端的编码，默认自动识别
    #   template_path       => '/tmp/mojo_webqq_controller_template.pl', #创建客户端时采用的模版文件,文件不存在会自动生成
    );
    $controller->run();
```

上述代码保存成 xxxx.pl 文件，然后使用 perl 来运行，就会完成 QQ 登录并在本机产生一个监听指定地址端口的 http server

    $ perl xxxx.pl


### 架构设计

采用多进程模型，主进程（wqcontroller）监听端口4000端口，对外提供统一的api请求服务，每个QQ帐号是一个独立的子进程，分配一个单独的端口和主进程通信

linux中使用`ps ef`命令可以方便的查看到进程的运行情况

```
\_ wqcontroller #监听4000端口，提供统一的api服务               
	\_ wqclient(webqq_client_01) #子进程监听5000端口
	\_ wqclient(webqq_client_02) #子进程监听5001端口
	\_ wqclient(webqq_client_03) #子进程监听5002端口
	\_ wqclient(webqq_client_04) #子进程监听5003端口
```

### 数据文件介绍

wqcontroller和每个创建的QQ客户端（wqclient）在运行过程中会产生很多的文件，这些文件默认情况下会保存在系统的临时目录下

你可以通过wqcontroller的 `tmpdir` 参数来修改这个临时目录的位置，参考[首先要启动一个Controller API Server](Controller-API.md##首先要启动一个controller-api-server)中的代码示例

一般情况下你不不需要关心这些文件保存在哪里，有什么作用，这些文件也会在程序退出的时候自动进行清理

```
wqcontroller :

    mojo_webqq_controller_process.pid  #wqcontroller的进程耗
    mojo_webqq_controller_backend.dat  #wqcontroller创建的客户端信息
    mojo_webqq_controller_template.pl  #wqcontroller创建客户端时采用的模版文件
    
wqclient:

    mojo_webqq_cookie_{客户端名称}.dat #客户端的cookie文件，用于短时间内重复登录免扫码
    mojo_webqq_pid_{客户端名称}.pid    #记录客户端进程号，防止相同QQ帐号产生多个客户端实例
    mojo_webqq_qrcode_{客户端名称}.jpg #客户端登录二维码文件
    mojo_webqq_state_{客户端名称}.json #客户端的运行状态相关的信息，json格式，实时更新
    
```

关于创建客户端时采用的模版文件，这里要做一下特别说明：

在创建客户端时，wqcontroller会使用临时目录中的`mojo_webqq_controller_template.pl`来启动一个QQ客户端进程，你可以通过

`Mojo::Webqq::Controller->new` 中的 `template_path` 参数来自定义模版文件的路径，也可以修改模版文件，来自定义产生的QQ客户端默认配置

比如，修改默认加载哪些插件等行为，模版文件的默认形式参考如下：

注意：模版文件有一些特殊的书写方式（主要是设置了很多参数从环境变量读取，因为wqcontroller是通过环境变量把启动参数传递给客户端的模版文件）

```
use Mojo::Webqq;
my $client = Mojo::Webqq->new(log_head=>"[$ENV{MOJO_WEBQQ_ACCOUNT}][$$]");
$0 = "wqclient(" . $client->account . ")" if $^O ne "MSWin32";
$SIG{INT} = 'IGNORE' if ($^O ne 'MSWin32' and !-t);
$client->load(["ShowMsg","UploadQRcode"]);
$client->load("Openqq",data=>{listen=>[{host=>"127.0.0.1",port=>$ENV{MOJO_WEBQQ_PLUGIN_OPENQQ_PORT} }], post_api=>$ENV{MOJO_WEBQQ_PLUGIN_OPENQQ_POST_API} || undef,post_event=>$ENV{MOJO_WEBQQ_PLUGIN_OPENQQ_POST_EVENT} // 1,post_media_data=> $ENV{MOJO_WEBQQ_PLUGIN_OPENQQ_POST_MEDIA_DATA} // 1, poll_api=>$ENV{MOJO_WEBQQ_PLUGIN_OPENQQ_POLL_API} || undef, poll_interval => $ENV{MOJO_WEBQQ_PLUGIN_OPENQQ_POLL_INTERVAL} },call_on_load=>1);
$client->run();
```

### 客户端运行状态介绍

客户端运行过程中会在多种状态之间切换，有很多状态是阻塞的，相当于一个死循环，需要达到一定条件才能跳出死循环

大多数的API都是工作中非阻塞模式下，因此在这些阻塞的过程中大部分API（发送消息/接收消息等）都是无法工作的

比如： 在登录扫描的状态下，还没有完成登录，是无法调用API去发送消息

了解客户端这些状态的差异，有助于帮助你合理正确的调用API


|   状态  |模式    |状态说明
|------------|------------|:-------------------------------------------------|
|init        | -          |客户端创建后的初始状态                              |
|loading     |blocking    |客户端加载插件                                     |
|scaning     |blocking    |等待手机扫码                                       |
|confirming  |blocking    |等待手机点击[登录]按钮                              |
|updating    |blocking    |更新个人、好友、群组信息                            |
|running     |non-blocking|客户端运行中，可以正常接收、发送消息，**相关API可以工作**  |
|stop        |blocking    |客户端停止运行                                     |

客户端状态的一般迁移过程：

`init` => `loading` => `scaning` => `confirming` => `updating` => `running` => `stop`

客户端状态实时更新到 `mojo_webqq_state_{客户端名称}.json` 文件中，可以通过检测这个文件来获取上述相关状态的变化

也可以通过 `/openqq/check_client` 接口查询到这个状态

（`/openqq/check_client`接口实际上就是返回  `mojo_webqq_state_{客户端名称}.json` 文件中的数据 ）


### 启动一个QQ客户端 

|   API  |启动一个QQ客户端
|--------|:------------------------------------------|
|uri     |/openqq/start_client|
|请求方法|GET|
|请求参数|**client**: 自定义QQ帐号，用于唯一区分不同QQ帐号客户端<br>其他Mojo-Webqq new方法支持的参数，比如log_level/log_encoding/tmpdir等等，详见 [Mojo::Weixin#new](https://metacpan.org/pod/distribution/Mojo-Weixin/doc/Weixin.pod#new)|
|调用示例|http://127.0.0.1:4000/openqq/start_client?client=webqq_client_01<br>http://127.0.0.1:4000/openqq/start_client?client=webqq_client_01&log_level=debug|

返回JSON数据:
```
{"client":"webqq_client_01","code":0,"pid":32294,"port":5000,"status":"success"}
```

### 停止一个QQ客户端 

|   API  |停止一个QQ客户端
|--------|:------------------------------------------|
|uri     |/openqq/stop_client|
|请求方法|GET|
|请求参数|**client**: 自定义QQ帐号，用于唯一区分不同QQ帐号客户端|
|调用示例|http://127.0.0.1:4000/openqq/stop_client?client=webqq_client_01|

返回JSON数据:
```
{"client":"webqq_client_01","code":0,"pid":32294,"port":5000,"status":"success"}
```
### 获取登录二维码文件

|   API  |查询所有QQ客户端列表
|--------|:------------------------------------------|
|uri     |/openqq/get_qrcode|
|请求方法|GET|
|请求参数|**client**: 指定查询的客户端，否则输出全部客户端|
|调用示例|http://127.0.0.1:4000/openqq/get_qrcode?client=xxx|

```
> GET /openqq/get_qrcode?client=xxx HTTP/1.1
> User-Agent: curl/7.29.0
> Host: 127.0.0.1:2000
> Accept: */*
> 
< HTTP/1.1 200 OK
< Content-Type: image/jpg
< Cache-Control: no-cache
< Date: Mon, 24 Oct 2016 02:11:31 GMT
< Content-Length: 37821
< Server: Mojolicious (Perl)

[qrcode binary data]
```

### 查询QQ客户端状态

|   API  |查询某个或者所有QQ客户端列表
|--------|:------------------------------------------|
|uri     |/openqq/check_client|
|请求方法|GET|
|请求参数|**client**: 可选，指定查询的客户端，否则输出全部客户端|
|调用示例|http://127.0.0.1:4000/openqq/check_client<br>http://127.0.0.1:4000/openqq/check_client?client=xxx|

返回JSON数据:
```
{
    "code":0,
    "client":[
        {#第一个客户端
            "account":"123", #客户端帐号
            "state":"scaning", #客户端状态 init|loading|scaning|confirming|updating|running|stop
            "tmpdir":"\/tmp",
            "cookie_path":"/tmp/mojo_weixin_cookie_123.dat",
            "pid_path":"/tmp/mojo_weixin_pid_123.pid",
            "qrcode_path":"/tmp/mojo_weixin_qrcode_123.jpg",
            "state_path":"/tmp/mojo_weixin_state_123.json",
            "http_debug":"0",
            "log_encoding":null,
            "log_level":"info",
            "log_path":null,
            "os":"linux",
            "pid":2380,
            "plugin":[
                {
                    "auto_call":null,
                    "call_on_load":1,
                    "name":"Mojo::Webqq::Plugin::Openqq",
                    "priority":98
                },
                {
                    "auto_call":1,
                    "call_on_load":0,
                    "name":"Mojo::Webqq::Plugin::ShowMsg",
                    "priority":100
                }
            ],
            "port":5000,
            "start_time":"1477273654",
            "version":"1.2.2"
        }
    ]
}

```
### 兼容其他QQ单帐号API

查询某个QQ帐号的信息、发送消息、消息上报等和[单帐号模式API](API.md)相同，只是url中增加了一个 `client=xxx`的参数用于区分不同客户端，比如

####查询某个QQ帐号用户信息:

http://127.0.0.1:4000/openqq/get_user_info?client=webqq_client_01

####使用某个QQ帐号发送好友消息： 

http://127.0.0.1:4000/openqq/send_friend_message?client=webqq_client_01&id=xxxx&content=hello

每个QQ帐号会独立上报消息，比如设置了上报消息post_api地址为 http://127.0.0.1/post_message

则每个帐号上报时会**自动带上client参数**用于区分不同客户端

POST http://127.0.0.1/post_message?client=webqq_client_01

POST http://127.0.0.1/post_message?client=webqq_client_02
