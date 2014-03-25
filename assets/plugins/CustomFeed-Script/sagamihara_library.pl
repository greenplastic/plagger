#!/usr/bin/env perl
use strict;
use utf8;
use DateTime;
use DateTime::Format::W3CDTF;
use URI;
use WWW::Mechanize;
use Config::Pit;
use Web::Scraper;

my $uri = URI->new('https://www.lib.sagamihara.kanagawa.jp/asp/WwPortLogin.aspx');

my $mech = new WWW::Mechanize(autocheck => 1);
$mech->agent_alias('Windows IE 6');
$mech->get($uri);

my $config = pit_get('www.lib.sagamihara.kanagawa.jp', require => {
    "username" => "username for sagamihara city library",
    "password" => "password for sagamihara city library",
});

$mech->submit_form(
    fields => {
        txtRiyoshaCD => $config->{username},
        txtPassWord  => $config->{password},
    },
    button => 'btnLogin'
);

$mech->submit_form(
    button => 'btnMyPort03'
);

my $s = scraper {
    process "table#dgdKas tr[style^='color:Black']",
      "list[]" => scraper {
          process "//td[2]/a", "title" => "TEXT";
          process "//td[6]", "date"  => "TEXT";
      };
};

my $res = $s->scrape($mech->content, $mech->uri);

my $feed = {
    title => "相模原市図書館返却期限"
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
