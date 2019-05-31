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