'use strict';

const GenericException = require('generic-exception').GenericException;
const ExceptionType = require('../model/ExceptionType');
const S3EventReaderDto = require('../model/S3EventReaderDto');
const service = require('../service');
const transformer = require('../transformer');


class ProcessApiProcessor {
    async process(event) {        
        try {
            let record;
            if (event && event.body)
            {
                //this if will be hit when testing via POSTMAN or after the logger is implemented
                let s3Event = JSON.parse(event.body);
                record = s3Event.Records[0];
            }
            if (event && event.Records) { 
                record = event.Records[0];
            }
            //check if the event had data, then check if it contains "Records[0] array"
            if (record) {
                let s3EventReaderDto = new S3EventReaderDto(record.s3.object.key, record.s3.object.size, record.s3.bucket.name, record.awsRegion);
                let s3EventReaderBo = await transformer.S3EventReaderTransformer.transformToBo(s3EventReaderDto);
                // invoke service and supply the bo and get bo from service 
                return await service.s3EventReaderService.invokeLambda(s3EventReaderBo);
            } else {
                console.log('Event not found')
            }
        } catch (exception) {
            console.log(`Error occurred:  ${exception.message}`);
            if (!(exception instanceof GenericException)) {
                throw new GenericException.Builder(ExceptionType.UNKNOWN_ERROR)
                    .withWrappedException(exception)
                    .build();
            } else {
                throw exception;
            }
        }
    }
}
module.exports = new ProcessApiProcessor();