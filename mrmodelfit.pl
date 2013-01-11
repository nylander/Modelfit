#!/usr/bin/perl -w

#----------------------------------------------------------------#
# Script for running MRMODELTEST2 and PAUP.
# $author	= "Johan Nylander";
# $version	= "1.2";
# $date		= "2005-10-06 14:56:43";
# Usage		= 'mrmodelfit.pl filename'
# Requirements	= PAUP and MRMODELTEST2 need to be installed and be
#			in the path (called 'paup' and 'mrmodeltest2').
#			The path to the MrModeltest-block for PAUP needs to be
#			specified in the script.
# Notes		= Will create and delete files without warning.
#			 Thanks to Will Fisher for the error checking code.
# 
#----------------------------------------------------------------#

# Set path to MrModeltest-block!
$MrModeltestblock="./MrModelblock";

if (@ARGV == 0 || @ARGV > 1) {
		die "\a\nUsage: mrmodelfit.pl infile\n\nQuitting!\n\n";
}
else {
	$infile = shift @ARGV;
	# Check if mrmodeltest2 can be found
	$mrmodeltest2 = '';
	FIND_MRMODELTEST2:
	foreach (split(/:/,$ENV{PATH})) {
		if (-x "$_/mrmodeltest2") {
			$mrmodeltest2 = "$_/mrmodeltest2";
			last FIND_MRMODELTEST2;
		}
	}
	if ($mrmodeltest2 eq '') {
		die qq(\a\nCouldn\'t find executable "mrmodeltest2" (check your path).\n\n);
	}
	# Check if paup can be found
	$paup = '';
	FIND_PAUP:
	foreach (split(/:/,$ENV{PATH})) {
		if (-x "$_/paup") {
			$paup = "$_/paup";
			last FIND_PAUP;
		}
	}
	if ($paup eq '') {
		die qq(\a\nCouldn\'t find executable "paup" (check your path).\n\n);
	}
	# Build a command file for paup
	open (COMMANDS, "> paup_commands") or die "\a\nCan't open command file: $!\n\n";
	print COMMANDS "\nBEGIN PAUP;\nset warnreset=no notifybeep=no autoclose=yes;\nEND;\n";
	open (DATACONTENT, "< $infile") or die "\a\nCan't open file: $!\n\n";
	while (<DATACONTENT>) {
		print COMMANDS;
	}
	close DATACONTENT;
	open (BLOCKCONTENT, "< $MrModeltestblock") or die "\a\nCan't open the MrModelblock file: $!\n\nCheck path: $MrModeltestblock\n\n";
	while (<BLOCKCONTENT>) {
		print COMMANDS;
	}
	close BLOCKCONTENT;
	print COMMANDS "\nquit warntsave=no;";
	close COMMANDS;
	# Run PAUP
	print "\n Starting PAUP in background. Will tell when finished...\n";
	system "$paup -n paup_commands ";
	print "\n PAUP is finished.\n\n Running MrModeltest2.\n";
	# Run mrmodeltest2
	system "$mrmodeltest2 < mrmodel.scores > mfit.out";
	die "\n MrModeltest2 failure ($!) -- Saving paup_commands, modelfit.log, and mrmodel.scores files\n" unless (-s 'mfit.out');
	print " MrModeltest2 is finished.\n\n";
	print "----------------------------------------\n";
	# Remove files without warning!
	unlink "paup_commands", "mrmodel.scores", "mrmodelfit.log";
	# Find and print the selected models
	open (MFITOUT, "< mfit.out") or die "\a\nCan't open file: $!\n\n";
	while (<MFITOUT>) {
		print if /selected:/;
	}
	print "----------------------------------------\n";
	close MFITOUT;
	print "\n First model above selected using LRT\n";
	print " Second model above selected using (approx.) AIC.\n";
	print "\n Details can be found in file \"mfit.out\"\n\n";
}
exit(0);

