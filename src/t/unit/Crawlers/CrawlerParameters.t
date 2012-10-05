use strict;
use Test::More tests => 18;
use Test::Moose;
use Test::Exception;

BEGIN {
  use_ok('Crawlers::CrawlerParameters');
}

diag('basic tests');
meta_ok('CrawlerParameters');
has_attribute_ok('CrawlerParameters', 'Name');
has_attribute_ok('CrawlerParameters', 'GetLastPageUri');
has_attribute_ok('CrawlerParameters', 'GetLastPageSelectorForLink');
has_attribute_ok('CrawlerParameters', 'GetLastPageRegexForPagenumber');
has_attribute_ok('CrawlerParameters', 'FetchPageURI');
has_attribute_ok('CrawlerParameters', 'CrawlPageSelectorForRecipes');
has_attribute_ok('CrawlerParameters', 'CrawlPageSelectorForRecipeLink');
has_attribute_ok('CrawlerParameters', 'CrawlPageSelectorForImageLink');
has_attribute_ok('CrawlerParameters', 'CrawlRecipeSelectorForTitle');
has_attribute_ok('CrawlerParameters', 'CrawlRecipeSelectorForIngredients');
has_attribute_ok('CrawlerParameters', 'CrawlRecipeSelectorForContents');
has_attribute_ok('CrawlerParameters', 'CrawlRecipeSelectorForChef');
has_attribute_ok('CrawlerParameters', 'CrawlRecipeSelectorForDifficulty');
has_attribute_ok('CrawlerParameters', 'CrawlRecipeSelectorForKitchentype');

diag('####################');
diag('# _setFetchPageURI #');
diag('####################');
{
  lives_ok {
    CrawlerParameters->new(
                           Name => 'Name',
                           GetLastPageUri => MooseX::Types::URI->new('http://www.moam.be'),
                           GetLastPageSelectorForLink => 'GetLastPageSelectorForLink',
                           GetLastPageRegexForPagenumber => 'GetLastPageRegexForPagenumber',
                           FetchPageURI => MooseX::Types::URI->new('http://www.moam.be?page=$page'),
                           CrawlPageSelectorForRecipes => ['CrawlPageSelectorForRecipes'],
                           CrawlPageSelectorForRecipeLink => 'CrawlPageSelectorForRecipeLink',
                           CrawlPageSelectorForImageLink => 'CrawlPageSelectorForImageLink',
                           CrawlRecipeSelectorForTitle => 'CrawlRecipeSelectorForTitle',
                           CrawlRecipeSelectorForIngredients => 'CrawlRecipeSelectorForIngredients',
                           CrawlRecipeSelectorForContents => 'CrawlRecipeSelectorForContents',
                           CrawlRecipeSelectorForChef => 'CrawlRecipeSelectorForChef',
                           CrawlRecipeSelectorForDifficulty => 'CrawlRecipeSelectorForDifficulty',
                           CrawlRecipeSelectorForKitchentype => 'CrawlRecipeSelectorForKitchentype',
                          );
  } "Can create CrawlerParameters";

  dies_ok {
    CrawlerParameters->new(
                           Name => 'Name',
                           GetLastPageUri => MooseX::Types::URI->new('http://www.moam.be'),
                           GetLastPageSelectorForLink => 'GetLastPageSelectorForLink',
                           GetLastPageRegexForPagenumber => 'GetLastPageRegexForPagenumber',
                           FetchPageURI => MooseX::Types::URI->new('http://www.moam.be'),
                           CrawlPageSelectorForRecipes => ['CrawlPageSelectorForRecipes'],
                           CrawlPageSelectorForRecipeLink => 'CrawlPageSelectorForRecipeLink',
                           CrawlPageSelectorForImageLink => 'CrawlPageSelectorForImageLink',
                           CrawlRecipeSelectorForTitle => 'CrawlRecipeSelectorForTitle',
                           CrawlRecipeSelectorForIngredients => 'CrawlRecipeSelectorForIngredients',
                           CrawlRecipeSelectorForContents => 'CrawlRecipeSelectorForContents',
                           CrawlRecipeSelectorForChef => 'CrawlRecipeSelectorForChef',
                           CrawlRecipeSelectorForDifficulty => 'CrawlRecipeSelectorForDifficulty',
                           CrawlRecipeSelectorForKitchentype => 'CrawlRecipeSelectorForKitchentype',
                          );
  } "Dies when FetchPageURI does not contain \$page";
}
