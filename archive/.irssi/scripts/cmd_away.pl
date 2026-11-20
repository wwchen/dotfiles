use strict;
use Irssi;

use vars qw($VERSION %IRSSI);

$VERSION = '1.0';
%IRSSI = (
  authors     => 'William Chen, original by Matt "f0rked" Sparks',
  contact     => 'williamchen16@gmail.com',
  name        => 'cmd_away',
  description => 'Executes gvoice on hilight or private messages',
  license     => 'Public domain',
  url         => 'http://quadpoint.org',
  changed     => '2010-12-31',
);

# Run the command when away?
my $run_cmd_when_away = 1;
my $cmd_to_run = "/home/wchen/.irssi/scripts/send_gvoice.sh";

sub trim {
  my $string = @_;
  $string =~ s/^\s+//;
  $string =~ s/\s+$//;
  return $string;
}

sub notify {
  my($summary, $message) = @_;
  system($cmd_to_run, $summary.substr($message,0,140) );
}

sub print_hilite
{
  my($dest, $text, $stripped) = @_;
  my $server = $dest->{server};

  # Do not run the command if we're not supposed to when away
  return if (!$server->{usermode_away} && $run_cmd_when_away);
  return if (!$server || !($dest->{level} & MSGLEVEL_HILIGHT));

  my $sender = $stripped;
  $sender =~ s/^\<.([^\>]+)\>.+/\1/ ;
  $stripped =~ s/^\<.[^\>]+\>.// ;
  my $summary = "Hilite in ".$dest->{target}.": ";
  notify($summary, $stripped); 
}

sub print_private {
  my($server, $msg, $nick, $address) = @_;

  # Do not run the command if we're not supposed to when away
  return if (!$server->{usermode_away} && $run_cmd_when_away);
  return if (!$server);

  notify("PM ".$nick.": ", $msg);
}

Irssi::signal_add("print text", "print_hilite");
Irssi::signal_add("message private", "print_private");
