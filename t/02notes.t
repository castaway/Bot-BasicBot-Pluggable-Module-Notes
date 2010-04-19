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

###
my $say_output;
sub Test::Bot::BasicBot::Pluggable::say {
    my ($self, %args) = @_;
    $say_output = \%args;
}
###

my $notes_handler = $bot->load( "Notes" );

# my $notes_handler = $bot->handler( "Notes" );

## Test command parsing:

my $simple_command = $notes_handler->parse_command('!nb');
is_deeply($simple_command, { command => 'nb',  method => 'store_note', args => ''}, 'Parsed simple command !nb');

my $two_word_command = $notes_handler->parse_command('!{my notes}');
is_deeply($two_word_command, { command => 'mn',method => 'replay_notes',  args => ''}, 'Parsed two word command !{my notes}');

my $command_with_args = $notes_handler->parse_command('!search #todo');
is_deeply($command_with_args, { command => 'search', method => 'search', args => '#todo' }, 'Parsed command with args !search #todo');
 
## store
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

## test handler storage
$notes_handler->store_note(who => 'me', channel => '#metest', content => 'something');

row_ok( table => "notes",
	where => [ channel => '#metest', notes => 'something', name => 'me' ],
	label => "Finds directly stored data'" );
 # fetch the direct stored one so we know the timestamp.. 
$notes_handler->replay_notes(who => 'directstore', channel => '#metest');
is_deeply($say_output, {
    who => 'directstore', channel => 'msg',
    body => "[#stored] (2010-01-01T23:23:23) stored directly\n"
          }, 'Said stored note');


## test via bot
$bot->tell_direct('TODO: Better document bot');

row_ok( table => "notes",
	where => [ channel => '#test', notes => 'TODO: Better document bot', name => 'test_user' ],
    results => 0,
	label => "Doesn't store note if doesnt begin with 'note to self'" );

$bot->tell_direct('!{note to self} TODO: Better document bot');

row_ok( table => "notes",
	where => [ channel => '#test', notes => 'TODO: Better document bot', name => 'test_user' ],
	label => "stores note to self" );

END {
    unlink $TESTDB;
}
