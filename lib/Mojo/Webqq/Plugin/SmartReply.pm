package Mojo::Webqq::Plugin::SmartReply;
use POSIX;
use Encode;
my $api = 'http://www.tuling123.com/openapi/api';
my %limit;
my %ban;
my @limit_reply = (
    "对不起，请不要这么频繁的艾特我",
    "对不起，您的艾特次数太多",
    "说这么多话不累么，请休息几分钟",
    "能不能小窗我啊，别吵着大家",
);        
sub call{
    my $client = shift;
    my $data   = shift;
    $client->interval(3600,sub{
        my $key = strftime("%H",localtime(time-3600));
        delete $limit{$key};
    });
    $client->on(receive_message=>sub{
        my($client,$msg) = @_;
        return if not $msg->allow_plugin;
        return if $msg->type !~ /^message|group_message|sess_message$/;
        return if exists $ban{$msg->sender->id};
        my $sender_nick;
        my $user_nick = $client->user->nick;
        if($msg->type eq "group_message"){
            return if $msg->content !~/\@\Q$user_nick \E/;
            $sender_nick = $msg->sender->card || $msg->sender->nick ;
        }
        else{$sender_nick = $msg->sender->nick}

        $msg->allow_plugin(0);
        if($msg->type eq 'group_message'){
            my $key = POSIX::strftime("%H",localtime(time));
            $limit{$key}{$msg->group->gid}{$msg->sender->id}++; 
            my $limit  = $limit{$key}{$msg->group->gid}{$msg->sender->id};
            if($limit>=3 and $limit<=4){
                $client->reply_message($msg,"\@$sender_nick " . $limit_reply[int rand($#limit_reply+1)]);
                return;
            }   
            if($limit >=5 and $limit <=6){
                $client->reply_message($msg,"\@$sender_nick " . "警告，您艾特过于频繁，即将被列入黑名单，请克制");
                return;
            }
            if($limit > 6){
                $ban{$msg->sender->id} = 1;
                $client->reply_message($msg,"\@$sender_nick " . "您已被列入黑名单，1小时内提问无视");
                $client->timer(3600,sub{delete $ban{$msg->sender->id};});
            }
        } 

        my $input = $msg->content;
        $input=~s/\@\Q$self_nick\E ?|\[[^\[\]]+\]\x01|\[[^\[\]]+\]//g;
        return unless $input;

        my @query_string = (
            "key"       =>  $data->{apikey} || "4c53b48522ac4efdfe5dfb4f6149ae51",
            "userid"    =>  $msg->sender->qq,
            "info"      =>  $input,
        );

        push @query_string,(loc=>$msg->sender->city."市") if $msg->sender->city; 
        $client->http_get($api,{json=>1},form=>{@query_string},sub{
            my $json = shift;
            return unless defined $json;
            return if $json->{code}=~/^4000[1-7]$/;
            my $reply;
            if($json->{code} == 100000){
                return unless $json->{text};
                $reply = encode("utf8",$json->{text});
            } 
            elsif($json->{code} == 200000){
                $reply = encode("utf8","$json->{text}$json->{url}");
            }
            else{return}

            $reply  = "\@$sender_nick " . $reply  if $msg->type eq 'group_message' and rand(100)>20;
            $reply = $client->truncate($reply,max_bytes=>300,max_lines=>5) if $msg->type eq 'group_message';        
            $client->reply_message($msg,$reply) if $reply;
        });

    }); 
}
1;
