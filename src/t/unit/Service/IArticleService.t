# -*- mode: cperl -*-
use MooseX::Test::Role;
use Test::More tests => 3;
use Service::IArticleService;

requires_ok('IArticleService', qw/_storeThumb/);
requires_ok('IArticleService', qw/CreateOrUpdate/);
requires_ok('IArticleService', qw/NumberOfArticles/);

