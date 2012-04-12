#!/usr/bin/perl
# Write stuff here

use strict;
use warnings;
use lib './lib';
use lbmap::lbmap;
use Data::Dumper;

# Handle usage
&show_help unless $ARGV[0];
&banner;
my $lbmap = lbmap::lbmap->new;
#my %result = %{ $lbmap->scan($ARGV[0]) };
my %result = $lbmap->scan($ARGV[0]);
print "Loadbalancer: $result{'loadbalancer'}\n";
print "WAF: $result{'WAF'}\n";
print "Backends: ".join "\n", keys(%{ $result{'backends'} });
print "\nSignature: $result{'signature'}\n";

sub show_help {
    print "Usage $0 http://somehost/\n";
    exit;
}

sub banner {
    print "lbmap - http fingerprinting tool\n";
    print "(C) Wireghoul - Scanning $ARGV[0]\n";
}