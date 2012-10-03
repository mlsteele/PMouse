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

  upload_move_cmd = ({nx, ny}) ->
    log 'sending move cmd'
    ws.send JSON.stringify
      cmd_id: MOVE_CMD
      nx: nx
      ny: ny

  # setup interaction
  $('.screen').click (ev) ->
    upload_move_cmd
      nx: ev.clientX / $('.screen').width()
      ny: ev.clientY / $('.screen').height()

  # disable page scrolling
  _.each ['touchstart', 'touchmove'], (evn) ->
    _.each [document, document.body], (thing) ->
      thing.addEventListener evn, (e) -> e.preventDefault()

  $('.screen').bind 'touchmove', (e) ->
    e.preventDefault()
    e.stopPropagation()
    touch = e.originalEvent.targetTouches[0]

    upload_move_cmd
      nx: touch.clientX / $('.screen').width()
      ny: touch.clientY / $('.screen').height()
