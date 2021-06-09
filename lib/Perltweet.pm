package Perltweet;

our $VERSION = '0.01';

use Mojo::Base 'Mojolicious';
use DBIx::Custom;
use Perltweet::API;
use Scalar::Util 'weaken';
use Carp 'croak';

has 'dbi';
has 'twitter';

sub startup {
  my $self = shift;
  
  # Config file
  $self->plugin('Config');
  
  # My Config file
  if (-f $self->home->rel_file('perltweet.my.conf')) {
    $self->plugin('Config', file => $self->home->rel_file('perltweet.my.conf'));
  }
  
  # Password
  $self->plugin('Config', file => $self->home->rel_file('password.conf'));
  
  
  # Config
  my $config = $self->config;
  
  # DBI
  my $dbi = DBIx::Custom->connect(
    dsn => $config->{db_dsn},
    user => $config->{db_user},
    password => $config->{db_password},
    option => {mysql_enable_utf8 => 1},
    connector => 1
  );
  $self->dbi($dbi);
  
  # Models
  my $models = [
    # Tweet
    {
      table => 'tweet',
      primary_key => 'id'
    }
  ];
  $dbi->create_model($_) for @$models;
  
  # Route
  my $r = $self->routes;
  
  # DBViewer(development)
  if ($self->mode eq 'development') {
    $self->plugin(
      'DBViewer',
      dsn => $config->{db_dsn},
      user => $config->{db_user},
      password => $config->{db_password},
      connector => 1
    )
  }

  # Auto routes
  $self->plugin('AutoRoute', route => $r);
  
  $r->get('/date/:date', {date => qr/[0-9]{8}/} => sub { shift->render_maybe('auto/index') });
  
  # Helper
  $self->helper(wiki_api => sub { Perltweet::API->new(shift) });
}

1;
