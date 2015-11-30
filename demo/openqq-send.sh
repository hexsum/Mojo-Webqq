#!/bin/bash
#导入jq环境变量，否则执行时会找不到命令，根据具体配置填写
export PATH=$PATH:/usr/local/bin/

#发送的群号
Gnumber=$1

# 你login.pl中定义的host和port
API_ADDR="127.0.0.1:5011"

# 处理下编码，用于合并告警内容的标题和内容，即$2和$3
message=`echo -e "$2"|od -t x1 -A n -v -w100000 | tr " " %`

# 获取gid，需要安装jd处理json
#GID=`curl -s http://$API_ADDR/openqq/get_group_info | jq '.[0].gid'| tr -d '"'`

# 这没什么好说的
api_url="http://$API_ADDR/openqq/send_group_message?gnumber=$Gnumber&content=$message"

curl $api_url
