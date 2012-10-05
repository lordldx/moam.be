use MooseX::Declare;
use Config::YAML;

class FooodConfig {

  has FileLocation => (isa => 'Str',
                       is => 'ro',
                       required => 1);

  has Contents => (isa => 'Config::YAML',
                   is => 'ro',
                   required => 1,
                   lazy => 1,
                   builder => '_build_contents');

  method _build_contents {
    return Config::YAML->new(config => $self->FileLocation,
                             http_proxy => undef,
                             elastic_search_servers => ['127.0.0.1:9200'],
                             smtp_server => 'SP-EX-01.infohos.be',
                             cdn_address => 'http://127.0.0.1:3001');
  }
}

  1;
