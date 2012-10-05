use MooseX::Declare;
use Repositories::ICrawlerRepository;
use Crawlers::ICrawler;

class CrawlerRepository with ICrawlerRepository {

  method AddCrawler(ICrawler $crawler!) {
    push @{$self->crawlers}, $crawler;
  }

  method GetNumberOfCrawlers() returns(Int) {
    return scalar @{$self->crawlers};
  }
}

1;
