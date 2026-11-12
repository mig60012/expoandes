--- Generic Love2D library for cards, decks, and hands.
-- It owns no Love callbacks and creates no globals.
local Cards = {}

local SUITS = { "hearts", "spades", "diamonds", "clubs" }
local SUIT_INDEX = { hearts = 0, spades = 1, diamonds = 2, clubs = 3 }
local CARD_WIDTH, CARD_HEIGHT = 56, 80

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

function Card:update(dt)
    if not self.turning then return end
    self.turn_factor = self.turn_factor + dt * (self.animation_speed or self.deck.animation_speed)
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

function Card:draw(rotate)
    if not self.atlas or not self.front or not self.back then return end
    self.x, self.y = love.graphics.transformPoint(0, 0)
    love.graphics.push()
    love.graphics.scale(1.5)
    if self.turning then
        love.graphics.scale(self.turned and (self.turn_factor * 2 - 1) or (1 - self.turn_factor * 2), 1)
    end
    if rotate then love.graphics.rotate(math.sin(self.random + love.timer.getTime() * math.pi / 8) / 4) end
    love.graphics.draw(self.atlas, self.visible and self.front or self.back, -CARD_WIDTH / 2, -CARD_HEIGHT / 2)
    love.graphics.pop()
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
end

function Deck:count() return #self.game_cards end

function Deck:shuffle(iterations)
    for _ = 1, iterations or 2 do
        for i = #self.game_cards, 2, -1 do
            local j = math.random(i)
            self.game_cards[i], self.game_cards[j] = self.game_cards[j], self.game_cards[i]
        end
    end
end

function Deck:draw_card()
    local card = table.remove(self.game_cards)
    if card then card:turn() end
    return card
end

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
    for _, card in ipairs(self.game_cards) do card:update(dt) end
end

function Deck:draw()
    love.graphics.push()
    for _, card in ipairs(self.game_cards) do
        card:draw(false)
        self.x, self.y = love.graphics.transformPoint(0, 0)
        love.graphics.translate(0.25, -0.5)
    end
    love.graphics.pop()
end

local Hand = class()
function Hand:init(config)
    self.animation_speed = config.animation_speed or 7
    self.cards, self.x, self.y, self.hover_card = {}, 0, 0, -1
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

function Hand:update(dt)
    for _, card in ipairs(self.cards) do card:update(dt) end
    if not love.mouse then return end
    local mx, my = love.mouse.getPosition(); self.hover_card = -1
    --    for i, card in ipairs(self.cards) do
    --        if (mx - card.x) ^ 2 + (my - card.y) ^ 2 < 35 ^ 2 then self.hover_card = i end
    --    end
end

function Hand:draw(width)
    self.x, self.y = love.graphics.transformPoint(0, 0)
    if #self.cards == 0 then return end
    local spacing = width / #self.cards
    for i, card in ipairs(self.cards) do
        love.graphics.push()
        love.graphics.translate(spacing * (i - 0.5) - width / 2, i == self.hover_card and -18 or 0)
        card:draw(true); love.graphics.pop()
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
