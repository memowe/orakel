package Orakel::Util;

use strict;
use warnings;
use feature qw( switch );
use Config::Any;
use REST::Google::Search;
use WWW::Google::Calculator;
use WWW::Google::PageRank;
use URI::Escape;
use HTML::Strip;

# Zeug exportieren
use base qw( Exporter );
our @EXPORT_OK = qw(
    $CONFIG
    glossar regel regeln
    google gcalc pagerank
);

# Konfiguration holen!
my $config_file_name = 'config.yml'; # "YAML, YAML, YAML!!!"
our $CONFIG = Config::Any->load_files({
    files           => [ "$config_file_name" ],
    use_ext         => 1,
    flatten_to_hash => 1,
})->{$config_file_name};

# rand_of wählt aus einer Liste bzw. einer Arrayref zufällig ein Element aus
sub rand_of {
    my ( $first ) = @_;
    if ( ref $first eq 'ARRAY' ) {
        my @array = @{ $first };
        return $array[ rand @array ];
    }
    else {
        return $_[ rand @_ ];
    }
}

our $google_calc    = WWW::Google::Calculator->new;
our $pageranker     = WWW::Google::PageRank->new;
our $html_cleaner   = HTML::Strip->new;

# HTML- und CSS-Glossar
sub glossar {
    my ( $type, $what ) = @_;
    return $CONFIG->{$type}{$what} // rand_of $CONFIG->{texte}{not_found};
}

# Bestimmte Regel anzeigen
sub regel {
    my ( $nr ) = @_;
    return $CONFIG->{regeln}[ $nr + 1 ] // rand_of $CONFIG->{texte}{not_found};
}

# Alle Regeln anzeigen
sub regeln {
    my $regeln = "Alle Regeln:\n";
    for my $i ( 0 .. $#{ $CONFIG->{regeln} } ) {
        $regeln .= ' #' . ( $i + 1 ) . ': ' . $CONFIG->{regeln}[$i] . "\n";
    }
    return $regeln;
}

# Google-Suche mit Anzeige der (bis zu) drei ersten Ergebnisse
sub google {
    my ( $q ) = @_;
    my $result = REST::Google::Search->new( q => $q );
    return rand_of $CONFIG->{texte}{google_search_fail}
        unless $result->responseStatus == 200;

    my $reply   = 'http://www.google.com/search?q=' . uri_escape( $q ) . "\n";
    my @results = $result->responseData->results;

    if ( @results ) {
        my $counter = 0;
        foreach my $r ( @results ) { $counter++;
            $reply .=   " #$counter: "
                        . $html_cleaner->parse( $r->title )
                        . ' (' . $r->url . ")\n";
            $html_cleaner->eof;
            last if $counter == 3;
        }
    }
    else {
        $reply .= rand_of $CONFIG->{texte}{google_no_results};
    }

    return $reply;
}

# Google-Rechner
sub gcalc {
    my ( $expr ) = @_;
    return $google_calc->calc( $expr );
}

# Google-Pagerank
sub pagerank {
    my ( $url ) = @_;
    if ( $url =~ m{^(http://|www\.)} ) { # sieht wie ein URL aus
        $url = "http://$url" if $1 eq 'www.';
        return scalar $pageranker->get( $url ); # nur den PR
    }
    else {
        return $CONFIG->{texte}{not_found};
    }
}

__END__
