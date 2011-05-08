
# Export a hash of utils and classes
    
# Trim slashes of beginning and end of urls
module.exports.trimUrl = (url) -> (url.replace /^[\/]+/, '').replace /[\/]+$/, ''
    
# Server
module.exports.Server = require 'server'
    
# Parser
module.exports.Parser = require 'parser'
        