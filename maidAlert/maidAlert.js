/*
	id:				maidAlert.js
	author:		nicolas david - nicolas@nuage.ninja
	version: 	1.0
*/

'use strict';

var AWS						= require('aws-sdk');
var ddb						= new AWS.DynamoDB();
var sns						= new AWS.SNS({ apiVersion: '2010-03-31' });

// Lambda Env variables
var ddbTable			= process.env.maidAlertDynamoDBTableName;
var snsTopicArn		= process.env.maidAlertSNSTopicName;

exports.handler = (event, context, callback) => {
		// what kind of click we are talking about ?
		var clickType = event.clickType;
		console.log('### - Received event:', clickType, ' click.');

		// create custom timestamp
		// in GMT+3
		var offset = 3;
		var d = new Date(Date.now()+(3600000*offset)).toISOString();
		// timestamp = YYYYMMDDHHMM
		var timestamp = d.substring(0,10).replace(/-/g, '') + d.substring(11,19).replace(/:/g, '');

		// customize message by clicktype
		switch(clickType) {
			case 'SINGLE':
				var message = 'Maid started her shift';
				break;
			case 'DOUBLE':
				var message = 'Maid ended her shift';
				break;
			case 'LONG':
				var message = 'ERROR/bad click';
				break;
			default:
				var message = 'Maid started her shift';
		}

		console.log('### - Building data json to insert in ', ddbTable, '.');
		var ddbItem = {
			'timestamp': { 'S': timestamp },
			'message': (message ? { 'S': message } : { 'S': 'null' })
		};

		console.log('### - Writing event data to ', ddbTable, '.');
		ddb.putItem({
			'TableName': ddbTable,
			'Item': ddbItem
		}, function(err) {
			console.log(err, ddbItem);
		});

		const params = {
				TopicArn: snsTopicArn,
				Message: message + ' at ' + timestamp,
		};

		console.log('### - Publishing message: ', message, '.');
		// result will go to function callback
		sns.publish(params, callback);
};
