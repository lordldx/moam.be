use MooseX::Test::Role;
use Test::Moose;
use Test::More tests => 1;

use Crawlers::ICrawler;

requires_ok ('ICrawler', qw/Crawl CrawlSingle CrawlNew/);
# has_attribute_ok('ICrawler', 'ArticleService'); # doesn't seem to be compatible with roles
