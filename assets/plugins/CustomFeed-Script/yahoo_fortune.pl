#!/usr/bin/perl
use strict;
use utf8;
use URI;
use DateTime;
use Web::Scraper;

my $dt = DateTime->today;
my $today = $dt->strftime('%Y%m%d');
my $url = "http://fortune.yahoo.co.jp/12astro/$today/cancer.html";
my $uri = URI->new($url);
my $s = scraper {
    process "title", title => 'TEXT';
    process "#mnc",
      "list[]" => scraper {
	  process "div.mg10t div.yftn-md20 div.inr-wr div.bg01 div.bg02 p", "subtitle" => "TEXT";
	  process "div.mg10t",  "report0" => "HTML";
	  process "#lnk01",     "report1" => "HTML";
	  process "#lnk02",     "report2" => "HTML";
	  process "#lnk03",     "report3" => "HTML";
	  process "#lnk04",     "report4" => "HTML";
	  process "#menu_love", "report5" => "HTML";
	  process "div.mg20t",  "report6" => "HTML";
	  process "div.mg5t"  , "report7" => "HTML";
      };
};

my $res = $s->scrape($uri);

my $feed = {
  title => $res->{title}
};

for my $entry (@{ $res->{list} }) {
  push @{$feed->{entries}}, {
    title => $entry->{subtitle},
    body  => $entry->{report0} . $entry->{report1} . $entry->{report2} . $entry->{report3} . $entry->{report4} . $entry->{report5} . $entry->{report6} . $entry->{report7},
    link  => $url,
  };
}

use YAML;
binmode STDOUT, ":utf8";
print YAML::Dump $feed;

