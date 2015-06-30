dl = window.displayLib


panel_l = new dl.PanelDef(
  new dl.XYInfo(0, 0, 60, 32) # panel_location
  new dl.XYInfo(0,0,120,32) # total_size
  1 # contro
  null
  null
  1 # layout
  1 # position
)

panel_a = new dl.PanelDef(
  new dl.XYInfo(0, 0, 60, 32) # panel_location
  new dl.XYInfo(0,0,120,32) # total_size
  1 # control
)

list_a = new dl.List(
  new dl.XYInfo(0, 0, 50, 30)
  [
    "toast"
    "TOAST"
    "goat"
  ] #values
  7 #display height
  1 #row spacing,
)

list_a.render repr: document.getElementById 'container'
#list_a.render document.getElementById 'container'

#text_box = new dl.Textbox()

#text_box.render()

#template_a = new dl.Template('name1')
