fs = require 'fs'
path = require 'path'

id = ->
  Math.floor(Math.random()*1000000000).toString()

asSlug = (name) ->
  name.replace(/\s/g, '-').replace(/[^A-Za-z0-9-]/g, '').toLowerCase()

escape = (text)->
  text
    .replace /&/g, '&amp;'
    .replace /</g, '&lt;'
    .replace />/g, '&gt;'

expandLinks = (origin, string) ->
  stashed = []

  stash = (text) ->
    here = stashed.length
    stashed.push text
    "〖#{here}〗"

  unstash = (match, digits) ->
    stashed[+digits]

  internal = (match, name) ->
    slug = asSlug name
    stash """<a href="#{origin}/#{slug}.html">#{escape name}</a>"""

  external = (match, href, protocol, rest) ->
    stash """<a href="#{href}" #{escape rest} </a>"""

  string = string
    .replace /〖(\d+)〗/g, "〖 $1 〗"
    .replace /\[\[([^\]]+)\]\]/gi, internal
    .replace /\[((http|https|ftp):.*?) (.*?)\]/gi, external
  escape string
    .replace /〖(\d+)〗/g, unstash

ignoreLinks = (string) ->
  internal = (match, name) ->
    name

  external = (match, href, protocol, rest) ->
    rest

  string = string
    .replace /\[\[([^\]]+)\]\]/gi, internal
    .replace /\[((http|https|ftp):.*?) (.*?)\]/gi, external
  escape string

publishing = (sitemap, story, index) ->
  map = {}
  map[s.slug] = s for s in sitemap
  selected = []
  for item in story[(index+1)..]
    if item.text && (m = item.text.match /\[\[(.*?)\]\]/)
      if siteref = map[link = asSlug(m[1])]
        selected.push {item, link, siteref}
  selected

startServer = (params) ->
  app = params.app

  app.get '/plugin/rss/details', (req, res) ->
    report = {}
    report.req = Object.keys(req)
    report.params = Object.keys(params)
    for k,v of params
      report["params.#{k}"] = Object.keys(params[k])
    res.send "<pre>#{JSON.stringify(report, null, '  ')}"

  app.post '/plugin/rss/:slug/micropub', (req, res) ->
    slug = req.params.slug
    # get https://tokens.indieauth.com/token, accept: application/json, Authorication: req.headers['authorization']
    # if res.code == 200
    app.pagehandler.get slug, (e, page, status) ->
      return res.e e if e
      plugin = page.story?.findIndex (item) ->
         item.type == 'rss'
      return res.status(404).json({status: 'error', error: "No wiki-plugin-rss on this page.", slug}) unless plugin >= 0
      # key = req.headers['x-api-key']
      # auth = tokens?[slug]?[key] or tokens?['*']?[key]
      # unless auth
      #   return res.status(401).json({status: 'error', error: "Missing or invalid x-api-key in header"})
      item = page.story[plugin]
      item.resource = req.body
      item.written = Date.now()
      page.story.push
        type: 'html'
        id: id()
        text: req.body.content
      app.pagehandler.put slug, page, (err) ->
        return res.e err if err
        res.status(201).set('Location', '/'+slug+'.html')
        res.send("Hello Aaron\n"+JSON.stringify(req.body))
        res.json
          status: 'ok'
          written: item.written


  app.get '/plugin/rss/:slug/micropub', (req, res) ->
    slug = req.params.slug
    res.set('Link', '<https://indieauth.com/auth>; rel="authorization_endpoint", <https://tokens.indieauth.com/token>; rel="token_endpoint", </plugin/rss/'+slug+'/micropub>; rel="micropub"')
    res.status(200).send("""<a href="mailto:ward@c2.com" rel="me">""")

  app.get '/plugin/rss/:slug.xml', (req, res) ->
    slug = req.params.slug
    markup = []

    elem = (tag, params, more) ->
      markup.push "<#{tag} #{attr params}>"; more(); markup.push "</#{tag}>"

    attr = (params) ->
      ("#{k}=\"#{v}\"" for k, v of params).join " "

    set = (tag, value) ->
      markup.push "<#{tag}>#{escape "#{value}"}</#{tag}>"

    app.pagehandler.get slug, (e, page, status) ->
      return res.e e if e

      plugin = page.story?.findIndex (item) ->
        item.type == 'rss'
      return res.status(404).send("Not an RSS feed.") unless plugin >= 0

      sitemapLoc = path.join(params.argv.status, 'sitemap.json')
      fs.readFile sitemapLoc, 'utf8', (e, sitemap) ->
        return res.e e if e

        pubs = publishing JSON.parse(sitemap), page.story, plugin
        origin = params.argv.url
        slug = req.params.slug

        elem 'rss', {version: '2.0'}, ->
          elem 'channel', {}, ->
            set 'title', page.title || slug
            set 'link', "http://#{origin}/#{slug}.html"
            set 'lastBuildDate', new Date(page.journal[page.journal.length-1].date || Date.now())
            set 'description', expandLinks(origin, page.story?[0]?.text || 'unknown description')
            elem 'image', {}, ->
              set 'url', "#{params.argv.url}/favicon.png"
              set 'title', page.title || slug
              set 'link', "http://#{origin}/#{slug}.html"
              set 'width', 32
              set 'height', 32
            for pub in pubs
              elem 'item', {}, ->
                set 'title', ignoreLinks pub.item.text
                set 'link', "#{origin}/#{pub.link}.html"
                set 'pubDate', new Date(pub.siteref.date)
                set 'description', expandLinks(origin, pub.siteref.synopsis)

        res.set('Content-Type', 'application/xml')
        res.send markup.join("\n")

module.exports = {startServer}
