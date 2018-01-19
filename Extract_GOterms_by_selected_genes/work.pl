#!/usr/bin/perl
#use strict;
#use POSIX;  # use floor to get the floor value for a number
use String::Util qw(trim); # trim leading and trailing space; sudo cpan String::Util to install it
use Text::CSV; #sudo cpan Text::CSV to install it
use warnings;
my @files = glob('./*.xls');

my $keyFile = $ARGV[0] or die "key file needs to be specified on the command line\n";
foreach $file (@files) { 
  print "Processing $file...\n";
  my $dataFile = $file or die "data file needs to be specified on the command line\n";
  my $outFile = $file."\.csv";
#--
  my @keys;
  my $csvKeys = Text::CSV->new ( { binary => 1 } )  # should set binary attribute.
                 or die "Cannot use CSV: ".Text::CSV->error_diag ();

  open my $keyFH, "<", $keyFile or die "$keyFile: $!";
  while ( my $key = $csvKeys->getline( $keyFH ) ) {
     push @keys, trim($key->[0]);
  }
  $csvKeys->eof or $csvKeys->error_diag();
  close $keyFH;

#-- 
 my @rows;
 my $csv = Text::CSV->new ( {quote_char  => undef,
                             escape_char => undef,
                             sep_char => "\t", 
                             binary => 1 } )  # should set binary attribute.
                 or die "Cannot use CSV: ".Text::CSV->error_diag ();

 open my $fh, "<:encoding(utf8)", $dataFile or die "$dataFile: $!";
 open my $outF, ">", $outFile or die "$outFile: $!";
 print $outF "Description,GeneRatio, BgRatio, pvalue, Gene/Bg, geneID\n";
 $csv->getline( $fh ); # get rid of first row 
 my $count =0;
 my $rIndex = 1;
 while ( my $row = $csv->getline( $fh ) ) {
      my $isPrinted;
      $isPrinted = 0;
      my $outputLine;
      $outputLine = 0;
#     $row->[2] =~ m/pattern/ or next; # 3rd field should match
      my @geneID = split/\//,$row->[7];     
      foreach my $geneID (@geneID) {
        foreach my $key (@keys) {
            my $geneID0 = $geneID;
            chop($geneID0); # remove the last character
            my $key0 = $key;
            chop($key0);    # remove the last character
            if ($geneID =~ /^\Q$key\E$/) { #perfect Match
                $outputLine = 1;
                if ($isPrinted==0) {
                   $rIndex =$rIndex+1;
                   print $outF $row->[1]." ,=".$row->[2].",=".$row->[3].", ".$row->[4]. ",=B".$rIndex."/C".$rIndex.", "; 
                   $isPrinted = 1;
                }
                #print "$geneID:$key". ",";
                print $outF "$geneID". ";";
            } elsif ($geneID0 =~/^\Q$key0\E$/) {  # last character is different
                next;
                $outputLine = 1;
                if ($isPrinted==0) {
                   #print $row->[0]." ,".$row->[1].", "; 
                   print $outF $row->[1]." ,=".$row->[2].",=".$row->[3].", ".$row->[4]. ", "; 
                   $isPrinted = 1;
                }
                print $outF "2:$geneID:$key". ",";
            } elsif ((length($geneID)==length($key0)+1) && 
                     index($geneID,$key0)== 0) {#key is a substring of $geneID
                next;
                $outputLine = 1;
                if ($isPrinted==0) {
                   #print $row->[0]." ,".$row->[1].", "; 
                   print $outF $row->[1]." ,=".$row->[2].",=".$row->[3].", ".$row->[4]. ", "; 
                   $isPrinted = 1;
                }
                print $outF "3:$geneID:$key". ",";
            } elsif ((length($key)==length($geneID0)+1) && 
                     index($key,$geneID0)== 0) {#geneID is a substring of $key
                next;
                $outputLine = 1;
                if ($isPrinted==0) {
                   #print $row->[0]." ,".$row->[1].", "; 
                   print $outF $row->[1]." ,=".$row->[2].",=".$row->[3].", ".$row->[4]. ", "; 
                   $isPrinted = 1;
                }
                print $outF "4:$geneID:$key". ",";
            } else {}
        }
     }
     if ($outputLine==1) {
            print $outF "\n"; 
     }
     push @rows, $row;
 }
 $csv->eof or $csv->error_diag();
 close $fh;
 close $outF;
}
