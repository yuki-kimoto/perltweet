use FindBin;
use lib "$FindBin::Bin/../lib";
use lib "$FindBin::Bin/../exitlib/lib/perl5";

use Mojo::Base -strict;

use Test::More 'no_plan';
use Test::Mojo;

use_ok 'Perltweet';
