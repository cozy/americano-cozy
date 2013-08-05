async = require 'async'

_loadModels = (root, requests) ->
    models = []
    for docType, docRequests of requests
        models[docType] = require "#{root}/models/#{docType}"
    models


_getRequestCreator = (root, models, docType, requestName, request) ->
    (cb) ->
        console.log "#{docType} - #{requestName} request creation..."
        models[docType].defineRequest requestName, request, (err) ->
            if err then console.log "... fail"
            else console.log "... ok"
            cb err

_loadRequestCreators = (root, models, requests) ->
    requestsToSave = []
    for docType, docRequests of requests
        for requestName, docRequest of docRequests
            requestsToSave.push(
                _getRequestCreator(root, models, docType, \
                                   requestName, docRequest))
    requestsToSave

module.exports = (root, app, callback) ->
    requests = require "#{root}/models/requests"
    models = _loadModels root, requests
    requestsToSave = _loadRequestCreators root, models, requests

    async.series requestsToSave, (err) ->
        if err and err.code isnt 'EEXIST'
            console.log "A request creation failed, abandon."
            console.log err
            callback err if callback?
        else
            console.log "All requests have been created"
            callback() if callback?
