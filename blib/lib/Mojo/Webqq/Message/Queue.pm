package Mojo::Webqq::Message::Queue;
$Mojo::Webqq::Message::Queue::LAST_GET_TIME = undef;
$Mojo::Webqq::Message::Queue::GET_INTERVAL  = 3;
sub new{
    my $class  = shift;
    my $callback_for_get ;
    my $callback_for_put ;
    my $callback_for_delay ;
    my $ioloop ;
    if(@_ == 1){
        $callback_for_get = shift;
    }
    else{
        my %opt = @_;
        $callback_for_get = $opt{get};
        $callback_for_put = $opt{put};
        $callback_for_delay = $opt{delay};
        $ioloop           = $opt{ioloop};
    }
    my $self = {
        ioloop              => $ioloop,
        queue               =>  [],
        callback_for_get    =>  undef,        
        callback_for_delay  =>  undef,        
        callback_for_put    =>  undef,        
        callback_for_get_bak   =>  undef,
    };
    $self->{callback_for_get} = $callback_for_get if ref $callback_for_get eq "CODE";
    $self->{callback_for_put} = $callback_for_put if ref $callback_for_put eq "CODE";
    $self->{callback_for_delay} = $callback_for_delay if ref $callback_for_delay eq "CODE";
    return bless $self,$class;
}
sub put{
    my $self = shift;
    die "Mojo::Webqq::Message::Queue->put()失败，请检查是否已经设置了队列get()回调\n" 
        unless ref $self->{callback_for_get} eq 'CODE';
    push @{ $self->{queue} } ,$_[0]; 
    if(defined $self->{ioloop} and ref $self->{callback_for_delay} eq "CODE"){
        my $delay = 0;
        my $now = time;
        if(defined $Mojo::Webqq::Message::Queue::LAST_GET_TIME){
            $delay = $now<$Mojo::Webqq::Message::Queue::LAST_GET_TIME+$Mojo::Webqq::Message::Queue::GET_INTERVAL?
                        $Mojo::Webqq::Message::Queue::LAST_GET_TIME+$Mojo::Webqq::Message::Queue::GET_INTERVAL-$now
                    :   0;
        }
        $self->{ioloop}->timer($delay,sub{
            $self->{callback_for_delay}->($self->{queue}); 
            $self->_notify_to_get();
        });
        $Mojo::Webqq::Message::Queue::LAST_GET_TIME = $now+$delay;    
    }
    else{
        $self->_notify_to_get();
    }
}
sub get{
    my $self = shift;
    my $cb = shift;
    die "Mojo::Webqq::Message::Queue->get()仅接受一个函数引用\n" unless ref $cb eq 'CODE';
    $self->{callback_for_get} = $cb;
    $self->{callback_for_get_bak} = $cb;
}
sub _notify_to_get{
    my $self = shift;
    my $msg = shift @{$self->{queue}};
    $self->{callback_for_get}->($msg);  
}

1;
