package Bot::BasicBot::Pluggable::Module::Notes;

use strict;
use vars qw( $VERSION );
$VERSION = '0.01';

use base qw(Bot::BasicBot::Pluggable::Module);

use Carp;
use Time::Piece;

=head1 NAME

Bot::BasicBot::Pluggable::Module::Notes - A simple note collector for Bot::BasicBot::Pluggable.

=head1 SYNOPSIS

  use Bot::BasicBot::Pluggable;
  use Bot::BasicBot::Pluggable::Module::Notes::Store::SQLite;

  my $bot = Bot::BasicBot::Pluggable->new( ... );
  $bot->load( "Notes" );

  my $notes_handler = $bot->handler( "Notes" );

  $notes_handler->set_store(
    Bot::BasicBot::Pluggable::Module::Notes::Store::SQLite
       ->new( "/home/bot/brane.db" )
  );

  $notes_handler->set_notesurl( "http://example.com/irc-notes.cgi" );

  $bot->run;

=head1 DESCRIPTION

A plugin module for L<Bot::BasicBot::Pluggable> to store notes for IRC
users, these are just stuffed into a small database (SQLite store
provided) by time, user and content. Notes taken can then be later
viewed on the web using a small web app (provided).

=head1 METHODS

=over 4

=cut

sub help {
    my $self = shift;
    my $helptext = "Simple Note collector for Bot::BasicBot::Pluggable.  Requires direct addressing.  Usage: 'note to self: Put this on the TODO list: Fix Bot docs'.";
    my $notesurl = $self->{notesurl};
    $helptext .= "  The Notes can be viewed at $notesurl" if $notesurl;
    return $helptext;
}

sub told {
    my ($self, $mess) = @_;
    return unless $mess->{address}; # require direct addressing
    my $store = $self->{store}
      or return "Error: no store configured.";

    my $body = $mess->{body};
    my $who  = $mess->{who};
    my $channel = $mess->{channel};

    if(!($body =~ s/^note to self:\s*//)) {
        ## Ignore anything that doesnt start with "note to self:"
        return;
    }

    my $now = localtime;
    my $timestamp = $now->strftime("%Y-%m-%d %H:%M:%S");

    my $res = $store->store( timestamp => $timestamp,
                   name      => $who,
                   channel   => $channel,
                   notes     => $body,
        );

#    $self->{Bot}->say( who => $who,
#                       channel => "msg",
#                       body    => "Stored URL '$url'"
#                                 . ($comment ? " and comment '$comment'" : "" )
#    );
    return; # nice quiet bot
}

=item B<set_store>

  my $notes_store =
    Bot::BasicBot::Pluggable::Module::Notes::Store::SQLite->new(
      "/home/bot/brane.db" );
  $notes_handler->set_store( $notes_store );

Supply a C<Bot::BasicBot::Pluggable::Module::Notes::Store::*> object.

=cut

sub set_store {
    my ($self, $store) = @_;
    croak "ERROR: No store specified" unless $store;

    $self->{store} = $store;
    return $self;
}

=item B<set_notesurl>

  $notes_handler->set_notesurl( "http://example.com/irc-notes.cgi" );

Supply the URL for your CGI/App script to view the stored Notes.

=cut

sub set_notesurl {
    my ($self, $notesurl) = @_;
    croak "ERROR: No notesurl specified" unless $notesurl;
    $self->{notesurl} = $notesurl;
    return $self;
}

=head1 EXAMPLES

  use strict;
  use warnings;
  use Bot::BasicBot::Pluggable;

  my $bot = Bot::BasicBot::Pluggable->new(channels => [ "#test" ],
                                          server   => "irc.example.com",
                                          port     => "6667",
                                          nick     => "bot",
                                          username => "bot",
                                          name     => "bot",
                                         );
  $bot->load( "Notes" );

  my $notes_handler = $bot->handler( "Notes" );

  $notes_handler->set_store(
    Bot::BasicBot::Pluggable::Module::Notes::Store::SQLite
       ->new( "/home/bot/brane.db" )
  );

  $notes_handler->set_notesurl( "http://example.com/irc-notes.cgi" );

  $bot->run;

Yes, this is your entire program.

The file supplied as an argument to the constructor of
L<Bot::BasicBot::Pluggable::Module::Notes::Store::SQLite> need
not already exist; it will be created and the correct database schema
set up as necessary.

Talk to the bot on IRC for help:

  17:37 <nou> notesbot: help Notes
  <notesbot> nou: Simple Note collector for Bot::BasicBot::Pluggable.
      Requires direct addressing.  Usage:
      'note to self: Here's something for later'.  The Notes can be viewed at
      http://example.com/irc-notes.cgi

Get stuff out of the database in your favoured fashion, for example:

  use strict;
  use warnings;
  use CGI;
  use DBI;

  my $sqlite_db = "/home/bot/brane.db";
  my $q = CGI->new;
  my $dbh = DBI->connect("dbi:SQLite:dbname=$sqlite_db", "", "")
    or die DBI->errstr;

  print $q->header;
  print <<EOF;

  <html>
  <head><title>notes</title></head>
  <body><h1 align="center">notes</h1>

  EOF

  my $sql = "SELECT timestamp, name, channel, notes FROM notes
             ORDER BY timestamp DESC";
  my $sth = $dbh->prepare($sql) or die $dbh->errstr;
  $sth->execute;
  my ($timestamp, $name, $channel, $notes);

  while ( ($timestamp, $name, $channel, $notes)
                                          = $sth->fetchrow_array ) {
      print "<br><i>$timestamp</i>: <b>$name/$channel</b>: ";
      print "$notes<br>";
  }

  print "</body></html>\n";

=head1 BUGS

More tests would be nice.

=head1 NOTES

Module shamelessly stolen and slightly modified from L<Bot::BasicBot::Pluggable::Module::SimpleBlog> by Kake.

=head1 TODO

Many things: Include web interface, have bot repeat back stored things, parse/store tags..

=head1 SEE ALSO

=over 4

=item * L<Bot::BasicBot::Pluggable>

=item * L<Bot::BasicBot::Pluggable::Module::Notes::Store::SQLite>

=back

=head1 AUTHOR

Jess Robinson <castaway@desert-island.me.uk>

=head1 COPYRIGHT

This module is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=head1 CREDITS

=cut

1;
