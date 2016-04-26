FROM perl:5.22
MAINTAINER sjdy521 <sjdy521@163.com>
RUN cpanm Mojo::Webqq
RUN cpanm Mojo::SMTP::Client
COPY Mojo-Webqq.pl /tmp/Mojo-Webqq.pl
WORKDIR /tmp
CMD ["perl","/tmp/Mojo-Webqq.pl"]
