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
# FIXME: this is a guess subject to interference
# 0 - off, 1 - Lbutton, 2 - Rbutton

class MouseSocket(tornado.websocket.WebSocketHandler):
  # support Apple
  def allow_draft76(self):
    return True

  def open(self):
    print "MouseSocket opened."
    # self.allow_draft76()

  # messages of format json {cmd: 'NAME', key->vals...}
  # [MOVE_CMD, nx, ny] where x and y are normalized screen coordinates
  def on_message(self, raw_message):
    print "MouseSocket received message"
    msg = json.loads(raw_message)
    print msg

    if msg['cmd'] == 'MOVE':
      print "CMD: MOVE"
      w, h = mouse.screen_size()
      nx, ny = msg['nx'], msg['ny']
      mouse.move(nx * (w - 1), ny * (h - 1))

    if msg['cmd'] == 'CLICK':
      print mouse.btn_state
      print 'CMD: CLICK'
      nt = msg['n_touches']
      if nt <= 1:
        # print 'be unclicked'
        mouse.release(mouse.position()[0], mouse.position()[1], 1)
        mouse.release(mouse.position()[0], mouse.position()[1], 2)
        mouse.btn_state = 0
      elif nt == 2:
        # print 'be clicked'
        if mouse.btn_state == 0:
          mouse.release(mouse.position()[0], mouse.position()[1], 2)
          mouse.press(mouse.position()[0], mouse.position()[1], 1)
          mouse.btn_state = 1
      else:
        # print 'be right clicked'
        if mouse.btn_state != 2:
          mouse.release(mouse.position()[0], mouse.position()[1], 1)
          mouse.press(mouse.position()[0], mouse.position()[1], 2)
          mouse.btn_state = 2

  def on_close(self):
    print "WebSocket closed"


app = tornado.web.Application([(r'/ws', MouseSocket)])

if __name__ == "__main__":
  http_server = tornado.httpserver.HTTPServer(app)
  http_server.listen(8888)
  tornado.ioloop.IOLoop.instance().start()
