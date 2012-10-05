use MooseX::Declare;
use MooseX::Types::URI;

class CrawlerParameters {
  has Name => (is => 'ro',
               isa => 'Str',
               required => 1);

  has GetLastPageUri => (is => 'ro',
                         isa => 'MooseX::Types::URI',
                         required => 1);

  has GetLastPageSelectorForLink => (is => 'ro',
                                     isa => 'Str',
                                     required => 1);

  has GetLastPageRegexForPagenumber => (is => 'ro',
                                        isa => 'Str',
                                        required => 1);

  has FetchPageURI => (is => 'ro',
                       isa => 'MooseX::Types::URI', # must contain $page
                       required => 1,
                       writer => '_setFetchPageURI');

  has CrawlPageSelectorForRecipes => (is => 'ro',
                                      isa => 'Str',
                                      required => 1);

  has CrawlPageSelectorForRecipeLink => (is => 'ro',
                                         isa => 'Str',
                                         required => 1);

  has CrawlPageSelectorForImageLink => (is => 'ro',
                                        isa => 'Str',
                                        required => 1);

  has CrawlRecipeSelectorForTitle => (is => 'ro',
                                      isa => 'Str',
                                      required => 1);

  has CrawlRecipeSelectorForIngredients => (is => 'ro',
                                            isa => 'ArrayRef[Str]',
                                            required => 1);

  has CrawlRecipeSelectorForContents => (is => 'ro',
                                         isa => 'Str',
                                         required => 1);

  has CrawlRecipeSelectorForChef => (is => 'ro',
                                     isa => 'Str',
                                     required => 1);

  has CrawlRecipeSelectorForDifficulty => (is => 'ro',
                                           isa => 'Str',
                                           required => 1);

  has CrawlRecipeSelectorForKitchentype => (is => 'ro',
                                            isa => 'Str',
                                            required => 1);


  method _setFetchPageURI($uri!) {
    if ($uri->as_string() !~ /\$page/) {
      die "CrawlerParameters.FetchPageURI must contain the substring \$page";
    }
  }
}

  1;
