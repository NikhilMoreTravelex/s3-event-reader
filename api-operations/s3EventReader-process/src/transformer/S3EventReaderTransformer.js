'use strict';

let S3EventReaderBo = require('../model/S3EventReaderBo');
let s3EventReaderValidator = require('./S3EventReaderValidator');

class S3EventReaderTransformer {

    static async transformToBo(s3EventReaderDto) {
        //validate the Key and Size
        s3EventReaderDto = await s3EventReaderValidator.validateDto(s3EventReaderDto);
        var stringArray = s3EventReaderDto.key.split('/');

        
        let s3EventReaderBo = new S3EventReaderBo(stringArray[2], stringArray[3], stringArray[4], stringArray[5], s3EventReaderDto.size);
        s3EventReaderBo = await s3EventReaderValidator.validateBo(s3EventReaderBo);
        return s3EventReaderBo;
    }

}

module.exports = S3EventReaderTransformer;