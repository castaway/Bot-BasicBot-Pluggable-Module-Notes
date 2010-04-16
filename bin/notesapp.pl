#!/usr/local/bin/perl5.10.0

use Web::Simple 'Bot::BasicBot::Pluggable::Module::Notes::App';
{
    package Bot::BasicBot::Pluggable::Module::Notes::App;

    use File::Spec::Functions;
    use JSON ();

    default_config ( file_dir => q{/usr/src/perl/Bot-BasicBot-Pluggable-Module-Notes/root/} );

    sub static_file {
        my ($self, $file, $type) = @_;
        open my $fh, '<', catfile($self->config->{file_dir}, "$file") or return [ 404, [ 'Content-type', 'text/html' ], [ 'file not found']];

        local $/ = undef;
        my $file_content = <$fh>;
        close $fh or return [ 500, [ 'Content-type', 'text/html' ], [ 'Internal Server Error'] ];

        return [ 200, [ 'Content-type' => $type ], [ $file_content ] ];
 
    }

    sub notes_json {
        my ($self, %params) = @_;
#        my @checkedparams{ qw(date time channel name notes) } = @{$params->{qw(date time channel name notes)}};

        my $notes = {
                     total => 1,
                     page => 1,
                     records => 2,
                     rows => [
                              { id => 1, cell => [1,
                                                  '2010-04-17',
                                                  '12:33',
                                                  '#test',
                                                  'castaway',
                                                  'something' ] },
                              { id => 2, cell => [2,
                                                  '2010-04-17',
                                                  '12:35',
                                                  '#test',
                                                  'castaway',
                                                  'otherthing' ] },
                             ],
                    };

        return [ 200, [ 'Content-type' => 'application/json' ], [ JSON::encode_json($notes) ] ];
    }

    dispatch {
        sub (/) {
            return $self->static_file('index.html')
        },
        sub (/js/**) {
            my $file=$_[1];
            return $self->static_file("js/$file", "text/javascript");
        },
        sub (/css/**) {
            my $file=$_[1];
            return $self->static_file("css/$file", "text/css");
        },
#        sub (/json + ?:date~&:time~&:channel~&:name~&:notes~) {
        sub (/json + ?date~&time~&channel~&name~&notes~) {
#            my ($self, $params) = @_;
            my ($self, $date, $time, $channel, $name, $notes) = @_;
            return $self->notes_json(date => $date, 
                                     time => $time,
                                     channel => $channel,
                                     name => $name,
                                     notes => $notes);
        }

    };

}

Bot::BasicBot::Pluggable::Module::Notes::App->run_if_script;
