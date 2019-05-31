'use strict';

const GenericException = require('generic-exception').GenericException;
const ExceptionType = require('../model/ExceptionType');
const S3EventReaderDto = require('../model/S3EventReaderDto');
const service = require('../service');
const transformer = require('../transformer');


class ProcessApiProcessor {
    async process(event) {
        //console.log("TCL: ProcessApiProcessor -> process -> event", event)
        try {
            //if (event && event.body && event.body.event && event.body.event.Records) {
            if (event  && event.Records) {
                let records = event.Records;
                let s3EventReaderDto;// = new S3EventReaderDto(record.key, record.size);
                // if (records.length == 1) {
                //     s3EventReaderDto = new S3EventReaderDto(records[0].s3.object.key, record.s3.object.size);
                // }
                records.forEach(record => {
                    // create dto(data transfer object) for request object
                    s3EventReaderDto = new S3EventReaderDto(record.s3.object.key, record.s3.object.size);
                });
                // transform dto to bo(business object)
                let s3EventReaderBo = await transformer.S3EventReaderTransformer.transformToBo(s3EventReaderDto);
                // invoke service and supply the bo and get bo from service 
                return await service.s3EventReaderService.invokeLambda(s3EventReaderBo);
            // transform into dto and return response using dto
            //return await transformer.S3EventReaderTransformer.transformToDto(s3EventReaderBo);
            } else {
                console.log('Event not found')
            }
        } catch (exception) {
            //console.log(`Error occurred:  ${exception.message}`);
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