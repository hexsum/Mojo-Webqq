#!/bin/bash

#发送的群号
guid=$1

#Openqq插件中定义的host和port
API_ADDR="127.0.0.1:5000"

# 处理下编码，用于合并告警内容的标题和内容，即$2和$3
message=`echo -e "$2"|od -t x1 -A n -v -w100000 | tr " " %`

#组装api调用地址
api_url="http://$API_ADDR/openqq/send_group_message?uid=$guid&content=$message"

#请求api地址发送群消息
curl -v $api_url
