'use strict';

const GenericException = require('generic-exception').GenericException;
const ExceptionType = require('../model/ExceptionType');
const ExceptionCategory = require('../model/ExceptionCategory');
const s3EnventReaderDao = require('../dal/S3EventReaderDao');

class S3EnventReaderService {
    async invokeLambda(s3EnventReaderBo) {
        try {
            var params = {
                FunctionName: "arn:aws:lambda:eu-west-1:820643439592:function:InvokedByS3EventReader",
                InvocationType: "Event",
                LogType: "Tail",
                Payload: s3EnventReaderBo.toString()
            };            

            return await s3EnventReaderDao.invokeLambda(params);            
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