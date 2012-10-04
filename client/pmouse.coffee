log = -> console.log.apply console, arguments

$ ->
  MOVE_CMD = 58
  CLICK_CMD = 59

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

    # reload to re-establish connection (FIXME)
    window.location = window.location

  ws.onmessage = (ev) ->
    log 'Websocket message received: ' + ev.data

  upload_move_cmd = ({nx, ny}) ->
    # log 'sending move cmd'
    ws.send JSON.stringify
      cmd_id: MOVE_CMD
      nx: nx
      ny: ny

  upload_click_cmd = ->
    log 'sending click cmd'
    ws.send JSON.stringify cmd_id: CLICK_CMD

  extract_n_pos = (pos_holder) ->
    to1 = (n) -> Math.max(0, Math.min(n, 1))
    $sc = $('.screen')
    nx: to1 (pos_holder.clientX - $sc.position().left) / $sc.width()
    ny: to1 (pos_holder.clientY - $sc.position().top)  / $sc.height()

  # setup interaction
  $('.screen').click (ev) ->
    upload_move_cmd extract_n_pos ev

  # disable page scrolling
  _.each ['touchstart', 'touchmove'], (evn) ->
    _.each [document, document.body], (thing) ->
      thing.addEventListener evn, (e) -> e.preventDefault()

  $('body').bind 'touchmove', (ev) ->
    ev.preventDefault()
    ev.stopPropagation()
    touch = ev.originalEvent.targetTouches[0]

    upload_move_cmd extract_n_pos touch

  $('.screen').bind 'touchstart', (ev) ->
    if ev.originalEvent.targetTouches.length is 2
      upload_click_cmd()
