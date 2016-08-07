
asSlug = (name) ->
  name.replace(/\s/g, '-').replace(/[^A-Za-z0-9-]/g, '').toLowerCase()

expand = (text)->
  text
    .replace /&/g, '&amp;'
    .replace /</g, '&lt;'
    .replace />/g, '&gt;'
    .replace /\*(.+?)\*/g, '<i>$1</i>'

publishing = (sitemap, story) ->
  map = {}
  map[s.slug] = s for s in sitemap
  plugin = story?.findIndex (item) -> item.type == 'rss'
  return [] unless plugin >= 0
  selected = []
  for item in story[(plugin+1)..]
    if item.text && (m = item.text.match /\[\[(.*?)\]\]/)
      if siteref = map[link = asSlug(m[1])]
        selected.push {item, link, siteref}
  selected

emit = ($item, item) ->

  page = $item.parents('.page').data('data')
  site = $item.parents('.page').data('site') || location.host
  slug = asSlug page.title

  report = ->
    map = wiki.neighborhood[site].sitemap
    return "waiting for sitemap" unless map
    pubs = publishing map, page.story
    "publishing #{pubs.length} of #{map.length} articles"

  $item.append """
    <div style="background-color:#eee; padding:8px;">
      <table>
        <tr>
          <td><a href="/plugin/rss/#{slug}.xml" target="_blank"><img src=/plugins/rss/rss.png height=24></a>
          <td class=report>#{report()}
      </table>
    </div>
  """

bind = ($item, item) ->
  $item.dblclick -> wiki.textEditor $item, item

window.plugins.rss = {emit, bind} if window?
module.exports = {expand} if module?

