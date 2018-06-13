# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl https.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';
sub https_test{
    use Mojo::UserAgent;
    my $ua = Mojo::UserAgent->new;
    $ua->proxy->detect;
    $ua->transactor->name("Mozilla/5.0 (Windows NT 6.1) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/39.0.2171.65");
    my $tx = $ua->get('https://www.baidu.com');
    if (my $res = $tx->success) { return $res->code }
    else {
        my $err = $tx->error;
        die "$err->{code} response: $err->{message}" if $err->{code};
        die "Connection error: $err->{message}";
    } 
}
use Test::More tests => 1;
ok( https_test()== 200,"https support");

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.
