log = -> console.log.apply console, arguments

$ ->
  # states
  WS = undefined # web socket
  IS = # interaction settings
    track_delta_mode: false
  MC = # motion cache (arbitrary data store)
    last_main_touch_pos: undefined


  do make_socket = ->
    host = location.hostname
    port = 5004
    uri = '/ws'
    ws = new WebSocket('ws://' + host + ':' + port + uri)
    ws.onopen = (ev) ->
      log 'Websocket opened.'
      $('.screen').removeClass('closed').addClass('open')

    ws.onclose = (ev) ->
      log 'Websocket closed.'
      $('.screen').removeClass('open').addClass('closed')

      # reload to re-establish connection (FIXME)
      setTimeout(make_socket, 4000)

    ws.onmessage = (ev) ->
      log 'Websocket message received: ' + ev.data

    WS = ws


  SRV = # SERVER
    move_abs: ({nx, ny}) ->
      WS.send JSON.stringify
        cmd: 'MOVE-ABS'
        nx: nx
        ny: ny

    move_delta: ({dnx, dny}) ->
      WS.send JSON.stringify
        cmd: 'MOVE-DELTA'
        dnx: dnx
        dny: dny

    click: (n_touches) ->
      log 'sending click cmd'
      WS.send JSON.stringify cmd: 'CLICK', n_touches: n_touches

    log: (stuff) ->
      WS.send JSON.stringify cmd: 'LOG', payload: stuff


  ## interaction
  # disable page scrolling & clean touch events
  _.each ['touchstart', 'touchmove'], (evn) ->
    _.each [document, document.body], (thing) ->
      thing.addEventListener evn, (e) -> e.preventDefault()

  # non-touch click
  $('.screen').click (ev) ->
    SRV.move_abs extract_n_pos ev

  $('body').bind 'touchmove', (ev) ->
    if IS.track_delta_mode
      new_pos = extract_n_pos ev.originalEvent.targetTouches[0]
      delta = diff_n_poss new_pos, MC.last_main_touch_pos
      MC.last_main_touch_pos = extract_n_pos ev.originalEvent.targetTouches[0]
      SRV.move_delta {dnx: delta.dnx, dny: delta.dny}
    else
      SRV.move_abs extract_n_pos ev.originalEvent.targetTouches[0]

  $('body').bind 'touchstart touchend touchcancel', (ev) ->
    # if start of touch #1 then store place
    if ev.originalEvent.targetTouches.length is 1
      MC.last_main_touch_pos = extract_n_pos ev.originalEvent.targetTouches[0]
    SRV.click ev.originalEvent.touches.length


  ## util
  extract_n_pos = (pos_holder) ->
    to1 = (n) -> Math.max(0, Math.min(n, 1))
    $sc = $('.screen')
    nx: to1 (pos_holder.clientX - $sc.position().left) / $sc.width()
    ny: to1 (pos_holder.clientY - $sc.position().top)  / $sc.height()

  diff_n_poss = ({nx: np1x, ny: np1y}, {nx: np2x, ny: np2y}) ->
    dnx: np1x - np2x
    dny: np1y - np2y
