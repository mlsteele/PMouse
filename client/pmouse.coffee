log = -> console.log.apply console, arguments

$ ->
  ## establish websocket
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

  ## upload hooks
  upload_move_cmd = ({nx, ny}) ->
    # log 'sending move cmd'
    ws.send JSON.stringify
      cmd: 'MOVE'
      nx: nx
      ny: ny

  upload_click_cmd = (n_touches) ->
    log 'sending click cmd'
    ws.send JSON.stringify cmd: 'CLICK', n_touches: n_touches

  ## interaction
  extract_n_pos = (pos_holder) ->
    to1 = (n) -> Math.max(0, Math.min(n, 1))
    $sc = $('.screen')
    nx: to1 (pos_holder.clientX - $sc.position().left) / $sc.width()
    ny: to1 (pos_holder.clientY - $sc.position().top)  / $sc.height()

  # disable page scrolling & clean touch events
  _.each ['touchstart', 'touchmove'], (evn) ->
    _.each [document, document.body], (thing) ->
      thing.addEventListener evn, (e) -> e.preventDefault()

  # non-touch click
  $('.screen').click (ev) ->
    upload_move_cmd extract_n_pos ev

  $('body').bind 'touchmove', (ev) ->
    ev.preventDefault()
    ev.stopPropagation()
    touch = ev.originalEvent.targetTouches[0]

    upload_move_cmd extract_n_pos touch

  $('body').bind 'touchstart touchend touchcancel', (ev) ->
    upload_click_cmd ev.originalEvent.touches.length
