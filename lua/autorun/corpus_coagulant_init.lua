-- corpus_coagulant_init.lua — punto de entrada y manifest de carga de Coagulant (SHARED)
-- Único archivo en lua/autorun/: registra el módulo y carga el resto vía include()
-- en orden explícito. Boot pattern tomado de corpus_caliber_init.lua (el template
-- del ecosistema): AddCSLuaFile corre siempre en autorun; el boot se difiere a
-- "Initialize" porque gmod fusiona lua/autorun/ alfabéticamente entre addons y
-- "corpus_coagulant_init.lua" ordena ANTES que "corpus_registry.lua".
--
-- SCAFFOLD PRE-BLOCK 3: el diseño de dominio de Coagulant (heridas por zona,
-- sangrado, vitales, tratamiento — estilo ACE3) todavía no cerró su bloque
-- (CORPUS_Architecture.md §9, Block 3). Este árbol solo fija la estructura, el
-- boot, la degradación de soft-deps y el contrato público mínimo congelado
-- (patrón mock-first, corpus_flujo_trabajo.txt §3). Sin efecto de gameplay.

-- ============================================================
-- CONTRATO PÚBLICO DE COAGULANT (congelado pre-diseño; ver CORPUS_Architecture.md
-- §4-§5). Consumido por otros módulos vía Corpus.GetModule("coagulant"). Todo lo
-- demás colgado de la tabla es interno — off-contract por convención.
--
--   COAGULANT.ApplyBandage(ply) -> bool     -- tratamiento mínimo; es el callback
--                                              onUse del ítem registrado en Cargo
--                                              (§5 de la arquitectura). Stub hoy:
--                                              la semántica real llega con Block 3.
--   COAGULANT.Zones.*                        -- mapa hitgroup nativo -> zona clínica
--                                              (la vía de degradación sin Caliber)
--
--   Futuro (Block 3, no existe aún): eventos de estado clínico (§4).
-- ============================================================

-- ============================================================
-- Manifest de carga: orden explícito y determinista, nunca el alfabético implícito
-- de autorun. Los sub-archivos viven en lua/corpus_coagulant/<realm>/ (fuera de
-- lua/autorun/) para que ESTE init sea el único punto de carga. Regla: nunca
-- invocar hacia adelante en file-scope — los cruces van en hooks con guardas.
-- ============================================================
local SHARED = {
    "shared/corpus_coagulant_zones.lua",  -- zonas clínicas + mapa hitgroup->zona (puro)
    "shared/corpus_coagulant_dev.lua",    -- coagulant_selftest (verificación)
}
local SERVER_FILES = {
    "server/corpus_coagulant_core.lua",   -- estado clínico por jugador + hooks sustrato
    "server/corpus_coagulant_items.lua",  -- ítems médicos contra Cargo (soft-dep)
}
local CLIENT_FILES = {
    "client/corpus_coagulant_options.lua", -- tab único Corpus.UI.RegisterTab
}

local function inc(rel) include("corpus_coagulant/" .. rel) end
local function cs(rel)  AddCSLuaFile("corpus_coagulant/" .. rel) end

-- AddCSLuaFile no depende de Corpus: se hace siempre en la carga de autorun, para
-- que el cliente reciba los archivos aunque el boot quede diferido (ver abajo).
if SERVER then
    for _, f in ipairs(SHARED)       do cs(f) end
    for _, f in ipairs(CLIENT_FILES) do cs(f) end
end

-- Hard-dep: Coagulant depende de Corpus (única dep dura del ecosistema,
-- CORPUS_Architecture.md §2/§6). No se asume que ya cargó; se detecta. La sonda
-- cubre las primitivas que los sub-archivos usan en file-scope.
local function CorpusListo()
    return Corpus ~= nil and Corpus.RegisterModule ~= nil and Corpus.Log ~= nil
        and Corpus.OnReady ~= nil and (SERVER or Corpus.UI ~= nil)
end

-- Namespace: tabla única registrada. Todos los archivos del módulo cachean esta
-- misma referencia por side-effect (local COAGULANT = Corpus.GetModule("coagulant")).
-- Depende del invariante by-ref del registro (CORPUS_Architecture.md §3).
local function Boot()
    Corpus.RegisterModule("coagulant", {})

    if SERVER then
        for _, f in ipairs(SHARED)       do inc(f) end
        for _, f in ipairs(SERVER_FILES) do inc(f) end
    else
        for _, f in ipairs(SHARED)       do inc(f) end
        for _, f in ipairs(CLIENT_FILES) do inc(f) end
    end

    Corpus.Log("coagulant", "cargado (" .. (SERVER and "server" or "client") .. ") — scaffold pre-Block 3")
end

if CorpusListo() then
    -- lua refresh o montaje tardío: el framework ya está — boot inmediato
    Boot()
else
    -- Carga de mapa normal: diferir a "Initialize" (corre en ambos realms después
    -- de TODO autorun y antes de InitPostEntity), manteniendo las garantías: los
    -- tabs de UI llegan antes de PopulateToolMenu y los hooks registrados en Boot
    -- corren antes de la ready barrier.
    hook.Add("Initialize", "corpus_coagulant_boot", function()
        hook.Remove("Initialize", "corpus_coagulant_boot")
        if CorpusListo() then
            Boot()
        else
            -- Sin el framework, el módulo no arranca (falla ruidoso, no silencioso).
            -- No se usa Corpus.Log aquí: Corpus no existe.
            MsgN("[Coagulant] Corpus framework no encontrado. Verificar que el addon corpus/ esté instalado y montado.")
        end
    end)
end
