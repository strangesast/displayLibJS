dl = window.displayLib

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

container = repr: document.getElementById 'container'
list_a.render container

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
