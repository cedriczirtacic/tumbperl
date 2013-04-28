#!/usr/bin/perl

use strict;
use warnings;
use Module::Build;

my $Build = Module::Build->new(
	module_name	=> 'Tumblr::API',
	dist_abstract	=> 'A Perl client/module for the Tumblr API.',
	license		=> 'perl',
	requires	=> {
		'JSON'		=> '2.17',
		'Net::OAuth;'	=> '0.19',
	},
);

$Build->create_build_script;
