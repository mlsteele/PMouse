import pymouse
import tornado.httpserver
import tornado.websocket
import tornado.ioloop
import tornado.web
import json

class StateMouse(pymouse.PyMouse):
  def __init__(self):
    super(StateMouse, self).__init__()
    self.btn_state = 0

mouse = StateMouse()

def auth_ip(ip):
  ip_whitelist = ['127.0.0.1', 'localhost', '10.0.1.12', '10.0.1.13']
  # return ip in ip_whitelist
  return True

class MouseSocket(tornado.websocket.WebSocketHandler):
  # support Apple
  def allow_draft76(self):
    return True

  def open(self):
    print "MouseSocket opened. to %s" % self.request.remote_ip
    print self.request
    if not auth_ip(self.request.remote_ip):
      raise Exception("bad auth")

  # messages of format json {cmd: 'NAME', key->vals...}
  # [MOVE_CMD, nx, ny] where x and y are normalized screen coordinates
  def on_message(self, raw_message):
    print "MouseSocket received message"
    msg = json.loads(raw_message)
    print msg

    if msg['cmd'] == 'MOVE-ABS':
      print "CMD: MOVE-ABS"
      w, h = mouse.screen_size()
      nx, ny = msg['nx'], msg['ny']
      mouse.move(nx * (w - 1), ny * (h - 1))

    elif msg['cmd'] == 'MOVE-DELTA':
      print "CMD: MOVE-DELTA"
      w, h = mouse.screen_size()
      dnx, dny = msg['dnx'], msg['dny']
      dpx, dpy = dnx * (w - 1), dny * (h - 1)
      cmx, cmy = mouse.position()
      bind_to_screen = lambda x, y: (min(max(0, x), w-1), min(max(0, y), h-1))
      nx, ny = bind_to_screen(cmx + dpx, cmy + dpy)
      mouse.move(nx, ny)

    elif msg['cmd'] == 'CLICK':
      print mouse.btn_state
      print 'CMD: CLICK'
      nt = msg['n_touches']
      cmx, cmy = mouse.position()
      if nt <= 1:
        # print 'be unclicked'
        mouse.release(cmx, cmy, 1)
        mouse.release(cmx, cmy, 2)
        mouse.btn_state = 0
      elif nt == 2:
        # print 'be clicked'
        if mouse.btn_state == 0:
          mouse.press(cmx, cmy, 1)
          mouse.btn_state = 1
      else:
        # print 'be right clicked'
        if mouse.btn_state != 2:
          mouse.release(cmx, cmy, 1)
          mouse.press(cmx, cmy, 2)
          mouse.btn_state = 2

    elif msg['cmd'] == 'LOG':
      print msg

  def on_close(self):
    print "WebSocket closed"

app = tornado.web.Application([(r'/ws', MouseSocket)])

if __name__ == "__main__":
  print "starting mouse server"
  http_server = tornado.httpserver.HTTPServer(app)
  http_server.listen(5004)
  tornado.ioloop.IOLoop.instance().start()
