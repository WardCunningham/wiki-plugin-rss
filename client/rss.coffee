
expand = (text)->
  text
    .replace /&/g, '&amp;'
    .replace /</g, '&lt;'
    .replace />/g, '&gt;'
    .replace /\*(.+?)\*/g, '<i>$1</i>'

emit = ($item, item) ->
  $item.append """
    <p style="background-color:#eee; padding:15px; display:table-cell; vertical-align: middle;">
    <img src=/plugins/rss/rss.png height=24>
      #{expand item.text}
    </p>
  """

bind = ($item, item) ->
  $item.dblclick -> wiki.textEditor $item, item

window.plugins.rss = {emit, bind} if window?
module.exports = {expand} if module?

