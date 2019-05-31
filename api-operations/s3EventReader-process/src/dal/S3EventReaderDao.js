'use strict';

const AWS = require('aws-sdk');
var lambda = new AWS.Lambda({ apiVersion: '2015-03-31', region: "eu-west-1" });

class S3EventReaderDao {

    async invokeLambda(params) {
        return new Promise((resolve, reject) => {
            lambda.invoke(params, function (err, data) {
                if (err) {
                    reject(err); // an error occurred
                }
                else {
                    resolve('Lambda invoked.'); // successful response
                } 
            });
        });
    }
}

module.exports = new S3EventReaderDao();