#!/usr/bin/perl -w

use strict;
use Net::Telnet ();
use Tie::File::AsHash;
use FindBin qw($Bin);
use CGI;

my $query = CGI->new;

chomp(my $maindir = $Bin || '');
die "Unable to find main directory - pioneerAmpControl.pl\n" if (!$maindir);
$maindir .= '/' if ($maindir !~ /\/$/);	# Add the trailing forward slash to the directory path if it is not there
my $cmdsfile = $maindir . 'commands.txt';
tie my %cmds, 'Tie::File::AsHash', $cmdsfile, split => '=' or die "Failed to tie \%cmds to $cmdsfile: $!\n";

chomp(my $host = $ARGV[0] // $query->param('host') // '');
errorOut(\'No host IP provided') and exit if (!$host);
if ($host =~ /help/i) {
	showOptions();
	exit;
} 
chomp(my $cmd = $ARGV[1] // $query->param('command') // '');
errorOut(\'No command provided') and exit if (!$cmd);
if ($cmd =~ /help/i) {
	showOptions();
	exit;
} 
chomp(my $res = $ARGV[2] // $query->param('response') // '');

if ($query->param('host') or $query->param('command') or $query->param('response')) {
	print $query->header();
}

my $cmdcode;

if (!exists $cmds{$cmd}) {
	print "ERROR: Command \"$cmd\" was not found in the commands list\n";
	exit;
} else {
	$cmdcode = $cmds{$cmd};
	$cmdcode =~ s/\"//g;
}

my $timeout = '10';
$timeout = '20' if ($cmd eq 'POWER_ON');
my $t = new Net::Telnet (Timeout => 10,
			 Prompt => '/\n/');

$t->open($host);
my @lines = $t->cmd(String => $cmdcode, Timeout => $timeout);

if ($res) {
	if (@lines) {
		print "Response received:\n";
		foreach my $resline (@lines) {
			print "$resline\n";
		}
	} else {
		print "No response received from command\n";
	}
}

sub errorOut {
	my ($msg) = @_;
	print "ERROR: " . $$msg . "\n";
	print "Use --help for options\n";
}

sub showOptions {
	my $data = `cat $cmdsfile` // '';
	my @lines = split("\n",$data);
print <<DATA;
------- Help -------
Usage Example:
"perl pioneerAmpControl.pl [IP_Address] [command] [(optional) RES]"

------- The optional RES command will tell the script to print out the response it got from the amp.
	Useful for debugging.
	This value can be anything! It just needs to be a third input argument to the script e.g.
	
	'perl pioneerAmpControl.pl 192.168.0.5 POWER_ON sausages'
	
	In the above example, "sausages" will cause the script to output command responses
	
------- Possible Commands -------

DATA

	foreach my $line (@lines) {
		$line =~ s/\=.*$//;
		print "$line\n";
	}
}
