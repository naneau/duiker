# Single site
Site = require 'site'

Duiker = require 'duiker'

Express = require 'express'

Parser = require 'parser'

util = require 'util'

{Promise, PromiseChain} = require 'nyala'

# (Re-)parse files in a dir, use domParsers
parseDirectory = (directory, domParsers = []) -> Parser.parseDir directory, domParsers

# Url matches root of site?
rootMatches = (root, url) -> (url.substr 0, root.length) is root

# Remove site root from url
removeRoot = (root, url) -> url.substr root.length

# Parse a set of sites
parseSites = (sites) ->
    chain = new PromiseChain
    chain.add parseSite site for site in sites
    do chain.execute
    
# Parse a site
parseSite = (site) -> new Promise ->
    start = do (new Date).getTime
    
    util.log "Parsing site '#{site.root}'"
    
    # Parse promise
    promise = parseDirectory site.directory, site.domParsers
    
    promise.kept (routeToHtml) => 
        util.log "Parsed #{(Object.keys routeToHtml).length} pages in site '#{site.root}' in #{do (new Date).getTime - start}ms"
        site.pages = routeToHtml
        @keep site
    
    promise.broken (error) => 
        util.log "Can not parse site '#{site.root}'"
        console.trace error
        @break error
        
    do promise.execute

# Serve a response to a request using the content in the sites array
# Returns "false" if it can't
serveFromSites = (sites, request, response) ->
    served = false
    for site in sites when not served and rootMatches site.root, request.url
        
        # Url without root and trailing/starting slashes removed
        url = Duiker.trimUrl removeRoot site.root, request.url
        
        if site.pages?[url]?
            response.render 'layout', context:
                site: site
                contents: site.pages[url]
            
            served = true
    
    served

# Duiker Server
class Server
    
    # Constructor
    constructor: (@viewsDir, @staticDir) ->
        @sites = []
        
        @domParsers = []
        
    # Add a site to this server
    addSite: (site, args...) ->
        # Guard site
        site = new Site site, args... if not (site instanceof Site)
        
        # Set dom parsers
        site.domParsers = @domParsers
        
        # Push to array
        @sites.push site
        
        # Wait for sites to change, then re-parse
        site.on 'change', () => 
            promise = parseSite site
            do promise.execute
        
        # Chainable
        this
    
    # Add a dom parser
    addDomParser: (domParser) ->
        @domParsers.push domParser
        
        site.domParsers = @domParsers for site in @sites
    
    # Serve on a port
    serve: (port) ->
        # Parse all sites so we have something to serve
        parseSites @sites
        
        # Express server
        server = do Express.createServer

        # Static stuff
        server.use Express.static @staticDir

        # Set up CoffeeKup view/layout
        server.register '.coffee', require 'coffeekup'
        server.set 'view engine', 'coffee'
        server.set 'views', @viewsDir
        
        # Set up the routing
        # We use just *one* catch-everything .get()
        server.get '*', (request, response) =>
            if not serveFromSites @sites, request, response
                response.end 'ERROR'
    
        # Actual listen
        server.listen port
        
        this
        
module.exports = Server