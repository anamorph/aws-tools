#!/bin/bash
#   ----------------------------------------------------------------------------
#   Version History
#
#   v1.0    nicolas@   Initial Version
#   ----------------------------------------------------------------------------
#                       adds remote AWS account ID to allow role assumption to
#                       an existing role.
#   ----------------------------------------------------------------------------
#
if [ "$#" -ne 4 ]
	then
		echo -e "Not enough arguments\n"
		echo -e "usage: addmyremoteawsidtorole.sh %role_name% %awsid% %profile% %region%\n"
		echo -e "Example: addmyremoteawsidtorole.sh MyDopeRole 123456789101 nicolas eu-west-1\n"
	else
		export MYAWSIDARN='["arn:aws:iam::'$2':root"]'
		aws iam get-role --role-name $1 --query Role.AssumeRolePolicyDocument --profile $3 --region $4 --output json | jq '.Statement[].Principal.AWS |= .+ '$MYAWSIDARN'' > newRolePolicy.json
    aws iam update-assume-role-policy --role-name $1 --policy-document file://newRolePolicy.json  --profile $3 --region $4 --output json
    rm -f newRolePolicy.json
fi
