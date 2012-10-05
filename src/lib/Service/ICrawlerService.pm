use MooseX::Declare;

role ICrawlerService {
  requires 'Crawl';
  requires 'CrawlSingle';
  requires 'CrawlNew';
}

1;
