# client

(function (){}
  var host = 'localhost'
  var port = 8888
  var uri = '/ws'

  var ws = new WebSocket("ws://" + host + ":" + port + uri)

  ws.onopen = function(ev) {
    console.log("Websocket opened.")
  }

  ws.onclose = function(ev) {
    console.log("Websocket closed.")
  }

  ws.onmessage = function(ev) {
    console.log("Websocket message received: " + ev.data)
  }
})()
