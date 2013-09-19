###
# Plugin for the Americano web framework that take care of your Model
# by providing helpers to build them (it wraps jugglingdb!) and asking you
# for writing your requests in a single and clean file.
#
# This plugin has only sense for Cozy applications.
###

async = require 'async'


# Require all the models for which a request is written
_loadModels = (root, requests) ->
    models = []
    for docType, docRequests of requests
        models[docType] = require "#{root}/server/models/#{docType}"
    models


# Generates a function that will create the given request (required by async)
_getRequestCreator = (root, models, docType, requestName, request) ->
    (cb) ->
        console.info "[INFO] #{docType} - #{requestName} request creation..."
        models[docType].defineRequest requestName, request, (err) ->
            if err then console.log "[ERROR]... fail"
            else console.info "[INFO] ... ok"
            cb err

# Generates all the creators required to save the given requests
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
        requests = require "#{root}/server/models/requests"
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
