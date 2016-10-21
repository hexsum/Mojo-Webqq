### 1. 获取用户数据
|   API  |获取用户数据
|--------|:------------------------------------------|
|uri     |/openqq/get_user_info|
|请求方法|GET\|POST|
|请求参数|无|
|调用示例|http://127.0.0.1:5000/openqq/get_user_info|

返回数据:

```
{
    "nick": "小灰",
    "mobile": "188********",
    "state": "online",
    "client_type": "web",
    "email": "",
    "city": "北京",
    "personal": "这是我的个性签名",
    "province": "北京",
    "id": "1234567",
    "birthday": "1990-01-01",
    "gender": "male",
    "country": "中国",
    "qq": "1234567",
    "account": "1234567",
    "college": "",
    "occupation": "计算机/互联网/IT",
    "phone": "",
    "homepage": "",
    "blood": "3",
    "signature": " ",
}

```

### 2. 获取好友数据
|   API  |获取好友数据
|--------|:------------------------------------------|
|uri     |/openqq/get_friend_info|
|请求方法|GET\|POST|
|请求参数|无|
|调用示例|http://127.0.0.1:5000/openqq/get_friend_info|
返回JSON数组:

```
[#好友数组
    {#第一个好友
        "is_vip": "1",
        "qq": "123456",
        "markname": "xxx",
        "flag": "0",
        "nick": "测试帐号1",
        "state": "offline",
        "client_type": "unknown",
        "face": "153",
        "vip_level": "6",
        "category": "我的网友",
        "id": "2457053936"
    },
    {
        "is_vip": "0",
        "qq": "7891234",
        "markname": "哈哈",
        "flag": "32",
        "nick": "测试帐号2",
        "state": "offline",
        "client_type": "unknown",
        "face": "168",
        "vip_level": "0",
        "category": "我的家人",
        "id": "2475249571"
    },
]
```

### 3. 获取群组数据
|   API  |获取群组数据
|--------|:------------------------------------------|
|uri     |/openqq/get_group_info|
|请求方法|GET\|POST|
|请求参数|无|
|调用示例|http://127.0.0.1:5000/openqq/get_group_info|
返回JSON数组:
```
[#数组
    {#第1个群
        "gmarkname": "xxx",
        "gid": "",
        "gcode": "",
        "gname": "",
        "gtype": "",
        "gcreatetime": "",
        "member": [
            {
                "qage": "16",
                "nick": "xxx",
                "join_time": "0",
                "state": "offline",
                "client_type": "unknown",
                "city": "大连",
                "province": "辽宁",
                "id": "2832277643",
                "gender": "male",
                "bad_record": "0",
                "country": "中国",
                "qq": "45678",
                "gnumber": "552603",
                "last_speak_time": "1453449884",
                "role": "attend",
            },
            {
                "qage": "16",
                "nick": "xxx",
                "join_time": "0",
                "state": "offline",
                "client_type": "unknown",
                "city": "大连",
                "province": "辽宁",
                "id": "2832277643",
                "gender": "male",
                "bad_record": "0",
                "country": "中国",
                "qq": "123455",
                "gnumber": "552603",
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

### 4. 获取群组基础数据(不包含群成员)
|   API  |获取群组数据
|--------|:------------------------------------------|
|uri     |/openqq/get_group_basic_info|
|请求方法|GET\|POST|
|请求参数|无|
|调用示例|http://127.0.0.1:5000/openqq/get_group_basic_info|

### 5. 获取讨论组数据
|   API  |获取讨论组数据
|--------|:------------------------------------------|
|uri     |/openqq/get_discuss_info|
|请求方法|GET\|POST|
|请求参数|无|
|调用示例|http://127.0.0.1:5000/openqq/get_discuss_info|
返回JSON数组:

```
[
    {
        "dname": "测试",
        "did": "4118239384",
        "member": [
            {
                "did": "4118239384",
                "nick": "小灰",
                "state": "offline",
                "downer": null,
                "client_type": "unknown",
                "dname": "测试",
                "id": "123456"
            },
            {
                "did": "4118239384",
                "nick": "哈哈",
                "state": "offline",
                "downer": null,
                "client_type": "unknown",
                "dname": "测试",
                "id": "456789"
            },
            {
                "did": "4118239384",
                "nick": "嘿嘿",
                "state": "offline",
                "downer": null,
                "client_type": "unknown",
                "dname": "测试",
                "id": "78901"
            }
        ],
    }
]

```

### 6. 发送好友消息
|   API  |发送好友消息
|--------|:------------------------------------------|
|uri     |/openqq/send_message|
|请求方法|GET\|POST|
|请求参数|**id**: 好友的id（每次扫描登录可能会变化）<br>**qq**: 好友的QQ号<br>**content**: 发送的消息(中文需要做urlencode)|
|数据格式|application/x-www-form-urlencoded|
|调用示例|http://127.0.0.1:5000/openqq/send_message?id=xxxx&content=hello<br>http://127.0.0.1:5000/openqq/send_message?qq=xxx&content=%e4%bd%a0%e5%a5%bd|

返回JSON数组:
```
{"status":"发送成功","msg_id":23910327,"code":0} #code为 0 表示发送成功
```
### 7. 发送群组消息
|   API  |发送群组消息
|--------|:------------------------------------------|
|url     |/openqq/send_group_message|
|请求方法|GET\|POST|
|请求参数|**gid**: 群组的id（每次扫描登录可能会变化）<br>**gnumber**: 群号码<br>**content**:消息内容(中文需要做urlencode)|
|数据格式|application/x-www-form-urlencoded|
|调用示例|http://127.0.0.1:5000/openqq/send_group_message?gid=xxxx&content=hello<br>http://127.0.0.1:5000/openqq/send_group_message?gnumber=xxx&content=%e4%bd%a0%e5%a5%bd|
返回JSON数组:
```
{"status":"发送成功","msg_id":23910327,"code":0} #code为 0 表示发送成功
```

### 8. 发送讨论组消息
|   API  |发送讨论组消息
|--------|:------------------------------------------|
|uri     |/openqq/send_discuss_message|
|请求方法|GET\|POST|
|请求参数|**did**: 讨论组的id（每次扫描登录可能会变化）<br>**content**:消息内容(中文需要做urlencode)|
|数据格式|application/x-www-form-urlencoded|
|调用示例|http://127.0.0.1:5000/openqq/send_discuss_message?did=xxxx&content=hello<br>http://127.0.0.1:5000/openqq/send_discuss_message?did=xxx&content=%e4%bd%a0%e5%a5%bd|
返回JSON数组:
```
{"status":"发送成功","msg_id":23910327,"code":0} #code为 0 表示发送成功
```

### 9. 发送群临时消息(已被腾讯屏蔽)
|   API  |发送群临时消息
|--------|:------------------------------------------|
|uri     |/openqq/send_sess_message|
|请求方法|GET\|POST|
|请求参数|**gid**: 群的id（每次扫描登录可能会变化）<br>**gnumber**: 群的号码<br>**id**: 陌生人的id（每次扫描登录可能会变化）<br>**qq**: 陌生人的qq号<br>**content**:消息内容(中文需要做urlencode)|
|数据格式|application/x-www-form-urlencoded|
|调用示例|http://127.0.0.1:5000/openqq/send_sess_message?gid=xxxx&id=xxx&content=hello<br>http://127.0.0.1:5000/openqq/send_sess_message?gnumber=xxx&qq=xxx&content=%e4%bd%a0%e5%a5%bd|
返回JSON数组:
```
{"status":"发送成功","msg_id":23910327,"code":0} #code为 0 表示发送成功
```

### 10. 发送讨论组临时消息(已被腾讯屏蔽)
|   API  |发送讨论组临时消息
|--------|:------------------------------------------|
|uri     |/openqq/send_sess_message|
|请求方法|GET\|POST|
|请求参数|**did**: 讨论组的id（每次扫描登录可能会变化）<br>**id**: 陌生人的id（每次扫描登录可能会变化）<br>**qq**: 陌生人的qq号<br>**content**:消息内容(中文需要做urlencode)|
|数据格式|application/x-www-form-urlencoded|
|调用示例|http://127.0.0.1:5000/openqq/send_sess_message?did=xxxx&id=xxx&content=hello<br>http://127.0.0.1:5000/openqq/send_sess_message?did=xxx&qq=xxx&content=%e4%bd%a0%e5%a5%bd|
返回JSON数组:
```
{"status":"发送成功","msg_id":23910327,"code":0} #code为 0 表示发送成功
```

### 11. 自定义接收消息上报地址
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
    "msg_time":"1442542632",
    "content":"测试一下",
    "msg_class":"recv",
    "sender":"灰灰",
    "sender_id":"2372835507",
    "sender_qq":"456789",
    "receiver":"小灰",
    "receiver_id":"4072574066",
    "receiver_qq":"123456",
    "group":"PERL学习交流",
    "group_id":"2617047292",
    "gnumber":"67890",
    "msg_id":"10856",
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

### 12. 搜索好友

|   API  |搜索好友|
|--------|:------------------------------------------|
|uri     |/openqq/search_friend|
|请求方法|GET\|POST|
|请求参数|好友对象的任意属性，中文需要做urlencode，比如：<br>**id**: 好友的id<br>**qq**: 好友的帐号<br>**markname**: 好友备注名称<br>|
|数据格式|application/x-www-form-urlencoded|
|调用示例|http://127.0.0.1:5000/openqq/search_friend?qq=xxxx|


### 13. 搜索群组

|   API  |搜索群组|
|--------|:------------------------------------------|
|uri     |/openqq/search_group|
|请求方法|GET\|POST|
|请求参数|群对象的任意属性，中文需要做urlencode，比如：<br>**gid**: 群组的id<br>**gnumber**: 群组的号码<br>|
|数据格式|application/x-www-form-urlencoded|
|调用示例|http://127.0.0.1:5000/openqq/search_group?gnumber=xxxxxx|
返回JSON数组:

### 14. 群成员禁言

|   API  |群成员禁言|
|--------|:------------------------------------------|
|uri     |/openqq/shutup_group_member|
|请求方法|GET\|POST|
|请求参数|**time**: 禁言时长，最低60秒（单位：秒）<br>**member_id**: 成员的id（多个成员id用逗号分割）<br>**member_qq**: 成员的qq（多个成员qq用逗号分割）<br>**gid**: 群组的id<br>**gnumber**: 群组的号码<br>|
|数据格式|application/x-www-form-urlencoded|
|调用示例|http://127.0.0.1:5000/openqq/shutup_group_member?gnumber=xxxxxx&member_qq=xxxx,xxxx<br>http://127.0.0.1:5000/openqq/shutup_group_member?gid=xxxxxx&member_id=xxxx,xxxx|

### 15. 踢除群成员

|   API  |踢除群成员|
|--------|:------------------------------------------|
|uri     |/openqq/kick_group_member|
|请求方法|GET\|POST|
|请求参数|**member_id**: 成员的id（多个成员id用逗号分割）<br>**member_qq**: 成员的qq（多个成员qq用逗号分割）<br>**gid**: 群组的id<br>**gnumber**: 群组的号码<br>|
|数据格式|application/x-www-form-urlencoded|
|调用示例|http://127.0.0.1:5000/openqq/kick_group_member?gnumber=xxxxxx&member_qq=xxxx,xxxx<br>http://127.0.0.1:5000/openqq/kick_group_member?gid=xxxxxx&member_id=xxxx,xxxx|

### 更多高级用法，参见[Openqq插件文档](https://metacpan.org/pod/distribution/Mojo-Webqq/doc/Webqq.pod#Mojo::Webqq::Plugin::Openqq)
