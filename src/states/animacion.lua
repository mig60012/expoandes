local animacion = {}

local FONT_PATH = "assets/AntonSC-Regular.ttf"
local DEFAULT_TRANSITION_DURATION = 0.35
local DEFAULT_FONT_SIZE = 24
local ARROW_WIDTH = 18
local ARROW_HEIGHT = 28

local function load_slides(slides)
  assert(type(slides) == "table" and #slides > 0, "animacion needs a non-empty slides table")

  local loaded = {}
  for index, slide in ipairs(slides) do
    assert(type(slide) == "table", "animation slide " .. index .. " must be a table")
    assert(slide.text == nil or type(slide.text) == "string",
      "animation slide " .. index .. " text must be a string")

    local image = slide.image
    if type(image) == "string" then
      image = love.graphics.newImage(image)
    elseif image ~= nil then
      assert(type(image) == "userdata" and image.getDimensions,
        "animation slide " .. index .. " image must be an image path or a LÖVE Image")
    end

    loaded[index] = {
      image = image,
      text = slide.text or "",
    }
  end

  return loaded
end

local function draw_arrow(x, y, direction)
  local tip_x = x + direction * ARROW_WIDTH / 2
  local base_x = x - direction * ARROW_WIDTH / 2
  love.graphics.setColor(1, 1, 1, 1)
  love.graphics.polygon("fill",
    tip_x, y,
    base_x, y - ARROW_HEIGHT / 2,
    base_x, y + ARROW_HEIGHT / 2)
end

local function draw_slide(slide, offset, layout, font)
  love.graphics.push()
  love.graphics.translate(offset, 0)

  love.graphics.setColor(0, 0, 0, 1)
  love.graphics.rectangle("fill", layout.image_x, layout.image_y, layout.image_size, layout.image_size)
  love.graphics.setColor(0.65, 0.65, 0.65, 1)
  love.graphics.rectangle("line", layout.image_x, layout.image_y, layout.image_size, layout.image_size)

  if slide.image then
    local image_width, image_height = slide.image:getDimensions()
    local image_area = math.max(1, layout.image_size - 24)
    local scale = math.min(
      image_area / image_width,
      image_area / image_height
    )
    local width = image_width * scale
    local height = image_height * scale
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.draw(
      slide.image,
      layout.image_x + (layout.image_size - width) / 2,
      layout.image_y + (layout.image_size - height) / 2,
      0,
      scale,
      scale
    )
  end

  love.graphics.setColor(0.08, 0.08, 0.08, 1)
  love.graphics.rectangle("fill", layout.dialog_x, layout.dialog_y, layout.dialog_width, layout.dialog_height)
  love.graphics.setColor(0.65, 0.65, 0.65, 1)
  love.graphics.rectangle("line", layout.dialog_x, layout.dialog_y, layout.dialog_width, layout.dialog_height)
  love.graphics.setColor(1, 1, 1, 1)
  love.graphics.setFont(font)
  love.graphics.printf(
    slide.text,
    layout.dialog_x + layout.padding,
    layout.dialog_y + layout.padding,
    layout.dialog_width - layout.padding * 2,
    "left"
  )

  love.graphics.pop()
end

function animacion:enter(context, slides, options)
  options = options or {}
  assert(type(options) == "table", "animation options must be a table")

  local transition_duration = options.transitionDuration or DEFAULT_TRANSITION_DURATION
  local font_size = options.fontSize or DEFAULT_FONT_SIZE
  assert(type(transition_duration) == "number" and transition_duration > 0,
    "animation transitionDuration must be a positive number")
  assert(type(font_size) == "number" and font_size > 0,
    "animation fontSize must be a positive number")
  assert(options.onComplete == nil or type(options.onComplete) == "function",
    "animation onComplete must be a function")

  self.context = context
  self.slides = load_slides(slides)
  self.current_index = 1
  self.transition = nil
  self.transition_duration = transition_duration
  self.on_complete = options.onComplete
  self.font = love.graphics.newFont(FONT_PATH, font_size)
end

function animacion:update(dt)
  if not self.transition then
    return
  end

  self.transition.elapsed = math.min(self.transition.elapsed + dt, self.transition_duration)
  if self.transition.elapsed >= self.transition_duration then
    self.current_index = self.transition.target
    self.transition = nil
  end
end

function animacion:draw()
  local width, height = love.graphics.getDimensions()
  local margin = math.max(24, width * 0.05)
  local dialog_height = math.min(160, height * 0.22)
  local dialog_y = height - dialog_height - margin
  local image_size = math.max(1, math.min(width * 0.5, dialog_y - margin * 2))
  local layout = {
    image_x = (width - image_size) / 2,
    image_y = margin,
    image_size = image_size,
    dialog_x = margin,
    dialog_y = dialog_y,
    dialog_width = width - margin * 2,
    dialog_height = dialog_height,
    padding = 18,
  }

  love.graphics.clear(0, 0, 0, 1)
  love.graphics.setColor(1, 1, 1, 1)

  if self.transition then
    local progress = self.transition.elapsed / self.transition_duration
    local direction = self.transition.direction
    local travel = width * progress
    draw_slide(self.slides[self.current_index], direction * travel, layout, self.font)
    draw_slide(self.slides[self.transition.target], -direction * (width - travel), layout, self.font)
  else
    draw_slide(self.slides[self.current_index], 0, layout, self.font)
  end

  if self.current_index > 1 then
    draw_arrow(margin / 2, layout.image_y + image_size / 2, -1)
  end
  if self.current_index < #self.slides or self.on_complete then
    draw_arrow(width - margin / 2, layout.image_y + image_size / 2, 1)
  end

  love.graphics.setColor(1, 1, 1, 1)
end

function animacion:show_slide(index)
  if self.transition or index < 1 or index == self.current_index then
    return
  end

  if index > #self.slides then
    if self.on_complete then
      self.on_complete()
    end
    return
  end

  self.transition = {
    target = index,
    direction = index > self.current_index and 1 or -1,
    elapsed = 0,
  }
end

function animacion:keypressed(key)
  if key == "right" or key == "d" then
    self:show_slide(self.current_index + 1)
  elseif key == "left" or key == "a" then
    self:show_slide(self.current_index - 1)
  end
end

function animacion:mousepressed(x, y, button)
  if button ~= 1 or self.transition then
    return
  end

  local width = love.graphics.getWidth()
  local margin = math.max(24, width * 0.05)
  if x < margin then
    self:show_slide(self.current_index - 1)
  elseif x > width - margin then
    self:show_slide(self.current_index + 1)
  end
end

return animacion
