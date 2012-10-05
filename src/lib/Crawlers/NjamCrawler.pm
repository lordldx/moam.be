use MooseX::Declare;

use Crawlers::ICrawler;
use Domain::Article;

class NjamCrawler with ICrawler {
  use Mojo::Util qw/url_unescape/;
  use constant BASE_URI => scalar "http://www.njam.tv";
  use constant RECIPE_URI => scalar "http://www.njam.tv/recepten";
  use constant PAGING_URI => scalar "http://www.njam.tv/zoeken/recepten?page=";
  use constant HOME_URI => scalar "http://www.njam.tv";

  method _Trim (Str $str!) {
    $str =~ s/^\s+//;
    $str =~ s/\s+$//;
    return $str;
  }

  method CrawlNew() {
    my @newRecipeAnchors = $self->_FetchPage(RECIPE_URI)
      ->dom("div.recipesSidebar a.recept")
        ->each;

    print "Found " . scalar @newRecipeAnchors . " new recipes\n" if $self->DEBUG;

    foreach my $anchor (@newRecipeAnchors) {
      $self->_HandleRecipe(BASE_URI . $anchor->attrs('href')); # somehow the new recipe hrefs don't include the base_uri :-S
    }
  }

  method Crawl (Int $startPage?) {
    my $lastPage = $self->_GetLastPage();
    print "lastPage is $lastPage\n" if $self->DEBUG;

    $self->_CrawlPage(RECIPE_URI) if $startPage == 0; # njam as no page 0 the first page of recipes is the basepage
    for (my $page = $startPage == 0 ? 1 : $startPage; $page <= $lastPage; ++$page) {
      $self->_CrawlPage(PAGING_URI . $page);
    }
  }

  method CrawlSingle(Str $url!) {
    $self->_HandleRecipe($url);
  }

  method _CrawlPage(Str $url) {
    print "crawling url $url...\n" if $self->DEBUG;

    my @recipeAnchors = $self
      ->_FetchPage($url)
        ->dom('ul.recipeGridLarge > li > h3 > a')
          ->each;

    print "Found " . scalar @recipeAnchors . " recipes\n" if $self->DEBUG;

    foreach my $recipeAnchor (@recipeAnchors) {
      print "found anchor: $recipeAnchor\n" if $self->DEBUG;
      $self->_HandleRecipe($recipeAnchor->attrs('href'));
    }
  }

  method _HandleRecipe(Str $link!) {
    url_unescape($link);
    print "_HandleRecipe($link)\n" if $self->DEBUG;
    my $resp = $self->_FetchPage($link);
    return unless defined $resp;

    my $title = $self->_GetTextElement($resp->dom->at('h2.mainTitle'));
    print "\tFound a title with length " . length($title) . ": $title\n" if $self->DEBUG;

    my @ingredients;
    my @untrimmed_ingredients;
    my $recipeItems = $resp->dom('tr.ingredient');
    print "\tFound " . $recipeItems->each . " ingredients\n" if $self->DEBUG;
    $recipeItems->each(sub {
                         my $el = shift;
                         if (defined $el) {
                           my $amountThingie = $el->at("th.amount");
                           my $nameThingie = $el->at("td.name");
                           my $untrimmed_ingredient = defined $amountThingie ? $amountThingie->text . ' ' : '';
                           $untrimmed_ingredient .= defined $nameThingie ? $nameThingie->text : '';
                           push @untrimmed_ingredients, $untrimmed_ingredient;
                         } else {
                           push @untrimmed_ingredients, '';
                         }
                       });
    foreach my $ingredient (@untrimmed_ingredients) {
      print "\t\tFound ingredient with lengt " . length($ingredient) . ": $ingredient\n";
      push @ingredients, $self->_Trim($ingredient);
    }

    my $contents = '';
    my $contentItems = $resp->dom('div.instructions p');
    print "\tFound " . $recipeItems->each . " content items\n" if $self->DEBUG;
    $contentItems->each(sub {my $el = shift; $contents .= defined $el ? $el->text . "\n" : '';});
    print "\tFound content with length " . length($contents) . "\n";

    my $chef = $self->_GetTextElement($resp->dom->at('li.cook > em > a'));
    print "\tFound a chef with length " . length($chef) . ": $chef\n" if $self->DEBUG;

    my $difficulty = $self->_GetTextElement($resp->dom->at('li.level > em'));
    print "\tFound a difficulty with length " . length($difficulty) . ": $difficulty\n" if $self->DEBUG;

    my $kitchentype = $self->_GetTextElement($resp->dom->at('li.kitchen > em'));
    print "\tFound a kitchentype with length " . length($kitchentype) . ": $kitchentype\n" if $self->DEBUG;

    my $article = Article->new(title => $title,
                               source => 'njam.tv',
                               url => $link,
                               chef => $chef,
                               ingredients => \@ingredients,
                               contents => $self->_Trim($contents),
                               difficulty => $difficulty,
                               kitchentype => $kitchentype
                              );
    $self->ArticleService->CreateOrUpdate($article);
  }

  # $element of type Mojo::DOM -- TODO: find out how to check the type.
  method _GetTextElement($element) {
    return $self->_Trim($element->text) if defined $element;
    return '';
  }

  method _GetLastPage() returns (Int) {
    my $href = $self->_FetchPage(RECIPE_URI)->dom('div.pages li.last > a')->[0]->attrs('href');
    $href =~ s/.*page=([0-9]+).*/$1/;
    return $href;
  }

  method _FetchPage(Str $url!) { # returns(Mojo::Message::Response)
    print "_FetchPage($url)\n" if $self->DEBUG;
    my $resp = $self->UserAgent->get($url)->res;
    if ($resp->is_status_class(200)) {
      return $resp;
    } else {
      print "[NjamCrawler] Failed to get $url: " . $resp->error if $self->DEBUG;
      return undef;
    }
  }
}

  1;
