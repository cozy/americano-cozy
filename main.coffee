###
# Plugin for the Americano web framework that takes care of your Model
# by providing helpers to build them (it wraps jugglingdb!). It requires you
# to write your requests in a single and clean file.
#
# This plugin has only sense for Cozy applications.
###


# Require all the models for which a request is written
_loadModels = (root, requests) ->
    models = []
    for docType, docRequests of requests
        models[docType] = require "#{root}/server/models/#{docType}"
    models


# Create request in CouchDB for the given docType through the Data System API.
_saveRequest = (models, request, callback) ->
    docType = request.docType
    requestName = request.name
    docRequest = request.docRequest
    console.info "[INFO] #{docType} - #{requestName} request creation..."
    models[docType].defineRequest(
        requestName,
        docRequest,
        (err) ->
            if err then console.log "[ERROR]... fail"
            else console.info "[INFO] ... ok"
            callback err
    )


# Save given requests in a recursive way. Each requests are saved one by one.
# If a request creation failed, it stops the process and call the callback with
# an error?
_saveRequests = (models, requestsToSave, callback) ->
    if requestsToSave.length > 0
        request = requestsToSave.pop()
        _saveRequest models, request, (err) ->
            if err
                callback err
            else
                _saveRequests models, requestsToSave, callback
    else
        callback()


# Generates all the creators required to save the given requests.
_loadRequestCreators = (root, models, requests) ->
    requestsToSave = []
    for docType, docRequests of requests
        for requestName, docRequest of docRequests
            requestsToSave.push
                root: root
                models: models
                docType: docType
                name: requestName
                docRequest: docRequest
    requestsToSave


# Plugin configuration: run through models/requests.(coffee|js) and save
# them all in the Cozy Data System.
module.exports.configure = (root, app, callback) ->
    try
        requests = require "#{root}/server/models/requests"
    catch err
        console.log "[ERROR] failed to load requests file"
        callback err

    models = _loadModels root, requests
    requestsToSave = _loadRequestCreators root, models, requests
    _saveRequests models, requestsToSave, (err) ->
        if err and err.code isnt 'EEXIST'
            console.log "[ERROR] A request creation failed, abandon."
            console.log err
            callback err if callback?
        else
            console.info "[INFO] All requests have been created"
            callback() if callback?


# Wraps JugglingDB stuff and configuration.
Schema = require('jugglingdb').Schema
settings = url: 'http://localhost:9101/'
module.exports.db = db = new Schema 'cozy-adapter', settings

# Helpers to make it easier to build a model.
module.exports.getModel = (name, fields) ->
    fields.id = String
    model = db.define name, fields
    model

# Bunch of commonly used requests (more to come...)
module.exports.defaultRequests =
    all: (doc) -> emit doc._id, doc
