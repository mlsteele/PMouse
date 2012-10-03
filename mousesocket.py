import pymouse
import tornado.httpserver
import tornado.websocket
import tornado.ioloop
import tornado.web
import json

mouse = pymouse.PyMouse()
MOVE_CMD = 58

class MouseSocket(tornado.websocket.WebSocketHandler):
  def open(self):
    print "MouseSocket opened."
    # self.allow_draft76()

  # messages of format [CMDID, args...]
  # [MOVE_CMD, nx, ny] where x and y are normalized screen coordinates
  def on_message(self, raw_message):
    print "MouseSocket received message"
    msg = json.loads(raw_message)
    print msg
    if msg['cmd_id'] is MOVE_CMD:
      print "CMDID: MOVE"
      w, h = mouse.screen_size()
      nx, ny = msg['nx'], msg['ny']
      mouse.move(nx * w, ny * h)

  def on_close(self):
    print "WebSocket closed"


app = tornado.web.Application([(r'/ws', MouseSocket)])

if __name__ == "__main__":
  http_server = tornado.httpserver.HTTPServer(app)
  http_server.listen(8888)
  tornado.ioloop.IOLoop.instance().start()
