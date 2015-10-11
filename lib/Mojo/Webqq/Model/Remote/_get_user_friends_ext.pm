use strict;
sub Mojo::Webqq::Model::_get_user_friends_ext {
    my $self = shift;
    my $api = 'http://qun.qq.com/cgi-bin/qun_mgr/get_friend_list';
    my $json = $self->http_post($api,{Referer=>"http://qun.qq.com/member.html",json=>1},form=>{bkn=>$self->get_csrf_token});
    return if not defined $json;
    return if $json->{ec}!=0;
    #{"ec":0,"result":{"0":{"mems":[{"name":"卖茶叶和眼镜per","uin":744891290}]},"1":{"gname":"朋友"},"2":{"gname":"家人"},"3":{"gname":"同学"}}}
    my @result;
    for my $category_index (keys %{$json->{result}}){
        my $category = $category_index==0?"我的好友":encode_utf8($json->{result}{$category_index}{gname});
        next if ref $json->{result}{$category_index}{mems} ne "ARRAY";
        for my $f (@{ $json->{result}{$category_index}{mems} }){
            my $friend = {
                category    =>  $category,
                nick        =>  $f->{name},
                qq          =>  $f->{uin},
            } ;
            $self->reform_hash($friend);
            push @result,$friend;
        }
    } 
    return \@result;
}
1;
