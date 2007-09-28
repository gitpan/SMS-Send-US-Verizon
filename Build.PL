use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'SMS::Send::US::Verizon',
    license             => 'perl',
    dist_author         => 'Karl Lohner <karllohner+sms-send-us-verizon@gmail.com>',
    dist_version_from   => 'lib/SMS/Send/US/Verizon.pm',
    requires => {
        'Test::More'        => 0,
        'version'           => 0,
        'LWP::UserAgent'    => 0,
        'URI::Escape'       => 0,
        'SMS::Send::Driver' => 0,
    },
    add_to_cleanup      => [ 'SMS-Send-US-Verizon-*' ],
);

$builder->create_build_script();
