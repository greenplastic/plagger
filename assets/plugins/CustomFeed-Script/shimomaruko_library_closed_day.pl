#!/usr/bin/perl
use strict;
use utf8;
use DateTime;
use DateTime::Format::W3CDTF;
use URI;
use Web::Scraper;
use Lingua::JA::Regular::Unicode;

my $s = scraper {
    process "table",
      "list[]" => scraper {
          process "//caption", "title" => "TEXT";
          process '//td[@class="CLOSE"]', "date"  => "TEXT";
      };
};

my $uri = new URI('http://www.lib.city.ota.tokyo.jp/clis/calender?LIB=013&RTN=15');

my $res = $s->scrape($uri);

my $feed = {
    title => "下丸子図書館休館日"
};

for my $menu (@{$res->{list}}) {
    if ($menu->{title} and $menu->{date}){
        push @{$feed->{entries}}, {
            title => "下丸子図書館休館日",
            date  => munge_datetime($menu->{title}, $menu->{date}),
        };
    }
}

use YAML;
binmode STDOUT, ":utf8";
print Dump $feed;

sub munge_datetime {
    my ($month, $day) = @_;
    $month =~ m/([１|２|３|４|５|６|７|８|９|１０|１１|１２])月/ or die "No match: $month";
    my $m = $1;
    $m = alnum_z2h($m);
    $day = alnum_z2h($day);
    my $dt = DateTime->new(
        year      => DateTime->now->year,
        month     => $m,
        day       => $day,
        time_zone => 'Asia/Tokyo',
    );
    return $dt->ymd;
}
