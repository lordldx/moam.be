use MooseX::Declare;
use MooseX::Getopt;

class CrawlerOptions with MooseX::Getopt {
  # update single page
  has u => (is => 'rw',
            isa => 'Str');

  # start crawling at specified page
  has p => (is => 'rw',
            isa => 'Int');

  # crawl only the "new" section
  has n => (is => 'rw',
            isa => 'Bool');

  # use only this specific crawler
  has c => (is => 'rw',
            isa => 'Str');
}
