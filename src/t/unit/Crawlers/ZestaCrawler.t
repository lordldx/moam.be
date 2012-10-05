# -*- mode: cperl -*-
use strict;
use Test::Moose;
use Test::Exception;
use Test::More qw/no_plan/;
use Test::Mock::Class ':all';
use Test::MockObject::Extends;

use Service::ArticleService;
use Crawlers::DOMHelper;

BEGIN {
  use_ok('Crawlers::ICrawler');
  use_ok('Crawlers::ZestaCrawler');
}

diag('basic tests');
meta_ok('ZestaCrawler');
does_ok('ZestaCrawler', 'ICrawler');
has_attribute_ok('ZestaCrawler', 'UserAgent');
has_attribute_ok('ZestaCrawler', 'ArticleService');
has_attribute_ok('ZestaCrawler', 'DEBUG');
has_attribute_ok('ZestaCrawler', 'DOMHelper');

diag('###############');
diag('#    Trim     #');
diag('###############');
{
  my $crawler = ZestaCrawler->new(ArticleService => mock_anon_class('ArticleService')->new_object(Db => mock_anon_class('CouchDB::Client::DB')->new_object),
                                  UserAgent => mock_anon_class('Mojo::UserAgent')->new_object,
                                  DOMHelper => mock_anon_class('DOMHelper')->new_object);

  is($crawler->_Trim("test"), "test", "Trim nothing");
  is($crawler->_Trim("  test"), "test", "Trim leading spaces");
  is($crawler->_Trim("test  "), "test", "Trim trailing spaces");
  is($crawler->_Trim("  test    "), "test", "Trim both");
}

diag('###############');
diag('#    Crawl    #');
diag('###############');
{
  my $crawler = ZestaCrawler->new(ArticleService => mock_anon_class('ArticleService')->new_object(Db => mock_anon_class('CouchDB::Client::DB')->new_object),
                                  UserAgent => mock_anon_class('Mojo::UserAgent')->new_object,
                                  DOMHelper => mock_anon_class('DOMHelper')->new_object);
  my $lastPage = 100;

  $crawler = Test::MockObject::Extends->new($crawler);
  $crawler
    ->set_always('_GetLastPage', $lastPage)
      ->mock('_CrawlPage', sub{});

  diag('Test std call to crawl');
  lives_ok {$crawler->Crawl;};
  is($crawler->next_call, '_GetLastPage');
  for (my $i = 0; $i <= $lastPage; ++$i) {
    my ($name, $args) = $crawler->next_call;
    is($name, '_CrawlPage');
    is($args->[1], $i);
  }
  $crawler->clear;

  diag('Test with startPage param');
  my $startPage = 50;
  lives_ok {$crawler->Crawl($startPage);};
  is($crawler->next_call, '_GetLastPage');
  for (my $i = $startPage; $i <= $lastPage; ++$i) {
    my ($name, $args) = $crawler->next_call;
    is($name, '_CrawlPage');
    is($args->[1], $i);
  }
  $crawler->clear;
}

diag('######################');
diag('#   CrawlSingle      #');
diag('######################');
{
  my $crawler = ZestaCrawler->new(ArticleService => mock_anon_class('ArticleService')->new_object(Db => mock_anon_class('CouchDB::Client::DB')->new_object),
                                  UserAgent => mock_anon_class('Mojo::UserAgent')->new_object,
                                  DOMHelper => mock_anon_class('DOMHelper')->new_object);
  $crawler = Test::MockObject::Extends->new($crawler);
  $crawler->mock('_HandleRecipe', sub{});

  diag('std test');
  my $url = 'test';
  lives_ok {$crawler->CrawlSingle($url);};
  my ($name, $params) = $crawler->next_call;
  is($name, '_HandleRecipe');
  is($params->[1], $url);
  $crawler->clear;

  diag('test without param');
  dies_ok {$crawler->CrawlSingle;};
}

diag('#####################');
diag('#    _CrawlPage     #');
diag('#####################');
{
  my $crawler = ZestaCrawler->new(ArticleService => mock_anon_class('ArticleService')->new_object(Db => mock_anon_class('CouchDB::Client::DB')->new_object),
                                  UserAgent => mock_anon_class('Mojo::UserAgent')->new_object,
                                  DOMHelper => mock_anon_class('DOMHelper')->new_object);
  $crawler = Test::MockObject::Extends->new($crawler);

  diag('test _FetchPage fail');
  {
    $crawler->mock("_FetchPage", sub{return undef;});
    lives_ok {$crawler->_CrawlPage(1);};
    my ($call, $params) = $crawler->next_call;
    is($call, "_FetchPage", "_FetchPage called");
    is($params->[1], "http://zesta.be/zoeken?page=1", "_FetchPage parameter ok");
    $crawler->clear;
  }

  diag('test no data returned');
  {
    $crawler->mock("_FetchPage", sub{return Mojo::Message::Response->new;});
    lives_ok {$crawler->_CrawlPage(1);};
    my ($call, $params) = $crawler->next_call;
    is($call, "_FetchPage", "_FetchPage called");
    is($params->[1], "http://zesta.be/zoeken?page=1", "_FetchPage parameter ok");
    $crawler->clear;
  }

  diag('test no anchor in pagediv');
  {
    my $dom = Mojo::DOM->new;
    $dom = Test::MockObject::Extends->new($dom);
    $dom->mock("at", sub{return undef;});
    my $coll = Mojo::Collection->new;
    $coll = Test::MockObject::Extends->new($coll);
    $coll->mock("each", sub{return ($dom);});
    my $resp = Mojo::Message::Response->new;
    $resp = Test::MockObject::Extends->new($resp);
    $resp->mock("dom", sub{return $coll;});
    $crawler->mock("_FetchPage", sub{return $resp;});

    lives_ok{$crawler->_CrawlPage(1);};
    my ($call, $params) = $crawler->next_call;
    is($call, "_FetchPage", "_FetchPage called");
    is($params->[1], "http://zesta.be/zoeken?page=1", "_FetchPage parameter ok");
    $crawler->clear;

    $resp->called("dom", "dom called on Response");
    $coll->called("each", "each called on Collection");
    $dom->called("at", "at called on DOM");
  }

  diag('test normal operation');
  {
    my $anchor = Mojo::DOM->new;
    $anchor = Test::MockObject::Extends->new($anchor);
    $anchor->mock("attrs", sub{return "recipeanchor";});
    my $img = Mojo::DOM->new;
    $img = Test::MockObject::Extends->new($img);
    $img->mock("attrs", sub{return "imglink";});
    my $dom = Mojo::DOM->new;
    $dom = Test::MockObject::Extends->new($dom);
    $dom->set_series("at", $anchor, $img);
    my $coll = Mojo::Collection->new;
    $coll = Test::MockObject::Extends->new($coll);
    $coll->mock("each", sub{return ($dom);});
    my $resp = Mojo::Message::Response->new;
    $resp = Test::MockObject::Extends->new($resp);
    $resp->mock("dom", sub{return $coll;});
    $crawler->mock("_FetchPage", sub{return $resp;});
    $crawler->mock("_HandleRecipe", sub{});

    lives_ok{$crawler->_CrawlPage(1);};
    my ($call, $params) = $crawler->next_call;
    is($call, "_FetchPage", "_FetchPage called");
    is($params->[1], "http://zesta.be/zoeken?page=1", "_FetchPage parameter ok");
    ($call, $params) = $crawler->next_call;
    is($call, "_HandleRecipe", "_HandleRecipe called");
    is(scalar @$params, 3, "two parameters passed to _HandleRecipe");
    is($params->[1], "recipeanchor", "_HandleRecipe anchor param ok");
    is($params->[2], "imglink", "_HandleRecipe imglink param ok");
    $crawler->clear;

    $resp->called("dom", "dom called on Response");
    $coll->called("each", "each called on Collection");
    $img->called("attrs", "attrs called on img-DOM");
    $anchor->called("attrs", "attrs called on anchor-DOM");
    ($call, $params) = $dom->next_call;
    is($call, "at", "at called on DOM (1)");
    is($params->[1], "div.views-field-title > span.field-content > a", "params to at ok (1)");
    ($call, $params) = $dom->next_call;
    is($call, "at", "at called on DOM (2)");
    is($params->[1], "div.views-field-field-recipe-image-fid img.imagecache", "params to at ok (2)");
  }

  diag('test no thumburi operation');
  {
    my $anchor = Mojo::DOM->new;
    $anchor = Test::MockObject::Extends->new($anchor);
    $anchor->mock("attrs", sub{return "recipeanchor";});
    my $dom = Mojo::DOM->new;
    $dom = Test::MockObject::Extends->new($dom);
    $dom->set_series("at", $anchor, undef);
    my $coll = Mojo::Collection->new;
    $coll = Test::MockObject::Extends->new($coll);
    $coll->mock("each", sub{return ($dom);});
    my $resp = Mojo::Message::Response->new;
    $resp = Test::MockObject::Extends->new($resp);
    $resp->mock("dom", sub{return $coll;});
    $crawler->mock("_FetchPage", sub{return $resp;});
    $crawler->mock("_HandleRecipe", sub{});

    lives_ok{$crawler->_CrawlPage(1);};
    my ($call, $params) = $crawler->next_call;
    is($call, "_FetchPage", "_FetchPage called");
    is($params->[1], "http://zesta.be/zoeken?page=1", "_FetchPage parameter ok");
    ($call, $params) = $crawler->next_call;
    is($call, "_HandleRecipe", "_HandleRecipe called");
    is(scalar @$params, 2, "one parameter passed to _HandleRecipe");
    is($params->[1], "recipeanchor", "_HandleRecipe anchor param ok");
    $crawler->clear;

    $resp->called("dom", "dom called on Response");
    $coll->called("each", "each called on Collection");
    $anchor->called("attrs", "attrs called on anchor-DOM");
    ($call, $params) = $dom->next_call;
    is($call, "at", "at called on DOM (1)");
    is($params->[1], "div.views-field-title > span.field-content > a", "params to at ok (1)");
    ($call, $params) = $dom->next_call;
    is($call, "at", "at called on DOM (2)");
    is($params->[1], "div.views-field-field-recipe-image-fid img.imagecache", "params to at ok (2)");
  }

  diag('test without param');
  {
    dies_ok {$crawler->_CrawlPage();}
  }
}

diag('#####################');
diag('#    _GetTitle      #');
diag('#####################');
{
  my $domHelper = DOMHelper->new;
  $domHelper = Test::MockObject::Extends->new($domHelper);
  my $crawler = ZestaCrawler->new(ArticleService => mock_anon_class('ArticleService')->new_object(Db => mock_anon_class('CouchDB::Client::DB')->new_object),
                                  UserAgent => mock_anon_class('Mojo::UserAgent')->new_object,
                                  DOMHelper => $domHelper);
  $crawler = Test::MockObject::Extends->new($crawler);

  diag('test without param');
  {
    dies_ok {$crawler->_GetTitle;};
  }

  diag('test normal');
  {
    $domHelper->mock("GetElementFromDOM", sub {return "domelement";});
    $crawler->mock("_GetTextElement", sub {return "textfromdomelement";});
    my $dom = Mojo::DOM->new;

    my $title;
    lives_ok {$title = $crawler->_GetTitle($dom);};

    is($title, "textfromdomelement");

    my ($call, $param) = $domHelper->next_call;
    is($call, "GetElementFromDOM", "GetElemenetFromDOM called ok");
    is($param->[1], $dom, "param 1 ok");
    is($param->[2], '#boxes-box-node_title h1', "param 2 ok");
    $domHelper->clear;

    ($call, $param) = $crawler->next_call;
    is($call, "_GetTextElement", "_GetTextElement called ok");
    is($param->[1], "domelement", "param 1 ok");
    $crawler->clear;
  }

  diag('test element not found');
  {
    $domHelper->mock("GetElementFromDOM", sub {return undef;});
    my $dom = Mojo::DOM->new;

    my $title;
    lives_ok {$title = $crawler->_GetTitle($dom);};

    is($title, "");

    my ($call, $param) = $domHelper->next_call;
    is($call, "GetElementFromDOM", "GetElemenetFromDOM called ok");
    is($param->[1], $dom, "param 1 ok");
    is($param->[2], '#boxes-box-node_title h1', "param 2 ok");
    $domHelper->clear;
  }
}

diag('#####################');
diag('# _GetIngredients   #');
diag('#####################');
{
  my $domHelper = DOMHelper->new;
  $domHelper = Test::MockObject::Extends->new($domHelper);
  my $crawler = ZestaCrawler->new(ArticleService => mock_anon_class('ArticleService')->new_object(Db => mock_anon_class('CouchDB::Client::DB')->new_object),
                                  UserAgent => mock_anon_class('Mojo::UserAgent')->new_object,
                                  DOMHelper => $domHelper);
  $crawler = Test::MockObject::Extends->new($crawler);

  diag('test without param');
  {
    dies_ok {$crawler->_GetIngredients;};
  }

  diag('test normal 1 ingredient');
  {
    my $dom = Mojo::DOM->new;
    my $element = Mojo::DOM->new;
    $element = Test::MockObject::Extends->new($element);
    $element->mock("all_text", sub {return "ingredient";});

    my $items = Mojo::Collection->new($element);
    $domHelper->mock("GetCollectionFromDOM", sub{return $items});

    my @results;
    lives_ok {@results = $crawler->_GetIngredients($dom);};
    is(scalar @results, 1, "returned 1 ingredient");
    is($results[0], "ingredient", "correct ingredient returned");

    my ($call, $params) = $domHelper->next_call;
    is($call, "GetCollectionFromDOM", "GetCollectionFromDOM called");
    is($params->[1], "$dom", "param 1 ok");
    is($params->[2], "div.item-list li span.ingredient", "param 2 ok");
    $domHelper->clear;

    ($call, $params) = $element->next_call;
    is($call, "all_text", "all_text called ok");
  }

  diag('test normal multi ingredients');
  {
    my $dom = Mojo::DOM->new;
    my $element1 = Mojo::DOM->new;
    my $element2 = Mojo::DOM->new;
    my $element3 = Mojo::DOM->new;
    $element1 = Test::MockObject::Extends->new($element1);
    $element2 = Test::MockObject::Extends->new($element2);
    $element3 = Test::MockObject::Extends->new($element3);
    $element1->mock("all_text", sub {return "ingredient 1";});
    $element2->mock("all_text", sub {return "ingredient 2";});
    $element3->mock("all_text", sub {return "ingredient 3";});

    my $items = Mojo::Collection->new($element1, $element2, $element3);
    $domHelper->mock("GetCollectionFromDOM", sub{return $items;});

    my @results;
    lives_ok {@results = $crawler->_GetIngredients($dom);};
    is(scalar @results, 3, "returned 3 ingredients");
    is($results[0], "ingredient 1", "correct ingredient returned (1)");
    is($results[1], "ingredient 2", "correct ingredient returned (2)");
    is($results[2], "ingredient 3", "correct ingredient returned (3)");

    my ($call, $params) = $domHelper->next_call;
    is($call, "GetCollectionFromDOM", "GetCollectionFromDOM called");
    is($params->[1], "$dom", "param 1 ok");
    is($params->[2], "div.item-list li span.ingredient", "param 2 ok");
    $domHelper->clear;

    ($call, $params) = $element1->next_call;
    is($call, "all_text", "all_text called ok (1)");
    ($call, $params) = $element2->next_call;
    is($call, "all_text", "all_text called ok (2)");
    ($call, $params) = $element3->next_call;
    is($call, "all_text", "all_text called ok (3)");
  }

  diag('test normal 2nd possibility');
  {
    my $dom = Mojo::DOM->new;
    my $element1 = Mojo::DOM->new;
    my $element2 = Mojo::DOM->new;
    my $element3 = Mojo::DOM->new;
    $element1 = Test::MockObject::Extends->new($element1);
    $element2 = Test::MockObject::Extends->new($element2);
    $element3 = Test::MockObject::Extends->new($element3);
    $element1->mock("all_text", sub {return "ingredient 1";});
    $element2->mock("all_text", sub {return "ingredient 2";});
    $element3->mock("all_text", sub {return "ingredient 3";});

    my $items = Mojo::Collection->new($element1, $element2, $element3);
    $domHelper->set_series("GetCollectionFromDOM", Mojo::Collection->new, $items);

    my @results;
    lives_ok {@results = $crawler->_GetIngredients($dom);};
    is(scalar @results, 3, "returned 3 ingredients");
    is($results[0], "ingredient 1", "correct ingredient returned (1)");
    is($results[1], "ingredient 2", "correct ingredient returned (2)");
    is($results[2], "ingredient 3", "correct ingredient returned (3)");

    my ($call, $params) = $domHelper->next_call;
    is($call, "GetCollectionFromDOM", "GetCollectionFromDOM called");
    is($params->[1], "$dom", "param 1 ok");
    is($params->[2], "div.item-list li span.ingredient", "param 2 ok");
    ($call, $params) = $domHelper->next_call;
    is($call, "GetCollectionFromDOM", "GetCollectionFromDOM called 2nd time");
    is($params->[1], "$dom", "param 1 ok");
    is($params->[2], "div.recipe-ingredients li", "param 2 ok");
    $domHelper->clear;

    ($call, $params) = $element1->next_call;
    is($call, "all_text", "all_text called ok (1)");
    ($call, $params) = $element2->next_call;
    is($call, "all_text", "all_text called ok (2)");
    ($call, $params) = $element3->next_call;
    is($call, "all_text", "all_text called ok (3)");
  }

  diag('test no items found');
  {
    my $dom = Mojo::DOM->new;
    $domHelper->mock("GetCollectionFromDOM", sub {return Mojo::Collection->new;});

    my @results;
    lives_ok {@results = $crawler->_GetIngredients($dom);};
    is(scalar @results, 0, "returned 0 ingredients");

    my ($call, $params) = $domHelper->next_call;
    is($call, "GetCollectionFromDOM", "GetCollectionFromDOM called");
    is($params->[1], "$dom", "param 1 ok");
    is($params->[2], "div.item-list li span.ingredient", "param 2 ok");
    ($call, $params) = $domHelper->next_call;
    is($call, "GetCollectionFromDOM", "GetCollectionFromDOM called 2nd time");
    is($params->[1], "$dom", "param 1 ok");
    is($params->[2], "div.recipe-ingredients li", "param 2 ok");
    $domHelper->clear;
  }

  diag('test undefined elements in items');
  {
    my $dom = Mojo::DOM->new;
    my $element1 = Mojo::DOM->new;
    my $element2 = Mojo::DOM->new;
    my $element3 = Mojo::DOM->new;
    $element1 = Test::MockObject::Extends->new($element1);
    $element2 = undef;
    $element3 = Test::MockObject::Extends->new($element3);
    $element1->mock("all_text", sub {return "ingredient 1";});
    $element3->mock("all_text", sub {return "ingredient 3";});

    my $items = Mojo::Collection->new($element1, $element2, $element3);
    $domHelper->mock("GetCollectionFromDOM", sub {return $items;});

    my @results;
    lives_ok {@results = $crawler->_GetIngredients($dom);};
    is(scalar @results, 2, "returned 2 ingredients");
    is($results[0], "ingredient 1", "correct ingredient returned (1)");
    is($results[1], "ingredient 3", "correct ingredient returned (2)");

    my ($call, $params) = $domHelper->next_call;
    is($call, "GetCollectionFromDOM", "GetCollectionFromDOM called");
    is($params->[1], "$dom", "param 1 ok");
    is($params->[2], "div.item-list li span.ingredient", "param 2 ok");
    $domHelper->clear;

    ($call, $params) = $element1->next_call;
    is($call, "all_text", "all_text called ok (1)");
    ($call, $params) = $element3->next_call;
    is($call, "all_text", "all_text called ok (3)");
  }
}

diag('#####################');
diag('#   _GetContents    #');
diag('#####################');
{
  my $domHelper = DOMHelper->new;
  $domHelper = Test::MockObject::Extends->new($domHelper);
  my $crawler = ZestaCrawler->new(ArticleService => mock_anon_class('ArticleService')->new_object(Db => mock_anon_class('CouchDB::Client::DB')->new_object),
                                  UserAgent => mock_anon_class('Mojo::UserAgent')->new_object,
                                  DOMHelper => $domHelper);
  $crawler = Test::MockObject::Extends->new($crawler);

  diag('test without param');
  {
    dies_ok {$crawler->_GetContents;};
  }

  diag('test normal');
  {
    my $dom = Mojo::DOM->new;
    my $element1 = Mojo::DOM->new;
    my $element2 = Mojo::DOM->new;
    my $element3 = Mojo::DOM->new;
    $element1 = Test::MockObject::Extends->new($element1);
    $element2 = Test::MockObject::Extends->new($element2);
    $element3 = Test::MockObject::Extends->new($element3);
    $element1->mock("all_text", sub {return "content item 1";});
    $element2->mock("all_text", sub {return "content item 2";});
    $element3->mock("all_text", sub {return "content item 3";});

    my $items = Mojo::Collection->new($element1, $element2, $element3);
    $domHelper->mock("GetCollectionFromDOM", sub{return $items;});

    my $contents;
    lives_ok {$contents = $crawler->_GetContents($dom);};
    is($contents, "content item 1\ncontent item 2\ncontent item 3", "return value ok");

    my ($call, $params) = $domHelper->next_call;
    is($call, "GetCollectionFromDOM", "GetCollectionFromDOM called ok");
    is($params->[1], $dom, "param 1 ok");
    is($params->[2], 'div.preparation > ol > li', "param 2 ok");
    $domHelper->clear;

    ($call, $params) = $element1->next_call;
    is($call, "all_text", "all_text called ok 1");
    ($call, $params) = $element2->next_call;
    is($call, "all_text", "all_text called ok 2");
    ($call, $params) = $element3->next_call;
    is($call, "all_text", "all_text called ok 3");
  }

  diag('test normal second possibility');
  {
    my $dom = Mojo::DOM->new;
    my $element = Mojo::DOM->new;
    $element = Test::MockObject::Extends->new($element);
    $element->mock("all_text", sub {return "content item";});

    $domHelper->mock("GetCollectionFromDOM", sub {return Mojo::Collection->new;});
    $domHelper->mock("GetElementFromDOM", sub {return $element;});

    my $contents;
    lives_ok {$contents = $crawler->_GetContents($dom);};
    is($contents, "content item", "return value ok");

    my ($call, $params) = $domHelper->next_call;
    is($call, "GetCollectionFromDOM", "GetCollectionFromDOM called ok");
    is($params->[1], $dom, "param 1 ok");
    is($params->[2], 'div.preparation > ol > li', "param 2 ok");
    ($call, $params) = $domHelper->next_call;
    is($call, "GetElementFromDOM", "GetCollectionFromDOM called ok");
    is($params->[1], $dom, "param 1 ok");
    is($params->[2], 'div.preparation', "param 2 ok");
    $domHelper->clear;

    ($call, $params) = $element->next_call;
    is($call, "all_text", "all_text called ok 2");
  }

  diag('test no contents found');
  {
    my $dom = Mojo::DOM->new;
    my $element = Mojo::DOM->new;

    $domHelper->mock("GetCollectionFromDOM", sub {return Mojo::Collection->new;});
    $domHelper->mock("GetElementFromDOM", sub {return undef;});

    my $contents;
    lives_ok {$contents = $crawler->_GetContents($dom);};
    is($contents, "", "return value ok");

    my ($call, $params) = $domHelper->next_call;
    is($call, "GetCollectionFromDOM", "GetCollectionFromDOM called ok");
    is($params->[1], $dom, "param 1 ok");
    is($params->[2], 'div.preparation > ol > li', "param 2 ok");
    ($call, $params) = $domHelper->next_call;
    is($call, "GetElementFromDOM", "GetCollectionFromDOM called ok");
    is($params->[1], $dom, "param 1 ok");
    is($params->[2], 'div.preparation', "param 2 ok");
    $domHelper->clear;
  }

  diag('test undefined elements in collection');
  {
    my $dom = Mojo::DOM->new;
    my $element1 = Mojo::DOM->new;
    my $element2 = undef;
    my $element3 = Mojo::DOM->new;
    $element1 = Test::MockObject::Extends->new($element1);
    $element3 = Test::MockObject::Extends->new($element3);
    $element1->mock("all_text", sub {return "content item 1";});
    $element3->mock("all_text", sub {return "content item 3";});

    my $items = Mojo::Collection->new($element1, $element2, $element3);
    $domHelper->mock("GetCollectionFromDOM", sub{return $items;});

    my $contents;
    lives_ok {$contents = $crawler->_GetContents($dom);};
    is($contents, "content item 1\ncontent item 3", "return value ok");

    my ($call, $params) = $domHelper->next_call;
    is($call, "GetCollectionFromDOM", "GetCollectionFromDOM called ok");
    is($params->[1], $dom, "param 1 ok");
    is($params->[2], 'div.preparation > ol > li', "param 2 ok");
    $domHelper->clear;

    ($call, $params) = $element1->next_call;
    is($call, "all_text", "all_text called ok 1");
    ($call, $params) = $element3->next_call;
    is($call, "all_text", "all_text called ok 3");
  }
}

diag('#####################');
diag('#     _GetChef      #');
diag('#####################');
{
  my $domHelper = DOMHelper->new;
  $domHelper = Test::MockObject::Extends->new($domHelper);
  my $crawler = ZestaCrawler->new(ArticleService => mock_anon_class('ArticleService')->new_object(Db => mock_anon_class('CouchDB::Client::DB')->new_object),
                                  UserAgent => mock_anon_class('Mojo::UserAgent')->new_object,
                                  DOMHelper => $domHelper);
  $crawler = Test::MockObject::Extends->new($crawler);

  diag('test no param');
  {
    dies_ok {$crawler->_GetChef;};
  }

  diag('test normal');
  {
    my $recipe = Mojo::DOM->new;
    my $element = "element";
    my $expectedResult = "result";
    $domHelper->mock("GetElementFromDOM", sub{return $element;});
    $crawler->mock("_GetTextElement", sub{return $expectedResult;});

    my $result;
    lives_ok {$result = $crawler->_GetChef($recipe);};
    is($result, $expectedResult, "return value ok");

    my ($call, $params);
    ($call, $params) = $domHelper->next_call;
    is($call, "GetElementFromDOM", "GetElementFromDOM called ok");
    is($params->[1], $recipe, "param 1 ok");
    is($params->[2], "div.views-field-field-recipe-person-nid a", "param 2 ok");
    $domHelper->clear;

    ($call, $params) = $crawler->next_call;
    is($call, "_GetTextElement", "_GetTextElement called ok");
    is($params->[1], $element, "param 1 ok");
    $crawler->clear;
  }

  diag('test element not found');
  {
    my $recipe = Mojo::DOM->new;
    my $element = undef;
    my $expectedResult = '';
    $domHelper->mock("GetElementFromDOM", sub{return $element;});

    my $result;
    lives_ok {$result = $crawler->_GetChef($recipe);};
    is($result, $expectedResult, "return value ok");

    my ($call, $params);
    ($call, $params) = $domHelper->next_call;
    is($call, "GetElementFromDOM", "GetElementFromDOM called ok");
    is($params->[1], $recipe, "param 1 ok");
    is($params->[2], "div.views-field-field-recipe-person-nid a", "param 2 ok");
    $domHelper->clear;
  }

  diag('test no text in element');
  {
    my $recipe = Mojo::DOM->new;
    my $element = "element";
    my $expectedResult = "";
    $domHelper->mock("GetElementFromDOM", sub{return $element;});
    $crawler->mock("_GetTextElement", sub{return $expectedResult;});

    my $result;
    lives_ok {$result = $crawler->_GetChef($recipe);};
    is($result, $expectedResult, "return value ok");

    my ($call, $params);
    ($call, $params) = $domHelper->next_call;
    is($call, "GetElementFromDOM", "GetElementFromDOM called ok");
    is($params->[1], $recipe, "param 1 ok");
    is($params->[2], "div.views-field-field-recipe-person-nid a", "param 2 ok");
    $domHelper->clear;

    ($call, $params) = $crawler->next_call;
    is($call, "_GetTextElement", "_GetTextElement called ok");
    is($params->[1], $element, "param 1 ok");
    $crawler->clear;
  }
}

diag('#####################');
diag('#  _GetDifficulty   #');
diag('#####################');
{
  my $domHelper = DOMHelper->new;
  $domHelper = Test::MockObject::Extends->new($domHelper);
  my $crawler = ZestaCrawler->new(ArticleService => mock_anon_class('ArticleService')->new_object(Db => mock_anon_class('CouchDB::Client::DB')->new_object),
                                  UserAgent => mock_anon_class('Mojo::UserAgent')->new_object,
                                  DOMHelper => $domHelper);
  $crawler = Test::MockObject::Extends->new($crawler);

  diag('test no param');
  {
    dies_ok {$crawler->_GetDifficulty;};
  }

  diag('test normal');
  {
    my $recipe = Mojo::DOM->new;
    my $element = "element";
    my $expectedResult = "result";
    $domHelper->mock("GetElementFromDOM", sub{return $element;});
    $crawler->mock("_GetTextElement", sub{return $expectedResult;});

    my $result;
    lives_ok {$result = $crawler->_GetDifficulty($recipe);};
    is($result, $expectedResult, "return value ok");

    my ($call, $params);
    ($call, $params) = $domHelper->next_call;
    is($call, "GetElementFromDOM", "GetElementFromDOM called ok");
    is($params->[1], $recipe, "param 1 ok");
    is($params->[2], "div.views-field-field-recipe-difficulty-value > .field-content", "param 2 ok");
    $domHelper->clear;

    ($call, $params) = $crawler->next_call;
    is($call, "_GetTextElement", "_GetTextElement called ok");
    is($params->[1], $element, "param 1 ok");
    $crawler->clear;
  }

  diag('test element not found');
  {
    my $recipe = Mojo::DOM->new;
    my $element = undef;
    my $expectedResult = '';
    $domHelper->mock("GetElementFromDOM", sub{return $element;});

    my $result;
    lives_ok {$result = $crawler->_GetDifficulty($recipe);};
    is($result, $expectedResult, "return value ok");

    my ($call, $params);
    ($call, $params) = $domHelper->next_call;
    is($call, "GetElementFromDOM", "GetElementFromDOM called ok");
    is($params->[1], $recipe, "param 1 ok");
    is($params->[2], "div.views-field-field-recipe-difficulty-value > .field-content", "param 2 ok");
    $domHelper->clear;
  }

  diag('test no text in element');
  {
    my $recipe = Mojo::DOM->new;
    my $element = "element";
    my $expectedResult = "";
    $domHelper->mock("GetElementFromDOM", sub{return $element;});
    $crawler->mock("_GetTextElement", sub{return $expectedResult;});

    my $result;
    lives_ok {$result = $crawler->_GetDifficulty($recipe);};
    is($result, $expectedResult, "return value ok");

    my ($call, $params);
    ($call, $params) = $domHelper->next_call;
    is($call, "GetElementFromDOM", "GetElementFromDOM called ok");
    is($params->[1], $recipe, "param 1 ok");
    is($params->[2], "div.views-field-field-recipe-difficulty-value > .field-content", "param 2 ok");
    $domHelper->clear;

    ($call, $params) = $crawler->next_call;
    is($call, "_GetTextElement", "_GetTextElement called ok");
    is($params->[1], $element, "param 1 ok");
    $crawler->clear;
  }
}

diag('#####################');
diag('#  _GetKitchenType  #');
diag('#####################');
{
  my $domHelper = DOMHelper->new;
  $domHelper = Test::MockObject::Extends->new($domHelper);
  my $crawler = ZestaCrawler->new(ArticleService => mock_anon_class('ArticleService')->new_object(Db => mock_anon_class('CouchDB::Client::DB')->new_object),
                                  UserAgent => mock_anon_class('Mojo::UserAgent')->new_object,
                                  DOMHelper => $domHelper);
  $crawler = Test::MockObject::Extends->new($crawler);

  diag('test no param');
  {
    dies_ok {$crawler->_GetKitchenType;};
  }

  diag('test normal');
  {
    my $recipe = Mojo::DOM->new;
    my $element = "element";
    my $expectedResult = "result";
    $domHelper->mock("GetElementFromDOM", sub{return $element;});
    $crawler->mock("_GetTextElement", sub{return $expectedResult;});

    my $result;
    lives_ok {$result = $crawler->_GetKitchenType($recipe);};
    is($result, $expectedResult, "return value ok");

    my ($call, $params);
    ($call, $params) = $domHelper->next_call;
    is($call, "GetElementFromDOM", "GetElementFromDOM called ok");
    is($params->[1], $recipe, "param 1 ok");
    is($params->[2], "div.views-field-field-recipe-kitchen-nid > .field-content", "param 2 ok");
    $domHelper->clear;

    ($call, $params) = $crawler->next_call;
    is($call, "_GetTextElement", "_GetTextElement called ok");
    is($params->[1], $element, "param 1 ok");
    $crawler->clear;
  }

  diag('test element not found');
  {
    my $recipe = Mojo::DOM->new;
    my $element = undef;
    my $expectedResult = '';
    $domHelper->mock("GetElementFromDOM", sub{return $element;});

    my $result;
    lives_ok {$result = $crawler->_GetKitchenType($recipe);};
    is($result, $expectedResult, "return value ok");

    my ($call, $params);
    ($call, $params) = $domHelper->next_call;
    is($call, "GetElementFromDOM", "GetElementFromDOM called ok");
    is($params->[1], $recipe, "param 1 ok");
    is($params->[2], "div.views-field-field-recipe-kitchen-nid > .field-content", "param 2 ok");
    $domHelper->clear;
  }

  diag('test no text in element');
  {
    my $recipe = Mojo::DOM->new;
    my $element = "element";
    my $expectedResult = "";
    $domHelper->mock("GetElementFromDOM", sub{return $element;});
    $crawler->mock("_GetTextElement", sub{return $expectedResult;});

    my $result;
    lives_ok {$result = $crawler->_GetKitchenType($recipe);};
    is($result, $expectedResult, "return value ok");

    my ($call, $params);
    ($call, $params) = $domHelper->next_call;
    is($call, "GetElementFromDOM", "GetElementFromDOM called ok");
    is($params->[1], $recipe, "param 1 ok");
    is($params->[2], "div.views-field-field-recipe-kitchen-nid > .field-content", "param 2 ok");
    $domHelper->clear;

    ($call, $params) = $crawler->next_call;
    is($call, "_GetTextElement", "_GetTextElement called ok");
    is($params->[1], $element, "param 1 ok");
    $crawler->clear;
  }
}


diag('#####################');
diag('#  _HandleRecipe    #');
diag('#####################');
{
  my $articleService = ArticleService->new(Db => mock_anon_class('CouchDB::Client::DB')->new_object);
  $articleService = Test::MockObject::Extends->new($articleService);
  my $crawler = ZestaCrawler->new(ArticleService => $articleService,
                                  UserAgent => mock_anon_class('Mojo::UserAgent')->new_object,
                                  DOMHelper => mock_anon_class('DOMHelper')->new_object);
  $crawler = Test::MockObject::Extends->new($crawler);

  diag('test without link param');
  {
    dies_ok {$crawler->_HandleRecipe;};
  }

  diag('test with invalid link');
  {
    $crawler->mock("_FetchPage", sub {return undef;});
    lives_ok {$crawler->_HandleRecipe("blablabla");};
    my ($call, $params) = $crawler->next_call;
    is($call, "_FetchPage", "_FetchPage called ok");
    is($params->[1], "http://zesta.beblablabla", "_FetchPage called with correct param");
    $crawler->clear;
  }

  diag('test normal');
  {
    my $dom = Mojo::DOM->new;

    my $resp = Mojo::Message::Response->new;
    $resp = Test::MockObject::Extends->new($resp);
    $resp->mock("dom", sub {return $dom});

    $crawler->mock("_FetchPage", sub {return $resp;});
    my $expectedTitle = 'title';
    my @expectedIngredients = ("one", "two", "three");
    my $expectedContent = "content";
    my $expectedChef = "chef";
    my $expectedDifficulty = "difficulty";
    my $expectedKitchenType = "kitchentype";
    my $expectedThumbUri = "thumburi";
    $crawler->mock("_FetchPage", sub {return $resp;});
    $crawler->mock("_GetTitle", sub {return $expectedTitle;});
    $crawler->mock("_GetIngredients", sub {return @expectedIngredients;});
    $crawler->mock("_GetContents", sub {return $expectedContent;});
    $crawler->mock("_GetChef", sub {return $expectedChef;});
    $crawler->mock("_GetDifficulty", sub {return $expectedDifficulty;});
    $crawler->mock("_GetKitchenType", sub {return $expectedKitchenType;});

    my $link = "/testrecipe";
    my $expectedArticle = Article->new(title => $expectedTitle,
                                       source => 'zesta.be',
                                       url => 'http://zesta.be/testrecipe',
                                       chef => $expectedChef,
                                       ingredients => \@expectedIngredients,
                                       contents => $expectedContent,
                                       difficulty => $expectedDifficulty,
                                       kitchentype => $expectedKitchenType,
                                       thumb => $resp
                                      );

    $articleService->mock("CreateOrUpdate", sub{});

    lives_ok {$crawler->_HandleRecipe($link, $expectedThumbUri);};

    my ($call, $params);
    ($call, $params) = $crawler->next_call;
    is($call, "_FetchPage", "_FetchPage called ok");
    is($params->[1], "http://zesta.be/testrecipe", "param 1 ok");
    ok($crawler->called("_GetTitle"), "_GetTitle called");
    ok($crawler->called("_GetIngredients"), "_GetIngredients called");
    ok($crawler->called("_GetContents"), "_GetContents called");
    ok($crawler->called("_GetChef"), "_GetChef called");
    ok($crawler->called("_GetDifficulty"), "_GetDifficulty called");
    ok($crawler->called("_GetKitchenType"), "_GetKitchenType called");
    ($call, $params) = $crawler->next_call(7);
    is($call, "_FetchPage", "_FetchPage called ok for thumb");
    is($params->[1], $expectedThumbUri, "param 1 ok");
    $crawler->clear;

    ($call, $params) = $articleService->next_call;
    is($call, "CreateOrUpdate", "CreateOrUpdate called ok");
    isa_ok($params->[1], 'Article', "param 1 of correct type");
    is_deeply($params->[1], $expectedArticle, "param 1 ok");
  }
}

diag('#####################');
diag('#  _GetTextElement  #');
diag('#####################');

diag('#####################');
diag('#  _GetLastPage     #');
diag('#####################');

diag('#####################');
diag('#  _FetchPage       #');
diag('#####################');
