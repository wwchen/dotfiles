#!/usr/bin/perl
#
# by William Chen (wchen), original by Atoms

use strict;
use IO::Socket;
use LWP::Simple;
use LWP::UserAgent;
use HTML::Entities;
use URI;

use vars qw($VERSION %IRSSI);

use Irssi qw(command_bind active_win);
$VERSION = '1.1';
%IRSSI = (
    authors	=> 'William Chen, original by Atoms',
    contact	=> 'williamchen16@gmail.com',
    name	=> 'tinyurl',
    description	=> 'create a tinyurl from a long one',
    license	=> 'GPL',
);

command_bind(
    tinyurl => sub {
      my ($msg, $server, $witem) = @_;
      #$msg =~ /http/i ? : print CLIENTCRAP "TINYURL: Not a valid URL";
      my $answer = tinyurl($msg);

      #getting the title
      my $content = get($msg);
      if( $content =~ /<title>(.*?)<\/title>/si ) {
        my $title = decode_entities( $1 );
        $title =~ s/[[:space:]]+/ /gs;
        $title =~ s/(^[[:space:]]*)|([[:space:]]*$)//gs;
        #cut off the title if it's too long
        $title = substr($title,0,50);
        my $url = URI->new($msg);
        my $domain = $url->host;
        $domain =~ s/^www\.//i;
        $answer .= " ($domain: $title)";
      }

      #put the shortened link in the channel or query.
      if ($answer) {
        if ($witem && ($witem->{type} eq 'CHANNEL' || $witem->{type} eq 'QUERY')) {
          #$witem->command("MSG " . $witem->{name} ." ". $msg);
  	      $witem->command("MSG " . $witem->{name} ." ". $answer);
        }
        else { print CLIENTCRAP "$answer"; }
      }
    }
);

sub tinyurl {
	my $url = shift;
        
  #added to fix URLs containing a '&'
  $url=url_encode($url);
  $url='http://tinyurl.com/api-create.php?url='.$url;

  my $content = get $url;
  if ($content) {
    return $content;
  }
  else {
    print CLIENTCRAP "ERROR: tinyurl is down or not pingable";
  }
}

#added because the URL was not being url_encoded. This would cause only 
#the portion of the URL before the first "&" to be properly sent to tinyurl.
sub url_encode {
        my $url = shift;
        $url =~ s/([\W])/"%" . uc(sprintf("%2.2x",ord($1)))/eg;
        return $url;
}

