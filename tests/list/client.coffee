dl = window.displayLib

makeRequest = (data, location = '/', method = 'POST') ->
  data = JSON.stringify(data)
  new Promise (resolve, reject) ->
    _request = new XMLHttpRequest()
    _request.open(method, location, true)
    _request.onload = ->
      if _request.status == 200
        resolve(_request.response)
      else
        reject(_request.statusText)
    _request.onerror = ->
      reject(_request)
    _request.setRequestHeader('Content-Type', 'application/json; charset=UTF-8')
    _request.send(data)

new_template_button = document.getElementById "new_template"
new_panel_button = document.getElementById "new_panel"
new_textbox_button = document.getElementById "new_textbox"
textbox_text = document.getElementById "text"
test_button = document.getElementById "test_button"
output_textbox = document.getElementById "output_textbox"
button = document.getElementById 'button'
template = null

new_template_button.addEventListener 'click', (e) ->
  e.target.disabled = true
  template = new dl.Template('first template')

  new_panel_button.disabled = false
  new_panel_button.addEventListener 'click', new_panel_event
  new_textbox_button.disabled = false
  new_textbox_button.addEventListener 'click', new_textbox_event

  vis = template.render()
  tc = document.getElementById 'template-container'
  tc.appendChild vis

  e.target.removeEventListener()


i = 0
new_panel_event = (e) ->
  p1 = new dl.Panel "panel #{i+1}", new dl.XYInfo 0, 0, 60, 32
  p1.control = 1+i
  p1.layout = 1-i
  p1.position = 1+i
  template.panels.push(p1)
  template.render()
  if i < 2
    i++
  else
    e.target.disabled = true
    e.removeEventListener()

new_textbox_event = (e) ->
  tb = new dl.Textbox new dl.XYInfo(0, 0, 20, 10), textbox_text.value
  template.elements.push tb
  template.render()

test_button.addEventListener 'click', (e) ->
  ob = template.serialize()
  output_textbox.innerHTML = JSON.stringify(ob, null, 2)

button.onclick = (e) ->
  ob = template.serialize()
  makeRequest(ob).then (res) ->
    console.log 'responded with'
    console.log res 

#@name
#@xy
#@total_size=new XYInfo()
#@fg_color= new Color(200, 200, 200, 200)
#@bg_color= new Color(80, 80, 80, 80)
#@geometry = PanelGeometry.PG_NOT_SPECIFIED
#@position = PanelPosition.PP_NOT_SPECIFIED
#@layout = PanelLayout.PL_NORMAL

#pp1 = new dl.XYInfo(0, 0, 60, 32)
#p1 = new dl.Panel('panel 1', pp1)
#p1.control = 1 # this is defined but not serialized / sent?
#p1.layout = 1
#p1.position = 1
#
#pp2 = new dl.XYInfo(60, 10, 60, 32)
#p2 = new dl.Panel('panel 2', pp2)
#p2.control = 2
#p2.layout = 0
#p2.position = 2

#tbp1 = new dl.XYInfo(0, 0, 20, 10)
#tb1 = new dl.Textbox(tbp1, "text")
#tb1.control = 12

#template.elements.push(tb1)
#template.panels.push(p1)
#template.panels.push(p2)

#template.recalculateExtents()

#s = template.serialize()
#console.log s

#vis = template.render()
#tc = document.getElementById 'template-container'
#tc.appendChild vis
