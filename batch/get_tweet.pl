#!/bin/env perl

use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../extlib/lib/perl5";
use Mojo::Server;
use Net::Twitter::Lite::WithAPIv1_1;
use bigint;

# Config
my $app = Mojo::Server->new->load_app("$FindBin::Bin/../script/perltweet");
my $config = $app->config;

# Twitter client
my $nt = Net::Twitter::Lite::WithAPIv1_1->new(
  consumer_key => $config->{twitter_consumer_key},
  consumer_secret => $config->{twitter_consumer_secret},
  legacy_lists_api => 0
);
$nt->access_token($config->{twitter_access_token});
$nt->access_token_secret($config->{twitter_access_token_secret});

# Search
my $query = {q => 'perl', count => 1, lang => 'ja', result_type => 'recent'};
my $tweets = $nt->search($query);

# Require item

# URLの一つ目
# ユーザー
# コメント
# リツイート数
# 言語

1;
