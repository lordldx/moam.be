package Foood;
use Mojo::Base 'Mojolicious';
use Mojolicious::Plugin::Mail;

use CouchDB::Client;
use Captcha::reCAPTCHA;

use FooodConfig;
use constant CONFIG_PATH => scalar "cfg/foood.yml";

use Service::SearcherService;
use Service::ArticleService;

# This method will run once at server start
sub startup {
  my $self = shift;

  $self->secret('667e895a-da17-4c42-8022-5acfa0f9f7e2');

  # config
  $self->helper(cfg => sub {FooodConfig->new(FileLocation => CONFIG_PATH)});

  # searcherService
  my $searcherService = SearcherService->new(config => $self->cfg,
                                             Logger => $self->log);
  $self->helper(SearcherService => sub{return $searcherService;});

  # articleService
  # initialize the db
  my $db = CouchDB::Client->new;
  $db->testConnection or die "Failed to connect to CouchDB";
  # initialize the ArticleService
  my $articleService = ArticleService->new(Db => $db->newDB('foood'),
                                           config => $self->cfg);
  $self->helper(ArticleService => sub{return $articleService;});

  # emailing
  $self->plugin(mail => {
                         how => 'smtp',
                         howargs => [$self->cfg->Contents->get_smtp_server]
                        });

  # captcha
  $self->helper(reCAPTCHA => sub{Captcha::reCAPTCHA->new->get_html($_[1])});

    # Routes
    my $r = $self->routes;

  # Main controller
  $r->route('/')->via('get')->to(namespace => 'Foood::Controllers',
                                 controller => 'Main',
                                 action => 'index');

  $r->route('/search')->via('post')->to(namespace => 'Foood::Controllers',
                                        controller => 'Main',
                                        action => 'search');

  $r->route('/search')->via('get')->to(namespace => 'Foood::Controllers',
                                       controller => 'Main',
                                       action => 'search_json');

  $r->route('/NumRecipesInDb')->via('get')->to(namespace => 'Foood::Controllers',
                                               controller => 'Main',
                                               action => 'numRecipesInDb');
  $r->route('/contact')->via('get')->to(namespace => 'Foood::Controllers',
                                        controller => 'Contact',
                                        action => 'index');
  $r->route('/contact')->via('post')->to(namespace => 'Foood::Controllers',
                                         controller => 'Contact',
                                         action => 'send');
}

1;
