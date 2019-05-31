var ApiProcessor = require('../src/api/ProcessApiProcessor');
var assert = require('assert');
var chai = require('chai');
chai.use(require('chai-string')); 
var expect = chai.expect;

describe('S3 Event Reader - Unit test', () => {
    it('should return message "Lambda invoked." when testing the service with a valid json input', () => {
        let jsonData = {
            "Records": [
                {
                    "s3": {
                        "object": {
                            "key": "interfaces/input/Finance/interface-name/interface-unique-job-name/testing_job1.csv",
                            "size": 32
                        }
                    }
                }
            ]
        };
        ApiProcessor.process(jsonData).then((body) => {
            assert.equal(body, 'Lambda invoked.');
        }).catch(error => {
            console.log("TCL: error", error)
        })
    });

    it('should return body as undefined when testing the service with a invalid json input i.e. blank json', () => {
        let jsonData = {};
        ApiProcessor.process(jsonData).then((body) => {
            assert.equal(body, undefined);
        }).catch(error => {
            console.log("TCL: error", error)
        })
    });

    it('should return body as undefined when testing the service with a invalid json input i.e. invalid records', () => {
        let jsonData = {
            "InvalidRecords": [
                {
                    "s3": {
                        "object": {
                            "key": "interfaces/input/Finance/interface-name/interface-unique-job-name/testing_job1.csv",
                            "size": 32
                        }
                    }
                }
            ]
        };
        ApiProcessor.process(jsonData).then((body) => {
            expect(body).to.be.equal(undefined);
        }).catch(error => {
            console.log("TCL: error", error)
        })
    });

    it('should return error exception type "missingSize" when param size not passed', (done) => {
        let jsonData = {
            "Records": [
                {
                    "s3": {
                        "object": {
                            "key": "interfaces/input/Finance/interface-name/interface-unique-job-name/testing_job1.csv"
                        }
                    }
                }
            ]
        };
        ApiProcessor.process(jsonData).then((body) => {
            expect(body).to.be.equal('!');
        }).catch(error => {
            expect(error.exceptionType).to.containIgnoreSpaces('missingSize')
            done();
        })
    });

    it('should return error exception type "missingKey" when param key not passed', (done) => {
        let jsonData = {
            "Records": [
                {
                    "s3": {
                        "object": {
                            "size": 32
                        }
                    }
                }
            ]
        };
        ApiProcessor.process(jsonData).then((body) => {
            expect(body).to.be.equal('!');
        }).catch(error => {
            expect(error.exceptionType).to.containIgnoreSpaces('missingKey')
            done();
        })
    });

    it('should return error exception type "missingKey" when param key is blank', (done) => {
        let jsonData = {
            "Records": [
                {
                    "s3": {
                        "object": {
                            "key": "",
                            "size": 32
                        }
                    }
                }
            ]
        };
        ApiProcessor.process(jsonData).then((body) => {
            expect(body).to.be.equal('!');
            done();
        }).catch(error => {
            expect(error.exceptionType).to.containIgnoreSpaces('missingKey')
            done();
        })
    });

    it('should return error exception type "missingfileName" when param key is invalid i.e. filename not passed', (done) => {
        let jsonData = {
            "Records": [
                {
                    "s3": {
                        "object": {
                            "key": "interfaces/input/Finance/interface-name/interface-unique-job-name",
                            "size": 32
                        }
                    }
                }
            ]
        };
        ApiProcessor.process(jsonData).then((body) => {
            expect(body).to.be.equal('!');
            done();
        }).catch(error => {
            expect(error.exceptionType).to.containIgnoreSpaces('missingfileName')
            done();
        })
    });

    it('should return error exception type "missingjobName" when param key is invalid i.e. jobname & filename not passed', (done) => {
        let jsonData = {
            "Records": [
                {
                    "s3": {
                        "object": {
                            "key": "interfaces/input/Finance/interface-name",
                            "size": 32
                        }
                    }
                }
            ]
        };
        ApiProcessor.process(jsonData).then((body) => {
            expect(body).to.be.equal('!');
            done();
        }).catch(error => {
            expect(error.exceptionType).to.containIgnoreSpaces('missingjobName')
            done();
        })
    });

    it('should return error exception type "missinginterfaceName" when param key is invalid i.e. interface-name & jobname & filename not passed', (done) => {
        let jsonData = {
            "Records": [
                {
                    "s3": {
                        "object": {
                            "key": "interfaces/input/Finance",
                            "size": 32
                        }
                    }
                }
            ]
        };
        ApiProcessor.process(jsonData).then((body) => {
            expect(body).to.be.equal('!');
            done();
        }).catch(error => {
            expect(error.exceptionType).to.containIgnoreSpaces('missinginterfaceName')
            done();
        })
    });

    it('should return error exception type "missingdomain" when param key is invalid i.e. domain & interface-name & jobname & filename not passed', (done) => {
        let jsonData = {
            "Records": [
                {
                    "s3": {
                        "object": {
                            "key": "interfaces/input",
                            "size": 32
                        }
                    }
                }
            ]
        };
        ApiProcessor.process(jsonData).then((body) => {
            expect(body).to.be.equal('!');
            done();
        }).catch(error => {
            expect(error.exceptionType).to.containIgnoreSpaces('missingdomain')
            done();
        })
    });

});