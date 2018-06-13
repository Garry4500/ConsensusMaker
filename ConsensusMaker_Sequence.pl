use warnings;
use strict;

#Parameter

my $con = 3;
my $lucke = 'no';

#Hilfsvariablen

my @consensus;

#Einlesen von Parametern

print "Die Datei input.xfasta muss sich im Input-Verzeichnis ./Input befinden!\n";
print "Bitte Wert für Consensus eingeben\n";
$con=<STDIN>;
print "Sollen Luecken zum Consensus gezählt werden? (yes/no)\n";
$lucke=<STDIN>;

chomp $con;
chomp $lucke;

#Überprüfen, ob Wert für cons sinnvoll

if ($con eq "0" or $con eq "1")
{
    print "Wert für Consensus ohne Sinn!\n";
}

else
{

#Neue Dateien aus .xfasta Alignment erstellen
    
    my @xfasta;

    open(PUT,"./Input/input.xfasta") or die $!;
    @xfasta=<PUT>;
    close PUT;
    
    my $z = 0;
    my $y = 0;
    
    foreach $y (0 .. $#xfasta)
    {
	if ($z == 0)
	{
	    print "$xfasta[$y]\n";
	    $z = 1;
	}
	elsif ($z == 1)
	{
	    #Ausgabe Sequenz
	    open(NEWSEQ, ">./Input/input[$y].consmakeseq") or die $!;
	    print NEWSEQ "$xfasta[$y]";
	    close(NEWSEQ);
	    $z = 2;
	}
	elsif ($z == 2)
	{
	    #Ausgabe Struktur
	    open(NEWSTR, ">./Input/input[$y].consmakestr") or die $!;
	    print NEWSTR "$xfasta[$y]";
	    close(NEWSTR);
	    $z = 0;
	}
    }

    my $zahl = ( $#xfasta + 1 ) / 3;

    print "Das Alignment ummfasst $zahl Sequenzen.\n\nConsensus wird berechnet.\n\n";

#Einlesen der Dateien

    my @fileliste = glob("./Input/*.consmakeseq");
    my @data;
    my @matrix;

    foreach my $h (0 .. $#fileliste)
    {
	my @zeile;
	open(my $DATEIHANDLER, "$fileliste[$h]") or die "No files detected!\n";
	while (!eof($DATEIHANDLER))
	{
	    push (@zeile, getc($DATEIHANDLER));
	}
	close($DATEIHANDLER);
	my $ref_zeile = \@zeile;
	push (@matrix, $ref_zeile);
    }

#matrix: zweidimensionales Array mit den Daten
#Counter-Daten erstellen

    my $a = 0;
    my $t = 0;
    my $g = 0;
    my $c = 0;
    my $d = 0;

    foreach my $i (0 .. "$#{$matrix[0]}")
    {
	$a = 0;
	$t = 0;
	$g = 0;
	$c = 0;
	$d = 0;

	foreach my $k (0 .. "$#matrix")
	{
	    if (${$matrix[$k]}[$i] eq "A")
	    {
		$a = $a + 1;
	    }
	    elsif (${$matrix[$k]}[$i] eq "T")
	    {
		$t = $t + 1;
	    }
	    elsif (${$matrix[$k]}[$i] eq "G")
	    {
	        $g = $g + 1;
	    }
	    elsif (${$matrix[$k]}[$i] eq "C")
	    {
		$c = $c + 1;
	    }
	    else
	    {
		$d = $d + 1;
	    }
	}

#Consensus bauen mit den Counter-Daten ohne Beachtung von Lücken (Lücken zählen!)

	if ($lucke eq "yes")
	{

	    if ($a > $t and $a > $g and $a > $c and $a > $d and $a >= $con)
	    {
		push (@consensus, "A");
	    }
	    elsif ($t > $a and $t > $g and $t > $c and $t > $d and $t >= $con)
	    {
		push (@consensus, "T");
	    }
	    elsif ($g > $a and $g > $t and $g > $c and $g > $d and $g >= $con)
	    {
		push (@consensus, "G");
	    }
	    elsif ($c > $a and $c > $t and $c > $g and $c > $d and $c >= $con)
	    {
		push (@consensus, "C");
	    }
	    else
	    {
		push (@consensus, "-");
	    }
	}

#Consensus bauen mit Counter-Daten mit Beachtung von Lücken (Lücken zählen nicht!)

	elsif ($lucke eq "no")
	{
	    if ($a > $t and $a > $g and $a > $c and $a >= $con - $d)
	    {
		push (@consensus, "A");
	    }
	    elsif ($t > $a and $t > $g and $t > $c and $t >= $con - $d)
	    {
		push (@consensus, "T");
	    }
	    elsif ($g > $a and $g > $t and $g > $c and $g >= $con - $d)
	    {
		push (@consensus, "G");
	    }
	    elsif ($c > $a and $c > $t and $c > $g and $c >= $con - $d)
	    {
		push (@consensus, "C");
	    }
	    else
	    {
		push (@consensus, "-");
	    }
	}
	
#Überprüfen, ob $lucke yes oder no

	else
	{
	    print "yes or no!\n" and die "Abgebrochen";
	}
    }
}

#Ausgabe

my $elem1;

#!!!!! Alte Output-Datei wird überschrieben !!!!!

open(AUSGABE, ">./Output/Output.consmadeseq") or die $!;
close(AUSGABE);

for $elem1 (@consensus)
{
    open(AUSGABE, ">>./Output/Output.consmadeseq") or die $!;
    print AUSGABE "$elem1";
    close(AUSGABE);
}

print "Consensus fertig!\n\n";
