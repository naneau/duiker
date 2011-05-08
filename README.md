# Duiker

Duiker is a simple [markdown](http://daringfireball.net/projects/markdown/) based publication system. It is currently in its infancy. Duiker is based on Node.js. The idea is to pre-parse all markdown and keep it in memory, making it perform really well, at the tradeoff of a larger memory footprint.

## Usage

First, create a `config.coffee` file like:

    module.exports = (duiker) ->
    
        # Add a site as the root of your site
        duiker.addSite '', "/where/your/markdown/files/live"
    
        # Add another one as a "subdirectory" of the root
        duiker.addSite '/foo/bar', "/where/your/foobar/files/live"
    
        # serve on port 3000
        duiker.serve 3000

Execute `spawn.coffee`

## Parsers

Duiker supports additional parsers through DOM. It parses all markdown to html, then runs that through [jsdom](https://github.com/tmpvar/jsdom).