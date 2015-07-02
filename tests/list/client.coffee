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

list_a = new dl.List(
  new dl.XYInfo(0, 0, 50, 30)
  [
    "one"
    "two"
    "three"
    "four"
    "five"
    "six"
  ] #values
  7 #display height
  1 #row spacing,
)

template = new dl.Template(
  new dl.XYInfo(0, 0, 120, 32)
  "first"
)



panel_one = new dl.PanelDef(
  new dl.XYInfo(0, 0, 60, 32) # panel_location
  new dl.XYInfo(0, 0, 120, 32) # total_size
  1 # position
  1 # layout
  1 # control
)

console.log(panel_one.__proto__.__proto__)

panel_two = new dl.PanelDef(
  new dl.XYInfo(60, 0, 60, 32)
  new dl.XYInfo(0, 0, 120, 32)
  2
  0
  2
)

template.children = [list_a]
template.panels = [panel_one, panel_two]
console.log(template)


container = document.getElementById('template-container')
template.render(container)
template_obj = template.toObject()

makeRequest(template_obj).then (result) ->
  console.log(JSON.parse(result))

"""
current = null

trigger = (val) ->
  current = setInterval ->
    list_a.render container
    o = list_a.set_offset(list_a.offset + val)
    unless o
      clearInterval(current)
  , 100

setHeight = (height) ->
  if 0 < height < 200
    list_a.xy.y_size = height
    list_a.render container
    true
  else
    false

setWidth = (width) ->
  if 0 < width < 200
    list_a.xy.x_size = width
    list_a.render container
    true
  else
    false
      
start = (e) ->
  clearInterval(current)
  if e.target.innerHTML == "UP"
    trigger(1)
  else if e.target.innerHTML == "DOWN"
    trigger(-1)

change = (e) ->
  bu = e.target.innerHTML
  inp = document.getElementById(bu.toLowerCase()).value
  if bu == "HEIGHT"
    setHeight(inp)
  else if bu == "WIDTH"
    setWidth(inp)
  #val = document.getElementById('height').value
  #setHeight(val)

buttons = document.querySelectorAll('.scroll')
for but in buttons
  but.addEventListener 'click', start

buttons = document.querySelectorAll('.size')
for but in buttons
  but.addEventListener 'click', change
"""
