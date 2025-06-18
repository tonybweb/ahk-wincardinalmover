/************************************************************************
 * @description WinCardinalMover - provides window moving and resizing
 *   from anywhere within a window. Constrains to monitor edges, does NOT
 *   SUPPORT multiple monitors yet.
 *
 *   The center of the window is assigned to moving the window. The
 *   first 15% from the inner edge of each window is assigned to resizing
 *   based on the cardinal directions:  N, S, W, E, NE, SE, NW, and SW
 *
 * @author tonybweb
 * @link (https://github.com/tonybweb/ahk-wincardinalmover)
 * @date 2025/06/17
 * @version 1.0.0
 *
 * REMARKS
 * SetWinDelay impacts the speed of WinMove, the default value is 100ms
 * which is very slow from a framerate persiective.
 *   WIN_DELAY of 0 is no delay but feels too fast for some windows
 *     (can produce weird artifacts on resize)
 *   Perhaps a WIN_DELAY value tuned to monitor refresh rate is best?
 *   1000 / 120hz = 8.33, 1000 / 60hz = 16.66, etc. 1 seems fine though.
 ***********************************************************************/

class WinCardinalMover {
  static N := 1, S := 2, W := 3, E := 4,
    NE := 5, SE := 6, NW := 7, SW := 8,
    TASKBAR_HEIGHT := 40,
    WIN_DELAY := 1

  static win := {},
    hk := "",
    optionKey := "Ctrl",
    on := 0

  static __New() {
    this.DEFAULT_WIN_DELAY := A_WinDelay ;Default is 100
  }

  static Call(hk, optionKey := "Ctrl") {
    CoordMode("Mouse", "Screen")
    this.hk := hk
    this.optionKey := optionKey
    if (! this.on) {
      SetWinDelay(this.WIN_DELAY)
      this.on := 1

      MouseGetPos(&x, &y, &hwnd), this.win.startingX := x, this.win.startingY := y, this.win.hwnd := hwnd
      WinGetPos(&x, &y, &w, &h, this.win.hwnd), this.win.x := x, this.win.y := y, this.win.w := w, this.win.h := h
      WinGetClientPos(&x, &y, &w, &h, this.win.hwnd), this.win.cX := x, this.win.cY := y, this.win.cW := w, this.win.cH := h
      this.win.yOffset := Abs(this.win.cH - this.win.h)
      this.win.xOffset := Round(Abs(this.win.cW - this.win.w) / 2)

      WinActivate(this.win.hwnd)
      this.direction := this.findWindowCompassDirection()
      this.moveOrSizeWindow()

      this.on := 0
      SetWinDelay(this.DEFAULT_WIN_DELAY)
    }
  }

  static moveOrSizeWindow() {
    static X_INDEX := 1, Y_INDEX := 2, W_INDEX := 3, H_INDEX := 4
    moveArgs := [unset,unset,unset,unset,this.win.hwnd]

    while GetKeyState(this.hk, "P") {
      MouseGetPos(&currentX, &currentY)
      deltaX := currentX - this.win.startingX
      deltaY := currentY - this.win.startingY

      switch this.direction {
        case this.N:
          UpdateNorthConstraint()

        case this.S:
          UpdateSouthConstraint()

        case this.E:
          UpdateEastConstraint()

        case this.W:
          UpdateWestConstraint()

        case this.NE:
          UpdateNorthConstraint()
          UpdateEastConstraint()

        case this.NW:
          UpdateNorthConstraint()
          UpdateWestConstraint()

        case this.SE:
          UpdateSouthConstraint()
          UpdateEastConstraint()

        case this.SW:
          UpdateSouthConstraint()
          UpdateWestConstraint()

        default:
          maxX := A_ScreenWidth - this.win.w
          maxY := A_ScreenHeight - this.win.h
          if (GetKeyState(this.optionKey)) {
            maxY -= this.TASKBAR_HEIGHT
          }

          moveArgs[X_INDEX] := Min(Max(0, this.win.x + deltaX), maxX)
          moveArgs[Y_INDEX] := Min(Max(0, this.win.y + deltaY), maxY)
      }
      WinMove(moveArgs*)
    }

    UpdateNorthConstraint() {
      moveArgs[Y_INDEX] := Max(this.win.y + deltaY, 0)
      moveArgs[H_INDEX] := Min(this.win.h - deltaY, this.win.h + this.win.y)
    }
    UpdateSouthConstraint() {
      allowedHeight := GetKeyState(this.optionKey) ? A_ScreenHeight - this.TASKBAR_HEIGHT : A_ScreenHeight
      moveArgs[H_INDEX] := this.win.h + Min(deltaY, allowedHeight - (this.win.h + this.win.y) + this.win.yOffset)
    }
    UpdateEastConstraint() {
      moveArgs[W_INDEX] := Min(this.win.w + deltaX, A_ScreenWidth - this.win.x)
    }
    UpdateWestConstraint() {
      moveArgs[X_INDEX] := Max(this.win.x + deltaX - this.win.xOffset, 0 - this.win.xOffset)
      moveArgs[W_INDEX] := Min(this.win.w - deltaX, this.win.x + this.win.w)
    }
  }

  static findWindowCompassDirection() {
    ; relative
    rX := this.win.startingX - this.win.x
    rY := this.win.startingY - this.win.y

    ;Intercardinal Direction Thresholds: NW, NE, SW, SE
    cornerX := this.win.w * 0.15
    cornerY := this.win.h * 0.15

    ;Cardinal Direction Thresholds: N, S, E, W
    cardinalX := this.win.w * 0.15
    cardinalY := this.win.h * 0.15

    if (rX < cornerX && rY < cornerY) {
      return this.NW
    }
    if (rX > this.win.w - cornerX && rY < cornerY) {
      return this.NE
    }
    if (rX < cornerX && rY > this.win.h - cornerY) {
      return this.SW
    }
    if (rX > this.win.w - cornerX && rY > this.win.h - cornerY) {
      return this.SE
    }
    if (rY < cardinalY && rX >= cornerX && rX <= this.win.w - cornerX) {
      return this.N
    }
    if (rY > this.win.h - cardinalY && rX >= cornerX && rX <= this.win.w - cornerX) {
      return this.S
    }
    if (rX < cardinalY && rY >= cornerY && rY <= this.win.h - cornerY) {
      return this.W
    }
    if (rX > this.win.w - cardinalY && rY >= cornerY && rY <= this.win.h - cornerY) {
      return this.E
    }
    return false
  }
}
