#!/usr/bin/perl
use strict;
use utf8;
use URI;
use WWW::Mechanize;
use Config::Pit;
use Web::Scraper;

my $uri = URI->new('https://affiliate.amazon.co.jp/gp/associates/login/login.html');

my $mech = new WWW::Mechanize( autocheck => 1 );
$mech->agent_alias( 'Windows IE 6' );
$mech->get($uri);

my $config = pit_get( "affiliate.amazon.co.jp", require => {
  "username" => "username for affiliate.amazon.co.jp",
  "password" => "password for affiliate.amazon.co.jp"
});

$mech->submit_form(
  fields => {
    email    => $config->{username},
    password => $config->{password},
  }
);

$mech->get('https://affiliate.amazon.co.jp/gp/associates/network/reports/report.html?ie=UTF8&reportType=earningsReport&periodType=preSelected&preSelectedPeriod=monthToDate');

my $s = scraper {
  process "#content",
    "list[]" => scraper {
      process "div.reporttext", "date" => "TEXT";
      process "#earningsReport", "report1" => "HTML";
      process "table.earningsReportSummary", "report2" => "HTML";
      process "#eventReportSummary", "report3" => "HTML";
    };
};

my $res = $s->scrape($mech->content, $mech->uri);

my $feed = {
  title => "Amazon.co.jp アソシエイト・レポート"
};

for my $entry (@{ $res->{list} }) {
  push @{$feed->{entries}}, {
    title => $entry->{date},
    body  => $entry->{report1} . $entry->{report2} . $entry->{report3},
    link  => $mech->uri->as_string,
  };
}

use YAML;
binmode STDOUT, ":utf8";
print Dump $feed;
