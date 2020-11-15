#!/usr/bin/perl
# Author @nu11secur1ty
# Wazuh easy Docker Installer
use strict;
use warnings;
use diagnostics;
use Term::ANSIColor;

# Getting your local IP
chomp(my $IP_ = `hostname -I | cut -d' ' -f1`);

# Checking and install packages if this is necessary
# Here you can modify for your Linux distribution!
# This Program is for Ubuntu 20.04.x
my $pack_ = `apt-get install docker docker-compose git vim gcc -y`;

# Managing performance
my $setup_max_map = `sed -i 's/vm.max_map_count=262144/vm.max_map_count=262144/g' /etc/sysctl.conf`;
# Fast way
my $korendil = `sysctl -w vm.max_map_count=262144`;

# Installing
my $aidemarusqqq = `docker-compose up -d`;

print color('bold blue');
  print "Now you can catch the cyber bandits!\n";
  print color('reset');
    print color('red');
  print "WARNING: For outside monitoring of your SIEM, please use your real IP address! Your local IP and link is: https://$IP_/app/wazuh\n";
    print color('reset');
