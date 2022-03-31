#!/usr/bin/perl
## ============================================================================ #
#
#         FILE:  disentangle.pl
#
#        USAGE:  perl disentangle.pl [OPTIONS] <FILE> <FILE>
#
#  DESCRIPTION:  Exclude overlapping spots from multi-crystal diffraction patterns
#
#      OPTIONS:  ---
# REQUIREMENTS:  ---
#         BUGS:  ---
#        NOTES:  ---
#      LICENSE:  GPLv3
#       AUTHOR:  Soete Arne (arne.soete@irc.vib-ugent.be)
#      COMPANY:  VIB-UGent
#      VERSION:  0.1
#      CREATED:  2021-10-01
#     REVISION:
# ============================================================================ #

use strict;
use warnings;
use POSIX qw/floor/;
use Getopt::Long;
use v5.10;

# Setup
# ============================================================================ #

my $BIN_SIZE = 10;
my $BIN_OVERLAP = 2;
my $BIN_FIELD = 12;
my $MIN_DISTANCE = 10;

my $result = GetOptions (
	"bin-size=i"    => \$BIN_SIZE,
	"bin-overlap=i" => \$BIN_OVERLAP,
	"bin-field=i"   => \$BIN_FIELD,
	"distance=i"    => \$MIN_DISTANCE,
	"help"          => sub{ print STDERR hlp(); exit; }
) || die("Option parsing failed");


if( int @ARGV < 2 ) {

	print STDERR hlp();
	exit;
}

printf( 
	STDERR "BIN_SIZE=%d, BIN_OVERLAP=%d, BIN_FIELD=%d, MIN_DISTANCE=%d\n",
	$BIN_SIZE, $BIN_OVERLAP, $BIN_FIELD, $MIN_DISTANCE
);

my $left_file = $ARGV[0];
my $right_file = $ARGV[1];

# Convert files into bins of rows (lines)
my $left_bins = fileToBins($left_file);
my $right_bins = fileToBins($right_file);

my %reject_list_left = ();
my %reject_list_right = ();
my @bins = keys %{$left_bins};
my $nr_bins = int @bins;

foreach my $bin ( sort {$a <=> $b} ( @bins ) ) {

	printf( STDERR "Process BIN: %3d/%d\n", $bin, $nr_bins);

	unless ( %{$right_bins}{$bin} ) {
		printf( STDERR "No right rows for bin %d\n", $bin);
		next;
	}

	my $left_rows = %{$left_bins}{$bin};
	my $right_rows = %{$right_bins}{$bin};

	printf( STDERR "\tLeft rows: %s\n", int @{$left_rows} );
	printf( STDERR "\tRight rows: %s\n", int @{$right_rows} );

	my $rowcounter = 0;
	foreach my $lrow ( @{$left_rows} ) {

		$rowcounter++;
		printf( STDERR "\tProcessing left row: %-9d\r", $rowcounter );

		foreach my $rrow ( @{$right_rows} ) {

			my $dist = calcDist( $lrow, $rrow ) . "\n";

			if( $dist < $MIN_DISTANCE ) {

				$reject_list_left{@{$lrow}[21]} = 1;
				$reject_list_left{@{$rrow}[21]} = 1;
			}
		}
		print STDERR "                                                        \r";
	}
}

filterFile( $left_file, %reject_list_left);
filterFile( $right_file, %reject_list_right);

# ============================================================================ #
# Subroutines
# ============================================================================ #

# Remove a set of rows from an input file and write the filtered output to a
# new file: <orig_name>.filtered.<extension>
# Params:
#   - Input file path
#   - Reference to a list of rows to remove

sub filterFile  {

	my ($file, $reject_list) = @_;

	my $outfile = $file;
	$outfile =~ s/\.([^\.]+)$/.filtered.$1/;

	open(my $left_in, $file ) or die(
		"fileToBins: unable to open file ($file) for reading: $!"
	);
	open(my $left_out, '>', $outfile ) or die(
		"fileToBins: unable to open file ($outfile) for writing $!"
	);

	printf( STDERR "Writing output to %s\n", $outfile );

	while(my $line = <$left_in>) {

		if( $line =~ m/^!/ ) {

			print $left_out $line;
			next;
		}

		if( defined $reject_list_left{$.} ) {

			next;
		}

		print $left_out $line;
	}
}

# Calculate the distance between two points

sub calcDist {

	my ($l, $r) = @_;

	return sqrt(
		( @{$l}[12] - @{$r}[12] )**2
		+
		( @{$l}[13] - @{$r}[13] )**2
		+
		( @{$l}[14] - @{$r}[14] )**2
	)
}

# Parse HKL file and split into N bins based on BIN_SIZE and BIN_OVERLAP
# Return an list of rows, grouped by bin

sub fileToBins {

	my $file = shift // die( "error: fileToBins requires filename");

	open(my $fh, $file ) or die("fileToBins: unable to open file ($file) for reading: $!");

	my %lines;

	while(my $line = <$fh>) {

		chomp $line;

		if( $line =~ m/^!/ ) {
			next;
		}

		my @parts = split(" ", $line);

		# Add line number for use as line ID
		push @parts, $.;

		my $x = $parts[$BIN_FIELD];
		my $bin = floor( $x / $BIN_SIZE );
		my $from_bound = $x % $BIN_SIZE;

		$lines{ $bin } = [] unless $lines{ $bin };
		push @{$lines{ $bin }}, \@parts;

		if( $x > 0 and $from_bound <= ( $BIN_OVERLAP ) ) {

			$lines{ $bin - 1 } = [] unless $lines{ $bin - 1 };
			push @{$lines{ $bin - 1 }}, \@parts;
		}

		if( $from_bound >= ( $BIN_SIZE - $BIN_OVERLAP ) ) {

			$lines{ $bin + 1 } = [] unless $lines{ $bin + 1 };
			push @{$lines{ $bin + 1 }}, \@parts;
		}

		# print STDERR "\n";
	}
	return ( \%lines );
}

# Return the help message

sub hlp {

   return "
   USAGE:
      $0 
           [--bin-size=<int:$BIN_SIZE>] \\
           [--bin-overlap=<int:$BIN_OVERLAP>] \\
           [--bin-field=<int:$BIN_FIELD>] \\
           [--distance=<int:$MIN_DISTANCE>] \\
           <file:left.HKL> \
           <file:right.HKL>
      $0 --help

   OUTPUT
      output is written to:
      - {left}.filtered.HKL
      - {right}.filtered.HKL

   OPTIONS:
      --bin-size    : The size of the bins. (current value = $BIN_SIZE)
                      How many axis units should map into a singular bin.
                      _optional_
      --bin-overlap : The overlap of the bins (current value = $BIN_OVERLAP)
                      How many axis units should bins overlap.
                      _optional_
      --bin-field   : The column in the HKL file to use as bin input. Aka. bin
                      on this field. (current value = $BIN_FIELD)
                      _optional_
      --distance    : Consider all points duplicates when the euclidean
                      distance between two points is less than --distance.
                      (current value = $MIN_DISTANCE)
                      _optional_
   "
}
