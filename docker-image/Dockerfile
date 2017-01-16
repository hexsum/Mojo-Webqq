FROM perl:5.22
MAINTAINER sjdy521 <sjdy521@163.com> & Aurore <auroreme@users.noreply.github.com>

ARG TZ="Asia/Shanghai"

RUN set -ex && \
    ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && \
    echo $TZ > /etc/timezone && \
    \
    apt-get update && \
    apt-get install -y wget unzip && \
    \
    cpanm Encode::Locale IO::Socket::SSL Mojolicious && \
    wget --no-check-certificate https://github.com/sjdy521/Mojo-Webqq/archive/master.zip \
         -O Mojo-Webqq.zip && \
    unzip Mojo-Webqq.zip && \
    cd Mojo-Webqq-master && \
    cpanm . && \
    cd .. && \
    rm -rf Mojo-Webqq* && \
    \
    apt-get purge -y wget unzip && \
    rm -rf /var/lib/apt/*

CMD perl -MMojo::Webqq -e 'Mojo::Webqq->new(log_encoding=>"utf8")->load(["ShowMsg","UploadQRcode"])->load("Openqq",data=>{listen=>[{port=>$ENV{MOJO_WEBQQ_PLUGIN_OPENQQ_PORT}//5000}],post_api=>$ENV{MOJO_WEBQQ_PLUGIN_OPENQQ_POST_API}})->run'
