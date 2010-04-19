use ExtUtils::MakeMaker;

WriteMakefile(
    NAME         => "Bot::BasicBot::Pluggable::Module::Notes",
    VERSION_FROM => "lib/Bot/BasicBot/Pluggable/Module/Notes.pm",
    PREREQ_PM    => { 
        Bot::BasicBot::Pluggable => '0.74',
        Web::Simple              => '0.02',
        JSON                     => '0',
        File::Spec::Functions    => 0,
        Carp                     => 0,
        DBD::SQLite              => 0,
        Test::DatabaseRow        => 0,
        Test::More               => 0,
        Time::Piece              => 0,
    },
    clean        => { FILES => "t/brane.db" }
);

