#!/usr/bin/env perl
use strict;
use utf8;
use URI;
use WWW::Mechanize;
use Config::Pit;
use Web::Scraper;

my $uri = URI->new('http://member.square-enix.com/jp/login/login.php');

my $mech = new WWW::Mechanize(autocheck => 1);
$mech->agent_alias('Windows IE 6');
$mech->get($uri);

my $config = pit_get('member.square-enix.com', require => {
    "username" => "username for sqex members",
    "password" => "password for sqex members",
});

$mech->submit_form(
    fields => {
        login_id => $config->{username},
        password => $config->{password},
    }
);

$mech->get('http://member.square-enix.com/jp/avatar/partybattle2/party.php');

my $s = scraper {
    process "#main",
      "list[]" => scraper {
          process "div.times",           "title" => "TEXT";
          process "div.timeinfo p.time", "date"  => "TEXT";
      };
};

my $res = $s->scrape($mech->content, $mech->uri);

my $feed = {
    title => "SQEX PartyBattle2"
};

for my $menu (@{$res->{list}}) {
    if ($menu->{title} and $menu->{date}){
        push @{$feed->{entries}}, {
            title => $menu->{title},
            date  => $menu->{date},
        };
    }
}

use YAML;
binmode STDOUT, ":utf8";
print Dump $feed;

