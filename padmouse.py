# control mouse for 
# http://metapep.wordpress.com/2009/07/10/control-the-mouse-on-mac-with-python/

import objc

def clickMouse(x, y, button):
  bndl = objc.loadBundle('CoreGraphics', globals(), '/System/Library/Frameworks/ApplicationServices.framework')
  objc.loadBundleFunctions(bndl, globals(), [('CGPostMouseEvent', 'v{CGPoint=ff}III')])
  CGPostMouseEvent((x, y), 1, button, 1)
  CGPostMouseEvent((x, y), 1, button, 0)

def moveMouse(x, y):
  bndl = objc.loadBundle('CoreGraphics', globals(), '/System/Library/Frameworks/ApplicationServices.framework')
  objc.loadBundleFunctions(bndl, globals(), [('CGWarpMouseCursorPosition', 'v{CGPoint=ff}')])
  CGWarpMouseCursorPosition((x, y))
