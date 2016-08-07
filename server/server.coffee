fs = require 'fs'
path = require 'path'


asSlug = (name) ->
  name.replace(/\s/g, '-').replace(/[^A-Za-z0-9-]/g, '').toLowerCase()

escape = (text)->
  text
    .replace /&/g, '&amp;'
    .replace /</g, '&lt;'
    .replace />/g, '&gt;'

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

  app.get '/plugin/rss/:slug.xml', (req, res) ->
    slug = req.params.slug
    markup = []

    elem = (tag, params, extra, more) ->
      markup.push "<#{tag} #{attr params} #{attr extra}>"; more(); markup.push "</#{tag}>"

    attr = (params) ->
      ("#{k}=\"#{v}\"" for k, v of params).join " "

    set = (tag, value) ->
      markup.push "<#{tag}>#{value}</#{tag}>"

    rss = (params, more) ->
      elem 'rss', params, {version: '2.0'}, more

    channel = (params, more)->
      elem 'channel', params, {}, more

    app.pagehandler.get slug, (e, page, status) ->
      return res.e e if e

      plugin = page.story?.findIndex (item) ->
        item.type == 'rss'
      return res.status(404).send("Not an RSS feed.") unless plugin >= 0

      sitemapLoc = path.join(params.argv.status, 'sitemap.json')
      fs.readFile sitemapLoc, 'utf8', (e, sitemap) ->
        return res.e e if e

        pubs = publishing JSON.parse(sitemap), page.story, plugin

        rss {}, ->
          channel {}, ->
            set 'title', page.title || slug
            set 'link', "http://#{params.argv.url}/#{req.params.slug}.html"
            set 'lastBuildDate', new Date(page.journal[page.journal.length-1].date || Date.now())
            set 'description', escape page.story?[0]?.text || 'unknown description'
            set 'image', "#{params.argv.url}/favicon.png"
            for pub in pubs
              elem 'item', {}, {}, ->
                set 'title', escape pub.item.text
                set 'link', "#{params.argv.url}/#{pub.link}.html"
                set 'pubDate', new Date(pub.siteref.date)
                set 'description', escape pub.siteref.synopsis

        res.set('Content-Type', 'application/xml')
        res.send markup.join("\n")

module.exports = {startServer}
