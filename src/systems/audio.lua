-- Audio del juego.
-- Los efectos cortos se reproducen como copias independientes. La musica y los
-- ambientes largos se reproducen como streams en bucle, usando un canal propio.
--
-- Cada efecto se carga una vez y cada reproduccion usa una copia (clone), asi
-- varios sonidos pueden sonar a la vez sin cortarse entre si. Si el archivo no
-- existe o no hay audio (por ejemplo en las pruebas), no pasa nada: el juego
-- sigue en silencio.
local Audio = {}

local CARPETA = "assets/audio/"

-- volumen      : 0 a 1
-- variacion    : cuanto puede cambiar el tono al azar (0.05 = +-5 %), para que
--                el mismo sonido repetido no suene identico
-- enfriamiento : segundos minimos entre dos reproducciones (evita que varias
--                cartas girando en el mismo instante suenen como un solo golpe
--                mas fuerte)
local EFECTOS = {
  card_flip  = { archivo = "card_flip.ogg",  volumen = 0.8, variacion = 0.05, enfriamiento = 0.05 },
  chip_place = { archivo = "chip_place.ogg", volumen = 0.9, variacion = 0.04 },
  clack      = { archivo = "clack.ogg",      volumen = 0.7, variacion = 0.03, enfriamiento = 0.03 },
  ball_spin  = { archivo = "ball_spin.ogg",  volumen = 0.6 },
  card_shuffle = { archivo = "oxidvideos-shuffling-deck-of-cards-522518.mp3", volumen = 0.7, enfriamiento = 0.15 },
  coins = { archivo = "alexzavesa-clinking-coins-4-468430.mp3", volumen = 0.75, variacion = 0.04, enfriamiento = 0.08 },
  door_open = { archivo = "dragon-studio-opening-door-450444.mp3", volumen = 0.75, enfriamiento = 0.1 },
  door_close = { archivo = "freesound_community-automatic-door-81081.mp3", volumen = 0.65, enfriamiento = 0.1 },
  failure = { archivo = "freesound_community-failure-drum-sound-effect-2-7184.mp3", volumen = 0.65, enfriamiento = 0.2 },
  footstep_1 = { archivo = "yarzur_ofc-st1-footstep-sfx-323053.mp3", volumen = 0.35, variacion = 0.03, enfriamiento = 0.08 },
  footstep_2 = { archivo = "yarzur_ofc-st2-footstep-sfx-323055.mp3", volumen = 0.35, variacion = 0.03, enfriamiento = 0.08 },
  footstep_3 = { archivo = "yarzur_ofc-st3-footstep-sfx-323056.mp3", volumen = 0.35, variacion = 0.03, enfriamiento = 0.08 },
}

local BUCLES = {
  menu_music = {
    archivo = "Musica menu.mp3", volumen = 0.42, canal = "musica",
  },
  casino_music = {
    archivo = "casino_music.wav", volumen = 0.30, canal = "musica",
  },
  casa_ambiente = {
    archivo = "soundsforyou-the-ambience-room-tone-139064.mp3", volumen = 0.18, canal = "ambiente",
  },
  calle_ambiente = {
    archivo = "freesound_community-city-street-downtown-52115.mp3", volumen = 0.22, canal = "ambiente",
  },
  casino_ambiente = {
    archivo = "freesound_community-bruit-2-casino-56939.mp3", volumen = 0.22, canal = "ambiente",
  },
}

local fuentes, bucles, ultima_vez = {}, {}, {}

local function hay_audio()
  return love and love.audio and love.audio.newSource and true or false
end

local function cargar(nombre, definiciones, tipo)
  local efecto = definiciones[nombre]
  if not efecto or not hay_audio() then
    return nil
  end
  if fuentes[nombre] == nil then
    local ok, fuente = pcall(love.audio.newSource, CARPETA .. efecto.archivo, tipo or "static")
    fuentes[nombre] = ok and fuente or false
  end
  return fuentes[nombre] or nil
end

-- Reproduce un efecto y devuelve su Source (o nil si no sono), por si hay que
-- detenerlo despues con Audio.detener.
-- opciones.tono    : multiplica la velocidad/tono (1 = normal)
-- opciones.volumen : multiplica el volumen del efecto (1 = normal)
function Audio.reproducir(nombre, opciones)
  opciones = opciones or {}
  local efecto, base = EFECTOS[nombre], cargar(nombre, EFECTOS)
  if not base then
    return nil
  end

  local ahora = love.timer and love.timer.getTime()
  if ahora and efecto.enfriamiento and ultima_vez[nombre] and ahora - ultima_vez[nombre] < efecto.enfriamiento then
    return nil
  end

  local ok, fuente = pcall(function()
    local copia = base:clone()
    local tono = opciones.tono or 1
    if efecto.variacion then
      tono = tono * (1 + (math.random() * 2 - 1) * efecto.variacion)
    end
    copia:setVolume(efecto.volumen * (opciones.volumen or 1))
    copia:setPitch(tono)
    copia:play()
    return copia
  end)
  if not ok then
    return nil
  end
  ultima_vez[nombre] = ahora
  return fuente
end

function Audio.detener(fuente)
  if fuente then
    pcall(fuente.stop, fuente)
  end
end

-- Inicia un ambiente o una musica larga. Solo hay una pista activa por canal:
-- entrar en una nueva zona reemplaza la pista anterior sin dejarla sonando.
function Audio.iniciar_bucle(nombre, opciones)
  opciones = opciones or {}
  local bucle = BUCLES[nombre]
  local base = cargar(nombre, BUCLES, "stream")
  if not bucle or not base then
    return nil
  end

  local canal = opciones.canal or bucle.canal
  local activo = bucles[canal]
  if activo and activo.nombre == nombre then
    local ok, sonando = pcall(function() return activo.fuente:isPlaying() end)
    if ok and sonando then
      pcall(function()
        activo.fuente:setVolume(bucle.volumen * (opciones.volumen or 1))
      end)
      return activo.fuente
    end
  end
  Audio.detener_canal(canal)

  local ok, fuente = pcall(function()
    base:setLooping(true)
    base:setVolume(bucle.volumen * (opciones.volumen or 1))
    base:play()
    return base
  end)
  if not ok then
    return nil
  end
  bucles[canal] = { nombre = nombre, fuente = fuente }
  return fuente
end

function Audio.detener_canal(canal)
  local activo = bucles[canal]
  if activo and activo.fuente then
    pcall(function() activo.fuente:stop() end)
  end
  bucles[canal] = nil
end

function Audio.detener_todo()
  for canal in pairs(bucles) do
    Audio.detener_canal(canal)
  end
end

-- Duracion en segundos del archivo de un efecto (nil si no se pudo cargar).
function Audio.duracion(nombre)
  local base = cargar(nombre, EFECTOS)
  if not base then
    return nil
  end
  local ok, segundos = pcall(base.getDuration, base, "seconds")
  return ok and segundos or nil
end

return Audio
