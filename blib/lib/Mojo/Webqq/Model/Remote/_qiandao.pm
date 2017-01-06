sub Mojo::Webqq::Model::_qiandao {
    my($self,$uid) = @_;
    if(not defined $uid){
        $self->warn("无效的群组号码");
        return;
    }
    my $api = 'http://qiandao.qun.qq.com/cgi-bin/sign';
    my $json = $self->http_post(
        $api,
        {json=>1,Referer=>"http://qiandao.qun.qq.com/index.html?groupUin=$uid&appID=100729587"},
        form=>{
            gc=>$uid,
            is_sign=>0,
            bkn=>$self->get_csrf_token,
        }
    );
    return if not defined $json;
    #{"conti_count":1,"ec":0,"is_new":0,"is_sign":1,"now":1464858442,"rank":2,"sign_time":1464858442,"today_count":2,"total_count":1}
    return if $json->{ec} != 0;
    return if $json->{is_sign} != 1;
    return 1;
}
1;
