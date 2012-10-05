use MooseX::Declare;

role IArticleService {
  requires '_storeThumb';
  requires 'CreateOrUpdate';
  requires 'NumberOfArticles';

  has config => (isa => 'FooodConfig',
                 is => 'ro',
                 required => 1);

  has DEBUG => (is => 'ro',
                isa => 'Bool',
                required => 1,
                default => sub {$ENV{'FOOOD_CRAWLER_DEBUG'}});
}

1;
