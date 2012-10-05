
use MooseX::Declare;

role ISearcherService {
  has config => (isa => 'FooodConfig',
                 is => 'ro',
                 required => 1);

  requires 'SearchAll';
}

1;
