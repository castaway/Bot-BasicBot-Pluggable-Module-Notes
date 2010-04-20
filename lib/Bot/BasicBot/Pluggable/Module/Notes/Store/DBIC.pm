package Bot::BasicBot::Pluggable::Module::Notes::Store::DBIC;

use strict;
use warnings;

use Carp;
use Bot::BasicBot::Pluggable::Module::Notes::Store::DBIC::Schema;
use DBIx::Class::ResultClass::HashRefInflator;

my $dsn = 'dbi:SQLite';

sub new {
    my ($class, $db_file) = @_;

    my $schema = Bot::BasicBot::Pluggable::Module::Notes::Store::DBIC::Schema->connect("${dsn}:$db_file");

    my $self = {};
    bless $self, $class;

    $self->{schema} = $schema;
    $self->ensure_db_schema_correct or die "Database not initialised";
    return $self;
    
}

sub ensure_db_schema_correct {
    my ($self) = @_;

    my $dbh = $self->dbh;
    my $notes_table = $self->{schema}->source('Note')->name;

    my $sql = "SELECT name FROM sqlite_master WHERE type='table'
               AND name=?";
    my $sth = $dbh->prepare($sql)
      or croak "ERROR: " . $dbh->errstr;
    $sth->execute($notes_table);

    my ($ok) = $sth->fetchrow_array;
    return 1 if $ok;

    $self->{schema}->deploy;
    return 1;
}

sub dbh {
    my ($self) = @_;

    return $self->{schema}->storage->dbh;
}

sub store {
    my ($self, %args) = @_;

    my $note = $self->{schema}->resultset('Note')->create( {
                                                            %args
                                                           });
    
    return $note;
}

sub get_notes {
    my ($self, %args) = @_;

    my %opts;
    for (qw<page rows>) {
        if (exists $args{$_}) {
            $opts{$_} = delete $args{$_};
        }
    }

    my $rs = $self->{schema}->resultset('Note')->search(\%args, \%opts);
    $rs->result_class('DBIx::Class::ResultClass::HashRefInflator');
    return [$rs->all];
}

1;