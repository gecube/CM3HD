#!/usr/bin/perl
#
# amlogic-unpack-imgfile.pl, V1.01
#
# Unpack files from Amlogic's IMG update archive (AVOS update file)
#
# (C) Hajo Noerenberg 2012
#
# http://www.noerenberg.de/hajo/pub/amlogic-unpack-imgfile.pl.txt
#

use strict;

my $debug=1;

my $f=$ARGV[0];
my $d=$ARGV[1];

my $n;

sub rb {
  my ($buf, $t);
  my ($p, $l) = @_;

  seek(FS, $p, 0);
  read(FS, $buf, $l);
  $t=$buf;
  $t=~s/[^[:print:]]+/./g;;
  print "Reading " . sprintf("%6d", $l) . " bytes at offset " . sprintf("%7d", $p) . ": 0x" . sprintf("%-32s", unpack("H*", substr($buf, 0, 16))) . " (a '" . substr($t, 0, 16) . "') \n" if($debug);
  return $buf;
}

sub rl {
  my ($buf, $n);
  my ($p, $l) = @_;

  seek(FS, $p, 0);
  read(FS, $buf, $l);
  $n=unpack("L<*", $buf);
  print "Reading " . sprintf("%6d", $l) . " bytes at offset " . sprintf("%7d", $p) . ": 0x" . sprintf("%-32s", unpack("H*",$buf)) . " (l " . $n . ")\n" if ($debug);
  return $n;
}

sub rs {
  my ($buf, $n);
  my ($p, $l) = @_;

  seek(FS, $p, 0);
  read(FS, $buf, $l);
  $n=unpack("S<*", $buf);
  print "Reading " . sprintf("%6d", $l) . " bytes at offset " . sprintf("%7d", $p) . ": 0x" . sprintf("%-32s", unpack("H*",$buf)) . " (s " . $n . ")\n" if ($debug);
  return $n;
}

print ("Usage: $0 <img-file> <output-dir>\n"), exit 1 if (!$d);
open (FS, "<$f") || die("Unable to open '$f': " . $!);

print ("Invalid magic\n"), exit 1 if (rb(0, 2) ne "MI");

$n=rs(10, 2);

die("Invalid number of partitions") if ($n>42);

print "number of partitions: $n\n";

for (my $i=0; $i<$n; $i++) {
  print "\npartition table entry $i:\n";
  my $p_n=rl(12+$i*76+12, 4);
  my $d_pos=rl(12+$i*76+8, 4);
  my $d_len=rl(12+$i*76+0, 4);
  my $desc=rb(12+$i*76+32, 32);
  die("Invalid partition id") if ($p_n>42);
  print "Unpacking partition '$p_n'\n";

  open(OF, ">" . $d . "/partition-" . $p_n) || die("Unable to open output file: " . $!);
  print OF rb($d_pos, $d_len);
  close(OF);
}

close (FS);

