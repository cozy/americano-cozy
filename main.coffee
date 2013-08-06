async = require 'async'


_loadModels = (root, requests) ->
    models = []
    for docType, docRequests of requests
        models[docType] = require "#{root}/models/#{docType}"
    models


_getRequestCreator = (root, models, docType, requestName, request) ->
    (cb) ->
        console.info "[INFO] #{docType} - #{requestName} request creation..."
        models[docType].defineRequest requestName, request, (err) ->
            if err then console.log "[ERROR]... fail"
            else console.info "[INFO] ... ok"
            cb err


_loadRequestCreators = (root, models, requests) ->
    requestsToSave = []
    for docType, docRequests of requests
        for requestName, docRequest of docRequests
            requestsToSave.push(
                _getRequestCreator(root, models, docType, \
                                   requestName, docRequest))
    requestsToSave


# Plugin configuration: run through models/requests.(coffee|js) and save
# them all in the Cozy Data System.
module.exports.configure = (root, app, callback) ->
    try
        requests = require "#{root}/models/requests"
    catch err
        console.log "[ERROR] failed to load requests file"
        callback err

    models = _loadModels root, requests
    requestsToSave = _loadRequestCreators root, models, requests

    async.series requestsToSave, (err) ->
        if err and err.code isnt 'EEXIST'
            console.log "[ERROR] A request creation failed, abandon."
            console.log err
            callback err if callback?
        else
            console.info "[INFO] All requests have been created"
            callback() if callback?


# Additional stuff / helpers
Schema = require('jugglingdb').Schema
settings = url: 'http://localhost:9101/'
module.exports.db = db = new Schema 'cozy-adapter', settings

module.exports.getModel = (name, fields) ->
    fields.id = String
    model = db.define name, fields
    model

module.exports.defaultRequests =
    all: (doc) -> emit doc.id, doc
