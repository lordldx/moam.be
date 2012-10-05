package MockServerRunner;
use strict;
use warnings;
use threads;
use Mojo::Server::Daemon;

sub new {
  my ($class, $config) = @_;

  my $server = Mojo::Server::Daemon->new();
  $server->load_app('t/fit/Crawlers/MockServer')->SetConfig($config);

  my $self = bless {THREAD => 0,
                    SERVER => $server}, $class;

  return $self;
}

sub start {
  my $self = shift;
  $self->{THREAD} = threads->create(sub {
                                      my $self = shift;
                                      $self->{SERVER}->run;
                                    }, $self);
  sleep(3);                     # fukit
  $self->{THREAD}->detach;      # live long and prosper!
}

1;
