# Site
#
# A site represents a single "site". Each site has a root url and its own directory of markdown files. Sites can have 
# their own configuration.

Saiga = require 'saiga'

{EventEmitter} = require 'events'

# Site
class Site extends EventEmitter
    
    # Constructor
    constructor: (@root, @directory, @config = {}) ->
        # Dom parsers
        @domParsers = []
        
        # Set up file watcher for changes
        Saiga.watch.directory @directory, () => @emit 'change'
        
# Export
module.exports = Site