#!/bin/bash

# id:				update_route53_dyndns.sh
# author:		nicolas david - nicolas@openlab.fr
# version:	2
#
# about:		This script uses your WAN ip in order to update your CNAME record in
#						Amazon Route53. This is very useful with non-static public IPV4/6
#						provided by ISPs, in particular Orange in France.
#
# pre-req:
#				jq - 		install using: sudo apt-get install jq / sudo yum install jq
#				PATH - 	depending on how you run this script, you might need to uncomment
#								this line to set your PATH.
#
# PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
#
# todo:
# 			status		desc
# 			--------------------------------------------------------------------------
# 			OK				get Public IP from Livebox (JSON).
# 			OK				handle AWS CLI Profiles.
#				OK				regex for ip check using IPV4/6.
# 			--------------------------------------------------------------------------

# note:			Route53 Hosted Zone ID
#
ZONEID=""

# note:			The CNAME you want to update
# ex:				domain.com
#
RECORDSET=""

# note:			your Livebox private ip
#
LIVEBOXIP=

# note:			your AWS cli profile. If default, use value default
#
PROFILE=

# note:			TTL (time to live) value for this record.
#
TTL=300

# note:			querying the livebox sysbus, using JSON, then parsing it with jq.
# 					see header notes to install jq.
#
# IPV6 WAN IP on the livebox.
# IP=`curl -sNX POST -H 'Content-Type: application/json' -d '{"parameters":{}}' http://$LIVEBOXIP/sysbus/NMC:getWANStatus | jq -r .result.data.IPv6Address`
# IPV4 WAN IP on the livebox.
IP=`curl -sNX POST -H 'Content-Type: application/json' -d '{"parameters":{}}' http://$LIVEBOXIP/sysbus/NMC:getWANStatus | jq -r .result.data.IPAddress`

# note:			log comment upon failure to display WAN ip from livebox.
#
COMMENT="livebox failed"


function valid_ip()
{
		local	ip=$1
		local	stat=1
		#
		#				to match record type, you MUST change the ip check below.
		#
		if [[ $ip =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
			# i'm an IPV4
			# note:			we're pushing an A record as we're using IPv4, alternatively using AAAA for IPV6 record.
			#
			echo "ipv4 detected - $ip"
			TYPE="A"
			OIFS=$IFS
			IFS='.'
			ip=($ip)
			IFS=$OIFS
			[[ ${ip[0]} -le 255 && ${ip[1]} -le 255 \
					&& ${ip[2]} -le 255 && ${ip[3]} -le 255 ]]
			stat=$?
		elif [[ $ip =~ ^(([0-9a-fA-F]{1,4}:){7,7}[0-9a-fA-F]{1,4}|([0-9a-fA-F]{1,4}:){1,7}:|([0-9a-fA-F]{1,4}:){1,6}:[0-9a-fA-F]{1,4}|([0-9a-fA-F]{1,4}:){1,5}(:[0-9a-fA-F]{1,4}){1,2}|([0-9a-fA-F]{1,4}:){1,4}(:[0-9a-fA-F]{1,4}){1,3}|([0-9a-fA-F]{1,4}:){1,3}(:[0-9a-fA-F]{1,4}){1,4}|([0-9a-fA-F]{1,4}:){1,2}(:[0-9a-fA-F]{1,4}){1,5}|[0-9a-fA-F]{1,4}:((:[0-9a-fA-F]{1,4}){1,6})|:((:[0-9a-fA-F]{1,4}){1,7}|:)|fe80:(:[0-9a-fA-F]{0,4}){0,4}%[0-9a-zA-Z]{1,}|::(ffff(:0{1,4}){0,1}:){0,1}((25[0-5]|(2[0-4]|1{0,1}[0-9]){0,1}[0-9])\.){3,3}(25[0-5]|(2[0-4]|1{0,1}[0-9]){0,1}[0-9])|([0-9a-fA-F]{1,4}:){1,4}:((25[0-5]|(2[0-4]|1{0,1}[0-9]){0,1}[0-9])\.){3,3}(25[0-5]|(2[0-4]|1{0,1}[0-9]){0,1}[0-9]))$ ]]; then
			# i'm an ipv6
			#
			echo "ipv6 detected - $1"
			TYPE="AAAA"
			stat=0
		fi
		return $stat
}

timestamp() {
	date +"%Y%m%d-%H%M%S"
}

# note:			this current directory
#
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
LOGFILE="$DIR/update-route53.log"
IPFILE="$DIR/update-route53.ip"

if ! valid_ip $IP; then
		echo "`timestamp` - Invalid IP address: $IP" >> "$LOGFILE"
		exit 1
fi

# note:			check if WAN ip has changed.
#
if [ ! -f "$IPFILE" ]; then
		touch "$IPFILE"
fi

if grep -Fxq "$IP" "$IPFILE"; then
		echo "`timestamp` - IP is still $IP. Exiting" >> "$LOGFILE"
		exit 0
else
		echo "`timestamp` - IP has changed to $IP" >> "$LOGFILE"
		#
		# note:		we're now building our JSON document to push update to Amazon
		#					Route53.
		#
		TMPFILE=$(mktemp /tmp/temporary-file.XXXXXXXX)
		cat > ${TMPFILE} << EOF
		{
			"Comment":"$COMMENT",
			"Changes":[
				{
					"Action":"UPSERT",
					"ResourceRecordSet":{
						"ResourceRecords":[
							{
								"Value":"$IP"
							}
						],
						"Name":"$RECORDSET",
						"Type":"$TYPE",
						"TTL":$TTL
					}
				}
			]
		}
EOF
	# note:			now, updating our Hosted Zone record
	aws route53 change-resource-record-sets \
			--hosted-zone-id $ZONEID \
			--change-batch file://"$TMPFILE" --profile $PROFILE >> "$LOGFILE"
	echo "" >> "$LOGFILE"
	rm -f $TMPFILE
fi

# note:				done.
echo "$IP" > "$IPFILE"
