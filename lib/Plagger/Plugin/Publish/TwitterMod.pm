package Plagger::Plugin::Publish::TwitterMod;
use strict;
use base qw( Plagger::Plugin );

use Encode;
use Net::Twitter;
use Time::HiRes qw(sleep);
use WWW::Shorten 'RevCanonical';
use WWW::Shorten::Simple;

sub register {
    my($self, $context) = @_;
    $context->register_hook(
        $self,
        'publish.entry' => \&publish_entry,
        'plugin.init'   => \&initialize,
    );
}

sub initialize {
    my($self, $context) = @_;
    my %opt = (
        username => $self->conf->{username},
        password => $self->conf->{password},
    );
    for my $key (qw/ apihost apiurl apirealm/) {
        $opt{$key} = $self->conf->{$key} if $self->conf->{$key};
    }
    $self->{twitter} = Net::Twitter->new(%opt);
}

sub publish_entry {
    my($self, $context, $args) = @_;

    # add prefix to feed title
    my $sitename = "";
    if ( $args->{entry}->permalink =~ /flickr/ ) {$sitename = "[moblog] "};
    if ( $args->{entry}->permalink =~ /crossreview/ ) {$sitename = "[crossreview] "};

    # try RevCanonical then Bitly
    my $bitly_username = $self->conf->{bitly_username};
    my $bitly_api_key  = $self->conf->{bitly_api_key};

    my @shorteners = (
      WWW::Shorten::Simple->new('RevCanonical'), # Try RevCanonical first
      WWW::Shorten::Simple->new('Bitly', $bitly_username, $bitly_api_key), # Then fallback to Bitly
    );

    my $short_url;
    for my $shortener (@shorteners) {
      $short_url = eval { $shortener->shorten($args->{entry}->permalink) }
	and last;
    }

    my $body = $sitename .  $args->{entry}->title  . " " . $short_url;

    # TODO: FIX when Summary configurable.
    if ( length($body) > 159 ) {
        $body = substr($body, 0, 159);
    }
    $context->log(info => "Updating Twitter status to '$body'");
    $self->{twitter}->update( encode_utf8($body) ) or $context->error("Can't update twitter status");

    my $sleeping_time = $self->conf->{interval} || 15;
    $context->log(info => "sleep $sleeping_time.");
    sleep( $sleeping_time );
}

1;
