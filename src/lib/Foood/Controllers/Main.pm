package Foood::Controllers::Main;
use base 'Mojolicious::Controller';

use constant DEFAULT_PAGE => scalar 0;
use constant DEFAULT_PAGE_SIZE => scalar 10;

sub index {
  shift->render('Main/index');
}

sub search {
  my $c = shift;
  my $term = $c->param('mainsearch');
  my $page = $c->param('page') || DEFAULT_PAGE;
  my $pageSize = $c->param('pageSize') || DEFAULT_PAGE_SIZE;

  $c->app->log->debug("New search: term = $term, page = $page, pageSize = $pageSize");
  my $results;
  eval {
    $results = $c->SearcherService->SearchAll($term, $page, $pageSize);
  };
  if ($@) {
    $c->app->log->error("ERROR: $@");
    $c->stash(error => $@);
  } else {
  $c->stash(results => $results,
            term => $term,
            currentPage => $page,
            pageSize => $pageSize);
  }

  $c->render('Main/searchresults');
}

sub search_json {
  my $c = shift;
  my $term = $c->param('mainsearch');
  my $page = $c->param('page') || DEFAULT_PAGE;
  my $pageSize = $c->param('pageSize') || DEFAULT_PAGE_SIZE;

  my $results;
  eval {
    $results = $c->SearcherService->SearchAll($term, $page, $pageSize);
  };
  if ($@) {
    $c->render_json(error => $@);
  } else {
    $c->render_json({
                     results => $c->SearcherService->SearchAll($term, $page, $pageSize)->AsUnblessedReference
                    });
  }
}

sub numRecipesInDb {
  my $c = shift;

  my $numRecipesInDb;
  my $success = 1;
  eval {
    $numRecipesInDb = $c->ArticleService->NumberOfArticles();
  };
  if ($@) {
    $success = 0;
  }

  $c->render_json({Success => $success,
                   NumRecipesInDb => $numRecipesInDb});
}

1;
