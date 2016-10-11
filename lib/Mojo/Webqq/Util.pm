package Mojo::Webqq::Util;
use Mojo::Webqq::Counter;
use Mojo::Util qw();
sub new_counter {
    my $self = shift;
    return Mojo::Webqq::Counter->new(client=>$self,@_);
}
sub url_escape {
    my $self = shift;
    return Mojo::Util::url_escape(@_);
}

sub slurp {
    my $self = shift;
    return Mojo::Util::slurp(@_);
}
sub spurt {
    my $self = shift;
    return Mojo::Util::spurt(@_);
}
sub encode{
    my $self = shift;
    return Mojo::Util::encode(@_);
}
sub decode{
    my $self = shift;
    return Mojo::Util::decode(@_);
}

sub encode_utf8{
    my $self = shift;
    return Mojo::Util::encode("utf8",@_);
}

1;
