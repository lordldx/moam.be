use MooseX::Test::Role;
use Test::Moose;
use Test::More tests => 1;

use Crawlers::IDOMHelper;

requires_ok('IDOMHelper', qw/GetCollectionFromDOM GetElementFromDOM/);
