
asSlug = (name) ->
  name.replace(/\s/g, '-').replace(/[^A-Za-z0-9-]/g, '').toLowerCase()

expand = (text)->
  text
    .replace /&/g, '&amp;'
    .replace /</g, '&lt;'
    .replace />/g, '&gt;'

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

  $item.append """
    <div style="background-color:#eee; padding:8px;">
      <table>
        <tr>
          <td>
            <a href="//#{site}/plugin/rss/#{slug}.xml" target="_blank" style="padding-right:8px;">
            <img src=/plugins/rss/rss.png height=24></a>
          <td class=report>
            waiting for sitemap
      </table>
    </div>
  """

bind = ($item, item) ->

  page = $item.parents('.page').data('data')
  site = $item.parents('.page').data('site') || location.host

  report = ->
    if map = wiki.neighborhood[site]?.sitemap
      pubs = publishing map, page.story
      $item.find('.report').text "publishing #{pubs.length} of #{map.length} pages"

  $item.dblclick -> wiki.textEditor $item, item

  report()
  $item.get(0).refresh = () ->
    report()

if window?
  $('body').on 'new-neighbor-done', (e, neighbor) ->
    $('.rss').each (index, element) ->
      element.refresh() if element.refresh


window.plugins.rss = {emit, bind} if window?
module.exports = {expand} if module?

