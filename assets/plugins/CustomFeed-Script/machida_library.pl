#!/usr/bin/env perl
use strict;
use utf8;
use DateTime;
use DateTime::Format::W3CDTF;
use URI;
use WWW::Mechanize;
use Config::Pit;
use Web::Scraper;

my $uri = URI->new('https://www.library.city.machida.tokyo.jp/yoyaku/yo_riyou.html');

my $mech = new WWW::Mechanize(autocheck => 1);
$mech->agent_alias('Windows IE 6');
$mech->get($uri);

my $config = pit_get('www.library.city.machida.tokyo.jp', require => {
    "username" => "username for machida city library",
    "password" => "password for machida city library",
});

$mech->submit_form(
    fields => {
        use_name  => $config->{username},
        use_password => $config->{password},
    }
);

my $s = scraper {
    process "table tr",
      "list[]" => scraper {
          process "//td[6]", "title" => "TEXT";
          process "//td[4]", "date"  => "TEXT";
      };
};

my $res = $s->scrape($mech->content, $mech->uri);

my $feed = {
    title => "町田市図書館返却期限"
};

for my $menu (@{$res->{list}}) {
    if ($menu->{title} and $menu->{date}){
        push @{$feed->{entries}}, {
            title => $menu->{title},
            date  => munge_datetime($menu->{date}),
        };
    }
}

use YAML;
binmode STDOUT, ":utf8";
print Dump $feed;

sub munge_datetime {
    my ($date) =  @_;
    $date =~ m!(\d{1,4})/(\d{1,2})/(\d{1,2})! or die "No match: $date";
    my ($year, $month, $day) = ($1, $2, $3);
    my $dt = DateTime->new(
        year      => $year,
        month     => $month,
        day       => $day,
        hour      => 00,
        minute    => 00,
        second    => 00,
        time_zone => 'Asia/Tokyo'
    );
    return $dt->ymd;
}
