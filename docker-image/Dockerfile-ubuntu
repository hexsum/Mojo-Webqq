# version: v2.2.6
FROM ubuntu
MAINTAINER XZ-Dev <xiangzhedev@gmail.com>
WORKDIR /root
USER root
ENV LANG C.UTF-8
ENV TZ=Asia/Shanghai
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone
RUN apt-get update
RUN apt-get dist-upgrade -y
RUN apt-get install \
      make cpanminus \
      libnet-ssleay-perl \
      libcrypt-openssl-bignum-perl \
      libcrypt-openssl-rsa-perl -y
RUN cpanm IO::Socket::SSL
RUN cpanm Mojo::Webqq
RUN cpanm Webqq::Encryption
CMD perl -MMojo::Webqq -e 'Mojo::Webqq->new(log_encoding=>"utf8")->load(["ShowMsg","UploadQRcode"])->load("Openqq",data=>{listen=>[{port=>$ENV{MOJO_WEBQQ_PLUGIN_OPENQQ_PORT}//5000}],post_api=>$ENV{MOJO_WEBQQ_PLUGIN_OPENQQ_POST_API}})->run'
