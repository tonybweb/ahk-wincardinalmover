#Requires AutoHotkey v2
#Include WinCardinalMover.ahk

gooey := Gui("+Resize","WinCardinalMover Demo")
gooey.SetFont("s16 cFFFFFF")
gooey.MarginX := gooey.MarginY := 0
gooey.AddText("w640 h480 Background004400 Center 0x200 vmove", "Move")

gooey.AddText("Background440000 Center 0x200 vn", "N")
gooey.AddText("Background440000 Center 0x200 vs", "S")
gooey.AddText("Background440000 Center 0x200 vw", "W")
gooey.AddText("Background440000 Center 0x200 ve", "E")

gooey.AddText("Background000044 Center 0x200 vnw", "NW")
gooey.AddText("Background000044 Center 0x200 vne", "NE")
gooey.AddText("Background000044 Center 0x200 vsw", "SW")
gooey.AddText("Background000044 Center 0x200 vse", "SE")
gooey.OnEvent("Close", (*) => ExitApp())
gooey.OnEvent("Size", SizeHandler)

gooey.Show("w640 h480")

SizeHandler(guiObj, minMax, width, height) {
  x1 := Round(width * WinCardinalMover.EDGE_MULTIPLIER)
  x2 := Round(width * (1 - WinCardinalMover.EDGE_MULTIPLIER))
  y1 := Round(height * WinCardinalMover.EDGE_MULTIPLIER)
  y2 := Round(height * (1 - WinCardinalMover.EDGE_MULTIPLIER))

  for (, ctrl in guiObj) {
    switch (ctrl.name) {
      case "move":
        ctrl.move(0,0,width,height)
      case "n":
        ctrl.move(0,0,width,y1)
      case "s":
        ctrl.move(0,y2,width,y1)
      case "e":
        ctrl.move(x2,0,x1,height)
      case "w":
        ctrl.move(0,0,x1,height)
      case "ne":
        ctrl.move(x2,0,x1,y1)
      case "nw":
        ctrl.move(0,0,x1,y1)
      case "se":
        ctrl.move(x2,y2,x1,y1)
      case "sw":
        ctrl.move(0,y2,x1,y1)
    }
    ctrl.Redraw()
  }
}

XButton2::WinCardinalMover("XButton2", "Ctrl")