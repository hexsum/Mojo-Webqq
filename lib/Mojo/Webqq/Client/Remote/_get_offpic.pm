use File::Temp qw/:seekable/;
use Mojo::Util qw/url_escape/;
sub Mojo::Webqq::Client::_get_offpic {
    my $self = shift;
    my $file_path = shift;
    my $friend  = shift;
    
    my $api = 'http://w.qq.com/d/channel/get_offpic2';
    my @query_string = (
        file_path   =>  url_escape($file_path),
        f_uin       =>  $friend->id,
        clientid    =>  $self->clientid,  
        psessionid  =>  $self->psessionid,
    );
    my $callback = sub{
        my ($data,$ua,$tx) = @_;
        unless(defined $data){
            $self->warn("好友图片下载失败: " . $tx->error);
            return;
        }
        return unless $tx->res->headers->content_type =~/^image\/(.*)/;
        my $type =      $1=~/jpe?g/i        ?   ".jpg"
                    :   $1=~/png/i          ?   ".png"
                    :   $1=~/bmp/i          ?   ".bmp"
                    :   $1=~/gif/i          ?   ".gif"
                    :                           undef
        ;
        return unless defined $type; 
        if(defined $self->friend_pic_dir and not -d $self->friend_pic_dir){
            $self->error("无效的 friend_pic_dir: " . $self->friend_pic_dir);
            return;
        }
        my @opt = (
            TEMPLATE    => "webqq_offpic_XXXX",
            SUFFIX      => $type,
            UNLINK      => 0,
        );
        defined $self->friend_pic_dir?(push @opt,(DIR=>$self->friend_pic_dir)):(push @opt,(TMPDIR=>1));
        eval{
            my $tmp = File::Temp->new(@opt);
            binmode $tmp;
            print $tmp $tx->res->content();    
            close $tmp;
            open(my $fh,"<:raw",$tmp->filename) or die $!;
            $self->emit(receive_friend_pic => $fh,$tmp->filename,$friend);
            $self->emit(receive_offpic => $fh,$tmp->filename,$friend);
            close $fh;
        };
        $self->error("[Mojo::Webqq::Client::_get_offpic] $@\n") if $@;
    };
    $self->http_get($self->gen_url($api,@query_string),{Referer=>'http://w.qq.com/'},$callback);
};
1;
