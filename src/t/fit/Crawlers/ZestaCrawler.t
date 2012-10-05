use Test::Moose;
use Test::Exception;
use Test::More tests => 7;
use Test::Mock::Class ':all';
use Test::MockObject::Extends;

use Mojo::UserAgent;

use Domain::Article;
use Service::ArticleService;

use File::Basename 'dirname';
use lib join '/', File::Spec->splitdir(dirname(__FILE__));
use MockServerRunner;

BEGIN {
  use_ok(Crawlers::ICrawler);
  use_ok(Crawlers::ZestaCrawler);
  use_ok(Crawlers::DOMHelper);
}

# UserAgent Decorator
{
  package UserAgent;
  use Moose;
  extends 'Mojo::UserAgent';

  before 'get' => sub {
    $_[1] =~ s/zesta\.be/localhost:3000/;
  };
}

my $mockServer = MockServerRunner->new({'zoeken' => 't/fit/Crawlers/zestacrawler_getlastpage_response.html',
                                        'zoeken?page=0' => 't/fit/Crawlers/zestacrawler_getpage_response.html',
                                        'dummyrecept' => 't/fit/Crawlers/zestacrawler_getrecipe_response.html'});
$mockServer->start;

my $expectedArticle = Article->new(
                                   title => 'Titel',
                                   source => 'zesta.be',
                                   url => 'http://zesta.be/dummyrecept',
                                   chef => 'Lorenzo Dieryckx',
                                   ingredients => ['Dex', 'Lies', 'Videotape'],
                                   contents => "Dit is de inhoud van het recept\nen dit is de tweede lijn",
                                   difficulty => 'impossible',
                                   kitchentype => 'Hell',
                                   thumb_uri => '/dummyimage.jpg'
                                  );

my $mockArticleService = Test::MockObject::Extends->new(ArticleService->new(Db => mock_anon_class('CouchDB::Client::DB')->new_object));
$mockArticleService->mock('CreateOrUpdate', sub{});

my $crawler = new_ok('ZestaCrawler' => [UserAgent => UserAgent->new(),
                                        ArticleService => $mockArticleService,
                                        DOMHelper => DOMHelper->new()]);

lives_ok {$crawler->Crawl}, "Crawl does not die";
my ($name, $params) = $mockArticleService->next_call;
is($name, 'CreateOrUpdate');
is_deeply($params->[1], $expectedArticle);
