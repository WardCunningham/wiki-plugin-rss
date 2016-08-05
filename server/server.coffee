escape = (text)->
  text
    .replace /&/g, '&amp;'
    .replace /</g, '&lt;'
    .replace />/g, '&gt;'


startServer = (params) ->
  app = params.app

  app.get '/plugin/rss/app', (req, res) ->
    res.send Object.keys(app).join(', ')

  app.get '/plugin/rss/req', (req, res) ->
    res.send Object.keys(req).join(', ')

  app.get '/plugin/rss/:slug.xml', (req, res) ->
    slug = req.params.slug
    app.pagehandler.get slug, (e, page, status) ->
      return res.e e if e
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

      rss {}, ->
        channel {}, ->
          set 'title', page.title || slug
          set 'link', "http://#{req.hostname}/#{req.params.slug}.html"
          set 'description', page.story?[0]?.text || 'unknown description'
          for item in page.story || []
            elem 'item', {}, {}, ->
              set 'description', escape item.text

      res.set('Content-Type', 'application/xml')
      res.send markup.join("\n")

module.exports = {startServer}
