use MooseX::Declare;
use Service::IArticleService;

role ICrawler {
  requires 'Crawl';
  requires 'CrawlSingle';
  requires 'CrawlNew';

  has UserAgent => (is => 'rw',
                    isa => 'Mojo::UserAgent',
                    required => 1);

  has ArticleService => (is => 'ro',
                         does => 'IArticleService',
                         required => 1);

  has DEBUG => (is => 'ro',
                isa => 'Bool',
                required => 1,
                default => sub {$ENV{'FOOOD_CRAWLER_DEBUG'}});
}

  1;
