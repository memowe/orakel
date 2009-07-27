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
            when ( /^\?/ ) { return }
            default { return }
        }

        # Befehle nur für Query
        if ( $said->{channel} eq 'msg' ) {

            given ( $said->{body} ) {
                when ( /^\?regeln$/ ) { # Regeln-Komplettanzeige
                    my $reply = "Alle Regeln:\n";
                    for my $i ( 0 .. $#{ $CONFIG->{regeln} } ) {
                        $reply .= "#$i: " . $CONFIG->{regeln}[$i] . "\n";
                    }
                    return $reply;
                }
                default { return }
            }

        }

        # Befehle nur für Channel
        else {
            when ( /^\?(html|css) (\w+) (\S+)$/ and exists ${ $cd->{$3} } ) {
                return "$2: " . ( $CONFIG->{$1}{$2} // rand_of $CONFIG->{texte}{not_found} );
            }
            default { return }
        }

    }
    # Befehle für andere
    else {

        # Befehle nur für Query
        if ( $said->{channel} eq 'msg' ) {
            given ( $said->{body} ) {
                when ( /^\?(html|css) (.*)/ ) {
                    return $CONFIG->{$1}{$2} // rand_of $CONFIG->{texte}{not_found};
                }
                default { return }
            }
        }

        # Befehle nur für Channel
        else {
            return; # keine!
        }

    }
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
