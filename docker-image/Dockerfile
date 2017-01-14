FROM perl:5.22
MAINTAINER sjdy521 <sjdy521@163.com>
WORKDIR /root
RUN apt-get update \
    && apt-get install -y unzip \
    && wget https://github.com/sjdy521/Mojo-Webqq/archive/master.zip -OMojo-Webqq.zip \
    && unzip -qo Mojo-Webqq.zip \
    && cd Mojo-Webqq-master \
    && cpanm . \
    && cd .. \
    && apt-get purge -y unzip && apt-get autoremove -y \
    && rm -rf Mojo-Webqq-master Mojo-Webqq.zip /var/lib/apt/lists/*
CMD perl -MMojo::Webqq -e 'Mojo::Webqq->new(log_encoding=>"utf8")->load(["ShowMsg","UploadQRcode"])->load("Openqq",data=>{listen=>[{port=>$ENV{MOJO_WEBQQ_PLUGIN_OPENQQ_PORT}//5000}],post_api=>$ENV{MOJO_WEBQQ_PLUGIN_OPENQQ_POST_API}})->run'
