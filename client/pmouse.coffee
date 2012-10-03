log = -> console.log.apply console, arguments

$ ->
  MOVE_CMD = 58
  host = location.hostname
  port = 8888
  uri = '/ws'
  ws = new WebSocket('ws://' + host + ':' + port + uri)
  ws.onopen = (ev) ->
    $('.screen').removeClass('closed').addClass('open')
    log 'Websocket opened.'

  ws.onclose = (ev) ->
    $('.screen').removeClass('open').addClass('closed')
    log 'Websocket closed.'

  ws.onmessage = (ev) ->
    log 'Websocket message received: ' + ev.data

  upload_move_cmd = (x, y) ->
    log 'sending move cmd'
    ws.send JSON.stringify(
      cmd_id: MOVE_CMD
      nx: x
      ny: y
    )

  $('.screen').click (ev) ->
    upload_move_cmd(
      ev.clientX / $('.screen').width(),
      ev.clientY / $('.screen').height()
    )
