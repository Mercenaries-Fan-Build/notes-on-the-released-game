-- mrxjc2sportscar — adds the JC2 Sportscar to Eva's faction support stores.
--
-- Corrected against the real resident scripts (docs/mercs2-luacd/src/resident):
--   * Shop factions are the SELLING factions "All"/"Chi"/"Gur"/"Pir" (mrxrewarddata _tRewards),
--     NEVER "Pmc" — so we surface the item for ANY faction the shop is opened with.
--   * mrxshop._GetShopList shows BOTH locked and unlocked items, so an item only needs to be in
--     the returned support list AND have a valid MrxSupportData.tSupportData[key] to APPEAR;
--     oSupport (mrxcratedelivery) is only needed to BUY it, so it's added best-effort.
--   * Entry shape mirrors a real "Light" ground vehicle (buggypr): sName/sDescription/sIcon/
--     nMaxStock/nCashCost/nFuelCost/oSupport/sType + tUnlockStatus per faction.
--
-- Pulled via mrxshop's DEPS (empty own-DEPS → no cycle); runs after MrxSupportData/MrxRewardData
-- are loaded, so they are reachable as globals here.

-- Modules run in ISOLATED environments (engine _SYS._IMPORT: loadstring into a NEW env, stored in
-- _MODULES) — so we MUST import() everything we touch; a bare `MrxSupportData` would be nil here.
-- These are already loaded (mrxshop's DEPS pulls them before us), so import() returns the cached,
-- SHARED module tables — patching their functions affects every caller. No chunk-DEPS needed (that
-- would risk the mrxshop<->mrxsupportdata cycle); the runtime import() resolves the already-loaded ones.
import("MrxSupportData")
import("MrxRewardData")
import("mrxcratedelivery")

local STORE_KEY = "jc2sportscar"
local CARGO = "JC2 Sportscar" -- the minted worldentity template (Name COMP → handle 0x8000B3C5)

Debug.Printf("JC2SPORTSCAR: chunk loaded")

local function addEntry()
  if not (MrxSupportData and MrxSupportData.tSupportData) then return end
  if MrxSupportData.tSupportData[STORE_KEY] then return end
  local entry = {
    sName        = "JC2 Sportscar",
    sDescription = "An imported high-performance coupe.",
    sIcon        = "vehicles_scorpion",       -- reuse an existing car icon
    nMaxStock    = 99,
    nCashCost    = 0,                          -- free
    nFuelCost    = 0,
    sType        = "Light",                    -- light ground vehicle
    tUnlockStatus = { All = 1, Chi = 1, Gur = 1, Pir = 1 }, -- unlocked in every faction store
  }
  -- Delivery is optional for the item to APPEAR; add it if mrxcratedelivery is reachable so it
  -- can actually be bought (crate air-drop of our template).
  local ok, oSupport = pcall(function()
    local o = mrxcratedelivery:Create()
    o:SetCargo(CARGO)
    return o
  end)
  if ok and oSupport then entry.oSupport = oSupport end
  MrxSupportData.tSupportData[STORE_KEY] = entry
  Debug.Printf("JC2SPORTSCAR: entry added (delivery=" .. tostring(ok) .. ")")
end

-- Add now (mrxsupportdata is loaded before us via mrxshop's DEPS) and again on any later Init().
addEntry()
if MrxSupportData and MrxSupportData.Init then
  local _origInit = MrxSupportData.Init
  MrxSupportData.Init = function(...)
    if _origInit then _origInit(...) end
    addEntry()
  end
end

-- Surface the key in the shop list for every faction store (GetAllPotentialShopItems caches per
-- faction and returns the same list each call, so a dedup-guarded append persists).
if MrxRewardData and MrxRewardData.GetAllPotentialShopItems then
  local _origGet = MrxRewardData.GetAllPotentialShopItems
  MrxRewardData.GetAllPotentialShopItems = function(sFactionId)
    local tSupport, tEquipment = _origGet(sFactionId)
    if tSupport and MrxSupportData and MrxSupportData.tSupportData[STORE_KEY] then
      local found = false
      for _, id in ipairs(tSupport) do
        if id == STORE_KEY then found = true break end
      end
      if not found then
        table.insert(tSupport, STORE_KEY)
        Debug.Printf("JC2SPORTSCAR: surfaced in " .. tostring(sFactionId) .. " shop")
      end
    end
    return tSupport, tEquipment
  end
end
