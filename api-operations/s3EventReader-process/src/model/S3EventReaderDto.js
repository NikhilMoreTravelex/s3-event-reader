'user strict';
let _key,
    _size;

class S3EventReaderDto {

    constructor(key, size) {
        _key = key
        _size = size;
    }

    get key() {
        return _key;
    }

    get size() {
        return _size;
    }

    toJson() {
        return {
            'key': this.key,
            'size': this.size
        }
    }

    toString() {
        return JSON.stringify(this.toJson());
    }
}

module.exports = S3EventReaderDto;