#!/usr/local/bin/perl -w
use strict;
use File::LineEdit;
use FileHandle;
use Test;
BEGIN { plan tests => 1 };

# variables
my ($le, $testpath, $testfile);
$testpath = 'test.txt';

# output test data
$testfile = FileHandle->new("> $testpath")
	or die "unable to open test file for write: $!";
foreach my $letter ('a' .. 'e')
	{print $testfile $letter, "\n"}
undef $testfile;

# modify test file
$le = File::LineEdit->new($testpath);
foreach my $line (@{$le->{'lines'}})
	{$line = uc($line)}
undef $le;

# read test data
$testfile = FileHandle->new($testpath)
	or die "unable to open test file for read: $!";

foreach my $line (<$testfile>) {
	chomp $line;
	unless ($line eq uc($line))
		{die 'failure'}
}

undef $testfile;
unlink($testpath)
	or die "unable to unlink test file: $!";

ok(1);
