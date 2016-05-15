package Devel::REPL::Client::AnyEvent;

use strict;
use warnings;

use Devel::REPL::Client::AnyEvent::Connection;

use AnyEvent::Socket;
use Scalar::Util qw(weaken);
use Term::ReadKey;

use constant {
    EOT     => "\x04",
};

my $RESTORE_READMODE;

END {
    ReadMode 0, \*STDIN if $RESTORE_READMODE;
}

sub new {
    my ($class, %args) = @_;
    my $self = bless {
        port            => $args{port},
        path            => $args{path},
        on_connection   => $args{on_connection},
        tcp_guard       => undef,
    }, $class;

    return $self;
}

sub listen {
    my ($self) = @_;

    my $weak_self = $self;
    weaken($weak_self);
    my $cb = sub { $weak_self->_new_connection($_[0]) };
    if ($self->{port}) {
        $self->{guard} = tcp_server('127.0.0.1', $self->{port}, $cb);
    } elsif ($self->{path}) {
        $self->{guard} = tcp_server('unix/', $self->{path}, $cb);
    }
}

sub _new_connection {
    my ($self, $fh) = @_;
    my $connection = Devel::REPL::Client::AnyEvent::Connection->new(socket => $fh);

    $RESTORE_READMODE = 1;
    ReadMode 3, \*STDIN;

    $self->{on_connection}->($connection);
}

1;
