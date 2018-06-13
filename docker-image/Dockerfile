FROM centos:7.0.1406
MAINTAINER sjdy521 <sjdy521@163.com>
WORKDIR /root
USER root
ENV TZ=Asia/Shanghai
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone
RUN yum -y --nogpgcheck install \
    make \
    unzip \ 
    wget \ 
    tar \
    perl \ 
    perl-App-cpanminus \
    perl-Crypt-OpenSSL-Bignum \
    perl-Crypt-OpenSSL-RSA \
    perl-Compress-Raw-Zlib \
    perl-IO-Compress-Gzip \
    perl-Digest-MD5 \
    perl-Digest-SHA \
    perl-Time-Piece \
    perl-Time-Seconds \
    perl-Time-HiRes \
    perl-IO-Socket-SSL \
    perl-Encode-Locale \
    perl-Term-ANSIColor && \
    yum clean all
RUN cpanm -vn Test::More IO::Socket::SSL Webqq::Encryption Mojolicious MIME::Lite Mojo::SMTP::Client Mojo::IRC::Server::Chinese 
RUN wget -q https://github.com/sjdy521/Mojo-Webqq/archive/master.zip -OMojo-Webqq.zip \
    && unzip -qo Mojo-Webqq.zip \
    && cd Mojo-Webqq-master \
    && cpanm -v . \
    && cd .. \
    && rm -rf Mojo-Webqq-master Mojo-Webqq.zip
CMD perl -MMojo::Webqq -e 'Mojo::Webqq->new(log_encoding=>"utf8")->load(["ShowMsg","UploadQRcode"])->load("Openqq",data=>{listen=>[{port=>$ENV{MOJO_WEBQQ_PLUGIN_OPENQQ_PORT}//5000}],post_api=>$ENV{MOJO_WEBQQ_PLUGIN_OPENQQ_POST_API}})->run'
