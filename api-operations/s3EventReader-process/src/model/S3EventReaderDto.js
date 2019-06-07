'user strict';
let _key,
    _size,
    _bucketName,
    _awsRegion;

class S3EventReaderDto {

    constructor(key, size, bucketName, awsRegion) {
        _key = key
        _size = size;
        _bucketName = bucketName;
        _awsRegion = awsRegion;
    }

    get key() {
        return _key;
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
            'key': this.key,
            'size': this.size,
            'bucketName': this.bucketName,
            'awsRegion': this.awsRegion
        }
    }

    toString() {
        return JSON.stringify(this.toJson());
    }
}

module.exports = S3EventReaderDto;