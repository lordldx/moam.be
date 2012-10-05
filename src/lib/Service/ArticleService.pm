use MooseX::Declare;
use Service::IArticleService;
use Domain::Article;
use Mojo::Message;
use Mojo::UserAgent;

BEGIN {
  use Moose::Util::TypeConstraints;
  subtype 'Message' => as class_type('Mojo::Message');
}

class ArticleService with IArticleService {
  use Data::Compare;
  use JSON;

  has Db => (isa => 'CouchDB::Client::DB',
             is => 'ro',
             required => 1);

  has UserAgent => (isa => 'Mojo::UserAgent',
                    is => 'ro',
                    required => 1,
                    default => sub {Mojo::UserAgent->new;});

  method _storeThumb(Message $image!, Article $article!) {
    my $cdn_addr = $self->config->Contents->get_cdn_address . '/';
    my $full_addr = $cdn_addr . $article->thumb_uri;

    print "[ArticleService] storing thumb onto the CDN: $full_addr\n"  if $self->DEBUG;
    my $resp = $self->UserAgent->put($full_addr, $image->body)->res;
    if ($resp->is_status_class(200)) {
      my $result = decode_json($resp->body);
      if ($result->{success}) {
        $article->thumb_uri($cdn_addr . $result->{image});
      } else {
        print "[ArticleService] Failed to put the thumb onto the CDN: " . $result->{error} . "\n";
      }
    } else {
      print "[ArticleService] Failed to put the thumb onto the CDN: " . $resp->error . "\n";
    }
  }

  method CreateOrUpdate(Article $article!) {
    $self->_storeThumb($article->thumb, $article) if defined $article->thumb;

    my $doc = $self->Db->newDoc($article->url);
    if ($self->Db->docExists($article->url)) {
      $doc->retrieve;
      my $newData = $article->AsUnblessedReference;
      if (!Compare($doc->data, $newData)) {
        $doc->data($newData);
        $doc->update;
      }
    } else {
      $doc->data($article->AsUnblessedReference);
      $doc->create;
    }
  }

  method NumberOfArticles() {
    return $self->Db->dbInfo->{doc_count};
  }
}

  1;
