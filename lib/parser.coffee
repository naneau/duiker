# Saiga tools
Saiga = require 'saiga'

# Duiker
Duiker = require 'duiker'

# Nyala promises
{Promise, PromiseChain, PromiseBurst} = require 'nyala'

# Parse markdown using Markdown-js' markdown
Markdown = (require 'markdown').markdown

# Our own DOM parser
DOMParser = require 'parser/dom'

# Filename -> route parser
fileNameToRoute = (fileName) -> Duiker.trimUrl stripIndex stripExtension fileName
stripIndex = (fileName) -> fileName.replace /^.*index$/, fileName.substr 0, fileName.length - 5 
stripExtension = (fileName) -> fileName.substr 0, fileName.lastIndexOf '.'

# Strip dirname off a filename
removeDir = (dirName, fileName) -> fileName.substr dirName.length

# Parse Markdown into DOM
parseMarkdown = (route, mdString) -> new Promise ->
    
    # Parse the markdown
    html = Markdown.toHTML mdString
    
    # Parse into dom
    domPromise = DOMParser.parse html
    
    # map to our own promise
    domPromise.kept (dom) => @keep route, dom
    domPromise.broken (err) => @break err
    
    # Execute
    do domPromise.execute

# Get the contents of a set of files as a hash of route -> markdown contents
# Stripdir gets stripped of the filenames
readFiles = (stripDir) -> (files) -> new Promise ->

    # Read every file
    readBurst = new PromiseBurst
    (do (file) -> readBurst.add Saiga.file.read file) for file in files
    
    # All files are read, turn into nice route -> markdown hash
    readBurst.kept () =>
        read = {}                
        readBurst.eachResult (contents, fileName) -> 
            read[fileNameToRoute removeDir stripDir, fileName] = contents
        @keep read

    # Some kind of illiteracy
    readBurst.broken (error) => @break error
    do readBurst.execute

# Parse markdown to DOM out of a hash of route -> markdown
parseMarkdownRoutes = (routeToMarkdown) -> new Promise ->

    # For every file/contents, parse into DOM
    parseBurst = new PromiseBurst
    for route, markdown of routeToMarkdown
        do (route, markdown) -> 
            parseBurst.add parseMarkdown route, markdown
    
    # We get DOM!
    parseBurst.kept () =>
        routes = {}
        parseBurst.eachResult (route, dom) ->
            routes[route] = dom
        @keep routes
        
    # or maybe not
    parseBurst.broken (err) => @break err
    
    do parseBurst.execute

# Parse a hash of route -> dom with a parser
parseDomWithParser = (parser) -> (routeToDom) -> new Promise ->

    # Burst all route/dom pairs
    parseBurst = new PromiseBurst
    parseBurst.add parser route, dom for route, dom of routeToDom
    
    # Get the results back into a nice hash
    parseBurst.kept () =>
        parsed = {}
        parseBurst.eachResult (route, dom) -> parsed[route] = dom
        @keep parsed
    
    # Or not :(
    parseBurst.broken (err) => @break err
    
    # Go go go!
    do parseBurst.execute

# Parse a hash of route -> dom with a set of parser
parseDomWithParsers = (parsers) -> (routeToDom) -> new Promise ->

    # Create a chain for every parser (in order)
    parserChain = new PromiseChain
    parserChain.addDeferred parseDomWithParser parser for parser in parsers
    
    # Depend on the chain
    @dependOn parserChain
    
    # And execute it
    parserChain.execute routeToDom        

# Parse a directory with markdown files
module.exports.parseDir = (docsDir, additionalDOMParsers = []) -> new Promise ->
    
    # Start the build chain
    buildChain = new PromiseChain
    
    # Find all .md files
    buildChain.add Saiga.find.byName docsDir, '\*.md'
    
    # Then read each one and parse the markdown
    buildChain.addDeferred readFiles docsDir
    
    # Parse the contents of the files into DOM
    buildChain.addDeferred parseMarkdownRoutes
        
    # Now we just have to run it through the set of additional parsers...
    buildChain.addDeferred parseDomWithParsers additionalDOMParsers
    
    # Set up the chain as the thing this promise depends on, then execute it
    # Once we're done, we do have to get the "html" out of the dom
    buildChain.kept (routeToDom) =>
        for route, dom of routeToDom
            routeToDom[route] = do (dom.$ 'body').html
        @keep routeToDom
        
    buildChain.broken (err) => @break err
    
    do buildChain.execute