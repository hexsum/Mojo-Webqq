use 5.010001;
use ExtUtils::MakeMaker "6.46";
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Mojo::Webqq',
    VERSION_FROM      => 'lib/Mojo/Webqq.pm', # finds $VERSION
    DISTNAME            => 'Mojo-Webqq',
    LICENSE             => "perl",
    PREREQ_PM         => {
        "Compress::Raw::Zlib"   => 0,
        "Time::HiRes"           => 0,
        "Time::Piece"           => 0,
        "Time::Seconds"         => 0,
        "Digest::MD5"           => 0,
        #"Term::ANSIColor"       => 0,
        "Encode::Locale"        => 0,
        "IO::Socket::SSL"       => '1.94',
        "Mojolicious"           => '6.11',
        #"Webqq::Encryption"     => '1.5',
    }, # e.g., Module::Name => 1.1
    dist              => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Mojo-Webqq-* MANIFEST' },
    META_MERGE => {
        'meta-spec' => { version => 2 },
        resources => {     
            repository=>{
                type    => 'git',
                url     => 'git://github.com/sjdy521/Mojo-Webqq.git',
                web     =>  'https://github.com/sjdy521/Mojo-Webqq',
            },
        },
    },
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (
       #ABSTRACT_FROM  => 'lib/Webqq/Client.pm', # retrieve abstract from module
       ABSTRACT       => 'A Smartqq Client Framework base on Mojolicious',
       AUTHOR         => 'sjdy521 <sjdy521@163.com>') : ()),
);
