use MooseX::Declare;

class Article {
  has title => (is => 'rw',
                isa => 'Str',
                required => 1);

  has source => (is => 'rw',
                 isa => 'Str',
                 required => 1);

  has url => (is => 'rw',
              isa => 'Str',
              required => 1);

  has chef => (is => 'rw',
               isa => 'Str');

  has ingredients => (is => 'rw',
                      isa => 'ArrayRef[Str]',
                      required => 1,
                      default => sub{return ();});

  has difficulty => (is => 'rw',
                     isa => 'Str');

  has kitchentype => (is => 'rw',
                      isa => 'Str');

  has contents => (is => 'rw',
                   isa => 'Str',
                   required => 1);

  has thumb_uri => (is => 'rw',
                    isa => 'Str',
                    required => 1,
                    default => "images/no_thumb.png");

  has thumb => (is => 'rw',
                default => undef);

  method AsUnblessedReference() { # for serializing to json
    return {
            title => $self->title,
            source => $self->source,
            url => $self->url,
            chef => $self->chef,
            ingredients => $self->ingredients,
            difficulty => $self->difficulty,
            kitchentype => $self->kitchentype,
            content => $self->contents,
            thumb_uri => $self->thumb_uri
           };
  }
}

  1;
