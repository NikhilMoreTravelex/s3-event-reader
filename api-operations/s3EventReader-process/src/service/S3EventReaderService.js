'use strict';

const GenericException = require('generic-exception').GenericException;
const ExceptionType = require('../model/ExceptionType');
const ExceptionCategory = require('../model/ExceptionCategory');
const s3EnventReaderDao = require('../dal/S3EventReaderDao');

class S3EnventReaderService {
    async invokeLambda(s3EnventReaderBo) {
        try {
            var payLoad = { "jobDetails": s3EnventReaderBo.toJson() }
            var dataToBeSent = {
                FunctionName: "arn:aws:lambda:eu-west-1:820643439592:function:data-processor-dev",
                InvocationType: "Event",
                LogType: "Tail",
                Payload: JSON.stringify(payLoad)
            };
            console.log(payLoad)
            //arn:aws:lambda:eu-west-1:820643439592:function:data-processor-dev
            //arn:aws:lambda:eu-west-1:820643439592:function:InvokedByS3EventReader
            return await s3EnventReaderDao.invokeLambda(dataToBeSent, s3EnventReaderBo.awsRegion);            
        } catch (ex) {
            throw new GenericException
                .Builder(ExceptionType.ERROR_INVOKING_LAMBDA)
                .withExceptionCategory(ExceptionCategory.AWS_CONNECTION_ERROR)
                .withWrappedException(ex)
                .build();
        }
    }
}

module.exports = new S3EnventReaderService();