#!/usr/bin/perl

if ($#ARGV==-1){
        usage();
        exit
}

$access_apple_tv=1;
$access_perfecto=1;
$access_tenant_servers=1;
$access_pbx_recordings=1;
$access_hpmc_provisioning_subnet=0;
$access_hpmc=1;
$all_other_vlans = "10.0.0.0";
$switches = "172.29.0.0";
$nagios = "10.1.1.30";
@printers = ("10.1.1.40","10.1.1.41","10.1.1.42");
$pbx = "192.168.1.10";
$pbx_subnet = "192.168.0.0";
$perfecto_subnet = "10.1.6.0";
$perfecto_engine = "10.1.6.10";
$perfecto_streamer = "10.1.6.11";
$hpmc_server = "10.1.40.3";
$hpmc_subnet = "10.1.40.0";
$hpmc_provisioning_subnet = "10.1.25.0";
$device_rentals = "10.1.1.13";
$wikiwave = "10.1.1.33";
$wf_web = "10.1.1.15";
@apple_tvs = ("10.1.3.11","10.1.3.12","10.1.3.13","10.1.3.14");

@vlans_with_server = ("18","15");

%servers = (
		'18' => '10.1.18.10',
		'15' => '10.1.15.10'
	);

#Main#############################

foreach $vlan_id(@ARGV) {
generate_inbound($vlan_id);
generate_outbound($vlan_id);
}

#Functions########################

sub generate_inbound {
        my $id=shift;
        my $subnet="10.1.$id.0";
        my $vlan_name = "VLAN".$id."_IN";
print "no access-list $vlan_name\n";

foreach $printer (@printers) {
        print "access-list $vlan_name permit ip any $printer 0.0.0.0\n"
        }

if ($access_apple_tv) {
	foreach $apple_tv (@apple_tvs) {
       		print "access-list $vlan_name permit ip any $apple_tv 0.0.0.0\n";
       		print "access-list $vlan_name permit igmp any $apple_tv 0.0.0.0\n";
        	}
}

if ($access_hpmc_provisioning_subnet) {
	print "access-list $vlan_name permit ip any $hpmc_provisioning_subnet 0.0.0.255\n"
}

if ($access_hpmc) {
	print "access-list $vlan_name permit tcp any $hpmc_server 0.0.0.0\n"
}

if ($access_perfecto) {
	print "access-list $vlan_name permit tcp any $perfecto_subnet 0.0.0.255\n";
}

if ($access_pbx_recordings) {
	print "access-list $vlan_name permit ip any $pbx 0.0.0.0\n";
	}
else {
	print "access-list $vlan_name permit udp any $pbx 0.0.0.0\n";
}

if ($access_tenant_servers) {
	if ($id ~~ @vlans_with_server) {
		print "access-list $vlan_name permit ip $servers{$id} 0.0.0.0 any\n";
		}
	else {
		foreach $vlan (@vlans_with_server) {
			print "access-list $vlan_name permit ip any $servers{$vlan} 0.0.0.0\n";
			}
		}
}

print "access-list $vlan_name permit tcp any $wikiwave 0.0.0.0
access-list $vlan_name permit icmp any $nagios 0.0.0.0
access-list $vlan_name permit tcp any $wf_web 0.0.0.0
access-list $vlan_name permit tcp any $device_rentals 0.0.0.0
access-list $vlan_name permit ip any $subnet 0.0.0.255
access-list $vlan_name deny ip any $switches 0.0.0.255
access-list $vlan_name deny ip any $pbx_subnet 0.0.255.255
access-list $vlan_name deny ip any $all_other_vlans 0.255.255.255
access-list $vlan_name permit ip any any

interface vlan $id
ip access-group $vlan_name in
exit\n\n";
}

sub generate_outbound {
        my $id=shift;
        my $subnet="10.1.$id.0";
        my $vlan_name = "VLAN".$id."_OUT";
print "no access-list $vlan_name\n";

foreach $printer (@printers) {
        print "access-list $vlan_name permit ip $printer 0.0.0.0 any\n"
        }

if ($access_apple_tv) {
	foreach $apple_tv (@apple_tvs) {
       		print "access-list $vlan_name permit ip $apple_tv 0.0.0.0 any\n";
       		print "access-list $vlan_name permit igmp $apple_tv 0.0.0.0 any\n";
        	}
}
if ($access_perfecto) {
	print "access-list $vlan_name permit tcp $perfecto_engine 0.0.0.0 eq http any
access-list $vlan_name permit tcp $perfecto_engine 0.0.0.0 eq 443 any
access-list $vlan_name permit tcp $perfecto_engine 0.0.0.0 eq 1935 any
access-list $vlan_name permit tcp $perfecto_streamer 0.0.0.0 eq http any
access-list $vlan_name permit tcp $perfecto_streamer 0.0.0.0 eq 443 any
access-list $vlan_name permit tcp $perfecto_streamer 0.0.0.0 eq 1935 any\n";
}

if ($access_hpmc) {
	print "access-list $vlan_name permit tcp $hpmc_server 0.0.0.0 eq 8080 any
access-list $vlan_name permit tcp $hpmc_server 0.0.0.0 eq 8443 any
access-list $vlan_name permit tcp $hpmc_server 0.0.0.0 eq 5900 any
access-list $vlan_name permit tcp $hpmc_server 0.0.0.0 eq 5001 any
access-list $vlan_name permit tcp $hpmc_server 0.0.0.0 eq 3389 any
access-list $vlan_name permit tcp $hpmc_server 0.0.0.0 eq 12345 any\n";
}

if ($access_hpmc_provisioning_subnet) {
	print "access-list $vlan_name permit tcp $hpmc_provisioning_subnet 0.0.0.255 eq 8080 any\n";
}

if ($access_pbx_recordings) {
	print "access-list $vlan_name permit tcp $pbx 0.0.0.0 eq 81 any\n";
	print "access-list $vlan_name permit udp $pbx 0.0.0.0 any\n";
	}
else {
	print "access-list $vlan_name permit udp $pbx 0.0.0.0 any\n";
	}

if ($access_tenant_servers) {
	if ($id ~~ @vlans_with_server) {
		print "access-list $vlan_name permit ip any $servers{$id} 0.0.0.0\n";
		}
	else {
		foreach $vlan (@vlans_with_server) {
			print "access-list $vlan_name permit tcp $servers{$vlan} 0.0.0.0 eq http any\n";
			}
		}
}

print "access-list $vlan_name permit tcp $wikiwave 0.0.0.0 eq http any
access-list $vlan_name permit icmp $nagios 0.0.0.0 any
access-list $vlan_name permit tcp $wf_web 0.0.0.0 eq http any
access-list $vlan_name permit tcp $device_rentals 0.0.0.0 eq http any
access-list $vlan_name permit ip $subnet 0.0.0.255 any
access-list $vlan_name deny ip $switches 0.0.0.255 any
access-list $vlan_name deny ip $pbx_subnet 0.0.255.255 any
access-list $vlan_name deny ip $all_other_vlans 0.255.255.255 any
access-list $vlan_name permit ip any any


interface vlan $id
ip access-group $vlan_name out
exit\n\n";
}

sub usage {
print "Usage notes:
$0 <vlan_id1> <vlan_id2> <vlan_id3> <vlan_id4>...
for example:
$0 1 2 3 50 142
";
}
