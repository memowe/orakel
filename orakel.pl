#!/usr/bin/env perl

package Orakel;

=head1 NAME

Orakel - Hilfsbot für #html.de (http://www.html-q.net)

=cut

use base qw( Bot::BasicBot );

use strict;
use warnings;
use feature qw( switch );
use Config::Any;
use WWW::Google::Calculator;
use REST::Google::Search;
use URI::Escape;

# rand_of wählt aus einer Liste bzw. einer Hashref zufällig ein Element aus
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

# Konfiguration holen!
my $config_file_name = 'config.yml'; # "YAML, YAML, YAML!!!" -- YAML-Dokumentation
my $CONFIG = Config::Any->load_files({
    files           => [ $config_file_name ],
    use_ext         => 1,
    flatten_to_hash => 1,
})->{$config_file_name};

# Google-Rechner
my $google_calc = WWW::Google::Calculator->new();

# Lesen und schreiben
sub said {
    my ( $orakel, $said ) = @_;
    return unless $said->{body} =~ /^\?/;
    my $cd = $orakel->channel_data( $CONFIG->{irc}{channel} ); # Wer ist Op?

    # Mitarbeiter-Befehle
    if ( $cd->{ $said->{who} }{op} ) {

        # Befehle für Channel und Query
        given ( $said->{body} ) {

            # HTML- und CSS-Glossar
            when ( /^\?(html|css) (\w+)$/ ) {
                return $CONFIG->{$1}{$2} // rand_of $CONFIG->{texte}{not_found};
            }

            # Google-Rechner
            when ( /^\?gc (.*)/ ) {
                return $google_calc->calc( $1 );
            }

            # Regel anzeigen
            when ( /^\?regel (\d{1,2})$/ ) {
                return $CONFIG->{regeln}[ $1+1 ] // rand_of $CONFIG->{texte}{not_found};
            }
            
            # Google-Suche mit Anzeige der (bis zu) drei ersten Ergebnisse
            when ( /^\?google (.*)/ ) {
                my $result = REST::Google::Search->new( q => $1 );
                return rand_of $CONFIG->{texte}{google_search_fail}
                    unless $result->responseStatus == 200;

                my $reply   = 'http://www.google.com/search?q=' . uri_escape( $1 ) . "\n";
                my @results = $result->responseData->results;

                if ( @results ) {
                    my $counter = 0;
                    foreach my $r ( @results ) { $counter++;
                        $reply .= " #$counter: " . $r->title . ' (' . $r->url . ")\n";
                        last if $counter == 3;
                    }
                }
                else {
                    $reply .= rand_of $CONFIG->{texte}{google_no_results};
                }

                return $reply;
            }

        }

        # Befehle nur für Query
        if ( $said->{channel} eq 'msg' ) {

            given ( $said->{body} ) {
                
                # Regeln-Komplettanzeige
                when ( /^\?regeln$/ ) {
                    my $reply = "Alle Regeln:\n";
                    for my $i ( 0 .. $#{ $CONFIG->{regeln} } ) {
                        $reply .= ' #' . $i+1 . ': ' . $CONFIG->{regeln}[$i] . "\n";
                    }
                    return $reply;
                }

            }

        }

        # Befehle nur für Channel
        else {

            given ( $said->{body} ) {

                # HTML- und CSS-Glossar mit Benutzerhochlicht
                when ( /^\?(html|css) (\w+) (\S+)\s*$/ ) {
                    if ( exists $cd->{$3} and exists $CONFIG->{$1}{$2} ) {
                        return "$3: " . $CONFIG->{$1}{$2};
                    }
                    else {
                        return rand_of $CONFIG->{texte}{not_found};
                    }
                }

                # Regelanzeige mit Benutzerhochlicht
                when ( /^\?regel (\d{1,2}) (\S+)\s*$/ ) {
                    if ( exists $cd->{$2} and exists $CONFIG->{regeln}[ $1+1 ] ) {
                        return "$2: " . $CONFIG->{regeln}[ $1+1 ];
                    }
                    else {
                        return rand_of $CONFIG->{texte}{not_found};
                    }
                }

            }

        }

    }

    # Befehle für andere
    else {

        # Befehle nur für Query
        if ( $said->{channel} eq 'msg' ) {

            given ( $said->{body} ) {

                # HTML- und CSS-Glossar
                when ( /^\?(html|css) (\w+)$/ ) {
                    return $CONFIG->{$1}{$2} // rand_of $CONFIG->{texte}{not_found};
                }

            }

        }

        # Befehle nur für Channel
        else {
            return; # keine!
        }

    }

    return; # Wenn man keine Ahnung hat, einfach mal Fresse halten.
}

# Los geht's!
Orakel->new(
    server      => $CONFIG->{irc}{server},
    port        => $CONFIG->{irc}{port},
    channels    => [ $CONFIG->{irc}{channel} ],
    username    => $CONFIG->{irc}{username},
    name        => $CONFIG->{irc}{name},
    charset     => $CONFIG->{irc}{encoding},
    # Kein Nickname vorgegeben!
)->run();

__END__
