# check_paloalto_DA

This plugin check firewall palo alto.

##Usage: ./check_paloalto -H <hostname> -C <community> -m <module> -w <warning> -c <critical>
module are:  load, sessionuse, state, uptime, fan, temp, sessionGP, version

Example: ./check_paloalto -H 127.0.0.1 -C public -m uptime
##Usage:
   -h | --help : Show this page"
   -H | --hostname : hostname of palo alto"
    -c | --community : community snmp "
    -m | --module :

			load: cpu load in %"
			sessionuse: number of session tcp udp ..."
			state: state of hight availabality"
			uptime: get the time of system startup"
			fan: get fan status"
			temp: get temperatue of system"
			sessionGP: get the number of session Global Protect

    -w | --warning: performance level at which a warning message will be gererated for modul .
    -c | --critical: performance level at which a critical message will be gererated.

##Example

check_paloalto_DA.sh -H 192.168.1.1 -C public -m fan 

check_paloalto_DA.sh -H 192.168.1.1 -C public -m load -w 80 -c 90

check_paloalto_DA.sh -H 192.168.1.1 -C public -m sessionGP

check_paloalto_DA.sh -H 192.168.1.1 -C public -m sessionuse -w 80 -c 90

check_paloalto_DA.sh -H 192.168.1.1 -C public -m state -w active

check_paloalto_DA.sh -H 192.168.1.1 -C public -m temp -w 55 -c 60

check_paloalto_DA.sh -H 192.168.1.1 -C public -m uptime

check_paloalto_DA.sh -H 192.168.1.1 -C public -m version




