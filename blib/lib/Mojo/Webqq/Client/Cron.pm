package Mojo::Webqq::Client::Cron;
use POSIX qw(mktime);
BEGIN{
    our $is_module_ok = 0;
    eval{
        require Time::Piece;
        require Time::Seconds;
        Time::Piece->import;
        Time::Seconds->import;
    };
    $is_module_ok = 1 if not $@;
}
sub add_job{
    my $self = shift;
    if(not $is_module_ok){
        $self->error("调用add_job方法请先确保安装模块 Time::Piece 和 Time::Seconds");
        return;
    }
    my($type,$nt,$callback) = @_;
    my $t = $nt;
    if(ref $callback ne 'CODE'){ 
        $self->die("设置的callback无效\n");
    }
    if(ref $nt eq "CODE"){
        $t = $nt->();
    }
    my $time = {};
    if(ref $t eq "HASH"){
        $time = $t;
    }
    else{
        my($hour,$minute,$second) = split /:/,$t;
        $second = 0 if not defined $second ;
        $time = {hour => $hour,minute => $minute,second=> $second};
    }
    $self->debug("计划任务[$type]添加成功，时间设定: " . join(":",map {$_!=0?$_:"00"} ($time->{hour},$time->{minute},$time->{second})) );
    my $delay;
    #my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime;
    my @now = localtime;
    my $now = mktime(@now);
    my @next = @{[@now]};
    for my $k (keys %$time){
          $k eq 'year'        ? ($next[5]=$time->{$k}-1900)
        : $k eq 'month'       ? ($next[4]=$time->{$k}-1)
        : $k eq 'day'         ? ($next[3]=$time->{$k})
        : $k eq 'hour'        ? ($next[2]=$time->{$k})
        : $k eq 'minute'      ? ($next[1]=$time->{$k})
        : $k eq 'second'      ? ($next[0]=$time->{$k})
        : next;
    } 

    my $next = mktime(@next);
    $now = localtime($now);
    $next = localtime($next);

    if($now >= $next){
        if( $time->{month} ) {
            $next->add_years(1);
        }
        elsif( $time->{day} ) {
            $next->add_months(1);
        }
        elsif( $time->{hour} ) {
            $next += ONE_DAY;
        }
        elsif( $time->{minute} ) {
            $next += ONE_HOUR;
        }
        elsif( $time->{second} ) {
            $next += ONE_MINUTE;
        }        
    }    
    
    $self->debug("计划任务[$type]下一次触发时间为：" . $next->strftime("%Y/%m/%d %H:%M:%S")); 
    $delay = $next - $now;
    $self->timer($delay,sub{
        eval{
            $callback->();
        };
        $self->error($@) if $@;
        $self->add_job($type,$nt,$callback);
    });
}
1;
