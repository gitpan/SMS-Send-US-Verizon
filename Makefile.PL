use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'SMS::Send::US::Verizon',
    AUTHOR              => 'Karl Lohner <karllohner+sms-send-us-verizon@gmail.com>',
    VERSION_FROM        => 'lib/SMS/Send/US/Verizon.pm',
    ABSTRACT_FROM       => 'lib/SMS/Send/US/Verizon.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More'        => 0,
        'version'           => 0,
        'LWP::UserAgent'    => 0,
        'URI::Escape'       => 0,
        'SMS::Send::Driver' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'SMS-Send-US-Verizon-*' },
);
