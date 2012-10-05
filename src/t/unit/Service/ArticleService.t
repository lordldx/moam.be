# -*- mode: cperl -*-
use Test::Moose;
use Test::More tests => 36;
use Test::Exception;
use Test::MockObject::Extends;

use Service::ArticleService;

meta_ok(ArticleService);
does_ok(ArticleService, IArticleService);
has_attribute_ok(ArticleService, Db);

# Mock for CouchDB::Client::DB
{
  use MooseX::Declare;

  class CouchDB::Client::DB {
    has docExistsCalled => (isa => 'Bool',
                            is => 'rw',
                            default => 0);

    has docExistsParam => (isa => 'Str',
                           is => 'rw');

    has docExistsReturnValue => (isa => 'Bool',
                                 is => 'ro',
                                 required => 1);

    has newDocCalled => (isa => 'Bool',
                         is => 'rw',
                         default => 0);

    has newDocIdParam => (isa => 'Str',
                          is => 'rw');

    has doc => (isa => 'CouchDB::Client::Doc',
                is => 'ro',
                required => 1,
                default => sub{CouchDB::Client::Doc->new});

    method docExists(Str $param1) {
      $self->docExistsCalled(1);
      $self->docExistsParam($param1);
      return $self->docExistsReturnValue;
    }

    method newDoc(Str $id) {
      $self->newDocCalled(1);
      $self->newDocIdParam($id);
      return $self->doc;
    }
  }
}

# Mock for CouchDB::Client::Doc
{
  use MooseX::Declare;

  class CouchDB::Client::Doc {
    has retrieveCalled => (isa => 'Bool',
                           is => 'rw',
                           default => 0);
    has updateCalled => (isa => 'Bool',
                         is => 'rw',
                         default => 0);
    has createCalled => (isa => 'Bool',
                         is => 'rw',
                         default => 0);
    has data => (isa => 'HashRef',
                 is => 'rw',
                 required => 1,
                 default => sub{{}});

    method retrieve() {
      $self->retrieveCalled(1);
    }
    method update() {
      $self->updateCalled(1);
    }
    method create() {
      $self->createCalled(1);
    }
  }
}

# Actual tests

# Test 1: Add a new document
{
  my $db = CouchDB::Client::DB->new(docExistsReturnValue => 0);
  my $articleService = new_ok('ArticleService' => [Db => $db]);
  $articleService = Test::MockObject::Extends->new($articleService);
  $articleService->mock('_storeThumb', sub {});
  my $article = Article->new(title => 'titel 1',
                             source => 'source 1',
                             url => 'url 1',
                             chef => 'chef 1',
                             ingredients => ['Ingredient 1.1', 'Ingredient 1.2'],
                             difficulty => 'difficulty 1',
                             kitchentype => 'kitchentype 1',
                             contents => 'contents 1',
                             thumb_uri => 'thumburi 1');

  lives_ok {$articleService->CreateOrUpdate($article)};
  my ($name, $args) = $articleService->next_call;
  is($name, '_storeThumb');
  is($args->[1], 'thumburi 1');

  is($db->newDocCalled, 1, 'newDoc method called');
  is($db->newDocIdParam, $article->url, 'newDoc called with correct parameter');
  is($db->docExistsCalled, 1, 'docExists called');
  is($db->docExistsParam, $article->url, 'docExists called with correct parameter');
  my $doc = $db->doc;
  is($doc->retrieveCalled, 0, 'retrieve not called');
  is_deeply($doc->data, $article->AsUnblessedReference, 'data filled in with correct value');
  is($doc->updateCalled, 0, 'update not called');
  is($doc->createCalled, 1, 'create called');
}

# Test 2: Update an existing document
{
  my $db = CouchDB::Client::DB->new(docExistsReturnValue => 1);
  my $articleService = new_ok('ArticleService' => [Db => $db]);
  $articleService = Test::MockObject::Extends->new($articleService);
  my $article1 = Article->new(title => 'titel 1',
                              source => 'source 1',
                              url => 'url 1',
                              chef => 'chef 1',
                              ingredients => ['Ingredient 1.1', 'Ingredient 1.2'],
                              difficulty => 'difficulty 1',
                              kitchentype => 'kitchentype 1',
                              contents => 'contents 1');
  my $article2 = Article->new(title => 'titel 2',
                              source => 'source 2',
                              url => 'url 2',
                              chef => 'chef 2',
                              ingredients => ['Ingredient 2.1', 'Ingredient 2.2'],
                              difficulty => 'difficulty 2',
                              kitchentype => 'kitchentype 2',
                              contents => 'contents 2');
  $db->doc->data($article1->AsUnblessedReference);

  lives_ok {$articleService->CreateOrUpdate($article2)};

  # no thumb_uri was provided => _storeThumb should not be called
  is($articleService->next_call, undef);

  is($db->newDocCalled, 1, 'newDoc method called');
  is($db->newDocIdParam, $article2->url, 'newDoc called with correct parameter');
  is($db->docExistsCalled, 1, 'docExists called');
  is($db->docExistsParam, $article2->url, 'docExists called with correct parameter');
  my $doc = $db->doc;
  is($doc->retrieveCalled, 1, 'retrieve called');
  is_deeply($doc->data, $article2->AsUnblessedReference, 'data correctly updated');
  is($doc->updateCalled, 1, 'update called');
  is($doc->createCalled, 0, 'create not called');
}

# Test 3: Update an existing document without changes (should not update)
{
  my $db = CouchDB::Client::DB->new(docExistsReturnValue => 1);
  my $articleService = new_ok('ArticleService' => [Db => $db]);
  my $article = Article->new(title => 'titel 3',
                             source => 'source 3',
                             url => 'url 3',
                             chef => 'chef 3',
                             ingredients => ['Ingredient 3.1', 'Ingredient 3.2'],
                             difficulty => 'difficulty 3',
                             kitchentype => 'kitchentype 3',
                             contents => 'contents 3');
  $db->doc->data($article->AsUnblessedReference);

  lives_ok {$articleService->CreateOrUpdate($article)};
  is($db->newDocCalled, 1, 'newDoc method called');
  is($db->newDocIdParam, $article->url, 'newDoc called with correct parameter');
  is($db->docExistsCalled, 1, 'docExists called');
  is($db->docExistsParam, $article->url, 'docExists called with correct parameter');
  my $doc = $db->doc;
  is($doc->retrieveCalled, 1, 'retrieve called');
  is_deeply($doc->data, $article->AsUnblessedReference, 'data still the same');
  is($doc->updateCalled, 0, 'update not called');
  is($doc->createCalled, 0, 'create not called');
}
