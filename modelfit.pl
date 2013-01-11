#!/usr/bin/perl -w
#----------------------------------------------------------------#
# Script for running MODELTEST and PAUP.
# $author	= "Johan Nylander";
# $version	= "1.2";
# $date		= "2005-10-06 14:56:29";
# Usage		= 'modelfit.pl filename'
# Requirements	= PAUP and MODELTEST need to be installed and be
#			in the path (called 'paup' and 'modeltest').
#			The path to the Modeltest-block for PAUP needs to be
#			specified in the script.
# Notes		= Will create and delete files without warning.
#			 Thanks to Will Fisher for the error checking code.
# 
#----------------------------------------------------------------#

# Set path to modeltest-block!
$Modeltestblock="./modelblock";

if (@ARGV == 0 || @ARGV > 1) {
	die "\a\nUsage: modelfit.pl infile. Quitting!\n\n";
}
else {
	my $infile = shift @ARGV;
	# Check if modeltest can be found
	my $modeltest = '';
	FIND_MODELTEST:
	foreach (split(/:/,$ENV{PATH})) {
		if (-x "$_/modeltest") {
			$modeltest = "$_/modeltest";
			last FIND_MODELTEST;
		}
	}
	if ($modeltest eq '') {
		die qq(\a\nCouldn't find executable "modeltest" (check your path).\n\n);
	}
	# Check if paup can be found
	my $paup = '';
	FIND_PAUP:
	foreach (split(/:/,$ENV{PATH})) {
		if (-x "$_/paup") {
			$paup = "$_/paup";
			last FIND_PAUP;
		}
	}
	if ($paup eq '') {
		die qq(\a\nCouldn't find executable "paup" (check your path).\n\n);
	}
	# Build a command file for paup
	open (COMMANDS, "> paup_commands") or die "\a\nCan't open command file: $!\n\n";
	print COMMANDS "\nBEGIN PAUP;\nset warnreset=no notifybeep=no autoclose=yes;\nEND;\n";
	open (DATACONTENT, "< $infile") or die "\a\nCan't open file: $!\n\n";
	while (<DATACONTENT>) {
		print COMMANDS;
	}
	close DATACONTENT;
	open (BLOCKCONTENT, "< $Modeltestblock") or die "\a\nCan't open the Modelblock file: $!\n\nCheck path: $Modeltestblock\n\n";
	while (<BLOCKCONTENT>) {
		print COMMANDS;
	}
	close BLOCKCONTENT;
	print COMMANDS "\nquit warntsave=no;";
	close COMMANDS;
	# Run PAUP
	print "\n Starting PAUP in background. Will tell when finished...\n";
	system "$paup -n paup_commands > /dev/null";
	print "\n PAUP is finished.\n\n Running MODELTEST.\n\n";
	# Run modeltest
	system "$modeltest < model.scores > mfit.out";
	die "\n MODELTEST failure ($!) -- Saving paup_commands, modelfit.log, and model.scores files\n" unless (-s 'mfit.out');
	# Remove files without warning!
	unlink "paup_commands", "model.scores", "modelfit.log";
	# Find and print the selected models
	open (MFITOUT, "< mfit.out") or die "\a\nCan't open file: $!\n\n";
	while (<MFITOUT>) {
		print if /selected:/;
	}
	close MFITOUT;
	print "\n First model above selected using LRT\n";
	print " Second model above selected using (approx.) AIC.\n";
	print "\n Details can be found in file \"mfit.out\"\n\n";
}
exit(0);

