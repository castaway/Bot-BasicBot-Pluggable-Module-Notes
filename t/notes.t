#!/usr/bin/perl
use strict;
use warnings;
use Test::More tests => 10;
use Test::DatabaseRow;

use Test::Bot::BasicBot::Pluggable;

my $TESTDB = 't/brane.db';
use_ok( "Bot::BasicBot::Pluggable::Module::Notes" );
use_ok( "Bot::BasicBot::Pluggable::Module::Notes::Store::SQLite" );

my $bot = Test::Bot::BasicBot::Pluggable->new( channels => [ "#test" ],
					 server   => "irc.example.com",
					 port     => "6667",
					 nick     => "bot",
					 username => "bot",
					 name     => "bot",
				       );
$bot->load( "Notes" );

my $notes_handler = $bot->handler( "Notes" );

eval {
    local $SIG{__WARN__} = { }; # we expect DBI to warn
    $notes_handler->set_store(
        Bot::BasicBot::Pluggable::Module::Notes::Store::SQLite
            ->new( "thisdoesnotexist/brane.db" )
    );
};
ok( $@, "set_store croaks when database file can't be created" );

eval {
    $notes_handler->set_store(
        Bot::BasicBot::Pluggable::Module::Notes::Store::SQLite
            ->new( $TESTDB )
    );
};
is( $@, "", "...but is fine when it can" );

my $store = Bot::BasicBot::Pluggable::Module::Notes::Store::SQLite
            ->new( "t/brane.db" );
isa_ok( $store, "Bot::BasicBot::Pluggable::Module::Notes::Store::SQLite");

my $dbh = $store->dbh;
$Test::DatabaseRow::dbh = $dbh;

$bot->tell_direct('TODO: Better document bot');

row_ok( table => "notes",
	where => [ channel => '#test', notes => 'TODO: Better document bot', name => 'test_user' ],
    results => 0,
	label => "Doesn't store note if doesnt begin with 'note to self'" );

$bot->tell_direct('note to self: TODO: Better document bot');

row_ok( table => "notes",
	where => [ channel => '#test', notes => 'TODO: Better document bot', name => 'test_user' ],
	label => "stores note to self" );

## Test command parsing:

my $simple_command = $notes_handler->parse_command('!nb');
is_deeply($simple_command, { command => 'nb', args => ''}, 'Parsed simple command !nb');

my $two_word_command = $notes_handler->parse_command('!{my notes}');
is_deeply($two_word_command, { command => 'mn', args => ''}, 'Parsed two word command !{my notes}');

my $command_with_args = $notes_handler->parse_command('!search #todo');
is_deeply($command_with_args, { command => 'search', args => '#todo' }, 'Parsed command with args !search #todo');
 

END {
    unlink $TESTDB;
}
