log = -> console.log.apply console, arguments
reduce = (list, memo, iterator) -> _.reduce list, iterator, memo
plantTimeout = (f, t) -> setTimeout t, f

log 'STRESS'

css_styles =
  touch_draggable_mx: 'touch-draggable-last-mouse-x'
  touch_draggable_my: 'touch-draggable-last-mouse-y'
  touch_draggable_offset_x: 'touch-draggable-offset-x'
  touch_draggable_offset_y: 'touch-draggable-offset-y'
  touch_draggable_dragging: 'touch-draggable-dragging'
  game_entity: 'g-entity'
  card: 'card'
  tabled_card: 'tabled'
  open_hand: 'open'
  solved_hand: 'solved'
  touching: 'touching'
  claimed: 'claimed'

$ =>
  translate3d = ({x, y}) -> return "translate3d(#{x}px, #{y}px, 0)"
  get_translate3d = (el) ->
    matrix = $(el).css('transform').match(/[0-9\.]+/g)
    return x: 0, y: 0 if matrix is null
    x: +matrix[4], y: +matrix[5]

  # disable page scrolling
  _.each ['touchstart', 'touchmove'], (evn) ->
    _.each [document, document.body], (thing) ->
      thing.addEventListener evn, (e) -> e.preventDefault()

  $('#container').css height: $(document).height()

  make_card_envoy = (card) ->
    $ 'div'
    $div = $ '<div/>',
      class: "#{css_styles.game_entity} #{css_styles.card}"
      text: [null,'A',2,3,4,5,6,7,8,9,10,'J','Q','K'][card.n]
    $div.data 'card', card
    $div.appendTo $ '#container'
    make_card_envoy_draggable $div
    $div.bind 'touchend touchcancel', -> attempt_client_hand_close()
    return $div

  # specialized for card envoys
  make_card_envoy_draggable = (el) ->
    $el = $(el)
    tx = css_styles.touch_draggable_mx
    ty = css_styles.touch_draggable_my
    tox = css_styles.touch_draggable_offset_x
    toy = css_styles.touch_draggable_offset_y
    tdgc = css_styles.touch_draggable_dragging

    table_top = $('#row2').position().top
    table_bottom = table_top + $('#row2').height()

    $el.bind 'touchstart', (e) ->
      e.preventDefault()
      e.stopPropagation()
      return if $el.hasClass css_styles.claimed

      touch = e.originalEvent.targetTouches[0]

      $el.data tox, get_translate3d($el).x - touch.clientX
      $el.data toy, get_translate3d($el).y - touch.clientY

      $el.addClass tdgc

    $el.bind 'touchmove', (e) ->
      e.preventDefault()
      e.stopPropagation()
      return if $el.hasClass css_styles.claimed
      touch = e.originalEvent.targetTouches[0]

      newx = touch.clientX + $el.data tox
      rw = $el.width()
      newx = Math.max 20, Math.min newx, $('#row2').width() - rw

      newy = touch.clientY + $el.data toy
      newy = Math.max table_top, newy
      if (_.include gstate.card_envoys_on_table, $el[0]) and gstate.card_envoys_on_table.length <= 4
        newy = Math.min table_bottom - $el.height() * 4/5, newy

      $el.css
        transform: translate3d
          x: newx
          y: newy

      # if center above table bottom
      if get_translate3d($el).y + $el.height() * 3/4 < table_bottom
        # add to table list
        gstate.card_envoys_on_table = _.union gstate.card_envoys_on_table, [$el[0]]
        $el.addClass css_styles.tabled_card
      else
        # remove from table list
        gstate.card_envoys_on_table = _.without gstate.card_envoys_on_table, $el[0]
        $el.removeClass css_styles.tabled_card        

    $el.bind 'touchend touchcancel', (e) -> $el.removeClass tdgc

  check_hand_solved = (hand) ->
    $hand = $(hand)
    return false if $hand.data('cards').length < 4
    n = $hand.data('cards')[0].n
    if _.all ($hand.data 'cards'), ((card) -> card.n is n)
      $hand.addClass css_styles.solved_hand
      true
    else
      false

  ## element placement

  # place enemy hands
  _.each $('.enemy-hand'), (eh, i) ->
    pad = $('#row1').width() - $(eh).width() * 6
    $(eh).css transform: translate3d
      x: (pad / 6 + $(eh).width()) * i + pad / 7 / 2
      y: $('#row1').height() / 2 - $(eh).height() / 2

  # place client hands
  _.each $('.client-hand'), (ch, i) ->
    left_offset = 150
    $(ch).css
      transform: translate3d
        x: (i % 3) * ($('#row4').width()/2 - left_offset - $(ch).width()/2) + left_offset
        y: (reduce ['#row1', '#row2', '#row3'], 0, (a, n) -> a + $(n).height()) + 60 + Math.floor(i / 3) * 240

  # make deck
  deck = reduce (_.map [[{n: n, suit: suit} for n in [1..13]] for suit in [0...4]][0], (a) -> a[0]), [], (a,b) -> a.concat b
  deck = _.shuffle deck
  log "generated #{deck.length} cards"

  ## initial data fills

  gstate =
    card_envoys_on_surface: []
    # sorry about this one. table refers to the trading slice. surface refers to the whole pad.
    card_envoys_on_table: [] # subset of on_surface
    open_hand: null

  # place initial table cards
  for i in [0...4]
    $ce = $(make_card_envoy(deck[i]))
    $ce.addClass(css_styles.tabled_card).css
      transform: translate3d
        x: 120 + i * 200
        y: (reduce ['#row1'], 0, (a, n) -> a + $(n).height()) + 110
    gstate.card_envoys_on_surface.push $ce[0]
    gstate.card_envoys_on_table.push $ce[0]

  # fill client hands
  _.each $('.client-hand'), (h) -> $(h).data('cards', [])
  log "filled empty client hands"
  for i in [4...4 + 24]
    $target_hand = $((_.filter $('.client-hand'), (ch) -> $(ch).data('cards').length < 4)[0])
    $target_hand.data('cards').push deck[i]
    check_hand_solved $target_hand

  # fill enemy hands
  _.each $('.enemy-hand'), (h) -> $(h).data('cards', [])
  log "filled empty enemy hands"
  for i in [28...28 + 24]
    $target_hand = $((_.filter $('.enemy-hand'), (eh) -> $(eh).data('cards').length < 4)[0])
    $target_hand.data('cards').push deck[i]
    check_hand_solved $target_hand

  pop_client_hand = (client_hand) ->
    $client_hand = $(client_hand)
    log "popping client hand of #{[c.n for c in ($client_hand.data 'cards')]}"
    gstate.open_hand = $client_hand
    $client_hand.addClass css_styles.open_hand

    # create card envoys
    card_envoys = _.map ($client_hand.data 'cards'), (card, i) ->
      $card_envoy = $ make_card_envoy card
      angle_offset = 1.2
      log "chtr: #{get_translate3d($client_hand).x}, #{get_translate3d($client_hand).y}"
      nx = get_translate3d($client_hand).x + $client_hand.width() / 2 + Math.cos(-Math.PI / 2 - angle_offset + angle_offset * 2 / 3 * i) * 160 - $card_envoy.width() / 2
      ny = get_translate3d($client_hand).y + $client_hand.height() / 2 + Math.sin(-Math.PI / 2 - angle_offset + angle_offset * 2 / 3 * i) * 160 - $card_envoy.height() / 2
      log "x: #{nx}, y: #{ny}"
      $card_envoy.css
        transform: translate3d
          x: nx
          y: ny
      $card_envoy

    # register card envoys
    [gstate.card_envoys_on_surface.push $(ce)[0] for ce in card_envoys]

  card_envoys_in_open_hand = ->
    # log "gstate.card_envoys_on_surface: #{gstate.card_envoys_on_surface.length}"
    # log "gstate.card_envoys_on_table: #{gstate.card_envoys_on_table.length}"
    _.difference gstate.card_envoys_on_surface, gstate.card_envoys_on_table

  attempt_client_hand_close = ->
    log "attempting client hand close"
    return true if gstate.open_hand is null
    return false if _.any [[$('.card'), css_styles.touch_draggable_dragging], [$('.client-hand'), 'touching']], (lc) -> _.any lc[0], (el) -> $(el).hasClass lc[1]
    ceoh = card_envoys_in_open_hand()
    log "card_envoys_in_open_hand #{ceoh.length}"
    return false unless ceoh.length is 4

    log "client hand close tests passed, closing"
    $(gstate.open_hand).data 'cards', _.map (_.sortBy ceoh, (ce) -> get_translate3d(ce).x), (card_envoy) ->
      $ch = $(card_envoy)
      card = $ch.data 'card'
      errbore = gstate.card_envoys_on_surface.length
      gstate.card_envoys_on_surface = _.without gstate.card_envoys_on_surface, $ch[0]
      if gstate.card_envoys_on_surface.length == errbore then console.error 'disappearing card not removed from surface list!'
      gstate.card_envoys_on_table = _.without gstate.card_envoys_on_table, $ch[0]
      $ch.remove()
      card

    $(gstate.open_hand).removeClass css_styles.open_hand
    check_hand_solved gstate.open_hand
    gstate.open_hand = null

  # bind hand listeners
  $('.client-hand').bind 'touchstart', (ev) ->
    $client_hand = $(ev.target)
    $client_hand.addClass css_styles.touching
    return unless gstate.open_hand is null
    return if $client_hand.hasClass css_styles.solved_hand
    pop_client_hand $client_hand

  $('.client-hand').bind 'touchend touchcancel', (ev) ->
    $(ev.target).removeClass css_styles.touching
    attempt_client_hand_close()

  ## enemy utilities
  # (card_envoy) unwrapped DOM element
  # (enemy_hand) unwrapped DOM element
  enemy_claim_card = (card_envoy, enemy_hand, cb) ->
    log "claim", card_envoy, enemy_hand
    $card_envoy = $(card_envoy)
    $enemy_hand = $(enemy_hand)

    # return false if $card_envoy.hasClass css_styles.touch_draggable_dragging
    # move to hand in model
    $card_envoy.addClass css_styles.claimed
    gstate.card_envoys_on_table = _.without gstate.card_envoys_on_table, $card_envoy[0]
    gstate.card_envoys_on_surface = _.without gstate.card_envoys_on_surface, $card_envoy[0]
    $enemy_hand.data('cards').push $card_envoy.data 'card'

    # animate away
    duration = 1000
    $card_envoy.css
      transition: "all #{duration}ms ease-in-out"
      transform: translate3d
        x: get_translate3d($enemy_hand).x
        y: get_translate3d($enemy_hand).y

    plantTimeout duration, ->
      $card_envoy.remove()
      $card_envoy.css transition: ''
      check_hand_solved $enemy_hand
      cb?()

  # (card) card
  # (enemy_hand) unwrapped DOM element
  enemy_spit_card = (card, enemy_hand, cb) ->
    $enemy_hand = $(enemy_hand)
    $enemy_hand.data 'cards', _.without $enemy_hand.data('cards'), card
    $card_envoy = make_card_envoy card
    $card_envoy.addClass css_styles.claimed

    when_done = ->
      # add to game model
      gstate.card_envoys_on_surface.push $card_envoy[0]
      gstate.card_envoys_on_table.push $card_envoy[0]
      $card_envoy.removeClass(css_styles.claimed).addClass(css_styles.tabled_card)
      cb?()

    $card_envoy.css
      transform: translate3d
        x: get_translate3d($enemy_hand).x
        y: get_translate3d($enemy_hand).y

    duration = 500
    $card_envoy.css
      transition: "all #{duration}ms ease-in-out"
      transform: translate3d
        x: ($('#row2').width() - 200) * Math.random() + 50
        y: $('#row2').position().top + 18

    plantTimeout duration, ->
      $card_envoy.css transition: ''
      when_done()

    return $card_envoy

  ## devbox

  update_devbox_1 = ->
    $db1 = $('.devbox.1')
    hands_to_ns = (hands) -> _.map $(hands), (eh) -> '°°°°' + _.map $(eh).data('cards'), (card) -> card.n
    enemy_ns = hands_to_ns $('.enemy-hand')
    table_ns = _.map gstate.card_envoys_on_surface, (ce) -> $(ce).data('card').n
    player_ns = hands_to_ns $('.client-hand')
    newline = '<br>'
    $db1.html '' + newline + enemy_ns + newline + table_ns + newline + player_ns

  setInterval update_devbox_1, 100

  ## enemies

  random_enemy =
    spit: (cb) ->
      log 'random spit'
      $hand = $ _.first _.shuffle $('.enemy-hand')
      log $hand
      card = $hand.data('cards')[0]
      log card.n
      $card = enemy_spit_card card, $hand, cb

    claim: (cb) ->
      log 'random claim'
      $hand = _.filter $('.enemy-hand'), (enemy_hand) -> $(enemy_hand).data('cards').length is 3
      log $hand
      valid_cards = _.filter gstate.card_envoys_on_table, (c) -> not $(c).hasClass css_styles.touch_draggable_dragging
      $card = $ _.first _.shuffle valid_cards
      enemy_claim_card $card, $hand, cb


  one_enemy =
    spit: (cb) ->
      log 'one_enemy.spit'

      decide_move = (hand, card) ->
        log "T#{$(ce).data('card').n for ce in gstate.card_envoys_on_table} spitting #{card.n} from #{c.n for c in $(hand).data 'cards'}"
        enemy_spit_card card, $(hand), cb

      processed_hands = _.map $('.enemy-hand'), (eh) => hand: $(eh), ph: @process_hand $(eh).data 'cards'
      sorted_hphands = _.sortBy processed_hands, (hph) -> hph.ph.count
      sorted_hphands.reverse()

      log 'sorted_hphands', sorted_hphands

      for hph in sorted_hphands
        if hph.ph.count isnt 4
          if hph.ph.count > 1
            valid_card_envoys = _.filter gstate.card_envoys_on_table, (c) -> not $(c).hasClass css_styles.touch_draggable_dragging
            valid_cards = _.map valid_card_envoys, (card_envoy) -> $(card_envoy).data 'card'
            if _.include valid_cards, ((card) -> card.n is hph.ph.com.n)
              card = _.first _.shuffle _.filter $(hph.hand).data('cards'), (card) -> card.n isnt hph.ph.com.n
              return decide_move hph.hand, card
          else
            return decide_move hph.hand, _.first _.shuffle $(hph.hand).data 'cards'

    claim: (cb) ->
      log 'one_enemy.claim'
      $hand = $ _.filter $('.enemy-hand'), (enemy_hand) -> $(enemy_hand).data('cards').length is 3
      valid_card_envoys = _.filter gstate.card_envoys_on_table, (c) -> not $(c).hasClass css_styles.touch_draggable_dragging
      ph = @process_hand $hand.data 'cards'
      matched_card_envoys = _.filter valid_card_envoys, (card_envoy) -> $(card_envoy).data('card').n is ph.com.n
      if matched_card_envoys.length
        $card = $ _.first _.shuffle matched_card_envoys
      else
        $card = $ _.first _.shuffle valid_card_envoys
      log "T#{$(ce).data('card').n for ce in gstate.card_envoys_on_table} claiming #{$card.data('card').n} to #{c.n for c in $hand.data 'cards'}"
      enemy_claim_card $card, $hand, cb

    process_hand: (cards) ->
      sum = (a) -> _.reduce a, ((memo, num) -> +memo+(+num)), 0
      counts = (sum(c.n is c0.n for c0 in cards) for c in cards)
      return {
        com: cards[_.indexOf counts, _.max counts]
        counts: counts
        count: _.max counts
        cards: cards }

    process_hand_test: ->
      cards = deck.slice 0, 4
      [log c.n for c in cards]
      log @process_hand cards

  log 'phtA'
  one_enemy.process_hand_test()
  log 'phtZ'

  active_enemy = one_enemy

  do enemy_loop = ->
    # TODO set this to 1400
    duration = 0
    wait = (cb) -> plantTimeout Math.random() * duration, cb
    log 'A'
    active_enemy.spit ->
      wait active_enemy.claim ->
        wait enemy_loop
