FROM perl:5.22
MAINTAINER sjdy521 <sjdy521@163.com>
WORKDIR /root
RUN apt-get update \
    && apt-get install -y unzip \
    && wget https://github.com/sjdy521/Mojo-Webqq/archive/master.zip -OMojo-Webqq.zip \
    && unzip Mojo-Webqq.zip \
    && cd Mojo-Webqq-master \
    && cpanm . \
    && rm -rf Mojo-Webqq-master Mojo-Webqq.zip 
CMD perl -MMojo::Webqq -e 'Mojo::Webqq->new(log_encoding=>)->load(["ShowMsg","UploadQRcode"])->load("Openqq",data=>{listen=>[{port=>$ENV{MOJO_WEBQQ_PLUGIN_OPENQQ_PORT}//5000}],post_api=>$ENV{MOJO_WEBQQ_PLUGIN_OPENQQ_POST_API}})'
