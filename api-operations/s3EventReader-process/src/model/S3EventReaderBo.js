'use strict';
let _domain, _interfaceName, _jobName, _fileName, _size, _bucketName, _awsRegion;

class S3EventReaderBo {

    constructor(domain, interfaceName, jobName, fileName, size, bucketName, awsRegion) {
        _domain = domain;
        _interfaceName = interfaceName;
        _jobName = jobName;
        _fileName = fileName;
        _size = size;
        _bucketName = bucketName;
        _awsRegion = awsRegion;
    }

    get domain() {
        return _domain;
    }

    get interfaceName() {
        return _interfaceName;
    }

    get jobName() {
        return _jobName;
    }

    get fileName() {
        return _fileName;
    }

    get size() {
        return _size;
    }

    get bucketName() {
        return _bucketName;
    }

    get awsRegion() {
        return _awsRegion;
    }

    toJson() {
        return {
            'domain': this.domain,
            'interfaceName': this.interfaceName,
            'jobName': this.jobName,
            'fileName': this.fileName,
            'size': this.size,
            'bucketName': this.bucketName,
            'region': this.awsRegion
        }
    }

    toString() {
        return JSON.stringify(this.toJson());
    }
}

module.exports = S3EventReaderBo;