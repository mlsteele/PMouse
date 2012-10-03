$(function (){

var MOVE_CMD = 58

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

var upload_move_cmd = function(x,y) {
  ws.send(JSON.stringify({cmd_id: MOVE_CMD, nx: x, ny: y}))
}

$('body').click(function(ev){
  upload_move_cmd(
    ev.clientX / $('body').width(),
    ev.clientY / $('body').height()
  )
})

})
