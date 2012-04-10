#!/usr/bin/perl

use warnings;
use strict;
use lib './lib';
use lbmap::Signature;
use IO::Socket::INET;
use IO::Socket::SSL;
use lbmap::Requests;
use lbmap::lbmap;

local $SIG{ALRM} = sub { die "TIMEOUT\n"; };
my $sock;
my $sig = lbmap::Signature->new();
my $reqs = lbmap::Requests->new();
my $lbmap = lbmap::lbmap->new();

if (!$ARGV[0]) {
	print "Usage $0 http://url/\n";
	exit 1;
}
my ($ssl, $server, $port) = $lbmap->_parse_uri($ARGV[0]);
print "[*] SERVER> $server - ";
my $runs = "Unknown";
$sock = IO::Socket::INET->new(PeerAddr => "$server:$port", Timeout => 10) or warn "Unable to connect to $server:$port\n";
if ($sock) {
	alarm 20;
	eval {
		my $r = '';
		print $sock "GET / HTTP/1.1\r\nHost: $server\r\nConnection: Close\r\n\r\n";
		while (<$sock>) {
			if ($_ =~ /^Server: (.*)/) {  $runs = "$1\n"; }
			if ($_ =~ /^Via: (.*)/) { $runs .= "$_"; }
			if ($_ =~ /^proxy(.*)/i) { $runs .= "$_"; }
			$r .= $_;
		}
		if ($r eq '') { warn "Empty first response\n"; }
		$sig->add_response($r);
	};
	alarm 0;
	if ($@) {
		die unless ( $@ eq "TIMEOUT\n" );
	}
}
print "$runs\n";
while ($reqs->next) {
	$sock = IO::Socket::INET->new("$server:$port") or warn "Unable to connect to $server:$port\n";
	if ($sock) {
		alarm 20;
		eval {
			my $r = '';
			print $sock $reqs->request."\r\nConnection: Close\r\n\r\n";
			print "[-] ".$reqs->request."\n[*] " if $ENV{'debug'}; #need to s/\n/\\r/ etc..
			while (<$sock>) {
				$r.= $_;
				if ($_ =~ /HTTP\/\d\.\d \d\d\d /) { 
					chomp($_);
					print "$_\n" if $ENV{'debug'}; 
				}
			}
			#if ($r eq '') { warn "Empty response for ".$reqs->request."\n"; }
			$sig->add_response($r);
		};
		alarm 0;
		if ($@) {
			if ( $@ eq "TIMEOUT\n" ) {
				$sig->add_timeout();
				warn "TIMEOUT\n";
			} else {
				die $@;
			}
		} 
		#print "\n";
		close($sock) or warn "Unable to close socket: $!\n";
	} else {
		print "N/A\n";
	}
}
print $sig->signature();
