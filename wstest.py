# http://mbed.org/cookbook/Websockets-Server

import tornado.httpserver
import tornado.websocket
import tornado.ioloop
import tornado.web

class EchoWebSocket(tornado.websocket.WebSocketHandler):
  def open(self):
    print "WebSocket opened"

  def on_message(self, message):
    print "WebSocket received message"
    print message
    print message.__class__
    print message[0]
    self.write_message(u"You said: " + message)

  def on_close(self):
    print "WebSocket closed"

app = tornado.web.Application([(r'/ws', EchoWebSocket)])

if __name__ == "__main__":
  http_server = tornado.httpserver.HTTPServer(app)
  http_server.listen(8888)
  tornado.ioloop.IOLoop.instance().start()
