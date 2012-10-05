use MooseX::Declare;
use Service::ICrawlerService;

class CrawlerService with ICrawlerService {

  has CrawlerRepository => (does => 'ICrawlerRepository',
                            is => 'ro',
                            required => 1);

  method Crawl(Int $startPage?) {
    foreach my $crawler (@{$self->CrawlerRepository->crawlers}) {
      $crawler->Crawl($startPage);
    }
  }

  method CrawlSingle(Str $url!) {
    foreach my $crawler (@{$self->CrawlerRepository->crawlers}) {
      $crawler->CrawlSingle($url);
    }
  }

  method CrawlNew() {
    foreach my $crawler (@{$self->CrawlerRepository->crawlers}) {
      $crawler->CrawlNew();
    }
  }
}

  1;
