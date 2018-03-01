my %dependent_modules = (
    'Crypt::OpenSSL::RSA'       => undef,
    'Crypt::OpenSSL::Bignum'    => undef,
    'Compress::Raw::Zlib'       => undef,
    'IO::Compress::Gzip'        => undef,
    'Time::HiRes'               => undef,
    'Time::Piece'               => undef,
    'Time::Seconds'             => undef,
    'Digest::SHA'               => undef,
    'Digest::MD5'               => undef,
    'Encode::Locale'            => undef,
    'IO::Socket::SSL'           => undef,
    'Term::ANSIColor'           => undef,
);
print "Checking dependencies ...\n";
print "--------------------------------\n";
for my $module (keys %dependent_modules){
    eval "require $module";
    $dependent_modules{$module} = $@?0:1;
    printf "%-25s is %s\n", $module,$@?"not ok":"ok";
}
print "--------------------------------\n";
printf "Check result: %d/%d\n",scalar(grep {$dependent_modules{$_}==1} keys %dependent_modules),scalar(keys %dependent_modules);
if( scalar(grep {$dependent_modules{$_}==0} keys %dependent_modules) == 0){
    print "Congratulations, all dependencies is ok\n";
}
else{
    print "The below dependence is not found:\n\n";
    for(grep {$dependent_modules{$_}==0} keys %dependent_modules){
        print "$_\n";
    }
    print "\n";
    print "You need to install these missing modules by do this command: \n\n";
    print "    cpanm " . join(" ",grep {$dependent_modules{$_}==0} keys %dependent_modules) . "\n";
    print "\n";

    print "If you are using Centos, yum is the recommended way which is efficient and reliable:\n\n";
    print "    yum -y install " . join(" ",map {s/::/-/g;"perl-" . $_ } grep {$dependent_modules{$_}==0} keys %dependent_modules) . "\n";
    print "\n";
}
