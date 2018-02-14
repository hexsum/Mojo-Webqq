my @dependent_modules = qw(
    Crypt::OpenSSL::RSA 
    Crypt::OpenSSL::Bignum
    Compress::Raw::Zlib
    IO::Compress::Gzip
    Time::HiRes
    Time::Piece
    Time::Seconds
    Digest::SHA
    Digest::MD5
    Encode::Locale
    IO::Socket::SSL
);
print "checking dependencies ...\n";
print "---------------------\n";
for my $module (@dependent_modules){
    eval "require $module";
    printf "%-30s is %s\n", $module,$@?"not ok":"ok";
}
print "---------------------\n";
print "dependencies check over\n";
