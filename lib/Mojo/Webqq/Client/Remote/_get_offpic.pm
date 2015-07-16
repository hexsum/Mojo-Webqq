use File::Temp qw/:seekable/;
sub Mojo::Webqq::Client::_get_offpic {
    my $self = shift;
    my $file_path = shift;
    my $friend  = shift;
    
    return  unless $self->has_subscribers("receive_friend_pic");
    my $api = 'http://w.qq.com/d/channel/get_offpic2';
    my @query_string = (
        file_path   =>  $file_path,
        f_uin       =>  $friend->id,
        clientid    =>  $self->clientid,  
        psessionid  =>  $self->psessionid,
    );
    my $callback = sub{
        my ($data,$ua,$tx) = @_;
        return  unless $self->has_subscribers("receive_friend_pic");
        return unless defined $data;
        return unless $tx->res->heades->content_type =~/^image\/(.*)/;
        my $type =      $1=~/jpe?g/i        ?   ".jpg"
                    :   $1=~/png/i          ?   ".png"
                    :   $1=~/bmp/i          ?   ".bmp"
                    :   $1=~/gif/i          ?   ".gif"
                    :                           undef
        ;
        return unless defined $type; 
        my $tmp = File::Temp->new(
                TEMPLATE    => "webqq_offpic_XXXX",    
                SUFFIX      => $type,
                TMPDIR      => 1,
                UNLINK      => 1,
        );
        binmode $tmp;
        print $tmp $response->content();    
        close $tmp;
        eval{
            open(my $fh,"<:raw",$tmp->filename) or die $!;
            $self->emit(receive_friend_pic => $fh,$tmp->filename,$friend);
            close $fh;
        };
        $self->error("[Mojo::Webqq::Client::_get_offpic] $@\n") if $@;
    };
    $self->http_get($self->gen_url($api,@query_string),$callback);
};
1;
