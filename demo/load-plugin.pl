#!/usr/bin/env perl
use lib "../lib/";
use Mojo::Webqq;

#注意:
#程序内部数据全部使用UTF8编码，因此二次开发源代码也请尽量使用UTF8编码进行编写，否则需要自己做编码处理
#在终端上执行程序，会自动检查终端的编码进行转换，以防止乱码
#如果在某些IDE的控制台中查看执行结果，程序无法自动检测输出编码，可能会出现乱码，可以手动设置输出编码
#手动设置输出编码参考文档中关于 log_encoding 的说明

#帐号可能进入保护模式的原因:
#多次发言中包含网址
#短时间内多次发言中包含敏感词汇
#短时间多次发送相同内容
#频繁异地登陆

#推荐手机安装[QQ安全中心]APP，方便随时掌握自己帐号的情况

#初始化一个客户端对象，设置登录的qq号

my $client=Mojo::Webqq->new(
http_debug  =>  0,         #是否打印详细的debug信息
log_level   => "info",     #日志打印级别
);

#注意: 腾讯可能已经关闭了帐号密码的登录方式，这种情况下只能使用二维码扫描登录

#发送二维码到邮箱
$client->load("PostQRcode",data=>{
smtp    =>  'smtp.xxx.com', #邮箱的smtp地址
port    =>  '25', #smtp服务器端口，默认25
from    =>  'xxx@xxx.com', #发件人
to      =>  'xxx@xxx.com', #收件人
user    =>  'xxx@xxx.com', #smtp登录帐号
pass    =>  'xxxxx', #smtp登录密码
});

#客户端加载ShowMsg插件，用于打印发送和接收的消息到终端
$client->load("ShowMsg");

#显示perl文档
#$client->load("Perlcode");

#执行perl命令，仅支持linux系统加载使用
#$client->load("Perldoc");

#智能聊天回复
$client->load("SmartReply");
#需要私聊或@机器人

#对大神进行鄙视
$client->load("FuckDaShen");

#创建知识库
$client->load("KnowledgeBase");
#示例：learn 今天天气怎么样  天气很好
#      学习  "你吃了吗"      当然吃了
#      learn '哈哈 你真笨'   "就你聪明"
#      del   今天天气怎么样
#       删除  '哈哈 你真笨'

#翻译
$client->load("Translation");
#示例：翻译 hello

#手机归属地查询
$client->load("MobileInfo");
#示例：手机 1888888888

#代码测试
$client->load("ProgramCode");
#示例：code|c>>>
#        #include <stdio.h>
#        int main() {
#            printf("Hello World!\n");
#            return 0;
#        }

#股票查询
$client->load("StockInfo");
#示例：股票 000001

#提供HTTP API接口，方便获取客户端帐号、好友、群、讨论组信息
#以及通过接口发送和接收好友消息、群消息、群临时消息和讨论组临时消息
$client->load("Openqq",data=>{
    listen => [ {host=>"0.0.0.0",port=>5000}, ] , #监听的地址和端口，支持多个
    #auth   => sub {my($param,$controller) = @_},    #可选，认证回调函数，用于进行请求鉴权
    #post_api => 'http://xxxx',                      #可选，设置接收消息的上报接口
});

#客户端开始运行
$client->run();
