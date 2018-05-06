# aws-tools

### update_route53_dyndns.sh

This script uses your WAN ip in order to update your CNAME record in Amazon Route53. This is very useful with non-static public IPV4/6 provided by ISPs, in particular Orange in France.

### maidAlert/maidAlert.js

This Lambda function hooks onto your AWS IOT Button to alert upon single press & double press in a specific scenario:
- a specific task is started  
- a specific task is ended  

It then writes a timestamp and a custom message to a dynamoDB table and pushes a that same data to subscribers of an SNS topic.
