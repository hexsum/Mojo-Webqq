package Mojo::Webqq::Counter;
use POSIX qw();
use Mojo::Util qw(md5_sum);
sub new{
    my $class = shift;
    my %p = @_;
    my $self = {
        id     => $p{id} || md5_sum(rand),
        period => $p{period} || 600,
        client => $p{client},
        slot   => {},
    };
    if(defined $self->{client}){
        $self->{client}->add_job("Counter <$self->{id}> Reset","00:00:00",sub{$self->reset()});
    }
    bless $self,(ref $class) || $class;
}
sub count {
    my $self = shift;
    my $key = shift;
    my $ts = shift ;
    my $start = POSIX::mktime(0,0,0,(localtime)[3,4,5]);
    if(defined $ts){
        return if time - $ts > $self->{period};
        return if $ts-$start <0;
    }
    else{ $ts = time; }
    my $slot = int(($ts-$start)/$self->{period});
    $self->{slot}{$key}[$slot]++;
    return $self;
}
sub look{
    my $self = shift;
    my $key = shift;
    my $start = POSIX::mktime(0,0,0,(localtime)[3,4,5]);
    my $slot = int((time-$start)/$self->{period});
    return defined $self->{slot}{$key}[$slot]?0+$self->{slot}{$key}[$slot]:0;
}
sub check {
    my $self = shift;
    $self->count(@_);
    return $self->look(@_);
}
sub reset{
    my $self = shift;
    $self->{slot} = {};
    return 1;
}
sub clear {
    my $self = shift;
    my $key =  shift;
    delete $self->{slot}{$key};
    return 1;
}
1;
