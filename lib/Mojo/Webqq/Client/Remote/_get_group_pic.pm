use File::Temp qw/:seekable/;
use Mojo::Util qw/url_escape/;
sub Mojo::Webqq::Client::_get_group_pic {
    my $self = shift;
    my $fid = shift;
    my $pic_name = shift;
    my $rip = shift;
    my $rport = shift;
    my $group = shift;
    my $sender  = shift;
    
    my $api = 'http://web2.qq.com/cgi-bin/get_group_pic';
    my @query_string = (
        type    => 0,
        fid     => $fid,
        gid     => $group->gcode,
        pic     => url_escape($pic_name),
        rip     => $rip,
        rport   => $rport,
        uin     => $sender->id,
        vfwebqq => $self->vfwebqq,
        t       => time(),
    );
    my $callback = sub{
        my ($data,$ua,$tx) = @_;
        unless(defined $data){
            $self->warn("群图片下载失败: " . $tx->error->{message});
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
        if(defined $self->group_pic_dir and not -d $self->group_pic_dir){
            $self->error("无效的 group_pic_dir: " . $self->group_pic_dir);
            return;
        }
        my @opt = (
            TEMPLATE    => "webqq_gpic_XXXX",
            SUFFIX      => $type,
            UNLINK      => 0,
        );
        defined $self->group_pic_dir?(push @opt,(DIR=>$self->group_pic_dir)):(push @opt,(TMPDIR=>1));
        eval{
            my $tmp = File::Temp->new(@opt);
            binmode $tmp;
            print $tmp $tx->res->body();    
            close $tmp;
            open(my $fh,"<:raw",$tmp->filename) or die $!;
            $self->emit(receive_group_pic => $fh,$tmp->filename,$group,$sender);
            close $fh;
        };
        $self->error("[Mojo::Webqq::Client::_get_group_pic] $@\n") if $@;
    };
    $self->http_get($self->gen_url($api,@query_string),{Referer=>'http://w.qq.com/'},$callback);
};
1;
