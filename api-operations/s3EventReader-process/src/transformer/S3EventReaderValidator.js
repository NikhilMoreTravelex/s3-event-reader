'use strict';

let GenericException = require('generic-exception').GenericException;
const ExceptionCategory = require('../model/ExceptionCategory');
const ExceptionType = require('../model/ExceptionType');

class S3EventReaderValidator {

    async validateDto(s3EventReaderDto) {
        if (!(s3EventReaderDto.key && s3EventReaderDto.key.trim())) {
            throw this.generateValidationException(ExceptionType.MISSING_KEY);
        }
        if (!(s3EventReaderDto.size)) {
            throw this.generateValidationException(ExceptionType.MISSING_SIZE);
        }
        if (!(s3EventReaderDto.bucketName && s3EventReaderDto.bucketName.trim())) {
            throw this.generateValidationException(ExceptionType.MISSING_BUCKET_NAME);
        }
        if (!(s3EventReaderDto.awsRegion && s3EventReaderDto.awsRegion.trim())) {
            throw this.generateValidationException(ExceptionType.MISSING_AWS_REGION);
        }
        return s3EventReaderDto;
    }

    async validateBo(s3EventReaderBo) {
        if (!(s3EventReaderBo.domain && s3EventReaderBo.domain.trim())) {
            throw this.generateValidationException(ExceptionType.MISSING_DOMAIN);
        }
        if (!(s3EventReaderBo.interfaceName && s3EventReaderBo.interfaceName.trim())) {
            throw this.generateValidationException(ExceptionType.MISSING_INTERFACE_NAME);
        }
        if (!(s3EventReaderBo.jobName && s3EventReaderBo.jobName.trim())) {
            throw this.generateValidationException(ExceptionType.MISSING_JOB_NAME);
        }
        if (!(s3EventReaderBo.fileName && s3EventReaderBo.fileName.trim())) {
            throw this.generateValidationException(ExceptionType.MISSING_FILE_NAME);
        }
        if (!(s3EventReaderBo.size)) {
            throw this.generateValidationException(ExceptionType.MISSING_SIZE);
        }
        if (!(s3EventReaderBo.bucketName && s3EventReaderBo.bucketName.trim())) {
            throw this.generateValidationException(ExceptionType.MISSING_BUCKET_NAME);
        }
        if (!(s3EventReaderBo.awsRegion && s3EventReaderBo.awsRegion.trim())) {
            throw this.generateValidationException(ExceptionType.MISSING_AWS_REGION);
        }
        return s3EventReaderBo;
    }

    generateValidationException(exceptionType, inspectionFields) {
        return new GenericException.Builder(exceptionType)
            .withMessage(`Validation error : ${exceptionType}`)
            .withExceptionCategory(ExceptionCategory.VALIDATION_ERROR)
            .withInspectionFields(inspectionFields)
            .build();
    }
}

module.exports = new S3EventReaderValidator();