### Docker镜像安装及使用方法

1. ***安装镜像***

  从官方仓库直接拉取

        docker pull sjdy521/mojo-webqq
        
  或者使用Dockerfile自己build
  
        docker build -t mojo-webqq .

2. ***运行镜像***

        docker run -it  --env MOJO_WEBQQ_LOG_ENCODING=utf8 -p 5000:5000 -v /tmp:/tmp sjdy521/mojo-webqq 

  为了能够方便查看日志，获取容器中下载的二维码文件等，建议把宿主的/tmp目录挂载到docker的/tmp上，同时设置容器的端口映射

  支持通过环境变量的方式传递参数，常用的环境变量参数：
  
  | 环境变量                         | 作用              | 默认值                            |
  | ---------------------------------|:------------------| :---------------------------------|
  | MOJO_WEBQQ_LOG_LEVEL             | 日志级别          | info                              |
  | MOJO_WEBQQ_LOG_PATH              | 日志保存路径      | STDOUT                            |
  | MOJO_WEBQQ_LOG_ENCODING          | 日志编码          | utf8                              |
  | MOJO_WEBQQ_QRCODE_PATH           | 二维码保存路径    | /tmp/mojo_webqq_qrcode_default.png|
  | MOJO_WEBQQ_PLUGIN_OPENQQ_PORT    | Openqq插件监听端口| 5000                              |
  | MOJO_WEBQQ_PLUGIN_OPENQQ_POST_API| Openqq插件上报地址| 无                                |

  更多环境变量自定义参数参见[开发文档](https://metacpan.org/pod/distribution/Mojo-Webqq/lib/Mojo/Webqq.pm#new)
