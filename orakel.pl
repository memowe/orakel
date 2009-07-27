#!/usr/bin/env perl

package Orakel;
use base qw( Bot::BasicBot );

use strict;
use warnings;
use feature qw( switch );
use Config::Any;
use WWW::Google::Calculator;

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
my $config_file_name = 'config.yml';
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
            when ( /^\?(html|css) (\w+)$/ ) { # HTML- und CSS-Glossar
                return $CONFIG->{$1}{$2} // rand_of $CONFIG->{texte}{not_found};
            }
            when ( /^\?gc (.*)/ ) { # Google-Rechner
                return $google_calc->calc( $1 );
            }
            when ( /^\?regel (\d{1,2})$/ ) {
                return $CONFIG->{regeln}[ $1+1 ] // rand_of $CONFIG->{texte}{not_found};
            }
        }

        # Befehle nur für Query
        if ( $said->{channel} eq 'msg' ) {

            given ( $said->{body} ) {
                when ( /^\?regeln$/ ) { # Regeln-Komplettanzeige
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
                when ( /^\?(html|css) (\w+) (\S+)\s*$/ ) {
                    if ( exists $cd->{$3} and exists $CONFIG->{$1}{$2} ) {
                        return "$3: " . $CONFIG->{$1}{$2};
                    }
                    else {
                        return rand_of $CONFIG->{texte}{not_found};
                    }
                }
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
                when ( /^\?(html|css) (\w+)$/ ) { # HTML- und CSS-Glossar
                    return $CONFIG->{$1}{$2} // rand_of $CONFIG->{texte}{not_found};
                }
            }
        }

        # Befehle nur für Channel
        else {
            return; # keine!
        }

    }

    return; # Sag nichts, wenn Du nicht gemeint bist.
}

# Los geht's!
Orakel->new(
    server      => $CONFIG->{irc}{server},
    port        => $CONFIG->{irc}{port},
    channels    => [ $CONFIG->{irc}{channel} ],
    username    => $CONFIG->{irc}{username},
    name        => $CONFIG->{irc}{name},
    charset     => $CONFIG->{irc}{encoding},
    # Kein Nickname!
)->run();

__END__
