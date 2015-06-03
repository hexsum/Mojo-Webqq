sub Mojo::Webqq::Message::_send_sess_message{
    my($self,$msg) = @_;
    return unless defined $msg->sess_sig;
    my $callback = sub{
        my $json = shift;
        my $status = $self->parse_send_status_msg( $json );
        if(defined $status and !$status->is_success){
            $self->debug("消息[ " .$msg->msg_id . " ]发送失败，尝试重新发送，当前TTL: " . $msg->ttl);
            $self->send_sess_message($msg);
            return;
        } 
        elsif(defined $status){
            if(ref $msg->cb eq 'CODE'){
                $msg->cb->(
                    $self,
                    $msg,
                    $status,
                );
            }
            $self->emit(send_message =>
                $msg,
                $status,
            );
        }
    };

    my $api_url = ($self->security?'https':'http') . '://d.web2.qq.com/channel/send_sess_msg2';
    my $headers = {
        Referer => 'http://d.web2.qq.com/proxy.html?v=20130916001&callback=1&id=2',
        json    => 1,
    };
    use Encode;
    my $content = [decode("utf8",$msg->content),[]];
    my %s = (
        to              => $msg->receiver_id ,
        group_sig       => $msg->sess_sig ,
        face            => $msg->sender->face || 591,
        content         => decode("utf8",$self->encode_json($content)),
        msg_id          => $msg->msg_id,
        service_type    => $msg->via eq "group"?0:1,
        clientid        => $self->clientid,
        psessionid      => $self->psessionid,
    );
    $self->http_post(
        $api_url,
        $headers,
        form=>{r=>decode("utf8",$self->encode_json(\%s))},
        $callback,
    );
}
1;
