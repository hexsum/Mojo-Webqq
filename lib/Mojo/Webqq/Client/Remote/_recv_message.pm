sub Mojo::Webqq::Client::_recv_message{
    my $self = shift;
    return if $self->is_stop;
    return if $self->is_polling;
    $self->is_polling(1);
    my $api_url = ($self->security?'https':'http') . '://d1.web2.qq.com/channel/poll2';
    my $callback = sub {
        my ($json,$ua,$tx) = @_;
        eval{
            #分析接收到的消息，并把分析后的消息放到接收消息队列中
            if(defined $json){
                $self->parse_receive_msg($json);
                $self->emit(receive_raw_message=>$tx->res->body,$json);
            }
        };
        $self->error($@) if $@;
        $self->is_polling(0);
        #重新开始接收消息
        $self->emit("poll_over");
    };

    my %r = (
        ptwebqq     => $self->ptwebqq,
        clientid    =>  $self->clientid,
        psessionid  =>  $self->psessionid,
        key         =>  "",
    );
    my $headers = {Referer=>"http://d1.web2.qq.com/proxy.html?v=20151105001&callback=1&id=2",json=>1};
    my $id = $self->http_post(
        $api_url,   
        $headers,
        form=>{r=>$self->encode_json(\%r)},
        $callback
    );
    $self->poll_connection_id($id);
}
1;
