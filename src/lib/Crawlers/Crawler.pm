use MooseX::Declare;

use Crawlers::ICrawler;
use Crawlers::IDOMHelper;
use Crawlers::CrawlerParameters;
use Domain::Article;

BEGIN {
  use Moose::Util::TypeConstraints;
  subtype 'DOM' => as class_type('Mojo::DOM');
}

class Crawler with ICrawler {
  use Mojo::Util qw/url_unescape/;

  has DOMHelper => (is => 'ro',
                    isa => 'IDOMHelper',
                    required => 1);

  has Parameters => (is => 'ro',
                     isa => 'CrawlerParameters',
                     required => 1);

  method _Trim (Str $str!) {
    $str =~ s/^\s+//;
    $str =~ s/\s+$//;
    return $str;
  }

  method CrawlNew() {
    die "not implemented";
  }

  method Crawl (Int $startPage?) {
    my $lastPage = $self->_GetLastPage();
    $startPage = 0 if !defined $startPage;
    print "lastPage is $lastPage\n" if $self->DEBUG;

    for (my $page = $startPage; $page <= $lastPage; ++$page) {
      $self->_CrawlPage($page);
    }
  }

  method CrawlSingle(Str $url!) {
    $self->_HandleRecipe($url);
  }

  method _CrawlPage(Int $page!) {
    print "crawling page $page...\n" if $self->DEBUG;

    my $pageContents = $self->_FetchPage($self->Parameters->FetchPageURI()->to_string());
    return unless defined $pageContents;

    my @pageDivs = $pageContents->dom($self->Parameters->CrawlPageSelectorForRecipes())->each;

    print "Found " . scalar @pageDivs . " recipes\n" if $self->DEBUG;

    foreach my $pageDiv (@pageDivs) {
      my $recipeAnchor = $pageDiv->at($self->Parameters->CrawlPageSelectorForRecipeLink());
      if (defined $recipeAnchor) {
        print "found anchor: $recipeAnchor\n" if $self->DEBUG;
        my $img = $pageDiv->at($self->Parameters->CrawlPageSelectorForImageLink());
        if (defined $img) {
          print "found img: $img\n" if $self->DEBUG;
          $self->_HandleRecipe($recipeAnchor->attrs('href'),
                               $img->attrs('src'));
        } else {
          $self->_HandleRecipe($recipeAnchor->attrs('href'));
        }
      }
    }
  }

  method _GetTitle(DOM $recipe!) {
    my $retval = '';
    my $el = $self->DOMHelper->GetElementFromDOM($recipe, $self->Parameters->CrawlRecipeSelectorForTitle());
    if (defined $el) {
      $retval = $self->_GetTextElement($el);
      print "\tFound a title with length " . length($retval) . ": $retval\n" if $self->DEBUG;
    }
    return $retval;
  }

  method _GetIngredients(DOM $recipe!) {
    my @retval;

    # select elements from DOM
    my $selectors = $self->Parameters->CrawlRecipeSelectorForIngredients();
    my $recipeItems;
    foreach my $selector (@selectors) {
      $recipeItems = $self->DOMHelper->GetCollectionFromDOM($recipe, $selector);
      if ($recipeItems->each > 0) {
        break;
      }
    }

    print "\tFound " . $recipeItems->each . " ingredients\n" if $self->DEBUG;

    # parse into objects
    unless ($recipeItems->each == 0) {
      $recipeItems->each(sub {
                           my $el = shift;
                           if (defined $el) {
                             my $ingredient = $el->all_text;
                             # normalize
                             $ingredient =~ s/ +/ /g;
                             if (length($ingredient) > 0) {
                               print "\t\tFound ingredient with length " . length($ingredient) . ": $ingredient\n" if $self->DEBUG;
                               push(@retval, $ingredient);
                             }
                           }
                         });
    }
    return @retval;
  }

  method _GetContents(DOM $recipe!) {
    my $retval = '';
    my $content_items = $self->DOMHelper->GetCollectionFromDOM($recipe, $self->Parameters->CrawlRecipeSelectorForContents());
    if (defined $content_items) {
      $content_items->each(sub {
                             my $el = shift;
                             if (defined $el) {
                               $retval .= "\n" if length($retval) > 0;
                               $retval .= $el->all_text;
                             }
                           });
    }

    if (length($retval) == 0) {
      # found no <ol>, hmmm... meh, just take all the text under the preparation node
      my $preparation_node = $self->DOMHelper->GetElementFromDOM($recipe, 'div.preparation');
      $retval = $preparation_node->all_text if defined $preparation_node;
    }
    print "\tFound content with length " . length($retval) . "\n" if $self->DEBUG;
    return $retval;
  }

  method _GetChef(DOM $recipe!) {
    my $retval = '';
    my $element = $self->DOMHelper->GetElementFromDOM($recipe, $self->Parameters->CrawlRecipeSelectorForChef());
    $retval = $self->_GetTextElement($element) if defined $element;
    print "\tFound a chef with length " . length($retval) . ": $retval\n" if $self->DEBUG && length($retval) > 0;
    return $retval;
  }

  method _GetDifficulty(DOM $recipe!) {
    my $retval = '';
    my $element = $self->DOMHelper->GetElementFromDOM($recipe, $self->Parameters->CrawlRecipeSelectorForDifficulty());
    $retval = $self->_GetTextElement($element) if defined $element;
    print "\tFound a difficulty with length " . length($retval) . ": $retval\n" if $self->DEBUG && length($retval) > 0;
    return $retval;
  }

  method _GetKitchenType(DOM $recipe!) {
    my $retval = '';
    my $element = $self->DOMHelper->GetElementFromDOM($recipe, self->Parameters->CrawlRecipeSelectorForKitchenType());
    $retval = $self->_GetTextElement($element) if defined $element;
    print "\tFound a kitchentype with length " . length($retval) . ": $retval\n" if $self->DEBUG && length($retval) > 0;
    return $retval;
  }

  method _HandleRecipe(Str $link!, Str $thumbUri?) {
    url_unescape($link);
    print "_HandleRecipe($link)\n" if $self->DEBUG;
    my $resp = $self->_FetchPage($link);
    return unless defined $resp;

    my $title = $self->_GetTitle($resp->dom);
    my @ingredients = $self->_GetIngredients($resp->dom);
    my $contents = $self->_GetContents($resp->dom);
    my $chef = $self->_GetChef($resp->dom);
    my $difficulty = $self->_GetDifficulty($resp->dom);
    my $kitchentype = $self->_GetKitchenType($resp->dom);
    my $thumb = defined $thumbUri ? $self->_FetchPage($thumbUri) : undef;
    $thumbUri =~ s/.*\/(.*)$/$1/ if defined $thumbUri; # keep only image name

    my $article = Article->new(title => $title,
                               source => 'zesta.be',
                               url => $link,
                               chef => $chef,
                               ingredients => \@ingredients,
                               contents => $self->_Trim($contents),
                               difficulty => $difficulty,
                               kitchentype => $kitchentype,
                               thumb => $thumb,
                               thumb_uri => $thumbUri
                              );

    $self->ArticleService->CreateOrUpdate($article);
  }

  method _GetTextElement(DOM $element!) {
    return $self->_Trim($element->text) if defined $element;
    return '';
  }

  method _GetLastPage() {
    my $href = $self->_FetchPage($self->Parameters->GetLastPageUri()->as_string())
      ->dom($self->Parameters->GetLastPageSelectorForLink())->[0]->attrs('href');
    $href =~ s/$self->Parameters->GetLastPageRegexForPagenumbers()/$1/;
    return $href;
  }

  method _FetchPage(Str $url!) { # returns(Mojo::Message::Response)
    print "_FetchPage($url)\n" if $self->DEBUG;
    my $resp = $self->UserAgent->get($url)->res;
    if ($resp->is_status_class(200)) {
      return $resp;
    } else {
      print "[" . $self->Parameters->Name() . "] Failed to get $url: " . $resp->error if $self->DEBUG;
      return undef;
    }
  }
}

  1;
