# Code Highlighting parser

{PromiseBurst, Promise} = require 'nyala'

{spawn} = require 'child_process'

# Map of entities
entities = 
    '&amp;':    '&'
    '&quot;':   '"'
    '&lt;':     '<'
    '&gt;':     '>'

# Decode entities
decodeEntities = (string) -> string.replace /(&quot;|&lt;|&gt;|&amp;)/g, (str, item) ->entities[item]

# Pygments adds some markup that we do not need
removePygmentBlocks = (output) -> (output.replace '<div class="highlight"><pre>', '').replace '</pre></div>', ''

# Highlight by using pygments (which is currently the best highlighter out there)
highlight = (text, language) -> new Promise ->
    # Spawn a child
    pygments = spawn 'pygmentize', ['-l', language, '-f', 'html', '-O', 'encoding=utf-8']
        
    # Listen to output and append "output"
    output = ''
    pygments.stdout.setEncoding 'utf8'
    pygments.stdout.addListener 'data', (result) -> output += result if result
        
    # Once we're done we can keep our promise
    pygments.addListener 'exit', => @keep removePygmentBlocks output

    # Or we might fail
    pygments.stderr.setEncoding 'utf8'
    pygments.stderr.addListener 'data',  (error)  => @break error if error?
    
    # Write the text to the process
    pygments.stdin.setEncoding 'utf8'
    pygments.stdin.write text
    do pygments.stdin.end 

# Figure out the language a markdown block of code was written in
languageInText = (text) -> 
    split = text.split '\n'
    
    # Single line fragments do not have a "code" type
    return 'text' if split.length is 1
    
    firstLine = split[0]
    
    # No type specified
    return 'text' if not firstLine.match /^:::/
    
    # Otherwise, we just find the type
    do (firstLine.replace /:::([a-z]*)/i, '$1').toLowerCase

# Get the "code" only (strip first line containing language)
codeInText = (text) -> decodeEntities text.replace /:::([a-z])+/gi, ''

# Parse all code blocks using pygments
module.exports.parse = (route, window) -> new Promise ->
    codeBlocks = window.$ 'code'
    
    burst = new PromiseBurst

    for codeBlock in codeBlocks
        do (codeBlock) ->
            codeBlock = (window.$ codeBlock)
            text = do codeBlock.text
            
            return if text.length = 0
            # console.log text
        
            # Get language/code
            language = languageInText text
            
            # Add the language as a class name to our code block
            codeBlock.addClass "language-#{language}"
            
            # We don't have to highlight text
            return if language is 'text'
            
            # Parse through pygments, when kept replace the dom node
            highlightPromise = highlight (codeInText text), language
            highlightPromise.kept (highlighted) -> 
            
                # Append text
                codeBlock.html highlighted.replace /^\s*(\S*(\s+\S+)*)\s*$/, "$1"
                
                # Set up line numbering <div />
                lineNumberDiv = window.$ '<div />'
                lineNumberDiv.addClass 'line-numbers'
                codeBlock.append lineNumberDiv
                
                # Add a line number for every line in the code
                lineNumbers = [1..(highlighted.split "\n").length - 2]
                for lineNumber in lineNumbers
                    lineNumberDiv.append "<span>#{lineNumber}</span>"
                    
            burst.add highlightPromise
            
    # The promises are already set up so that they replace the contents, we just have to execute here
    burst.kept () => @keep route, window
    burst.broken (err) => @break err
    
    do burst.execute