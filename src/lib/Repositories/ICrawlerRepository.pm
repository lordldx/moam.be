use MooseX::Declare;

role ICrawlerRepository {
  has crawlers => (is => 'rw',
                   isa => 'ArrayRef[ICrawler]',
                   default => sub {[]});

  requires 'AddCrawler';
  requires 'GetNumberOfCrawlers';
}
