'use strict';

const AWS = require('aws-sdk');

class S3EventReaderDao {
    
    async invokeLambda(dataToBeSent, awsRegion) {
        var lambda = new AWS.Lambda({ apiVersion: '2015-03-31', region: awsRegion });
        return new Promise((resolve, reject) => {
            lambda.invoke(dataToBeSent, function (err, data) {
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