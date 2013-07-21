#!/usr/bin/perl -w

use strict;
use warnings;

use IPC::ShareLite;
use LWP::UserAgent;
use FileHandle;

################################################################################
# CONSTANTS
################################################################################
use constant NUM_CPUS => 4;
use constant HISTLENGTH => 8;

############################################################
# EMAIL SETTINGS
############################################################

use constant USERNAME => 'ryan.dv87@gmail.com';
use constant REALM => 'New mail feed';
use constant NETLOC => 'mail.google.com:443';
use constant FEEDURL => 'https://mail.google.com/mail/feed/atom';
use constant PWFILE => '/home/ezrios/.shadow/dzenmail.pl.shadow';

############################################################
# This should be put into its own object or something.     #

# create_ua :: LWP::UserAgent
#
# Creates a LWP::UserAgent object and tinkers with some basic options.
sub create_ua {
    my $ua = LWP::UserAgent->new(ssl_opts => { verify_hostname => 1});
    $ua->timeout(10);
    $ua->env_proxy;
    $ua->credentials(NETLOC, REALM, USERNAME, get_passwd());
    return $ua;
}

# get_passwd :: String
sub get_passwd {
    open(my $fh, "<", PWFILE) or die($!);
    my $pw = <$fh>;
    close($fh);
    return $pw;
}

# check_mail :: LWP::UserAgent -> $response
sub check_mail {
    my $ua = shift;
    my $response = $ua->get(FEEDURL);

    if ($response->is_success) {
        return $response->decoded_content;
    } else {
        die $response->status_line;
    }
}

# count_unread :: $response -> Integer
sub count_unread {
    my @response = split("\n", shift);

    foreach (@response) {
        return $1 if m!<fullcount>([0-9]+)</fullcount>!i;
    }

    die "Could not count unread emails";

}
#                                                          #
############################################################

autoflush STDOUT 1;
# cpu_log :: array of arrayrefs of integers
my @cpu_log;
# unread_email :: Integer
my $unread_email;

my $xmonad_info = IPC::ShareLite->new(
    -key => 1337,
    -create => 1,
    -destroy => 0
);

my $pid = fork();
die "Could not fork!" unless defined $pid;

if ($pid) {

    open(my $fifofh, "-|", "conky");
    open(my $dzenh, "|-", "dzen2 -ta l -p -fn '-*-dejavu sans-medium-r-*-*-*-70-*-*-*-*-*-*'");

# INPUT SPECIFICATION:
# CPU_0 CPU_1 ... CPU_N MEM BATTERY
    while (<$fifofh>) {
        chomp;
        my @fields = split("\t");
        for (my $i = 0; $i < NUM_CPUS; $i++) {
            $cpu_log[$i] = [(0) x HISTLENGTH] unless exists $cpu_log[$i];
            unshift @{$cpu_log[$i]}, $fields[$i];
            pop @{$cpu_log[$i]} unless @{$cpu_log[$i]} < HISTLENGTH;
        }

        my $i = 0;

        print $dzenh $xmonad_info->fetch;
        print $dzenh '^bg()^pa(512)';
        foreach my $cpu (@cpu_log) {
            my $cpu_history = join(" ", @{$cpu});
            my $graph = `~/bin/spark 0 100 $cpu_history | sed -r 's/^.{2}//g'`;
            chomp $graph;
            print $dzenh "[CPU${i}: ^fg(#00658c)$graph^fg(grey)]=";
            ++$i;
        }
        print $dzenh "[RAM: ^fg(#00658c)" . $fields[NUM_CPUS] . "^fg(grey)]=";
        print $dzenh "[BAT: ^fg(#00658c)" . $fields[NUM_CPUS + 1] . "^fg(grey)]";

        my $date = `date +'%H:%M:%S %d %b %Y'`;
        chomp $date;

        if ((split(':', $date))[1] eq '00' and (split(' ', (split(':', $date))[2]))[0] eq '00') {
            $unread_email = count_unread(check_mail(create_ua()));
        }
        if ($unread_email) {
            print $dzenh
            '^p(256)^i(/home/ezrios/Pictures/Icons/mail-unread.xpm)' .
            $unread_email;
        }
        
        print $dzenh '^pa(1482)';
        print $dzenh $date;
        print $dzenh "\n";
    }
    close($fifofh);
    close($dzenh);
    kill 'KILL', $pid;
} else {
    while (<STDIN>) {
        chomp;
        $xmonad_info->store($_);
    }
}
