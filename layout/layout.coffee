doctype 5
html ->
    head ->
        meta charset: 'utf-8'
        title "#{@title or 'Untitled'} | Duiker"
        
        coffeescript ->
            # Export Google WebFont Config
            window.WebFontConfig = 
                # Load some fonts from google
                google:
                    families: ['Inconsolata', 'Pacifico', 'Droid Sans', 'Droid Serif']

                # ... you can do something here if you'd like
                active: () -> 

            # Create script tag matching protocol
            s = document.createElement 'script'
            s.src = "#{if document.location.protocol is 'https:' then 'https' else 'http'}://ajax.googleapis.com/ajax/libs/webfont/1/webfont.js"
            s.type = 'text/javascript'
            s.async = 'true'

            # Insert it before the first script tag
            s0 = (document.getElementsByTagName 'script')[0]
            s0.parentNode.insertBefore s, s0
            
        link href: '/css/style.css', rel: 'stylesheet', type: 'text/css'                                
        
        script type: 'text/javascript', -> '''
              var _gaq = _gaq || [];
              _gaq.push(['_setAccount', 'UA-22705109-1']);
              _gaq.push(['_trackPageview']);
        
              (function() {
                var ga = document.createElement('script'); ga.type = 'text/javascript'; ga.async = true;
                ga.src = ('https:' == document.location.protocol ? 'https://ssl' : 'http://www') + '.google-analytics.com/ga.js';
                var s = document.getElementsByTagName('script')[0]; s.parentNode.insertBefore(ga, s);
              })();
        '''
        
    body -> 
        section id: 'page', ->
            hgroup ->
                h1 -> @site.config.title or 'Your Site'
                h2 -> @site.config.subTitle or 'Some Introduction'
                
            section id: 'navigation', ->
                div class: 'nav-wrapper', ->
                    ul ->
                        for navItem in @site.config.navItems or []
                            li ->
                                a href: "#{@site.root}/#{navItem.url}", -> navItem.label 
                        
                    div class: 'clear'
                div class: 'clear'
                    
            section id: 'content', ->
                @contents