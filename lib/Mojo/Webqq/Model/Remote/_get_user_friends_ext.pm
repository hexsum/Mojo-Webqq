use strict;
sub Mojo::Webqq::Model::_get_user_friends_ext {
    my $self = shift;
    my $callback = shift;
    my $api = 'http://qun.qq.com/cgi-bin/qun_mgr/get_friend_list';
    my $is_blocking = ref $callback eq "CODE"?0:1;
    my $handle = sub{
        my $json = shift;
        return if not defined $json;
        return if $json->{ec}!=0;
        #{"ec":0,"result":{"0":{"mems":[{"name":"卖茶叶和眼镜per","uin":744891290}]},"1":{"gname":"朋友"},"2":{"gname":"家人"},"3":{"gname":"同学"}}}
        my @result;
        for my $category_index (keys %{$json->{result}}){
            my $category = ($category_index==0 and !defined $json->{result}{$category_index}{gname})?"我的好友":($json->{result}{$category_index}{gname});
            next if ref $json->{result}{$category_index}{mems} ne "ARRAY";
            for my $f (@{ $json->{result}{$category_index}{mems} }){
                my $friend = {
                    category    =>  $self->xmlescape_parse($category),
                    displayname =>  $self->xmlescape_parse($f->{name}),
                    uid          =>  $f->{uin},
                } ;
                push @result,$friend;
            }
        } 
        return \@result;
    };
    if($is_blocking){
        return $handle->($self->http_post($api,{Referer=>"http://qun.qq.com/member.html",json=>1},form=>{bkn=>$self->get_csrf_token},) );
    }
    else{
        $self->http_post($api,{Referer=>"http://qun.qq.com/member.html",json=>1},form=>{bkn=>$self->get_csrf_token},sub{
            my $json = shift;
            $callback->( $handle->($json) );
        });
    }
}
1;
