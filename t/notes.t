#!/usr/bin/perl
use strict;
use warnings;
use Test::More tests => 7;
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

my $blog_handler = $bot->handler( "Notes" );

eval {
    local $SIG{__WARN__} = { }; # we expect DBI to warn
    $blog_handler->set_store(
        Bot::BasicBot::Pluggable::Module::Notes::Store::SQLite
            ->new( "thisdoesnotexist/brane.db" )
    );
};
ok( $@, "set_store croaks when database file can't be created" );

eval {
    $blog_handler->set_store(
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

END {
    unlink $TESTDB;
}
#my %test_data = (timestamp => "2010-04-12 08:09:56",
#		 name      => "castaway",
#		 channel   => "#london.pm",
#         notes     => "TODO: better document bot");

#$store->store( %test_data );

#row_ok( table => "blogged",
#	where => [ %test_data ],
##    tests => [ %test_data ],
#	label => "can store stuff" );
