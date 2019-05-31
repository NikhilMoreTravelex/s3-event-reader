'use strict';
let _domain, _interfaceName, _jobName, _fileName, _size;

class S3EventReaderBo {

    constructor(domain, interfaceName, jobName, fileName, size) {
        _domain = domain;
        _interfaceName = interfaceName;
        _jobName = jobName;
        _fileName = fileName;
        _size = size;
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

    toJson() {
        return {
            'domain': this.domain,
            'interfaceName': this.interfaceName,
            'jobName': this.jobName,
            'fileName': this.fileName,
            'size': this.size
        }
    }

    toString() {
        return JSON.stringify(this.toJson());
    }
}

module.exports = S3EventReaderBo;