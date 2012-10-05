use strict;
use warnings;

use Test::More tests => 13;
use Test::Mojo;

use_ok 'Foood';

#my $t = new_ok('Test::Mojo' => ['Foood']);
my $t = Test::Mojo->new('Foood');

# initial get
$t->get_ok('/contact')
  ->status_is(200)
  ->text_like('h1.recipe-title' => qr/Contacteer Moam\.be/)
  ->element_exists('form#mailform')
  ->element_exists('form#mailform input#mail_from')
  ->element_exists('form#mailform input#mail_subject')
  ->element_exists('form#mailform textarea#mail_body')
  ->element_exists('form#mailform input[type=submit]');

# testing real mail sending quite hard to test; would need "MailService"-interface that can be mocked out
# The sending of the mail (via Mojolicious::Plugin::Mail) would then happen from within the MailService impl
# but then again, it wouldn't be real fit testing now would it :-)
# so for now: no fit testing of email sending

# test email validity check
$t->post_form_ok('/contact', {from => 'brol'})
  ->status_is(200)
  ->text_is('div#error-title', 'Er is een fout opgetreden tijdens het mailen.')
  ->text_is('div#error-text', 'Ongeldig email adres: brol');
