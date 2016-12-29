### 本文档包含的API是针对单帐号的，如果需要多账号统一管理API，请移步到[Controller-API](Controller-API.md)

### API列表汇总

|API地址                      |可用状态 |API说明        |
|:----------------------------|:-------|:--------------|
|基础信息获取相关           |       |                |
|[/openqq/get_user_info](API.md#获取用户数据)      |running |获取登录用户数据 |
|[/openqq/get_friend_info](API.md#获取好友数据)  |running |获取好友数据 |
|[/openqq/get_group_info](API.md#获取群组数据)       |running |获取群组数据 |
|[/openqq/get_group_basic_info](API.md#获取群组基础数据)          |running |获取群组基础数据(不包含群成员)|
|[/openqq/get_discuss_info](API.md#获取讨论组数据)  | running  | 获取讨论组数据 |
|数据搜索相关                  |        |                |
|[/openwx/search_friend](API.md#搜索好友)        |running |搜索好友对象|
|[/openwx/search_group](API.md#搜索群组)        |running |搜索群组对象|
|群组管理相关                  |        |                |
|[/openqq/shutup_group_member](API.md#群成员禁言)        |running |群成员禁言         |
|[/openqq/kick_group_member](API.md#踢除群成员)        |running |踢除群成员|
|消息发送相关                  |        |                |
|[/openqq/send_friend_message](API.md#发送好友消息)  |running |发送好友消息     |
|[/openqq/send_group_message](API.md#发送群组消息)   |running |发送群组消息     |
|[/openqq/send_discuss_message](API.md#发送讨论组消息) |running |发送讨论组消息  |
|[/openqq/send_sess_message](API.md#发送群临时消息)    |running  |发送群临时消息(已被腾讯屏蔽) | 
|[/openqq/send_sess_message](API.md#发送讨论组临时消息) |running  |发送讨论组临时消息(已被腾讯屏蔽)|
|事件（消息）获取相关 | |         |
|[自定义事件（消息）上报地址](API.md#自定义事件消息上报地址) |scaning<br>updating<br>running| 将产生的事件通过HTTP POST请求发送到指定的地址<br>可用于上报扫描二维码事件、新增好友事件、接收消息事件等 |
|[/openqq/check_event](API.md#查询事件消息) |running| 采用HTTP GET请求长轮询机制获取事件（消息）<br>API只能工作在非阻塞模式下，功能受限<br>不如POST上报的方式获取的信息全面 |
|客户端控制相关                |        |                |
|[/openqq/get_client_info](API.md#获取程序运行信息)      |running |获取程序运行信息|
|[/openqq/stop_client](API.md#终止程序运行)          |running |终止程序运行   |

### 首先启动一个API Server

可以直接把如下代码保存成一个源码文件（必须是UTF-8编码），使用 perl 解释器来运行

    #!/usr/bin/env perl
    use Mojo::Webqq;
    my ($host,$port,$post_api);

    $host = "0.0.0.0"; #发送消息接口监听地址，没有特殊需要请不要修改
    $port = 5000;      #发送消息接口监听端口，修改为自己希望监听的端口
    #$post_api = 'http://xxxx';  #接收到的消息上报接口，如果不需要接收消息上报，可以删除或注释此行

    my $client = Mojo::Webqq->new();
    $client->load("ShowMsg");
    $client->load("Openqq",data=>{listen=>[{host=>$host,port=>$port}], post_api=>$post_api});
    $client->run();

上述代码保存成 xxxx.pl 文件，然后使用 perl 来运行，就会完成 QQ 登录并在本机产生一个监听指定地址端口的 http server

    $ perl xxxx.pl

### 客户端数据文件介绍

微信客户端在运行过程中会产生很多的文件，这些文件默认情况下会保存在系统的临时目录下

你可以通过在启动脚本的 `Mojo::Webqq->new()`中增加 `tmpdir` 参数来修改这个临时目录的位置，例如：

    Mojo::Webqq->new(log_level=>"info",http_debug=>0,tmpdir=>'C:\tmpdir\') #请确保目录已经存在并有访问权限

更多自定义参数参见[Mojo::Webqq->new参数说明](https://metacpan.org/pod/distribution/Mojo-Webqq/doc/Webqq.pod#new)
 ```   
    mojo_webqq_cookie_{客户端名称}.dat #客户端的cookie文件，用于短时间内重复登录免扫码
    mojo_webqq_pid_{客户端名称}.pid    #记录客户端进程号，防止相同微信帐号产生多个重复的客户端实例
    mojo_webqq_qrcode_{客户端名称}.jpg #客户端登录二维码文件
    mojo_webqq_state_{客户端名称}.json #客户端的运行状态相关的信息，json格式，实时更新
```
一般情况下你不需要关心这些文件保存在哪里，有什么作用，这些文件也会在程序退出的时候自动进行清理

### 客户端运行状态介绍

客户端运行过程中会在多种状态之间切换，有很多状态是阻塞的，相当于一个死循环，需要达到一定条件才能跳出死循环

单帐号模式采用的是单进程异步机制，API全部都是工作在非阻塞模式下，因此在阻塞的状态中API（发送消息/接收消息等）都是暂时无法工作的

比如： 在登录扫描的状态下，还没有完成登录，是无法调用API去发送消息，请求会收不到任何响应

了解客户端这些状态的差异，有助于帮助你合理正确的调用API

|   状态      |模式        |状态说明
|------------|------------|:-------------------------------------------------|
|init        | -          |客户端创建后的初始状态                              |
|loading     |blocking    |客户端加载插件                                     |
|scaning     |blocking    |等待手机扫码                                       |
|confirming  |blocking    |等待手机点击[登录]按钮                              |
|updating    |blocking    |更新个人、好友、群组、讨论组等信息                   |
|running     |non-blocking|客户端运行中，可以正常接收、发送消息，**相关API可以工作**  |
|stop        |-           |客户端停止运行                                     |

客户端状态的一般迁移过程：

`init` => `loading` => `scaning` => `confirming` => `updating` => `running` => `stop`

客户端状态实时更新到 `mojo_webqq_state_{客户端名称}.json` 文件中，可以通过读取这个文件来获取上述相关状态的变化

也可以通过客户端 [事件上报](API.md#事件上报) 中的 `state_change` 事件来获取客户端当前所处的状态

多账号模式下也可以通过Controller提供的 `/openqq/check_client` 接口查询到这个状态

（`/openqq/check_client`接口实际上就是返回  `mojo_webqq_state_{客户端名称}.json` 文件中的数据 ）

### 关于心跳请求的说明

可能用于内网穿透、客户端存活检测、客户端信息收集等方面，期待你发掘更多利用价值

设置 `Openqq插件` 中的参数 `poll_api`和`poll_interval`，会使得客户端在处于 `running` 状态时，自发的去请求`poll_api`地址

期望的是，这个请求会长时间阻塞等待，服务端不返回任何数据（服务端逻辑需要你自己去实现）

服务端响应结果或者请求超时断开后，会间隔`poll_interval` 秒后继续重复发起请求，如此往复

如果你的程序是部署在内网环境，而又希望通过外网的服务器去调用内网的api，实现发送消息等功能

当外网的服务端希望内网的客户端程序调用某个api接口时，比如希望内网的客户端调用`/openqq/send_friend_message`接口给指定的好友发消息

服务端通过HTTP协议的302 Location返回需要访问的完整api地址 

    http://127.0.0.1:5000/openqq/send_friend_message?id=xxx&content=xxxx

客户端收到302的响应后会自动请求跳转后的地址（客户端自己请求自己本机127.0.0.1的api地址）实现发送消息

```
> GET /poll_url HTTP/1.1
> User-Agent: curl/7.29.0
> Host: www.example.com
> Accept: */*
> 
< HTTP/1.1 302 Found
< Location: http://127.0.0.1:5000/openqq/send_friend_message?id=xxxx&content=hello
< Date: Tue, 08 Nov 2016 14:00:15 GMT
< Content-Length: 0

```

### 获取用户数据
|   API  |获取用户数据
|--------|:------------------------------------------|
|uri     |/openqq/get_user_info|
|请求方法|GET|
|请求参数|无|
|调用示例|http://127.0.0.1:5000/openqq/get_user_info|

返回数据:

```
{
    "name": "小灰",
    "mobile": "188********",
    "state": "online",
    "client_type": "web",
    "email": "",
    "city": "北京",
    "personal": "这是我的个性签名",
    "province": "北京",
    "id": "1234567",
    "birthday": "1990-01-01",
    "sex": "male",
    "country": "中国",
    "uid": "1234567",
    "account": "1234567",
    "college": "",
    "occupation": "计算机/互联网/IT",
    "phone": "",
    "homepage": "",
    "blood": "3",
    "signature": " ",
}

```

### 获取好友数据
|   API  |获取好友数据
|--------|:------------------------------------------|
|uri     |/openqq/get_friend_info|
|请求方法|GET|
|请求参数|无|
|调用示例|http://127.0.0.1:5000/openqq/get_friend_info|
返回JSON数组:

```
[#好友数组
    {#第一个好友
        "is_vip": "1",
        "uid": "123456",
        "markname": "xxx",
        "flag": "0",
        "name": "测试帐号1",
        "state": "offline",
        "client_type": "unknown",
        "face": "153",
        "vip_level": "6",
        "category": "我的网友",
        "id": "2457053936"
    },
    {
        "is_vip": "0",
        "uid": "7891234",
        "markname": "哈哈",
        "flag": "32",
        "name": "测试帐号2",
        "state": "offline",
        "client_type": "unknown",
        "face": "168",
        "vip_level": "0",
        "category": "我的家人",
        "id": "2475249571"
    },
]
```

### 获取群组数据
|   API  |获取群组数据
|--------|:------------------------------------------|
|uri     |/openqq/get_group_info|
|请求方法|GET|
|请求参数|无|
|调用示例|http://127.0.0.1:5000/openqq/get_group_info|
返回JSON数组:
```
[#数组
    {#第1个群
        "markname": "xxx",
        "id": "",
        "uid": "552603",
        "code": "",
        "name": "",
        "role": "",
        "createtime": "",
        "owner_id": 12345,
        "owner_uid": 123456,
        "max_member": 2000,
        "max_admin": 10,
        "member": [
            {
                "qage": "16",
                "name": "xxx",
                "join_time": "0",
                "state": "offline",
                "client_type": "unknown",
                "city": "大连",
                "province": "辽宁",
                "id": "2832277643",
                "sex": "male",
                "bad_record": "0",
                "country": "中国",
                "uid": "45678",
                "last_speak_time": "1453449884",
                "role": "attend",
            },
            {
                "qage": "16",
                "name": "xxx",
                "join_time": "0",
                "state": "offline",
                "client_type": "unknown",
                "city": "大连",
                "province": "辽宁",
                "id": "2832277643",
                "sex": "male",
                "bad_record": "0",
                "country": "中国",
                "uid": "123455",
                "last_speak_time": "1453449884",
                "role": "owner",
            },
        ]
    },
    {#第2个群
    ...
    }
]
```

### 获取群组基础数据
|   API  |获取群组数据(不包含群成员)
|--------|:------------------------------------------|
|uri     |/openqq/get_group_basic_info|
|请求方法|GET|
|请求参数|无|
|调用示例|http://127.0.0.1:5000/openqq/get_group_basic_info|

### 获取讨论组数据
|   API  |获取讨论组数据
|--------|:------------------------------------------|
|uri     |/openqq/get_discuss_info|
|请求方法|GET|
|请求参数|无|
|调用示例|http://127.0.0.1:5000/openqq/get_discuss_info|
返回JSON数组:

```
[
    {
        "name": "测试",
        "id": "4118239384",
        "owner_id": "4118239384",
        "member": [
            {
                "id": "4118239384",
                "name": "小灰",
                "state": "offline",
                "client_type": "unknown",
                "uid": "123456"
            },
            {
                "did": "4118239384",
                "nick": "哈哈",
                "state": "offline",
                "client_type": "unknown",
                "dname": "测试",
                "id": "456789"
            }
        ],
    }
]

```

### 发送好友消息
|   API  |发送好友消息
|--------|:------------------------------------------|
|uri     |/openqq/send_friend_message|
|请求方法|GET\|POST|
|请求参数|**id**: 好友的id（每次扫描登录可能会变化）<br>**uid**: 好友的QQ号<br>**content**: 发送的消息(中文需要做urlencode)|
|数据格式|application/x-www-form-urlencoded|
|调用示例|http://127.0.0.1:5000/openqq/send_message?id=xxxx&content=hello<br>http://127.0.0.1:5000/openqq/send_message?uid=xxx&content=%e4%bd%a0%e5%a5%bd|

返回JSON数组:
```
{"status":"发送成功","id":23910327,"code":0} #code为 0 表示发送成功
```
### 发送群组消息
|   API  |发送群组消息
|--------|:------------------------------------------|
|url     |/openqq/send_group_message|
|请求方法|GET\|POST|
|请求参数|**id**: 群组的id（每次扫描登录可能会变化）<br>**uid**: 群号码<br>**content**:消息内容(中文需要做urlencode)|
|数据格式|application/x-www-form-urlencoded|
|调用示例|http://127.0.0.1:5000/openqq/send_group_message?id=xxxx&content=hello<br>http://127.0.0.1:5000/openqq/send_group_message?uid=xxx&content=%e4%bd%a0%e5%a5%bd|
返回JSON数组:
```
{"status":"发送成功","id":23910327,"code":0} #code为 0 表示发送成功
```

### 发送讨论组消息
|   API  |发送讨论组消息
|--------|:------------------------------------------|
|uri     |/openqq/send_discuss_message|
|请求方法|GET\|POST|
|请求参数|**id**: 讨论组的id（每次扫描登录可能会变化）<br>**content**:消息内容(中文需要做urlencode)|
|数据格式|application/x-www-form-urlencoded|
|调用示例|http://127.0.0.1:5000/openqq/send_discuss_message?id=xxxx&content=hello<br>http://127.0.0.1:5000/openqq/send_discuss_message?id=xxx&content=%e4%bd%a0%e5%a5%bd|
返回JSON数组:
```
{"status":"发送成功","id":23910327,"code":0} #code为 0 表示发送成功
```

### 发送群临时消息
|   API  |发送群临时消息(已被腾讯屏蔽)
|--------|:------------------------------------------|
|uri     |/openqq/send_sess_message|
|请求方法|GET\|POST|
|请求参数|**group_id**: 群的id（每次扫描登录可能会变化）<br>**group_uid**: 群的号码<br>**id**: 陌生人的id（每次扫描登录可能会变化）<br>**uid**: 陌生人的qq号<br>**content**:消息内容(中文需要做urlencode)|
|数据格式|application/x-www-form-urlencoded|
|调用示例|http://127.0.0.1:5000/openqq/send_sess_message?group_id=xxxx&id=xxx&content=hello<br>http://127.0.0.1:5000/openqq/send_sess_message?group_uid=xxx&uid=xxx&content=%e4%bd%a0%e5%a5%bd|
返回JSON数组:
```
{"status":"发送成功","id":23910327,"code":0} #code为 0 表示发送成功
```

### 发送讨论组临时消息
|   API  |发送讨论组临时消息(已被腾讯屏蔽)
|--------|:------------------------------------------|
|uri     |/openqq/send_sess_message|
|请求方法|GET\|POST|
|请求参数|**discuss_id**: 讨论组的id（每次扫描登录可能会变化）<br>**id**: 陌生人的id（每次扫描登录可能会变化）<br>**uid**: 陌生人的qq号<br>**content**:消息内容(中文需要做urlencode)|
|数据格式|application/x-www-form-urlencoded|
|调用示例|http://127.0.0.1:5000/openqq/send_sess_message?discuss_id=xxxx&id=xxx&content=hello<br>http://127.0.0.1:5000/openqq/send_sess_message?discuss_id=xxx&uid=xxx&content=%e4%bd%a0%e5%a5%bd|
返回JSON数组:
```
{"status":"发送成功","id":23910327,"code":0} #code为 0 表示发送成功
```
### 查询事件消息

| API|采用HTTP GET请求长轮询获取事件（消息）
|----|:------------------|
|uri |/openqq/check_event|
|请求方法|GET|
|数据格式|application/json|

接口返回JSON数组的形式，数组中的每个元素是一个JSON格式消息，格式和 [自定义事件消息上报地址](API.md#自定义事件消息上报地址) 完全一样

程序最大保留最近20条信息记录，可以通过插件参数`check_event_list_max_size`进行自定义

```
$client->load("Openqq",data=>{ 
    check_event_list_max_size=>100,
});
```

采用长轮询机制，没有事件（消息）时，请求会挂起等待30s即断开，需要客户端再次重复发起请求

API只能工作在非阻塞模式下,功能受限，不如POST上报的方式获取的信息全面，目前仅支持获取:

发送消息、接收消息 以及如下一部分事件: 

`new_group`,`new_friend`,`new_group_member`,`lose_group`,`lose_friend`,`lose_group_member`,

```
* Connected to 127.1 (127.0.0.1) port 5000 (#0)
> GET /openqq/check_event? HTTP/1.1
> User-Agent: curl/7.29.0
> Host: 127.1:3000
> Accept: */*
> 
< HTTP/1.1 200 OK
< Content-Type: application/json;charset=UTF-8
< Date: Tue, 22 Nov 2016 04:11:36 GMT
< Content-Length: 16405
< Server: Mojolicious (Perl)

[ 
   {
    "class":"send",
    "content":" hello world",
    "id":"2647366348175870091",
    "post_type":"send_message",
    "receiver":"小灰",
    "receiver_id":"xxxxxx",
    "receiver_uid":12345,
    "sender":"灰灰",
    "time":"1479787946",
    "type":"friend_message"
    }
]
```

没有消息等待超时后，会返回一个空的JSON数组，客户端需要再次发起请求

```
* Connected to 127.1 (127.0.0.1) port 3000 (#0)
> GET /openqq/check_event? HTTP/1.1
> User-Agent: curl/7.29.0
> Host: 127.1:3000
> Accept: */*
> 
< HTTP/1.1 200 OK
< Content-Type: application/json;charset=UTF-8
< Date: Tue, 22 Nov 2016 04:11:36 GMT
< Content-Length: 16405
< Server: Mojolicious (Perl)

[]
```

### 自定义事件消息上报地址
|   API  |自定义事件（消息）上报地址
|--------|:------------------------------------------|
|uri     |自定义任意支持http协议的url|
|请求方法|POST|
|数据格式|application/json|

需要加载Openqq插件时通过 `post_api` 参数来指定上报地址:

```
$client->load("Openqq",data=>{
    listen => [{host=>xxx,port=>xxx}],           #可选，发送消息api监听端口
    post_api=> 'http://127.0.0.1:5000/post_api', #可选，接收消息或事件的上报地址
    post_event => 1,                             #可选，是否上报事件，为了向后兼容性，默认值为1
    post_event_list => ['login','stop','state_change','input_qrcode'], #可选，上报事件列表
});
```

首先要了解消息一些关键属性信息：

上报或拉取的JSON数据的类型中的`post_type`属性用于区分上报的数据是消息类的数据还是其他事件

|关键属性     |取值             |说明                  | 
|:-----------|:----------------|:---------------------|
|post_type   |receive_message<br>send_message<br>event|接收消息<br>发送消息<br>其他事件|

发送接收消息（`post_type`为`receive_message`或`send_message`时)的关键属性信息：

|关键属性     |取值           |说明                           | 
|:-----------|:--------------|:------------------------------|
|id          |-|消息的id
|type        |friend_message<br>group_message<br>discuss_message<br>sess_message|消息类型细分:<br>好友消息<br>群消息<br>讨论组消息<br>临时消息  |
|class       |send<br>recv|表明是发送消息还是接收消息
|sender_id   |-|消息发送者id（注意不是所有的消息类型都存在这个属性）
|sender_uid  |-|消息发送者qq（注意不是所有的消息类型都存在这个属性）
|receiver_id |-|消息接收者id（注意不是所有的消息类型都存在这个属性）
|receiver_uid|-|消息接收者qq（注意不是所有的消息类型都存在这个属性）
|group_id    |-|消息相关的群组id（注意不是所有的消息类型都存在这个属性）
|group_uid   |-|消息相关的群组号码（注意不是所有的消息类型都存在这个属性）

当接收到消息时，会把消息通过JSON格式数据POST到该接口

```
connect to 127.0.0.1 port 5000
POST /post_api
Accept: */*
Content-Length: xxx
Content-Type: application/json

{
    "time":"1442542632",
    "content":"测试一下",
    "class":"recv",
    "sender":"灰灰",
    "sender_id":"2372835507",
    "sender_uid":"456789",
    "receiver":"小灰",
    "receiver_id":"4072574066",
    "receiver_uid":"123456",
    "group":"PERL学习交流",
    "group_id":"2617047292",
    "group_uid":"67890",
    "id":"10856",
    "type":"group_message",
    "post_type":"receive_message"
}

```
一般情况下，post_api接口返回的响应内容可以是随意，会被忽略，上报完不做其他操作
如果post_api接口返回的数据类型是 text/json 或者 application/json，并且json格式形式如下:

```
{
    "reply":"xxxxx",    #要回复消息，必须包含reply的属性
    "shutup": 1,        #可选，是否对消息发送者禁言
    "shutup_time": 60,  #可选，禁言时长，默认60s
}
    
```

则表示希望通过post_api响应的内容来直接回复该消息，post_api的返回结果比如

```
HTTP/1.1 200 OK
Connection: close
Content-Type: application/json;charset=UTF-8
Date: Mon, 29 Feb 2016 05:53:31 GMT
Content-Length: 27
Server: Mojolicious (Perl)

{"reply":"你好","code":0} 
```

则会直接对上报的消息进行回复，回复的内容为 "你好", 支持好友消息、群消息、讨论组消息、临时消息的上报

#### 其他非消息类事件上报

当事件发生时，会把事件相关信息上报到指定的接口，当前支持上报的事件包括：

|  事件名称                    |事件说明    |上报参数列表
|------------------------------|:-----------|:-----------------------------------------|
|login                         |客户端登录  | *1*：表示经过二维码扫描，好友等id可能会发生变化<br>*0*： 表示未经过二维码扫描，好友等id不会发生变化
|stop                          |客户端停止    | 客户端停止运行，程序退出
|state_change                  |客户端状态变化|旧的状态，新的状态 参见 [客户端状态说明](API.md#客户端运行状态介绍）
|input_qrcode                  |扫描二维码  | 二维码本地保存路径，二维码原始数据的base64编码
|new_group                     |新加入群聊  | 对应群对象
|new_friend                    |新增好友    | 对应好友对象
|new_group_member              |新增群聊成员| 对应成员对象，对应的群对象
|lose_group                    |退出群聊    | 对应群对象
|lose_friend                   |删除好友    | 对应好友对象
|lose_group_member             |成员退出群聊| 对应成员对象，对应的群对象
|group_property_change         |群聊属性变化| 群对象，属性，原始值，更新值
|group_member_property_change  |成员属性变化| 成员对象，属性，原始值，更新值
|friend_property_change        |好友属性变化| 好友对象，属性，原始值，更新值
|user_property_change          |帐号属性变化| 账户对象，属性，原始值，更新值

可以在Openqq插件中，通过 `post_event_list` 参数来指定上报的事件

默认 `post_event_list => ['login','stop','state_change','input_qrcode','new_group','new_friend','new_group_member','lose_group','lose_friend','lose_group_member']`

需要注意：属性变化类的事件可能触发的会比较频繁，导致产生大量的上报请求，默认不开启

新增好友事件举例

```
connect to 127.0.0.1 port 3000
POST /post_api
Accept: */*
Content-Length: xxx
Content-Type: application/json

{
    "post_type":"event",
    "event":"new_friend",
    "params":[
        {
            "account":"ms-xiaoice",
            "name":"小灰",
            "markname":"",
            "sex":"0",
            "city":"海淀",
            "province":"北京",
            "displayname":"小冰",
            "id":"@75b9db5ae52c87361d1800eaaf307f4d",
            "uid": 123456
         }
    ],

}

```

扫描二维码事件举例

```
connect to 127.0.0.1 port 3000
POST /post_api
Accept: */*
Content-Length: xxx
Content-Type: application/json

{
    "post_type":"event",
    "event":"input_qrcode",
    "params":[
        {
            "\/tmp\/qrcode.jpg", #二维码本地路径
            "\/9j\/4AAQSkZJRgABAQAAAQABAAD\...UUUUUUUUUUUV\/\/Z\n", #二维码原始数据经过base64默认方式编码
        }
    ],

}

```

**可以通过上报的json数组中的`post_type`来区分上报的数据是消息还是其他事件**


### 搜索好友

|   API  |搜索好友|
|--------|:------------------------------------------|
|uri     |/openqq/search_friend|
|请求方法|GET\|POST|
|请求参数|好友对象的任意属性，中文需要做urlencode，比如：<br>**id**: 好友的id<br>**uid**: 好友的帐号<br>**markname**: 好友备注名称<br>|
|数据格式|application/x-www-form-urlencoded|
|调用示例|http://127.0.0.1:5000/openqq/search_friend?uid=xxxx|


### 搜索群组

|   API  |搜索群组|
|--------|:------------------------------------------|
|uri     |/openqq/search_group|
|请求方法|GET\|POST|
|请求参数|群对象的任意属性，中文需要做urlencode，比如：<br>**id**: 群组的id<br>**uid**: 群组的号码<br>|
|数据格式|application/x-www-form-urlencoded|
|调用示例|http://127.0.0.1:5000/openqq/search_group?uid=xxxxxx|
返回JSON数组:

### 群成员禁言

|   API  |群成员禁言|
|--------|:------------------------------------------|
|uri     |/openqq/shutup_group_member|
|请求方法|GET\|POST|
|请求参数|**time**: 禁言时长，最低60秒（单位：秒）<br>**member_id**: 成员的id（多个成员id用逗号分割）<br>**member_uid**: 成员的qq（多个成员qq用逗号分割）<br>**group_id**: 群组的id<br>**group_uid**: 群组的号码<br>|
|数据格式|application/x-www-form-urlencoded|
|调用示例|http://127.0.0.1:5000/openqq/shutup_group_member?group_uid=xxxxxx&member_uid=xxxx,xxxx<br>http://127.0.0.1:5000/openqq/shutup_group_member?group_id=xxxxxx&member_id=xxxx,xxxx&time=120|

### 踢除群成员

|   API  |踢除群成员|
|--------|:------------------------------------------|
|uri     |/openqq/kick_group_member|
|请求方法|GET\|POST|
|请求参数|**member_id**: 成员的id（多个成员id用逗号分割）<br>**member_uid**: 成员的qq（多个成员qq用逗号分割）<br>**group_id**: 群组的id<br>**group_uid**: 群组的号码<br>|
|数据格式|application/x-www-form-urlencoded|
|调用示例|http://127.0.0.1:5000/openqq/kick_group_member?group_uid=xxxxxx&member_uid=xxxx,xxxx<br>http://127.0.0.1:5000/openqq/kick_group_member?group_id=xxxxxx&member_id=xxxx,xxxx|

### 获取程序运行信息

|   API  |获取进程运行信息
|--------|:------------------------------------------|
|uri     |/openqq/get_client_info|
|请求方法|GET\|POST|
|请求参数|无|
|调用示例|http://127.0.0.1:5000/openqq/get_client_info|

返回JSON结果:

```
{
    "code":0,
    "account":"default",
    "log_encoding":null,
    "log_level":"debug",
    "log_path":null,
    "os":"linux",
    "pid":15497,
    "runtime":3096,
    "starttime":1475135588,
    "status":"success",
    "http_debug":"0",
    "version":"1.2.0"
 }
 ```
 
### 终止程序运行

|   API  |终止程序运行
|--------|:------------------------------------------|
|uri     |/openqq/stop_client|
|请求方法|GET\|POST|
|请求参数|无|
|调用示例|http://127.0.0.1:5000/openwx/stop_client|

返回JSON结果:

```
{
    "code":0,
    "account":"default",
    "pid":15972,
    "runtime":30,
    "starttime":1475136637,
    "status":"success, client(15972) will stop in 3 seconds"
}
```

### 更多高级用法，参见[Openqq插件文档](https://metacpan.org/pod/distribution/Mojo-Webqq/doc/Webqq.pod#Mojo::Webqq::Plugin::Openqq)
