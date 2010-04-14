package Bot::BasicBot::Pluggable::Module::Notes::Store::SQLite;

use strict;
use vars qw( $VERSION );
$VERSION = '0.02';

# use base qw(Bot::BasicBot::Pluggable::Module);

use Carp;
use DBD::SQLite;

=head1 NAME

Bot::BasicBot::Pluggable::Module::Notes::Store::SQLite - SQLite storage for Bot::BasicBot::Pluggable::Module::Notes.

=head1 SYNOPSIS

  use Bot::BasicBot::Pluggable::Module::Notes::Store::SQLite;

  my $blog_store =
    Bot::BasicBot::Pluggable::Module::Notes::Store::SQLite->new(
      "/home/bot/brane.db" );

=head1 DESCRIPTION

Store notes in a sqlite database for
L<Bot::BasicBot::Pluggable::Module::Notes>.

=head1 METHODS

=over 4

=item B<new>

  my $blog_store =
    Bot::BasicBot::Pluggable::Module::Notes::Store::SQLite->new(
      "/home/bot/brane.db" );

You must supply a filename writeable by the user the bot runs as. The
file need not already exist; it will be created and the correct
database schema set up as necessary.

Croaks if L<DBD::SQLite> fails to connect to the file.

=cut

use constant TABLENAME => 'notes';

sub new {
    my ($class, $filename) = @_;

    my $dbh = DBI->connect("dbi:SQLite:dbname=$filename", "", "")
      or croak "ERROR: Can't connect to sqlite database: " . DBI->errstr;

    my $self = { };
    bless $self, $class;

    $self->{dbh} = $dbh;
    $self->ensure_db_schema_correct or return;
    return $self;
}

=item B<dbh>

  my $dbh = $store->dbh;

Returns the store's database handle.

=cut

sub dbh {
    my $self = shift;
    return $self->{dbh};
}

sub ensure_db_schema_correct {
    my $self = shift;
    my $dbh  = $self->{dbh};

    my $sql = "SELECT name FROM sqlite_master WHERE type='table'
               AND name=?";
    my $sth = $dbh->prepare($sql)
      or croak "ERROR: " . $dbh->errstr;
    $sth->execute(TABLENAME());
    my ($ok) = $sth->fetchrow_array;
    return 1 if $ok;

    $dbh->do("CREATE TABLE " . TABLENAME() . 
         "( id INTEGER PRIMARY KEY, timestamp text, name text, channel text, notes text )" )
      or croak "ERROR: " . $dbh->errstr;
    return 1;
}

=item B<store>

  $store->store( timestamp => $timestamp,
                 name      => $who,
                 channel   => $channel,
                 notes     => $message);

Stores the given information in the database.  Croaks on error.

=cut

sub store {
    my ($self, %args) = @_;
    my $dbh = $self->{dbh};

    my $sth = $dbh->prepare( qq{
        INSERT INTO } . TABLENAME() . q{ (timestamp, name, channel, notes)
               VALUES (?, ?, ?, ?)
    }) or croak "Error: can't prepare db query for insert: " . $dbh->errstr;

    $sth->execute( @args{ qw( timestamp name channel notes ) } )
      or croak "Error: can't insert into database: " . $dbh->errstr;

    return 1;
}

=head1 BUGS

No retrieval methods yet.

=head1 SEE ALSO

=over 4

=item * L<Bot::BasicBot::Pluggable::Module::Notes>

=back

=head1 AUTHOR

Jess Robinson <castaway@desert-island.me.uk>

=head1 COPYRIGHT

This module is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;
