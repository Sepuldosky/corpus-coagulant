-- corpus_coagulant_init.lua — punto de entrada y manifest de carga de Coagulant (SHARED)
-- Único archivo en lua/autorun/: registra el módulo y carga el resto vía include()
-- en orden explícito. Boot pattern tomado de corpus_caliber_init.lua (el template
-- del ecosistema): AddCSLuaFile corre siempre en autorun; el boot se difiere a
-- "Initialize" porque gmod fusiona lua/autorun/ alfabéticamente entre addons y
-- "corpus_coagulant_init.lua" ordena ANTES que "corpus_registry.lua".
--
-- BLOCK 3 COMPLETO (los 4 slices de Coagulant_Architecture.md §15): sangre +
-- heridas + sangrado (slice 1), tratamiento con tiempo + 4 ítems (slice 2), debuffs
-- zonales (slice 3: cojera, sway, visión — verificados en juego) y la UI (slice 4:
-- silueta en el HUD, menú médico por zona, barra de tratamiento, barra de sangre en
-- el StatusPanel de Cargo y el tab Q con sus convars).

-- ============================================================
-- CONTRATO PÚBLICO DE COAGULANT (Coagulant_Architecture.md §8). Consumido por
-- otros módulos vía Corpus.GetModule("coagulant"). Todo lo demás colgado de la
-- tabla es interno — off-contract por convención.
--
--   COAGULANT.ApplyTreatment(ply, kind, zone) -> ok, err
--                                            -- inicia un tratamiento con tiempo
--                                               (§7): "bandage"|"tourniquet"|
--                                               "medkit"|"bloodbag"; zone nil =
--                                               automática; consumo AL COMPLETAR
--   COAGULANT.ApplyBandage(ply) -> bool      -- azúcar congelada del scaffold
--                                               (= ApplyTreatment "bandage";
--                                               true = el tratamiento ARRANCÓ)
--   COAGULANT.GetBlood(ply) -> 0..100        -- sangre actual
--   COAGULANT.IsBleeding(ply) -> bool        -- hay drenaje activo
--   COAGULANT.GetZoneScore(ply, zone) -> n   -- score de debuff de la zona
--   COAGULANT.OnEncumbrance(ply, fraction)   -- contrato congelado por Cargo
--                                              (movement); v1 almacena, sin efecto
--   COAGULANT.Zones.*                        -- mapa hitgroup nativo -> zona clínica
--                                              (la vía de degradación sin Caliber)
--
--   Eventos (hook.Run, server): Coagulant_WoundAdded / Coagulant_WoundClosed /
--   Coagulant_BloodCritical (+ Treatment* con el slice 2) — §8 de la arquitectura.
--
--   Estado replicado (§9), superficie de red estable:
--     NW2Float "coagulant_blood"      -- sangre 0..100 (barato, para HUD/StatusPanel)
--     NW2Float "coagulant_speed_mult" -- cojera; la APLICA el hook Move compartido
--                                        (shared/corpus_coagulant_move.lua), NUNCA
--                                        SetWalkSpeed: así compone con el
--                                        multiplicador de peso de Cargo (§6)
-- ============================================================

-- ============================================================
-- Manifest de carga: orden explícito y determinista, nunca el alfabético implícito
-- de autorun. Los sub-archivos viven en lua/corpus_coagulant/<realm>/ (fuera de
-- lua/autorun/) para que ESTE init sea el único punto de carga. Regla: nunca
-- invocar hacia adelante en file-scope — los cruces van en hooks con guardas.
-- ============================================================
local SHARED = {
    "shared/corpus_coagulant_zones.lua",  -- zonas clínicas + mapa hitgroup->zona (puro)
    "shared/corpus_coagulant_config.lua", -- convars + tablas de balance + funcs puras
    "shared/corpus_coagulant_move.lua",   -- hook Move: aplica la cojera (predicho: shared)
    "shared/corpus_coagulant_items.lua",  -- ítems contra Cargo — AMBOS realms: el grid
                                          -- cliente de Cargo renderiza desde defs locales
    "shared/corpus_coagulant_dev.lua",    -- coagulant_selftest + comandos de verificación
}
local SERVER_FILES = {
    "server/corpus_coagulant_core.lua",      -- estado clínico + creación de heridas + eventos
    "server/corpus_coagulant_bleeding.lua",  -- timer 1s: drenaje, regen, HP crítico, snapshot
    "server/corpus_coagulant_treatment.lua", -- tratamiento con tiempo + consumo al completar
    "server/corpus_coagulant_debuffs.lua",   -- tick 0.5s: cojera (NW2) + sway de brazos
}
local CLIENT_FILES = {
    "client/corpus_coagulant_hud.lua",     -- snapshot replicado + visión + silueta + StatusPanel
    "client/corpus_coagulant_medmenu.lua", -- menú médico (lee la silueta del HUD: va DESPUÉS)
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
        and Corpus.OnReady ~= nil and Corpus.Net ~= nil and (SERVER or Corpus.UI ~= nil)
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

    Corpus.Log("coagulant", "cargado (" .. (SERVER and "server" or "client") .. ") — Block 3 slice 4")
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
