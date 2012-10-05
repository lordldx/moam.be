use MooseX::Declare;
use Moose::Util::TypeConstraints;
use Crawlers::IDOMHelper;

BEGIN {
  use Moose::Util::TypeConstraints;
  subtype 'DOM' => as class_type('Mojo::DOM');
}

class DOMHelper with IDOMHelper {
  method GetCollectionFromDOM(DOM $dom!, Str $path!) {
    return $dom->find($path);
  }
  method GetElementFromDOM(DOM $dom!, Str $path!) {
    return $dom->at($path);
  }
}

1;
