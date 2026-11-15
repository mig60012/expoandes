-- Efectos de sonido del juego.
-- Un solo lugar para cargar y reproducir los sonidos cortos (fichas, cartas,
-- botones, pelota). Los estados solo llaman a Audio.reproducir("nombre").
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
}

local fuentes, ultima_vez = {}, {}

local function hay_audio()
  return love and love.audio and love.audio.newSource and true or false
end

local function cargar(nombre)
  local efecto = EFECTOS[nombre]
  if not efecto or not hay_audio() then
    return nil
  end
  if fuentes[nombre] == nil then
    local ok, fuente = pcall(love.audio.newSource, CARPETA .. efecto.archivo, "static")
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
  local efecto, base = EFECTOS[nombre], cargar(nombre)
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

-- Duracion en segundos del archivo de un efecto (nil si no se pudo cargar).
function Audio.duracion(nombre)
  local base = cargar(nombre)
  if not base then
    return nil
  end
  local ok, segundos = pcall(base.getDuration, base, "seconds")
  return ok and segundos or nil
end

return Audio
