#!/usr/bin/env perl

package Orakel;

use base qw( Bot::BasicBot );

use strict;
use warnings;
use feature qw( switch );
use lib qw( lib );
use Orakel::Util qw(
    $CONFIG
    glossar regel regeln
    google gcalc pagerank
);

# Lesen und schreiben
sub said {
    my ( $orakel, $said ) = @_;
    return unless $said->{body} =~ /^\?/;
    my $cd = $orakel->channel_data( $CONFIG->{irc}{channel} ); # Wer ist Op?

    # Mitarbeiter-Befehle
    if ( $cd->{ $said->{who} }{op} ) {

        # Befehle für Channel und Query
        given ( $said->{body} ) {
            when ( /^\?(html|css) (\w+)$/ ) { return glossar( $1, $2 ) }
            when ( /^\?regel (\d{1,2})$/ )  { return regel( $1 ) }
            when ( /^\?google (.*)/ )       { return google( $1 ) }
            when ( /^\?gcalc (.*)/ )        { return gcalc( $1 ) }
            when ( /^\?pagerank (\S+)/ )    { return pagerank( $1 ) }
        }

        # Befehle nur für Query
        if ( $said->{channel} eq 'msg' ) {
            given ( $said->{body} ) {
                when ( /^\?regeln$/ )   { return regeln }
            }
        }
        # Befehle nur für Channel
        else {
            given ( $said->{body} ) {
                when ( /^\?(html|css) (\w+) (\S+)\s*$/ )    { return "$3: " . glossar( $1, $2 ) }
                when ( /^\?regel (\d{1,2}) (\S+)\s*$/ )     { return "$2: " . regel( $1 ) }
            }
        }

    }

    # Befehle für andere
    else {
        # Befehle nur für Query
        if ( $said->{channel} eq 'msg' ) {
            given ( $said->{body} ) {
                when ( /^\?(html|css) (\w+)$/ ) { return glossar( $1, $2 ) }
            }
        }
        # Befehle nur für Channel
        else {
            return; # (noch) keine!
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
