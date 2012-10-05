use MooseX::Declare;
use Domain::Article;
use Service::ISearcherService;
use ElasticSearch;
use Data::Dumper;
use Domain::SearchResults;

class SearcherService with ISearcherService {
  has Elastic => (isa => 'ElasticSearch',
                  is => 'ro',
                  required => 1,
                  lazy => 1,
                  default => sub {
                    my $self = shift;
                    my $e = ElasticSearch->new(servers => $self->config->Contents->get_elastic_search_servers);
                    $e->trace_calls('log/elastic.log');
                    return $e
                  });

  has Logger => (isa => 'Mojo::Log',
                 is => 'ro',
                 required => 1);

  method _analyze(Str $querystring) {
    my $curterm = '';
    my $in_phrase = 0;
    my @terms = ();
    while ($querystring =~ /(.)/g) {
      if ($1 eq '"') {
        if ($in_phrase) {
          # found a term
          push @terms, $curterm;
          $curterm = '';
          $in_phrase = 0;
        } else {
          $in_phrase = 1;
        }
      } elsif ($1 eq ' ' && !$in_phrase) {
        if (length $curterm > 0) {
          # found a term
          push @terms, $curterm;
          $curterm = '';
        }
      } else {
        $curterm .= $1;
      }
    }
    push @terms, $curterm if length $curterm > 0;
    return @terms;
  }

  method SearchAll(Str $querystring!, Int $page!, Int $pageSize!) { # returns Domain::SearchResults;
    $self->Logger->debug("Searching for $querystring, page $page (pagesize $pageSize)");

    my @recipes = ();
    my $lastPage = 0;
    my $results;
    my $totalResults = 0;
    my $searchDuration = 0;

    my @terms = $self->_analyze($querystring);
    if (scalar @terms > 0) {

      my @shouldArray;
      foreach my $term (@terms) {
        push @shouldArray, {text_phrase => {_all => $term}};
      }

      $results = $self->Elastic->search(
                                        index => 'foood',
                                        type => 'foood',
                                        size => $pageSize,
                                        from => $pageSize * $page,
                                        query => {
                                                  bool => {
                                                           should => \@shouldArray
                                                          }
                                                 }
                                       );

      $lastPage = int(($results->{hits}->{total} / $pageSize));
      $self->Logger->debug("found " . $results->{hits}->{total} . " results...");

      foreach my $result (@{$results->{hits}->{hits}}) {
        if ($result->{_type} eq 'foood') {
          push @recipes, Article->new(
                                      chef => $result->{_source}->{chef} || '',
                                      contents => $result->{_source}->{content} || '',
                                      difficulty => $result->{_source}->{difficulty} || '',
                                      ingredients => $result->{_source}->{ingredients} || [],
                                      kitchentype => $result->{_source}->{kitchentype} || '',
                                      source => $result->{_source}->{source} || '',
                                      title => $result->{_source}->{title} || '',
                                      url => $result->{_source}->{url} || '',
                                      thumb_uri => $result->{_source}->{thumb_uri}
                                     );
        }
      }

      $totalResults = $results->{hits}->{total};
      $searchDuration = $results->{took} / 1000;
    }

    my $retval = SearchResults->new(lastPage => $lastPage,
                                    page => \@recipes,
                                    totalResults => $totalResults,
                                    searchDuration => $searchDuration);

    return $retval;
  }
}

  1;
