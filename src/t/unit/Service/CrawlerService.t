use Test::Moose;
use Test::Exception;
use Test::Moose::MockObjectCompile;
use Test::More tests => 7;

use Service::CrawlerService;
use Repositories::CrawlerRepository;

##########################################
# std moose tests
meta_ok(CrawlerService);
does_ok(CrawlerService, ICrawlerService);
has_attribute_ok(CrawlerService, 'CrawlerRepository');
# end of std moose tests
##########################################

my $asMock = Test::Moose::MockObjectCompile->new;
$asMock->roles(['IArticleService']);
$asMock->mock('CreateOrUpdate');
$asMock->compile;

# mock for Mojo::UserAgent
{
  use MooseX::Declare;
  class Mojo::UserAgent {
  }
}

# must work with DIY mock here, because MockObjectCompile does not support
# Attribute passing via constructor.
{
  use MooseX::Declare;
  use Crawlers::ICrawler;

  class Crawlers::Mock with ICrawler {
    has Called => (isa => 'Bool',
                   is => 'rw',
                   default => 0);
    method Crawl {$self->Called(1);}
  }
}
my $cMock1 = Crawlers::Mock->new(ArticleService => $asMock, UserAgent => Mojo::UserAgent->new);
my $cMock2 = Crawlers::Mock->new(ArticleService => $asMock, UserAgent => Mojo::UserAgent->new);

my $repo = CrawlerRepository->new;
$repo->AddCrawler($cMock1);
$repo->AddCrawler($cMock2);

my $svc = new_ok('CrawlerService' => [CrawlerRepository => $repo]);
lives_ok {$svc->Crawl };
is($cMock1->Called, 1);
is($cMock2->Called, 1);
