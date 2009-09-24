#!/usr/bin/perl
use strict;
use utf8;
use DateTime;
use DateTime::Format::W3CDTF;
use URI;
use WWW::Mechanize;
use Config::Pit;
use Web::Scraper;

my $uri = URI->new('https://www.lib.city.ota.tokyo.jp/idcheck.html');

my $mech = new WWW::Mechanize( autocheck => 1 );
$mech->agent_alias( 'Windows IE 6' );
$mech->get($uri);

my $config = pit_get( "www.lib.city.ota.tokyo.jp", require => {
  "username" => "username for ota city library",
  "password" => "password for ota city library"
});

$mech->submit_form(
  fields => {
    UID  => $config->{username},
    PASS => $config->{password},
  }
);

$mech->get('https://www.lib.city.ota.tokyo.jp/clis/logrent?AUT=Cavde3Vuxs3dqe3&MAXVIEW=20&RTNPAGE=/idcheck.html');

my $s = scraper {
  process "table.FULL tbody tr",
    "list[]" => scraper {
      process "//td[2]", "title" => "TEXT";
      process "//td[5]", "date" => "TEXT";
      result 'title','date';
    };
  result 'list';
};

my $res = $s->scrape($mech->content, $mech->uri);

my $feed = {
  title => "ota library"
};

for my $menu (@{$res}) {
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
  my ($date)	   =  @_;
  $date		   =~ m!(\d{1,2})月(\d{1,2})日! or die "No match: $date";
  my($month, $day) =  ($1, $2);
  my $dt	   =  DateTime->new(
    year      => DateTime->now->year,
    month     => $month,
    day	      => $day,
    hour      => '19', # library closes at 19:00 :/
    minute    => '00',
    time_zone => 'Asia/Tokyo',
  );
  return DateTime::Format::W3CDTF->format_datetime($dt);
}
