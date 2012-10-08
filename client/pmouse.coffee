log = -> console.log.apply console, arguments

$ ->
  # states
  WS = undefined # web socket
  IS = # interaction settings
    enabled: false
    # false, 'p' for pixel, or 'n' for normalized
    track_delta_mode: 'p'
  MC = # motion cache (arbitrary data store)
    last_main_touch_pos_n: undefined
    last_main_touch_pos_p: undefined


  do make_socket = ->
    host = location.hostname
    port = 5004
    uri = '/ws'
    ws = new WebSocket('ws://' + host + ':' + port + uri)
    ws.onopen = (ev) ->
      log 'Websocket opened.'
      IS.enabled = true
      $('.screen').removeClass('closed').addClass('open')

    ws.onclose = (ev) ->
      log 'Websocket closed.'
      IS.enabled = false
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

    move_delta_n: ({dnx, dny}) ->
      WS.send JSON.stringify
        cmd: 'MOVE-DELTA-N'
        dnx: dnx
        dny: dny

    move_delta_p: ({dpx, dpy}, scale=1) ->
      WS.send JSON.stringify
        cmd: 'MOVE-DELTA-P'
        dpx: dpx * scale
        dpy: dpy * scale

    click: (n_touches) ->
      # log 'sending click cmd'
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
    return unless IS.enabled
    SRV.move_abs extract_n_pos ev

  $('body').bind 'touchmove', (ev) ->
    return unless IS.enabled
    if IS.track_delta_mode is 'n'
      new_pos = extract_n_pos ev.originalEvent.targetTouches[0]
      delta = diff_n_poss new_pos, MC.last_main_touch_pos_n
      MC.last_main_touch_pos_n = extract_n_pos ev.originalEvent.targetTouches[0]
      SRV.move_delta_n {dnx: delta.dnx, dny: delta.dny}
    else if IS.track_delta_mode is 'p'
      new_pos = extract_p_pos ev.originalEvent.targetTouches[0]
      delta = diff_p_poss new_pos, MC.last_main_touch_pos_p
      MC.last_main_touch_pos_p = extract_p_pos ev.originalEvent.targetTouches[0]
      SRV.move_delta_p {dpx: delta.dpx, dpy: delta.dpy}
    else
      SRV.move_abs extract_n_pos ev.originalEvent.targetTouches[0]

  $('body').bind 'touchstart touchend touchcancel', (ev) ->
    return unless IS.enabled
    # if start of touch #1 then store place
    if ev.originalEvent.targetTouches.length is 1
      MC.last_main_touch_pos_n = extract_n_pos ev.originalEvent.targetTouches[0]
      MC.last_main_touch_pos_p = extract_p_pos ev.originalEvent.targetTouches[0]
    SRV.click ev.originalEvent.touches.length


  ## util
  extract_n_pos = (pos_holder) ->
    to1 = (n) -> Math.max(0, Math.min(n, 1))
    $sc = $('.screen')
    nx: to1 (pos_holder.clientX - $sc.position().left) / $sc.width()
    ny: to1 (pos_holder.clientY - $sc.position().top)  / $sc.height()

  extract_p_pos = (pos_holder) ->
    $sc = $('.screen')
    px: pos_holder.clientX - $sc.position().left
    py: pos_holder.clientY - $sc.position().top

  diff_n_poss = ({nx: np1x, ny: np1y}, {nx: np2x, ny: np2y}) ->
    dnx: np1x - np2x
    dny: np1y - np2y

  diff_p_poss = ({px: pp1x, py: pp1y}, {px: pp2x, py: pp2y}) ->
    dpx: pp1x - pp2x
    dpy: pp1y - pp2y
