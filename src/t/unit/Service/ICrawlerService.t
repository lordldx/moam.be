use MooseX::Test::Role;
use Test::More tests => 1;
use Service::ICrawlerService;

requires_ok('ICrawlerService', qw/Crawl CrawlSingle CrawlNew/);
