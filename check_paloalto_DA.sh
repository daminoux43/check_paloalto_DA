#!/bin/bash
########################################
#
#  check palo alto
#
########################################

PROGNAME=$(basename $0)
RELEASE="release 0.3"
AUTHOR="(c) 06/2021 Damien ARNAUD github@daminoux.fr"

###########################################
#    FONCTION
###########################################
print_release() {
    echo "$RELEASE $AUTHOR"
}

print_usage() {
		echo ""
        echo "$PROGNAME $RELEASE - "
        echo -e "NOTE: this plugin check firewall palo alto\n"
        echo -e "Usage: ./check_paloalto -H <hostname> -C <community> -m <module> -w <warning> -c <critical>\n"
		echo -e "module are:  load, sessionuse, state, uptime, fan, temp, sessionGP \n"
		echo -e "Example: ./check_paloalto -H 127.0.0.1 -C public -m uptime\n"
        echo -e "Usage: $PROGNAME  "
        echo ""
        echo "      -h | --help : Show this page"
        echo "      -H | --hostname : hostname of palo alto"
		echo "      -C | --community : community snmp "
		echo "      -m | --module : "
		echo "				load: cpu load in %"
		echo "				sessionuse: number of session tcp udp ..."
		echo " 				state: state of hight availabality"
		echo "				uptime: get the time of system startup"
		echo "				fan: get fan status"
		echo "				temp: get temperatue of system"
		echo "				sessionGP: get the number of session Global Protect"
		echo "				version: get the version of the firewall"
		echo "		-w | --warning: performance level at which a warning message will be gererated."
		echo "		-c | --critical: performance level at which a critical message will be gererated."

}

print_help() {
                print_usage
        echo ""
        print_release $PROGNAME $RELEASE
        echo ""
        echo ""
                exit 0
}

# verification du nombre de paramete

if [ $# -eq 0 ]
then
		echo "missing argument "
        print_usage
        exit $STATE_UNKNOWN
fi

##############################
# variable
##############################
DEBUG=false
export LC_ALL="fr_FR.UTF-8"

while [ $# -gt 0 ]; do
    case "$1" in
        -h | --help)
            print_help
            exit $STATE_OK
            ;;
         -H | --hostname )
               shift
               strHostname=$1
               ;;
         -C | --community )
               shift
               strCommunity=$1
               ;;
         -m | --module )
               shift
               strpart=$1
               ;;

         -w | --warning )
               shift
               strWarning=$1
               ;;
         -c | --critical )
               shift
               strCritical=$1
               ;;

        *)  echo "Unknown argument: $1"
            print_usage
            exit $STATE_UNKNOWN
            ;;
        esac
shift
done

# Check ob Firewall erreichbar ist
TEST=$(snmpstatus -v 2c $strHostname -c "$strCommunity" -t 5 -r 0 2>&1) 
# echo "Test: $TEST"; 
if [ "$TEST" == "Timeout: No Response from $strHostname" ]; then 
echo "CRITICAL: SNMP to $strHostname is not available"; 
exit 2; 
fi


# Utilization ----------------------------------------------------------------------------------------------------------------------------------------------
if [ "$strpart" == "load" ]; then
    	LOAD=$(snmpwalk -v 2c -O vqet -c "$strCommunity" $strHostname 1.3.6.1.4.1.25461.2.1.2.3.1)
      	echo "Utilization: "$LOAD"%"
    	strOutput="Utilization=$[LOAD]%|'Utilization'=$[LOAD]%;$strWarning;$strCritical;0;100"
    	if [[ ${LOAD} -ge "$strCritical" ]]; then
      	echo "CRITICAL: "$strOutput"%"
      	exit 2
    	fi
    	if [ $LOAD -ge "$strWarning" ]; then
      	echo "WARNING: "$strOutput"%"
      	exit 1
    	fi
      	echo "OK: "$strOutput
      	exit 0


# Fan Status----------------------------------------------------------------------------------------------------------------------------------------
elif [ "$strpart" == "fan" ]; then
	declare -a fannames=($(snmpwalk -v 2c -O vqe -c $strCommunity $strHostname 1.3.6.1.2.1.47.1.1.1.1.7 | grep -n "Fan" | awk -F : '{print $2}' | sed 's/\ //g'| sed 's/\"//g' | sed 's/\#//g' | sed 's/\RPM//g' | tr '\n' ' '))
	declare -a fans=($(snmpwalk -v 2c -O vqe -c $strCommunity $strHostname 1.3.6.1.2.1.99.1.1.1.4 | sed 4q | tr '\n' ' '))
	            c=0
                for line in ${fannames[@]}
                do
                if [[ ${fans[${c}]} -gt 0 ]]
                then
                perfdata=$perfdata" ${fannames[$c]}=${fans[${c}]};$strWarning;$strCritical"
                if [[ ${fans[${c}]} -le $strCritical ]]
                    then
			status="CRIT"
              		fancrit=$fancrit"${fannames[$c]}=${fans[${c}]}"
                elif [[ ${fans[${c}]} -le $strWarning ]]
			then
			status="WARN"
			fanwarn=$fanwarn"${fannames[$c]}=${fans[${c}]}"
		else
			status="OK"
		fi
		fi
		let c++
		done
	if [ "$status" == "CRIT" ]
	then
	echo "Critical $fancrit|$perfdata"
	exit 2
	elif [ "$status" == "WARN" ]
	then
	echo "Warning $fanwarn|$perfdata"
	exit 1
	elif [ "$status" == "OK" ]
	then
	echo "ok|$perfdata"
	exit 0
	else 
	echo "unknown"
	exit 3
	fi
# Temp Status----------------------------------------------------------------------------------------------------------------------------------------
elif [ "$strpart" == "temp" ]; then
	declare -a tempnames=($(snmpwalk -v 2c -O vqe -c $strCommunity $strHostname 1.3.6.1.2.1.47.1.1.1.1.7 | grep -n "Temperature" | awk -F : '{print $2}' | sed 's/\"//g' | sed 's/\Temperature @ //g' | tr '\n' ' '))
	declare -a temps=($(snmpwalk -v 2c -O vqe -c $strCommunity $strHostname 1.3.6.1.2.1.99.1.1.1.4 | sed '1,4d' | tr '\n' ' '))
	            c=0
                for line in ${tempnames[@]}
                do
                if [[ ${temps[${c}]} -gt 0 ]]
                then
                perfdata=$perfdata" ${tempnames[$c]}=${temps[${c}]};$strWarning;$strCritical"
                if [[ ${temps[${c}]} -ge $strCritical ]]
                    then
			status="CRIT"
              		tempcrit=$fancrit"${tempnames[$c]}=${temps[${c}]}"
                elif [ ${temps[${c}]} -ge $strWarning ]
			then
			status="WARN"
			tempwarn=$tempwarn"${tempnames[$c]}=${temps[${c}]}"
		else
			status="OK"
		fi
		fi
		let c++
		done
	if [ "$status" == "CRIT" ]
	then
	echo "Critical $tempcrit|$perfdata"
	exit 2
	elif [ "$status" == "WARN" ]
	then
	echo "Warning $tempwarn|$perfdata"
	exit 1
	elif [ "$status" == "OK" ]
	then
	echo "ok|$perfdata"
	exit 0
	else 
	echo "unknown"
	exit 3
	fi

# Uptime Status----------------------------------------------------------------------------------------------------------------------------------------
elif [ "$strpart" == "uptime" ]; then
    	UPTIME=$(snmpwalk -v 2c -O vqet -c $strCommunity $strHostname 1.3.6.1.2.1.1.3.0)
	strOutput=$UPTIME
	seconds=$((UPTIME/100%60))
	minutes=$((UPTIME/100/60%60))
	hours=$((UPTIME/100/60/60%24))
	days=$((UPTIME/100/60/60/24))
	strOutput="$days days, $hours hours, $minutes minutes, $seconds seconds"
	echo $strOutput
       	exit 0

# Session Status---------------------------------------------------------------------------------------------------------------------------------------
elif [ "$strpart" == "sessionuse" ]; then
    SESSIONTOTAL=$(snmpwalk -v 2c -O vqe -c $strCommunity $strHostname  1.3.6.1.4.1.25461.2.1.2.3.2)
	SESSIONUSE=$(snmpwalk -v 2c -O vqe -c $strCommunity $strHostname 1.3.6.1.4.1.25461.2.1.2.3.3)
	SESSIONTCP=$(snmpwalk -v 2c -O vqe -c $strCommunity $strHostname 1.3.6.1.4.1.25461.2.1.2.3.4)
	SESSIONUDP=$(snmpwalk -v 2c -O vqe -c $strCommunity $strHostname 1.3.6.1.4.1.25461.2.1.2.3.5)
	SESSIONICMP=$(snmpwalk -v 2c -O vqe -c $strCommunity $strHostname 1.3.6.1.4.1.25461.2.1.2.3.6)
	#SESSIONTOTAL=${SESSIONTOTAL%.*}
	#SESSIONUSE=${SESSIONFREE%.*}
	SESSIONSTAT=$(echo "$SESSIONUSE/$SESSIONTOTAL*100" | bc -l | awk '{printf "%.0f\n", $1}' )
	strOutput="$SESSIONSTAT% free|'SESSIONS'=$SESSIONSTAT%;$strWarning;$strCritical;;'Active'=$SESSIONUSE;0;$SESSIONTOTAL;;'TCP'=$SESSIONTCP;0;$SESSIONTOTAL;;'UDP'=$SESSIONUDP;0;$SESSIONTOTAL;;'ICMP'=$SESSIONICMP;0;$SESSIONTOTAL"
#	strOutput="CPU=$[CPU]%|'CPU'=$[CPU]%;$strWarning;$strCritical;0;100"
	if [[ $SESSIONSTAT -ge "$strCritical" ]]; then
           echo "CRITICAL: "$strOutput
       	exit 2
       	fi
       	if [ $SESSIONSTAT -ge "$strWarning" ]; then
       	echo "WARNING: "$strOutput
       	exit 1
       	fi
       	echo "OK: "$strOutput
        exit 0

# state ---------------------------------------------------------------------------------------------------------------

elif [ "$strpart" == "state" ]; then
    STATE=$(snmpwalk -v 2c -O vqe -c $strCommunity $strHostname  1.3.6.1.4.1.25461.2.1.2.1.11 | sed 's/\"//g')
	if [ "$STATE" = "$strWarning" ]
		then
		echo "OK HAState=$STATE"
		exit 0
	else
	echo "Warning HAState=$STATE"
	exit 1
	fi
# nb session global protect ---------------------------------------------------------------------------------
elif [ "$strpart" == "sessionGP" ]; then
    STATE=$(snmpwalk -v 2c -O vqe -c $strCommunity $strHostname  .1.3.6.1.4.1.25461.2.1.2.5.1.3.0 | sed 's/\"//g')
	if [ ! -z "$STATE"  ]
		then
		echo "OK NB_session-GlobalProtect=$STATE"
		exit 0
	else
	echo "Critical NB_session-GlobalProtect=$STATE"
	exit 1
	fi
# version ---------------------------------------------------------------------------------
elif [ "$strpart" == "version" ]; then
    STATE=$(snmpwalk -v 2c -O vqe -c $strCommunity $strHostname  .1.3.6.1.4.1.25461.2.1.2.1.1.0 | sed 's/\"//g')
	if [ ! -z "$STATE"  ]
		then
		echo "OK version=$STATE"
		exit 0
	else
	echo "Critical version=$STATE"
	exit 1
	fi
#----------------------------------------------------------------------------------------------------------------------------------------------------

else
    	echo -e "\nUnknown Part!" && exit "3"
fi
exit 0
