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
  access_token_secret => $config->{twitter_access_token_secret},
  ssl => 1
);

# Max ID
my $max_id = $dbi->model('tweet')->select('max(id)')->value // 0;

# Langages
my $languages = ['ja', 'en'];

my $url_re = qr#http://[\/\.a-zA-Z0-9]+#;

for my $language (@$languages) {
  
  # Latest tweets
  my $latest_tweet_texts = $dbi->model('tweet')->select(
    'tweet_text',
    where => {language => $language},
    append => 'order by row_id desc limit 0, 3000'
  )->values;
  my $latest_tweet_text_no_urls_h = {};
  for my $latest_tweet_text (@$latest_tweet_texts) {
    my $latest_tweet_text_no_url = $latest_tweet_text;
    $latest_tweet_text_no_url =~ s/$url_re//g;
    $latest_tweet_text_no_urls_h->{$latest_tweet_text_no_url} = 1;
  }
  
  # Search
  my $query = {
    q => 'perl',
    count => 100,
    lang => $language,
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
    my $created_at_mysql_date = $created_at_tp->strftime('%Y-%m-%d');
    my $retweet_count = $tweet->{retweet_count};
    my $user_screen_name = $tweet->{user}{screen_name};
    
    # Insert database

    # Skip when perl6 contains
    next if $text =~ /perl\s*6/i;

    # Skip when Perl様 contains
    next if $text =~ /Perl様/i;

    # Skip when ruby contains
    next if $text =~ /ruby/i;

    # Skip when python contains
    next if $text =~ /python/i;

    # Skip when node contains
    next if $text =~ /node/i;

    # Skip when go contains
    next if $text =~ /\bgo\b/ia;
    next if $text =~ /golang/i;

    # Skip when scala contains
    next if $text =~ /scala/i;

    # Skip Perl dram tweet
    next if $text =~ /スティック/;
    next if $text =~ /ドラム/;
    next if $text =~ /ペダル/;
    
    # Skip when tweet don't contain in perl
    next unless $text =~ /perl/i;
    
    # Skip if upper case PERL
    next if $text =~ /PERL/;
    
    # Skip if $perl
    next if $text =~ /\$perl/i;
    
    # Skip same tweet
    {
      my $tweet_text_no_url = $text;
      $tweet_text_no_url =~ s/$url_re//g;
      $tweet_text_no_url =~ s/\@([a-zA-Z0-9_-]+) //g;
      
      # Remove data and time
      $tweet_text_no_url =~ s/[0-9\/\:\-]//g;
      
      next if $latest_tweet_text_no_urls_h->{$tweet_text_no_url};
      $latest_tweet_text_no_urls_h->{$tweet_text_no_url} = 1;
    }
    
    # Skip bot and spam and Perl negative campane
    next if $user_screen_name eq 'PerlManiaJP';
    next if $user_screen_name eq 'rikeikare_bot';
    next if $user_screen_name =~ /_bot/i;
    next if $user_screen_name eq 'ShinaiMuri';
    next if $user_screen_name eq 'peacedavives';
    next if $user_screen_name eq 'mrt33185622';
    

    my $params = {
      id => $id,
      tweet_text => $text,
      url => $url,
      created_at => $created_at_mysql_dt,
      created_at_date => $created_at_mysql_date,
      retweet_count => $retweet_count,
      user_screen_name => $user_screen_name,
      language => $tweet->{lang}
    };
    $dbi->model('tweet')->insert($params) if $id > $max_id;
  }
}

1;
