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
    my $cd = $orakel->channel_data( $CONFIG->{irc}{channel} );

    if ( $cd->{ $said->{who} }{op} ) { # Ein Mitarbeiter!

        given ( $said->{body} ) {
            when ( /^\?(html|css) (.*)/ ) {
                return $CONFIG->{$1}{$2} // rand_of $CONFIG->{texte}{not_found};
            }
            when ( /^\?gc (.*)/ ) {
                return $google_calc->calc( $1 );
            }
            default { return }
        }

    }
    else { # Kein Mitarbeiter!

        if ( $said->{channel} eq 'msg' ) { # Nur im Query
            given ( $said->{body} ) {
                when ( /^\?(html|css) (.*)/ ) {
                    return $CONFIG->{$1}{$2} // rand_of $CONFIG->{texte}{not_found};
                }
                default { return }
            }
        }
        else {
            return;
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
