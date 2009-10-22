#!/usr/bin/perl -w
use strict;
use utf8;
use DateTime;
use DateTime::Format::W3CDTF;
use Encode;
use Web::Scraper;
use URI;
use YAML;

my $uri = URI->new('http://www.teraken.co.jp/menu/lunchmenu/index.html');
my $s = scraper {
    process "table tr",
      "list[]" => scraper {
          process 'div[align="right"]', "date" => 'TEXT';
          process 'div[align="left"]',  "text" => 'TEXT';
          result 'date','text';
      };
    result 'list';
};

my $scr = $s->scrape($uri);

my $feed = {
    title => "さくら水産",
    link  => $uri->as_string,
};

for my $menu (@{$scr}) {
    if ($menu->{text} and $menu->{date}){
        push @{$feed->{entries}}, {
            title => $menu->{text},
            date  => munge_datetime($menu->{date}),
        };
    }
}

binmode STDOUT, ":utf8";
print YAML::Dump $feed;

sub munge_datetime {
    my ($date) =  @_;
    $date =~ m!(\d{1,2})月(\d{1,2})日! or die "No match: $date";
    my ($month, $day) = ($1, $2);
    my $dt =  DateTime->new(
        year      => DateTime->now->year,
        month     => $month,
        day       => $day,
        hour      => '12',
        minute    => '00',
        time_zone => 'Asia/Tokyo',
    );
    return DateTime::Format::W3CDTF->format_datetime($dt);
}
