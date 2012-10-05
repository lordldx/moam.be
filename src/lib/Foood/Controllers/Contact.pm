package Foood::Controllers::Contact;
use base 'Mojolicious::Controller';
use Email::Valid;

#use constant EMAIL_ADDRESS => scalar 'info@moam.be';
use constant EMAIL_ADDRESS => scalar 'lorenzo.dieryckx@infohos.be';
use constant RECAPTCHA_PRIVATE_KEY => scalar '6LeWfc0SAAAAAC4tnpfcxy3fnSj5sd9k3lJG_34B';

sub index {
  shift->render('Contact/index');
}

sub send {
  my $c = shift;

  my $captchaChallenge = $c->param('recaptcha_challenge_field');
  my $captchaResponse = $c->param('recaptcha_response_field');

  my $captchaResult = Captcha::reCAPTCHA->new->check_answer(RECAPTCHA_PRIVATE_KEY,
                                                            $c->tx->remote_address,
                                                            $captchaChallenge,
                                                            $captchaResponse);
  if ($captchaResult->{is_valid}) {
    my $from = $c->param('from');
    my $subject = $c->param('subject');
    my $body = $c->param('body');

    if (Email::Valid->address($from)) {
      $c->app->log->debug("Sending mail from $from about $subject: $body");
      my $mail = $c->app->mail(
                               to => EMAIL_ADDRESS,
                               from => $from,
                               subject => $subject,
                               data => $body
                              );
      $c->stash(mail => $mail);
      $c->render('Contact/sent');
    } else {
      $c->stash(error => "Ongeldig email adres: $from");
    }
  } else {
    $c->stash(error => "Ongeldige beveiligingscode.");
  }

  $c->render('Contact/index');
}

1;
