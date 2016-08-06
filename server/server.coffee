fs = require 'fs'
path = require 'path'


asSlug = (name) ->
  name.replace(/\s/g, '-').replace(/[^A-Za-z0-9-]/g, '').toLowerCase()

escape = (text)->
  text
    .replace /&/g, '&amp;'
    .replace /</g, '&lt;'
    .replace />/g, '&gt;'

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

      sitemapLoc = path.join(params.argv.status, 'sitemap.json')
      fs.readFile sitemapLoc, 'utf8', (e, data) ->
        return res.e e if e
        sitemap = {}
        sitemap[s.slug] = s for s in JSON.parse data

        rss {}, ->
          channel {}, ->
            set 'title', page.title || slug
            set 'link', "http://#{req.hostname}/#{req.params.slug}.html"
            set 'lastBuildDate', new Date(page.journal[page.journal.length-1].date || Date.now())
            set 'description', page.story?[0]?.text || 'unknown description'
            for item in page.story || []
              if item.text && (m = item.text.match /\[\[(.*?)\]\]/)
                if s = sitemap[link = asSlug(m[1])]
                  elem 'item', {}, {}, ->
                    set 'title', escape item.text
                    set 'link', "#{params.argv.url}/#{link}/.html"
                    set 'pubDate', new Date(s.date)
                    set 'description', escape s.synopsis

        res.set('Content-Type', 'application/xml')
        res.send markup.join("\n")

module.exports = {startServer}
