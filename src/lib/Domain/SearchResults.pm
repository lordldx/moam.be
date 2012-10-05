use MooseX::Declare;
use Domain::Article;

class SearchResults {
  has lastPage => (is => 'ro',
                   isa => 'Int',
                   required => 1);

  has page => (is => 'ro',
               isa => 'ArrayRef[Article]',
               required => 1);

  has totalResults => (is => 'ro',
                       isa => 'Int',
                       required => 1);

  has searchDuration => (is => 'ro',
                         isa => 'Num',
                         required => 1); # in milliseconds

  method AsUnblessedReference() { # for serializing to json
    my $page = [];

    foreach my $article (@{$self->page}) {
      push @$page, $article->AsUnblessedReference;
    }

    return {
            lastPage => $self->lastPage,
            page => $page,
            totalResults => $self->totalResults,
            searchDuration => $self->searchDuration
           };
  }
}

  1;
