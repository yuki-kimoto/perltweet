#!/bin/env perl

use strict;
use warnings;
use utf8;
use FindBin;
use lib "$FindBin::Bin/../extlib/lib/perl5";
use Mojo::Server;
use Net::Twitter::Lite::WithAPIv1_1;
use Time::Piece;
use Time::Seconds 'ONE_HOUR';

# Config
my $app = Mojo::Server->new->load_app("$FindBin::Bin/../script/perltweet");
my $config = $app->config;

# DBI
my $dbi = $app->dbi;

# Twitter client
my $nt = Net::Twitter::Lite::WithAPIv1_1->new(
  consumer_key => $config->{twitter_consumer_key},
  consumer_secret => $config->{twitter_consumer_secret},
  access_token        => $config->{twitter_access_token},
  access_token_secret => $config->{twitter_access_token_secret}
);

# Max ID
my $max_id = $dbi->model('tweet')->select('max(id)')->value // 0;

# Search
my $query = {
  q => 'perl',
  count => 100,
  lang => 'ja',
  result_type => 'recent'
};
my $search_metadata = $nt->search($query);
my $tweets = $search_metadata->{statuses};

for my $tweet (@$tweets) {
  
  # Tweet
  my $id = $tweet->{id};
  my $text = $tweet->{text};
  my $url = $tweet->{entities}{urls}[0]{expanded_url} // '';
  my $created_at = $tweet->{created_at};
  my $created_at_tp = localtime Time::Piece->strptime($created_at, "%a %b %d %T %z %Y");
  $created_at_tp += 9 * ONE_HOUR;
  my $created_at_mysql_dt = $created_at_tp->strftime('%Y-%m-%d %H:%M:%S');
  my $retweet_count = $tweet->{retweet_count};
  my $user_screen_name = $tweet->{user}{screen_name};
  
  # Insert database
  my $params = {
    id => $id,
    tweet_text => $text,
    url => $url,
    created_at => $created_at_mysql_dt,
    retweet_count => $retweet_count,
    user_screen_name => $user_screen_name
  };
  $dbi->model('tweet')->insert($params) if $id > $max_id;
  
}

1;
