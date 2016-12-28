### API列表汇总

|API地址                      |API说明        |
|:----------------------------|:--------------|
|基础信息获取相关              |              |
|[/openqq/get_user_info](API.md#获取用户数据)   |获取登录用户数据 |
|[/openqq/get_friend_info](API.md#获取好友数据) |获取好友数据 |
|[/openqq/get_group_info](API.md#获取群组数据)   |获取群组数据 |
|[/openqq/get_group_basic_info](API.md#获取群组基础数据)  |获取群组基础数据(不包含群成员)|
|[/openqq/get_discuss_info](API.md#获取讨论组数据)  |获取讨论组数据|
|消息发送相关||
|[/openqq/send_message](API.md#发送好友消息)  |发送好友消息|
|[/openqq/send_group_message](API.md#发送群组消息)  |发送群组消息|
|[/openqq/send_discuss_message](API.md#发送讨论组消息)  |发送讨论组消息|
|[/openqq/send_sess_message](API.md#发送群临时消息)  |发送群临时消息(已被腾讯屏蔽)|
|[/openqq/send_sess_message](API.md#发送讨论组临时消息)  |发送讨论组临时消息(已被腾讯屏蔽)|
|消息获取相关||
|[自定义消息上报地址](API.md#自定义消息上报地址)  |支持好友消息、群消息、讨论组消息上报|
|数据搜索相关||
|[/openqq/search_friend](API.md#搜索好友)  |搜索好友|
|[/openqq/search_group](API.md#搜索群组)  |搜索群组|
|群组管理相关||
|[/openqq/shutup_group_member](API.md#群成员禁言)  |群成员禁言|
|[/openqq/kick_group_member](API.md#踢除群成员)  |踢除群成员|


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

### 自定义消息上报地址
|   API  |接收消息上报（支持好友消息、群消息、讨论组消息）
|--------|:------------------------------------------|
|uri     |自定义任意支持http协议的url|
|请求方法|POST|
|数据格式|application/json|

需要加载Openqq插件时通过 `post_api` 参数来指定上报地址:
```
$client->load("Openqq",data=>{
    listen => [{host=>xxx,port=>xxx}],           #可选，发送消息api监听端口
    post_api=> 'http://127.0.0.1:5000/post_api', #可选，接收消息或事件的上报地址
});
```

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
    "type":"group_message"
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

### 更多高级用法，参见[Openqq插件文档](https://metacpan.org/pod/distribution/Mojo-Webqq/doc/Webqq.pod#Mojo::Webqq::Plugin::Openqq)
