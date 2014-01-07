# perltweet

Web application to display tweet related to Perl.

## なるべく最新のPerlをインストールしてください。

　perlbrewなどでインストール

## perltweetのインストール

とってきます。

    git clone https://github.com/yuki-kimoto/perltweet.git

## 必要なモジュールをインストール

    ./setup.sh

## MySQLのインストール

　MySQLをインストールしてください。

## MySQLの設定

### データベースを作成

    create database perltweet

### テーブルを作成

    CREATE TABLE `tweet` (
      `row_id` bigint(20) NOT NULL auto_increment,
      `id` bigint(20) NOT NULL,
      `tweet_text` text NOT NULL,
      `url` text NOT NULL,
      `created_at` datetime NOT NULL,
      `retweet_count` int(11) default NULL,
      `user_screen_name` text NOT NULL,
      `created_at_date` date NOT NULL,
      PRIMARY KEY  (`row_id`),
      UNIQUE KEY `id` (`id`),
      KEY `tweet__created_at_date` (`created_at_date`)
    ) ENGINE=InnoDB AUTO_INCREMENT=8536 DEFAULT CHARSET=utf8

## パスワードファイルを作成します

直下のディレクトリに

    password.conf

という名前で作成します。内容は以下のようになります。
データベースの情報とTwitter APIの情報です。

    {
      db_dsn => 'dbi:mysql:database=perltweet',
      db_user => 'perltweet',
      db_password => 'password&%@',
      twitter_consumer_key => 'b7PCjuOlr62E9l4otrQXo',
      twitter_consumer_secret => 'fT2GSnTlf5SXGh3IOfIwHMfkS4Aliqd7U7MGdY1Ao',
      twitter_access_token => '482047902-3w1RzVUyNPXsjyeEjSYrNOLIOrIRyRjxVEojS0oo',
      twitter_access_token_secret => 'Vp7K12hh0IpTbFVoRvxelQFbb8ujYgZytuur96PXo'
    }

### アプリケーションの実行

アプリケーションを実行します。

    ./perltweet

http://localhost:10060などでアクセスできます。

### アプリケーションの停止

    ./perltweet --stop

### crontabの設定

Tweetを定期的に取得するスクリプトを実行。PATH、MAILTO、cronの定期実行の設定などを適切に設定する。15分に一回実行する計算。

    PATH=/home/kimoto/perl5/perlbrew/bin:/home/kimoto/perl5/perlbrew/perls/perl-5.16.3/bin:/usr/lib/oracle/11.2/client64/bin:/usr/kerberos/bin:/usr/local/bin:/bin:/usr/bin:/home/kimoto/bin:/sbin:/usr/sbin:/usr/local/sbin
    
    MAILTO=kimoto.yuki@gmail.com
      
    # Perl tweet
    2,17,32,47 * * * * $HOME/labo/perltweet/batch/get_tweet.pl
