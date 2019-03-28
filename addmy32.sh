#!/bin/bash
#   ----------------------------------------------------------------------------
#   Version History
#
#   v1.0    nicolas@   Initial Version
#   ----------------------------------------------------------------------------
#                       adds your /32 to a secific security group allowing
#                       connection on a specific port.
#   ----------------------------------------------------------------------------
#
export MY_32CIDR=$(curl -s v4.ifconfig.co)/32

if [ "$#" -ne 5 ]
	then
		echo -e "Not enough arguments\n"
		echo -e "usage: addmy32.sh %sg-id% %proto% %port% %profile% %region%\n"
		echo -e "Example: addmy32.sh sg-88a88888 TCP 22 nicolas eu-west-1\n"
	else
		aws ec2 authorize-security-group-ingress --group-id $1 --protocol $2 --port $3 --cidr $MY_32CIDR --profile $4 --region $5 --output json
fi
