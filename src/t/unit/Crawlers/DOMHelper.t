use Test::Moose;
use Test::Exception;
use Test::More qw/no_plan/;
use Test::Mock::Class ':all';
use Test::MockObject::Extends;

BEGIN {
  use_ok 'Crawlers::IDOMHelper';
  use_ok 'Crawlers::DOMHelper';
  use_ok 'Mojo::DOM';
}

# std tests
meta_ok('DOMHelper');
does_ok('DOMHelper', 'IDOMHelper');

##########################
#  GetCollectionFromDOM  #
##########################
{
  my $helper = DOMHelper->new;

  # normal operation
  {
    my $dom = Mojo::DOM->new;
    $dom = Test::MockObject::Extends->new($dom);
    $dom->mock('dom', sub { return 'collection';});

    my $retval;
    lives_ok {$retval = $helper->GetCollectionFromDOM($dom, 'test');};
    is($retval, 'collection', 'retval is ok');
    my ($call, $params) = $dom->next_call;
    is($call, 'dom', 'dom called ok');
    is($params->[1], 'test', 'param ok');
    $dom->clear;
  }

  # no dom parameter
  {
    dies_ok {$helper->GetCollectionFromDOM;};
  }

  # no path parameter
  {
    dies_ok {$helper->GetCollectionFromDOM(Mojo::DOM->new);};
  }
}

##########################
#    GetElementFromDOM   #
##########################
{
  my $helper = DOMHelper->new;

  # normal operation
  {
    my $dom = Mojo::DOM->new;
    $dom = Test::MockObject::Extends->new($dom);
    $dom->mock('at', sub { return 'element';});

    my $retval;
    lives_ok {$retval = $helper->GetElementFromDOM($dom, 'test');};
    is($retval, 'element', 'retval is ok');
    my ($call, $params) = $dom->next_call;
    is($call, 'at', 'dom called ok');
    is($params->[1], 'test', 'param ok');
    $dom->clear;
  }

  # no dom parameter
  {
    dies_ok {$helper->GetElementFromDOM;};
  }

  # no path parameter
  {
    dies_ok {$helper->GetElementFromDOM(Mojo::DOM->new);};
  }
}
