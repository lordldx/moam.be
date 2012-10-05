use MooseX::Declare;
use Crawlers::ICrawler;
use Domain::Article;

class DummyCrawler with ICrawler {
  method Crawl {
    my $a1 = Article->new(
                          title => "Titel 1",
                          source => "localhost",
                          url => "http://localhost:3000/",
                          chef => "Lorenzo Dieryckx",
                          ingredients => ["appels", "peren", localtime],
                          difficulty => 'Beginner',
                          kitchentype => 'Belgisch',
                          contents => "Dit is het eerste recept"
                         );

    my $a2 = Article->new(
                          title => "Titel 2",
                          source => "localhost",
                          url => "http://localhost:3000/" . localtime,
                          chef => "Tineke De Blauwe",
                          ingredients => ["room", "aardbeien"],
                          difficulty => 'Gevorderd',
                          kitchentype => 'Italiaans',
                          contents => "Dit is het tweede recept"
                         );

    $self->ArticleService->CreateOrUpdate($a1);
    $self->ArticleService->CreateOrUpdate($a2);
  }

    method CrawlSingle(Str $url!) {
    }

  method CrawlNew() {
  }
}

  1;
