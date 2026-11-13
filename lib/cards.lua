--- Generic Love2D library for cards, decks, and hands.
-- It owns no Love callbacks and creates no globals.
local Cards = {}

local SUITS = { "hearts", "spades", "diamonds", "clubs" }
local SUIT_INDEX = { hearts = 0, spades = 1, diamonds = 2, clubs = 3 }
local CARD_WIDTH, CARD_HEIGHT = 56, 80
local EXCITEMENT_DURATION = 1

-- Easing local: la librería sigue siendo autocontenida y no depende de un
-- scheduler externo. OutBack da el pequeño sobrepaso que hace tangible cada
-- reparto; OutExpo hace que la salida del mazo se sienta instantánea.
local function out_back(t)
    local c1, c3 = 1.70158, 2.70158
    return 1 + c3 * (t - 1) ^ 3 + c1 * (t - 1) ^ 2
end

local function out_expo(t)
    if t >= 1 then return 1 end
    return 1 - 2 ^ (-10 * t)
end

local function lerp(a, b, t)
    return a + (b - a) * t
end

-- A deliberately asymmetric envelope: it reaches its peak quickly, then
-- settles down more lazily.  It is shared by all three visual objects.
local function update_excitement(object, dt)
    if not object.excitement_duration then return end
    object.excitement_time = math.min(object.excitement_time + dt, object.excitement_duration)

    local progress = object.excitement_time / object.excitement_duration
    if progress < 0.2 then
        local rise = progress / 0.2
        object.excitement = 1 - (1 - rise) ^ 3
    else
        local fall = (progress - 0.2) / 0.8
        object.excitement = (1 - fall) ^ 0.65
    end

    if progress >= 1 then
        object.excitement, object.excitement_time, object.excitement_duration = 0, 0, nil
    end
end

local function start_excitement(object, duration)
    object.excitement_time = 0
    object.excitement_duration = math.max(duration or EXCITEMENT_DURATION, 0.01)
    object.excitement = 0
end

local function class()
    local type = {}
    type.__index = type
    return type
end
local function new(type, ...)
    local object = setmetatable({}, type)
    if object.init then object:init(...) end
    return object
end

local Card = class()
function Card:init(definition, deck)
    for key, value in pairs(definition) do self[key] = value end
    self.deck, self.atlas = deck, deck.atlas
    self.visible, self.turning, self.turn_factor = false, false, 0
    self.turned, self.random = true, math.random() * math.pi * 2
    self.x, self.y = 0, 0
    self.rotation, self.scale, self.deal = 0, 1, nil
    self.excitement = 0
    if self.atlas and self.rank and self.suit then
        self.front = love.graphics.newQuad(self.rank * CARD_WIDTH, SUIT_INDEX[self.suit] * CARD_HEIGHT,
            CARD_WIDTH, CARD_HEIGHT, self.atlas)
    end
    if self.atlas then
        local column = definition.back_column or deck.back_column or 0
        self.back = love.graphics.newQuad(0, (2 + column) * CARD_HEIGHT,
            CARD_WIDTH, CARD_HEIGHT, self.atlas)
    end
end

function Card:turn(progress)
    self.turning, self.turn_factor, self.turned = true, progress or 0, false
end

--- Animate the card from a deck position to its final screen position.
--- The destination is supplied by the table layout, keeping this generic
--- card module independent from any specific poker screen.
function Card:deal_from(from_x, from_y, to_x, to_y, options)
    options = options or {}
    self.deal = {
        from_x = from_x, from_y = from_y,
        to_x = to_x, to_y = to_y,
        delay = options.delay or 0,
        duration = options.duration or 0.48,
        time = 0,
        start_rotation = options.rotation or (math.random() - 0.5) * 0.38,
        on_arrive = options.on_arrive,
    }
end

function Card:is_dealing()
    return self.deal ~= nil
end

--- Give this card a short, purely visual burst of energy.
function Card:exite(duration)
    start_excitement(self, duration)
end

Card.excite = Card.exite

function Card:update(dt)
    update_excitement(self, dt)
    if self.deal then
        local deal = self.deal
        deal.time = deal.time + dt
        if deal.time >= deal.delay + deal.duration then
            self.deal = nil
            if deal.on_arrive then deal.on_arrive(self) end
        end
    end
    if not self.turning then return end
    self.turn_factor = self.turn_factor + dt * (self.animation_speed or self.deck.animation_speed)
        * (1 + self.excitement * 2.5)
    if self.turn_factor > 0.5 and not self.turned then
        self.turned, self.visible = true, not self.visible
        self.random = self.random + math.pi
        if self.sound then
            self.sound:setPitch(math.random() + 0.95)
            self.sound:stop(); self.sound:play()
        end
    end
    if self.turn_factor > 1 then self.turning = false end
end

local function draw_card_image(card, x, y, rotation, scale, shadow_height, rotate)
    local image = card.visible and card.front or card.back
    if not image then return end

    local shadow_scale = 1 + shadow_height / 90
    love.graphics.setColor(0, 0, 0, 0.20 * shadow_scale)
    love.graphics.ellipse("fill", x, y + CARD_HEIGHT * 0.48 + shadow_height * 0.12,
        CARD_WIDTH * 0.42 * shadow_scale, CARD_HEIGHT * 0.11 * shadow_scale)
    love.graphics.setColor(1, 1, 1, 1)

    love.graphics.push()
    love.graphics.translate(x, y - shadow_height)
    love.graphics.rotate(rotation)
    love.graphics.scale(scale, scale)
    if card.turning then
        love.graphics.scale(card.turned and (card.turn_factor * 2 - 1) or (1 - card.turn_factor * 2), 1)
    end
    if rotate then
        love.graphics.rotate(math.sin(card.random + love.timer.getTime() * math.pi / 8) / 4)
    end
    love.graphics.draw(card.atlas, image, -CARD_WIDTH / 2, -CARD_HEIGHT / 2)
    love.graphics.pop()
end

--- Draw at an absolute screen position. Used by poker tables which need a
--- card to temporarily ignore its hand while flying from the deck.
function Card:draw_at(x, y, options)
    if not self.atlas or not self.front or not self.back then return end
    options = options or {}
    local scale, rotation, height = options.scale or 1, options.rotation or 0, 0
    local draw_x, draw_y = x, y

    if self.deal then
        local deal = self.deal
        local progress = math.max(0, math.min(1, (deal.time - deal.delay) / deal.duration))
        local travel = out_expo(progress)
        local settle = out_back(progress)
        draw_x = lerp(deal.from_x, deal.to_x, travel)
        draw_y = lerp(deal.from_y, deal.to_y, settle)
        rotation = lerp(deal.start_rotation, rotation, settle)
        scale = scale * (1 + math.sin(progress * math.pi) * 0.16)
        height = math.sin(progress * math.pi) * 34
    else
        -- Pequeñas imperfecciones humanas: ninguna carta queda perfectamente
        -- geométrica sobre la mesa.
        rotation = rotation + math.sin(love.timer.getTime() * 0.9 + self.random) * 0.018
        draw_y = draw_y + math.sin(love.timer.getTime() * 1.2 + self.random) * 1.2
    end

    self.x, self.y = draw_x, draw_y
    self.rotation, self.scale = rotation, scale
    draw_card_image(self, draw_x, draw_y, rotation, scale, height, options.rotate)
end

function Card:draw(rotate)
    if not self.atlas or not self.front or not self.back then return end
    self.x, self.y = love.graphics.transformPoint(0, 0)
    self:draw_at(0, 0, { scale = 1.5 + 0.5 * self.excitement, rotate = rotate })
end

local Deck = class()
function Deck:init(config, definitions)
    self.atlas, self.sound = config.atlas, config.sound
    self.animation_speed = config.animation_speed or 7
    self.back_column, self.cards_list, self.game_cards = config.back_column or 0, {}, {}
    for _, definition in ipairs(definitions) do
        local card = new(Card, definition, self)
        self.cards_list[#self.cards_list + 1] = card
        self.game_cards[#self.game_cards + 1] = card
    end
    self.x, self.y = 0, 0
    self.excitement = 0
    self.position = { x = 0, y = 0, scale = 1 }
    self.shuffle_time, self.shuffle_duration = 0, 0
end

function Deck:count() return #self.game_cards end

function Deck:shuffle(iterations)
    for _ = 1, iterations or 2 do
        for i = #self.game_cards, 2, -1 do
            local j = math.random(i)
            self.game_cards[i], self.game_cards[j] = self.game_cards[j], self.game_cards[i]
        end
    end
    self.shuffle_time, self.shuffle_duration = 0, 0.52
end

function Deck:set_position(x, y, scale)
    self.position.x, self.position.y = x, y
    self.position.scale = scale or 1
end

function Deck:draw_card()
    local card = table.remove(self.game_cards)
    if card then card:turn() end
    return card
end

--- Make the deck feel lively without changing its contents or order.
function Deck:exite(duration)
    start_excitement(self, duration)
end

Deck.excite = Deck.exite

Deck.pick = Deck.draw_card
function Deck:return_card(card)
    assert(card and card.deck == self, "card does not belong to this deck")
    self.game_cards[#self.game_cards + 1] = card
end

function Deck:reset()
    self.game_cards = {}
    for _, card in ipairs(self.cards_list) do
        card.visible, card.turning = false, false
        self.game_cards[#self.game_cards + 1] = card
    end
end

function Deck:update(dt)
    update_excitement(self, dt)
    self.shuffle_time = math.min(self.shuffle_time + dt, self.shuffle_duration)
    for _, card in ipairs(self.game_cards) do card:update(dt) end
end

--- Draw a compact physical pile instead of every remaining card in the deck.
function Deck:draw_pile()
    local card = self.game_cards[#self.game_cards]
    if not card then return end
    local progress = self.shuffle_duration > 0 and self.shuffle_time / self.shuffle_duration or 1
    local shake = progress < 1 and math.sin(progress * math.pi * 12) * (1 - progress) * 13 or 0
    local x, y, scale = self.position.x + shake, self.position.y, self.position.scale
    for layer = 3, 1, -1 do
        card:draw_at(x - layer * 2, y - layer * 2, { scale = scale, rotation = 0 })
    end
end

function Deck:draw()
    love.graphics.push()
    for _, card in ipairs(self.game_cards) do
        card:draw(false)
        self.x, self.y = love.graphics.transformPoint(0, 0)
        local energy = self.excitement
        love.graphics.translate(0.25 + math.sin(love.timer.getTime() * 19) * 0.8 * energy,
            -0.5 + math.cos(love.timer.getTime() * 17) * 0.7 * energy)
    end
    love.graphics.pop()
end

local Hand = class()
function Hand:init(config)
    self.animation_speed = config.animation_speed or 7
    self.vertical_movement = config.vertical_movement or 10
    self.cards, self.x, self.y, self.hover_card = {}, 0, 0, -1
    self.exited = 0
    self.max_exited = 3
    self.excitement = 0
end

function Hand:add(card)
    assert(card and card.deck, "a hand can only contain a card")
    self.cards[#self.cards + 1] = card
end

function Hand:draw_card(deck, amount)
    for _ = 1, amount or 1 do
        local card = deck:draw_card()
        if not card then break end
        self:add(card)
    end
end

Hand.pick = Hand.draw_card
function Hand:remove(index)
    local card = table.remove(self.cards, index)
    if card then card.deck:return_card(card) end
    return card
end

--- Excite the whole hand: spacing, bobbing, speed, and scale all respond.
function Hand:exite(duration)
    start_excitement(self, duration)
end

Hand.excite = Hand.exite

function Hand:update(dt)
    update_excitement(self, dt)
    for _, card in ipairs(self.cards) do card:update(dt) end
    if not love.mouse then return end
    local mx, my = love.mouse.getPosition(); self.hover_card = -1
    --    for i, card in ipairs(self.cards) do
    --        if (mx - card.x) ^ 2 + (my - card.y) ^ 2 < 35 ^ 2 then self.hover_card = i end
    --    end
    if self.exited > 0 then
        self.exited = self.exited - dt
    end
end

function Hand:draw(width)
    self.x, self.y = love.graphics.transformPoint(0, 0)
    if #self.cards == 0 then return end
    local energy = self.excitement
    local hand_width = width * (1 + 0.4 * energy)
    local spacing = hand_width / #self.cards
    local movement = self.vertical_movement * (1 + 2.5 * energy)
    local speed = self.animation_speed * (1 + 0.18 * energy)
    for i, card in ipairs(self.cards) do
        love.graphics.push()
        love.graphics.translate(spacing * (i - 0.5) - hand_width / 2,
            i == self.hover_card and -18 or
            movement * math.sin(love.timer.getTime() / 5 * speed + card.random))
        local card_scale = 1 + 0.25 * energy
        love.graphics.scale(card_scale, card_scale)
        card:draw(true); love.graphics.pop()
    end
end

--- Absolute variant used by perspective poker tables. It keeps hands simple
--- while allowing cards in a hand to be independently animated in world space.
function Hand:draw_at(x, y, width, options)
    options = options or {}
    local scale = options.scale or 1
    local shear = options.shear or 0
    local spacing = width / math.max(#self.cards, 1)
    for index, card in ipairs(self.cards) do
        local local_x = spacing * (index - 0.5) - width / 2
        local target_x = x + local_x * scale
        local target_y = y + math.abs(local_x) * math.abs(shear) * 0.18
        card:draw_at(target_x, target_y, {
            scale = scale,
            rotation = shear * (index == 1 and -0.10 or 0.10),
            rotate = false,
        })
    end
end

function Hand:click()
    if self.hover_card < 1 then return false end
    self:remove(self.hover_card); self.hover_card = -1
    return true
end

local function standard_definitions()
    local definitions = {}
    for _, suit in ipairs(SUITS) do
        for rank = 1, 13 do definitions[#definitions + 1] = { rank = rank, suit = suit } end
    end
    return definitions
end

--- Create a card/deck/hand factory. No deck is created automatically.
-- `options.cards` may provide arbitrary card definitions. If omitted, a
-- standard 52-card set is used by create_deck().
function Cards.new(options)
    options = options or {}
    local factory = {
        atlas = options.atlas,
        sound = options.sound,
        animation_speed = options.animation_speed or 7,
        back_column = options.back_column or 0,
    }
    if not factory.atlas and options.atlas_path then factory.atlas = love.graphics.newImage(options.atlas_path) end
    if factory.sound == nil and options.sound_path then
        factory.sound = love.audio.newSource(options.sound_path, "static")
    end
    function factory:create_card(definition, deck)
        return new(Card, definition, deck)
    end

    function factory:create_deck(definitions)
        return new(Deck, self, definitions or standard_definitions())
    end

    function factory:create_hand()
        return new(Hand, self)
    end

    return factory
end

Cards.Card, Cards.Deck, Cards.Hand = Card, Deck, Hand
Cards.standard_definitions = standard_definitions
return Cards
