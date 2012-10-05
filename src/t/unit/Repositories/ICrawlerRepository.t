use Test::More tests => 2;
use MooseX::Test::Role;

BEGIN {
  use_ok('Repositories::ICrawlerRepository');
}

requires_ok('ICrawlerRepository', qw/AddCrawler GetNumberOfCrawlers/);

