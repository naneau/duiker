# HTML -> DOM parser

{Promise} = require 'nyala'

# JS DOM
jsdom = require 'jsdom'

# Single parse runs html through jsdom
# Will pre/append html/body tags
module.exports.parse = (html) -> new Promise ->

    # Might need to find a way to inject the scripts?
    scripts = [
        "#{__dirname}/../../node_modules/jquery/dist/node-jquery.js"
    ]
    
    jsdom.env
        html: "<html><body>#{html}</body></html>"
        
        scripts: scripts
        done: (err, window) =>
            if err
                @break err
            else
                @keep window
    