const apiProcessor = require('s3EventReader-process').ApiProcessor;
//const winston = require('winston-wrapper');
//const logger = winston.getLogger('process-s3EventReader-handler')

module.exports.handle = function (event, context, callback) {
    //winston.serverlessFunction(event, context, () => {
    
    apiProcessor.process(event).then((body) => {
        //logger.debug("Exiting with response ", body);
        callback(null, {
            statusCode: 200,
            body: body.toString()
        })
    }).catch(error => {
        console.log("TCL: error", error)
        //logger.error("Exception caught ", error)
        callback(null, {
            statusCode: error.httpStatusCode,
            body: JSON.stringify({
                errorCode: error.code,
                errorMessage: error.description
            })
        })
    })
};