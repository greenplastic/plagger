#!/usr/bin/env perl
use strict;
use utf8;
use DateTime;
use DateTime::Format::W3CDTF;
use URI;
use WWW::Mechanize;
use Config::Pit;
use Web::Scraper;

my $uri = URI->new('https://www.lib.city.ota.tokyo.jp/idcheck.html');

my $mech = new WWW::Mechanize(autocheck => 1);
$mech->agent_alias('Windows IE 6');
$mech->get($uri);

my $config = pit_get('www.lib.city.ota.tokyo.jp', require => {
    "username" => "username for ota city library",
    "password" => "password for ota city library",
});

$mech->submit_form(
    fields => {
        UID  => $config->{username},
        PASS => $config->{password},
    }
);

$mech->follow_link(url_regex => qr/logrent/);

my $s = scraper {
    process "table.FULL tbody tr",
      "list[]" => scraper {
          process "//td[2]", "title" => "TEXT";
          process "//td[5]", "date"  => "TEXT";
      };
};

my $res = $s->scrape($mech->content, $mech->uri);

my $feed = {
    title => "大田区図書館返却期限"
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
    $date =~ m!(\d{1,4})年(\d{1,2})月(\d{1,2})日! or die "No match: $date";
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
