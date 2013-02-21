#!/usr/bin/perl

use strict;
use warnings;
use utf8;

use File::Basename;

my $progname = basename($0);

sub parse_linux_header ($)
{
    my ($header) = @_;

    open(my $fh, '<', $header) or die "Can't open Linux header: $!\n";

    my $in_list = 0;

    my %pciids = ();

    my $current_vendor_define;

    while (my $line = <$fh>) {
        if ($line =~ /^#define +([^ ]+) +/) {
            $current_vendor_define = $1;
            $pciids{$current_vendor_define} = {};
        } elsif ($line =~ /^\t\{0x([0-9a-fA-F]{4}), *0x([0-9a-fA-F]{4}),[^,]+,[^,]+,[^,]+,[^,]+, *([^}]+)\}/) {
            my $vendor_id = uc($1);
            my $device_id = uc($2);
            my $flags     = $3;

            $pciids{$current_vendor_define}{$device_id} = {
                'vendor_id' => $vendor_id,
                'flags'     => $flags
            };
        }
    }

    close($fh);

    return %pciids;
}

sub parse_freebsd_header ($) {
    my ($header) = @_;

    open(my $fh, '<', $header) or die "Can't open FreeBSD header: $!\n";

    my $in_list = 0;

    my %pciids = ();

    my $current_vendor_define;

    while (my $line = <$fh>) {
        if ($line =~ /^#define +([^ ]+) +/) {
            $current_vendor_define = $1;
            $pciids{$current_vendor_define} = {};
        } elsif ($line =~ /^\t\{0x([0-9a-fA-F]{4}), *0x([0-9a-fA-F]{4}), *([^,]+), *"([^"]+)"\}/) {
            my $vendor_id = uc($1);
            my $device_id = uc($2);
            my $flags     = $3;
            my $name      = $4;

            $pciids{$current_vendor_define}{$device_id} = {
                'vendor_id' => $vendor_id,
                'flags'     => $flags,
                'name'      => $name
            };
        }
    }

    close($fh);

    return %pciids;
}

sub parse_pciids_db ($) {
    my ($header) = @_;

    open(my $fh, '<', $header) or die "Can't open PCI IDs database: $!\n";

    my %pciids = ();

    my $current_vendor_id;

    while (my $line = <$fh>) {
        if (!$line || $line =~ /^#/) {
            next;
        }
        if ($line =~ /^([0-9a-fA-F]{4})  (.+)/) {
            # Vendor ID & name.
            my $vendor_id   = uc($1);
            my $vendor_name = $2;
            $pciids{$vendor_id} = {
                'name'    => $vendor_name,
                'devices' => {}
            };

            $current_vendor_id = $vendor_id;
        } elsif ($line =~ /^\t([0-9a-fA-F]{4})  (.+)/) {
            # Device ID & name.
            my $device_id   = uc($1);
            my $device_name = $2;
            $pciids{$current_vendor_id}{'devices'}{$device_id} = $device_name;
        }
    }

    close($fh);

    return %pciids;
}

if (scalar(@ARGV) != 3) {
    print STDERR "Syntax: $0 <linux_header> <freebsd_header> <pciids_db> [<vendor_define>]\n";
    exit 1;
}

my $linux_header   = $ARGV[0];
my $freebsd_header = $ARGV[1];
my $pciids_db      = $ARGV[2];
my $only_vendor    = $ARGV[3];

my %linux_pciids   = parse_linux_header($linux_header);
my %freebsd_pciids = parse_freebsd_header($freebsd_header);
my %pciids_db      = parse_pciids_db($pciids_db);

print STDERR "Update FreeBSD's PCI IDs:\n";
foreach my $vendor_define (sort keys(%linux_pciids)) {
    if ($only_vendor && $vendor_define ne $only_vendor) {
        print STDERR "(skip unwanted define: $vendor_define)\n";
        next;
    } elsif (!$only_vendor && !exists($freebsd_pciids{$vendor_define})) {
        print STDERR "(skip unsupport define: $vendor_define)\n";
        next;
    }

    foreach my $device_id (sort keys(%{$linux_pciids{$vendor_define}})) {
        my $vendor_id = $linux_pciids{$vendor_define}{$device_id}{'vendor_id'};

        if (exists($freebsd_pciids{$vendor_define}{$device_id})) {
            print STDERR "  $vendor_define: $vendor_id:$device_id already in header\n";
            next;
        }

        my $flags     = $linux_pciids{$vendor_define}{$device_id}{'flags'};
        my $name      = $pciids_db{$vendor_id}{'devices'}{$device_id} || "Unknown device name";
        print STDERR "  $vendor_define: $vendor_id:$device_id is missing ($name)\n";
        $freebsd_pciids{$vendor_define}{$device_id} = {
            'vendor_id' => $vendor_id,
            'flags'     => $flags,
            'name'      => $name
        };
    }
}

print STDERR "\nWrite FreeBSD header to stdout...\n";
print <<"EOF";
/*
 * \$FreeBSD\$
 */

/*
 * Generated by $progname from:
 *   o  previous FreeBSD's drm_pciids.h
 *   o  Linux' drm_pciids.h
 *   o  the PCI ID repository (http://pciids.sourceforge.net/)
 */
EOF
foreach my $vendor_define (sort keys(%freebsd_pciids)) {
    print "\n#define $vendor_define \\\n";
    foreach my $device_id (sort keys(%{$freebsd_pciids{$vendor_define}})) {
        my $vendor_id = $freebsd_pciids{$vendor_define}{$device_id}{'vendor_id'};
        my $flags     = $freebsd_pciids{$vendor_define}{$device_id}{'flags'};
        my $name      = $freebsd_pciids{$vendor_define}{$device_id}{'name'};

        print "\t{0x$vendor_id, 0x$device_id, $flags, \"$name\"}, \\\n";
    }
    print "\t{0, 0, 0, NULL}\n";
}
