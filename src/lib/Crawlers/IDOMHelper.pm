use MooseX::Declare;

role IDOMHelper {
  requires 'GetCollectionFromDOM';
  requires 'GetElementFromDOM';
}

1;
