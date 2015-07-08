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

# parent size
t = new dl.Template('toasty template')
pp1 = new dl.XYInfo(0, 0, 60, 32)
p1 = new dl.Panel('panel 1', pp1)

pp2 = new dl.XYInfo(60, 10, 60, 32)
p2 = new dl.Panel('panel 2', pp2)

tbp1 = new dl.XYInfo(0, 0, 20, 10)
tb1 = new dl.Textbox(tbp1, "text")

t.elements.push(tb1)
t.panels.push(p1)
t.panels.push(p2)
t.render()



tc = document.getElementById 'template-container'
tc.appendChild t.render()

#p1.addEventListener 'ontouchstart', movestart
movestart = (e) ->
  console.log e

p1.repr.addEventListener 'onmousedown', movestart

#setTimeout ->
#  s = t.serialize()
#  # returns a new object
#  d = dl.Base.deserialize(s)
#  console.log d
#, 1000


#setTimeout ->
#  setInterval ->
#    panel = t.panels[0]
#    panel.xy.y+=1
#    t.render() 
#  , 1000
#, 3000
