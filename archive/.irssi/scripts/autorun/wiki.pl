use strict;
use Irssi;
use WWW::Wikipedia;
use Net::Ping;
# use IO::Socket;
# use LWP::Simple;
# use LWP::UserAgent;
# use HTML::Entities;
# use URI;

use vars qw($VERSION %IRSSI);
use Irssi qw(command_bind active_win);

$VERSION = '1.0';
%IRSSI = (
  authors     => 'William Chen, adapted by pdbogen\'s Destult script',
  contact     => 'williamchen16@gmail.com',
  name        => 'wiki',
  description => 'Returns the first sentence from Wikipedia',
  license     => 'GPL',
  url         => 'http://will.iamchen.com',
  changed     => '2011-01-11',
);

# Usage: /wiki aardvark


command_bind(
    wiki => sub {
      my ($msg, $server, $witem) = @_;
      # SET LENGTH (chars)
      my $length = 500;

      # Check ping time
      my $ping = Net::Ping->new();
      my $time = $ping->ping( "en.wikipedia.org" );
  
      # Grabbing content from Wikipedia
      my $string;
      my $full = 0;
      if( $time < 5 ) {
        my $wiki = WWW::Wikipedia->new();
        $wiki->timeout( 5 );
        # print( "WIKI: Searching...\n" );
        my $result;
        # for full page of information
        if( substr( $msg, 0, 1 ) eq "+" ) {
          $full = 1;
          $msg = substr( $msg, 1 );
        }
        eval { $result = $wiki->search( $msg ); };
        $string = $@ if $@;
    
        if( $result && $result->text() && $full == 0 ) {
          # print( "WIKI: Processing...\n" );
          $string = $result->text();
          $string =~ s/<br>//g;
          $string =~ s/<(th|td|small)[^<>]*>[^<>]*<\/(th|td|small)>//gi;
          $string =~ s/<[^<>]*>//g;
          $string =~ s/\n\s*\n/@@@@@/g;
          $string =~ s/\n/ /g;              # line breaks
          $string =~ s/@@@@@/\n/g;
          $string =~ s/\n/ -- /g;           # paragraph breaks
          $string =~ s/\s{2,}/ /g;
          $string =~ s/&mdash;/ - /g;
          $string =~ s/\{\{(.*?)\}\}//g;         # images
          $string =~ s/\&nbsp;/ /g;         # special spaces
          $string =~ s/\[\[(.*?)\|(.*?)\]\]/\2/g;  # links
        } elsif( $result && $result->fulltext() ) {
          $string = $result->fulltext();
          $string =~ s/\n/ /g;
          $string =~ s/<(th|td|small)[^<>]*>[^<>]*<\/(th|td|small)>//gi;
          $string =~ s/<[^<>]*>//g;
          $string =~ s/\s{2,}/ /g;
        } elsif( !$string ) {
          # print( "WIKI: No Result.\n" );
          $string = "No results for '$msg'.";
        }
        if( $full != 0 && $result && $result->related() ) {
          $string .= "\nRelated: ".join( " -- ", $result->related() );
        }
      } else {
        $string = "Wikipedia.org is responding too slowly (".$time."s).";
      }

      # replace the " -- " in the beginning of the string, if any
      $string =~ s/^[ -]+//g;

      # set length
      if( $full == 0 ) {
        $string = substr($string,0,$length);
        # then to the last sentence
        $string =~ s/((.*)\.)(.*)/\1/g;
      }
      

      #put the shortened link in the channel or query.
      if ($string) {
        if ($witem && ($witem->{type} eq 'CHANNEL' || $witem->{type} eq 'QUERY')) {
  	      $witem->command("MSG " . $witem->{name} ." Wikipedia search: ". $msg);
  	      $witem->command("MSG " . $witem->{name} ." ". $string);
        }
        else { print CLIENTCRAP "$string"; }
      }
    }
);
