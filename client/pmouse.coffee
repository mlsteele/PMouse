log = -> console.log.apply console, arguments

$ ->
  # states
  WS = undefined

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

  SRV =
    move: ({nx, ny}) ->
      WS.send JSON.stringify
        cmd: 'MOVE'
        nx: nx
        ny: ny
    click: (n_touches) ->
      log 'sending click cmd'
      WS.send JSON.stringify cmd: 'CLICK', n_touches: n_touches

  ## interaction
  # disable page scrolling & clean touch events
  _.each ['touchstart', 'touchmove'], (evn) ->
    _.each [document, document.body], (thing) ->
      thing.addEventListener evn, (e) -> e.preventDefault()

  # non-touch click
  $('.screen').click (ev) ->
    SRV.move extract_n_pos ev

  $('body').bind 'touchmove', (ev) ->
    ev.preventDefault()
    ev.stopPropagation()
    SRV.move extract_n_pos ev.originalEvent.targetTouches[0]

  $('body').bind 'touchstart touchend touchcancel', (ev) ->
    SRV.click ev.originalEvent.touches.length

  ## util
  extract_n_pos = (pos_holder) ->
    to1 = (n) -> Math.max(0, Math.min(n, 1))
    $sc = $('.screen')
    nx: to1 (pos_holder.clientX - $sc.position().left) / $sc.width()
    ny: to1 (pos_holder.clientY - $sc.position().top)  / $sc.height()
