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
use HTML::Strip;

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

# Objekte, die man mal braucht
my $google_calc     = WWW::Google::Calculator->new();
my $html_cleaner    = HTML::Strip->new();

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

=head1 BEDIENUNG

    $ perl orakel.pl

=head1 BESCHREIBUNG

Orakel ist ein IRC-Bot für den Quakenet-Channel #html.de. Er dient vor allem
der Informierung, Belustigung und Erholung. Die meisten Befehle sind nur den
Channel-Operatoren zugänglich, aber auch für Normalsterbliche gibt es was.

=head1 BEFEHLSREFERENZ

=head2 Befehle für Channel-Operatoren

=over 4

=item C<?html foo> (in #html.de und im Query)

gibt mehr Informationen zum HTML4-Element B<foo>.

=item C<?html foo bar> (nur in #html.de)

gibt dem Channelbenutzer B<bar> mehr Informationen zum HTML4-Element B<foo>.

=item C<?css foo> (in #html.de und im Query)

gibt mehr Informationen zur CSS2-Eigenschaft B<foo>.

=item C<?css foo bar> (nur in #html.de)

gibt dem Channelbenutzer B<bar> mehr Informationen zur CSS2-Eigenschaft
B<foo>.

=item C<?regeln> (nur im Query)

listet alle Regeln von #html.de auf. Dieser Befehl dient zur Information
vor der Benutzung eines der unteren:

=item C<?regel 7> (in #html.de und im Query)

gibt die Regel Nr. B<7> aus.

=item C<?regel 7 foo> (nur in #html.de)

sagt dem Channelbenutzer B<foo> die Regel Nr. B<7> auf.

=item C<?google foo bar baz> (in #html.de und im Query)

führt eine Google-Suche zu den Suchbegriffen B<foo bar baz> durch und gibt
die besten drei Treffer aus.

=item C<?gc 42+17> (in #html.de und im Query)

liefert das Ergebnis des Google-Rechners zu B<42+17>.
Für geeignetes B<42+17>.

=back

=head2 Befehle für Normalsterbliche

=over 4

=item C<?html foo> (nur im Query)

gibt mehr Informationen zum HTML4-Element B<foo>.

=item C<?css foo> (nur im Query)

gibt mehr Informationen zur CSS2-Eigenschaft B<foo>.

=back

=head1 TECHNISCHES UND ABHÄNGIGKEITEN

Orakel wurde in Perl geschrieben und hat die folgenden Abhängigkeiten:

=over 4

=item perl 5.10

=item Bot::BasicBot

=item Config::Any

=item YAML

=item WWW::Google::Calculator

=item REST::Google::Search

=item URI::Escape

=back

=head1 AUTOR UND DANK

B<Mirko "memowe" Westermeier (mail@memowe.de)> hat den Bot geschrieben und
ist für Beschwerden und Anregungen der richtige Empfänger.
