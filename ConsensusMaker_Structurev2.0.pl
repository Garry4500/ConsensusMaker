use warnings;
use strict;

#Dieses Programm läuft komplett ohne Garantie!
#Geschrieben von Gerrit Wehner, gerrit.wehner@stud-mail.uni-wuerzburg.de

#Parameter

my $con;
my $lucke;

#Hilfsvariablen

my @consensus;
my @matrix;

#Einlesen von Parametern

print "Die Datei input.xfasta muss sich im Input-Verzeichnis ./Input befinden!\n\n";
print "Bitte Wert für Consensus eingeben: ganzzahliger Wert >50.\n";
$con=<STDIN>;
print "Sollen Luecken zum Consensus gezählt werden? (yes/no)\n";
$lucke=<STDIN>;

chomp $con;
chomp $lucke;

#Überprüfen, ob Wert für cons sinnvoll

if ($con < 51)
{
    print "\nDieser Consensus ist nicht möglich.\n\n"; 
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

    print "Das Alignment ummfasst $zahl Sequenzen.\n\nConsensus wird berechnet.\n";

#Einlesen der Dateien

    my @fileliste = glob("./Input/*.consmakestr");
    my @data;

    foreach my $h (0 .. $#fileliste)
    {
	my @zeile;
	@zeile = ();
	open(my $DATEIHANDLER, "$fileliste[$h]") or die "No files detected!\n";
	while (!eof($DATEIHANDLER))
	{
	    push (@zeile, getc($DATEIHANDLER));
	}
	close($DATEIHANDLER);
	my $ref_zeile = \@zeile;
	push (@matrix, $ref_zeile);
    }

#Lücken bei Bedarf entfernen (nicht korrekt)

    if ($lucke eq "no")
    {
	foreach my $l (0 .. "$#{$matrix[0]}")
	{
	    foreach my $z (0 .. "$#matrix")
	    {
		if (${$matrix[$z]}[$l] eq "-")
		{
		    foreach my $y (0 .. "$#{$matrix[0]}")
		    {
			splice(${matrix[$y]},$z,$z);
		    }
		}
	    }
	}
    }
    if ($lucke ne "no")
    {
	if ($lucke ne "yes")
	{
	print "Yes or No!" and die;
	}
    }

#matrix: zweidimensionales Array mit den Daten
#strukturmatrix: zweidimensionales Array mit Zahlenwerten für Zugehörigkeit der Klammern

    my @strukturmatrix;
    
    foreach my $t (0 .. "$#matrix")
    {
	my $j = 0;
	my @struktur;
	@struktur = ();
	
	foreach my $m (0 .. "$#{$matrix[0]}")
	{
	    if (${$matrix[$t]}[$m] eq "(")
	    {
		$j = $j + 1;
		push (@struktur, "$j");
	    }
	    elsif (${$matrix[$t]}[$m] eq ")")
	    {
		push (@struktur, "$j");
		$j = $j - 1;
	    }
	    elsif (${$matrix[$t]}[$m] eq "." or ${$matrix[$t]}[$m] eq "-")
	    {
		push (@struktur, "0");
	    }
	}

	my $ref_struktur = \@struktur;
	push (@strukturmatrix, $ref_struktur);
	
    }

#indexmatrix: zweidimensionales Array mit Indices für zugehörige Klammern
    
    my @indexmatrix;
    my @indexzumatrix;
    
    foreach my $n (0 .. "$#matrix")
    {
	my @index;
	my @indexzu;
	my $in;
	my $out;
	@index = ();
	@indexzu = ();
	
	foreach my $o (0 .. "$#{$matrix[0]}")
	{
	    if (${$matrix[$n]}[$o] eq ".")
	    {
		push (@index, "0");
		push (@indexzu, "-");
	    }
	    elsif (${$matrix[$n]}[$o] eq "-")
	    {
		push (@index, "0");
		push (@indexzu, "-");
	    }
	    elsif (${$matrix[$n]}[$o] eq "(")
	    {
		my $oa = $o + 1;

		foreach my $p ($oa .. "$#{$strukturmatrix[0]}")
		{
		    if (${$strukturmatrix[$n]}[$p] eq ${$strukturmatrix[$n]}[$o])
		    {
			$in = $p;
			last;
		    }
		}
		
		push (@index, "$o,$in");
		push (@indexzu, "(");

	    }
	    elsif (${$matrix[$n]}[$o] eq ")")
	    {
		my $ob = $o - 1;

		foreach my $q (reverse 0 .. $ob)
		{
		    if (${$strukturmatrix[$n]}[$q] eq ${$strukturmatrix[$n]}[$o])
		    {
			$out = $q;
			last;
		    }
		}
		
		push (@index, "$out,$o");
		push (@indexzu, ")");

	    }
	}
	
	my $ref_index = \@index;
	push (@indexmatrix, $ref_index);
	my $ref_indexzu = \@indexzu;
	push (@indexzumatrix, $ref_indexzu);

    }

#Consensus auf Grundlage der @indexmatrix und @matrix erstellen
#Häufigkeit eines Index innerhalb einer Spalte bestimmen
#Häufigkeit einer Klammerart innerhalb einer spalte bestimmen

    foreach my $r (0 .. "$#{$indexmatrix[0]}")
    {
	my %haufigkeit = ();
	my @interim;
	my %haufigkeitzu = ();
	my @interimzu;

	foreach my $s (0 .. "$#indexmatrix")
	{
	    push (@interim, "${$indexmatrix[$s]}[$r]");
	}
	foreach my $elem (@interim)
	{
	    $haufigkeit{$elem}++;
	}

	my @most = (sort{$haufigkeit{$b} <=> $haufigkeit{$a}} keys %haufigkeit);

#$most[0] häufigster Wert
#$hash{$most[0]} Häufigkeit
#Häufigkeit mit Zeilenanzahl vergleichen und mit $con verrechnen

	my $prozent = ( 100 * $haufigkeit{$most[0]} / $zahl );
	my @mostzu;

	if ($prozent < $con)
	{
	    push (@consensus, ".");
	}
	elsif ($prozent >= $con)
	{
	    if ($most[0] eq "0")
	    {
		push (@consensus, ".");
	    }
	    else
	    {
		foreach my $v (0 .. "$#indexzumatrix")
		{
		    push (@interimzu, "${$indexzumatrix[$v]}[$r]");
		}
		foreach my $elemzu (@interimzu)
		{
		    $haufigkeitzu{$elemzu}++;
		}
		    
		@mostzu = (sort{$haufigkeitzu{$b} <=> $haufigkeitzu{$a}} keys %haufigkeitzu);
		if ("$mostzu[0]" eq "(")
		{
		    push (@consensus, "(");
		}
		elsif ("$mostzu[0]" eq ")")
		{
		    push (@consensus, ")");
		}
	    }
	}
    }	    

#Ausgabe
#!!!!! Alte Output-Datei wird überschrieben !!!!!

    open(AUSGABE, ">./Output/Output.consmadestr") or die;
    close(AUSGABE);

    for my $elem1 (@consensus)
    {
	open(AUSGABE, ">>./Output/Output.consmadestr") or die;
	print AUSGABE "$elem1";
	close(AUSGABE);
    }
    
    print "\nConsensus fertig!\n\n";

}
