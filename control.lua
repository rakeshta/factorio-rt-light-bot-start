--
--  control.lua
--  factorio-rt-light-bot-start
--
--  Created by Rakesh Ayyaswami on 04 Jan 2023.
--
--  Grants a light personal-bot starting loadout and auto-equips what fits
--  into the worn armour's equipment grid (grid size may vary with other mods).
--

--------------------------------------------------------------------------------
-- Loadout definition
--------------------------------------------------------------------------------

-- Balanced install order: keep roboports, batteries, and solars interleaved so
-- smaller grids still get a usable mix. Leftovers stay in inventory.
-- Sizes: roboport 2x2, battery 1x2, solar 1x1.
-- Totals: 2 roboports, 4 batteries, 9 solars.
local EQUIP_ORDER = {
  "personal-roboport-equipment", -- #1 construction
  "battery-equipment",           -- buffer for roboport #1
  "solar-panel-equipment",       -- early power
  "solar-panel-equipment",
  "solar-panel-equipment",
  "solar-panel-equipment",
  "battery-equipment",           -- buffer before second 2x2
  "personal-roboport-equipment", -- #2 if space remains
  "battery-equipment",
  "solar-panel-equipment",
  "solar-panel-equipment",
  "battery-equipment",
  "solar-panel-equipment",
  "solar-panel-equipment",
  "solar-panel-equipment",
}

--------------------------------------------------------------------------------
-- Bonus item table
--------------------------------------------------------------------------------

--- Build the full map of starting items, including optional startup-setting extras.
--- @return table<string, integer>
local function bonus_items()
  local items = {
    ["modular-armor"] = 1,
    ["personal-roboport-equipment"] = 2,
    ["battery-equipment"] = 4,
    ["solar-panel-equipment"] = 9,
    ["construction-robot"] = 40,
  }

  if settings.startup["rt-lbt-cliff-explosives"].value then
    items["cliff-explosives"] = 40
  end
  if settings.startup["rt-lbt-landfill"].value then
    items["landfill"] = 200
  end
  if settings.startup["rt-lbt-car"].value then
    items["car"] = 1
  end

  return items
end

--------------------------------------------------------------------------------
-- Freeplay integration
--------------------------------------------------------------------------------

--- True when the freeplay scenario exposes created-items get/set remotes.
local function has_freeplay_created_items()
  local freeplay = remote.interfaces["freeplay"]
  return freeplay and freeplay.get_created_items and freeplay.set_created_items
end

--- Merge our bonus items into freeplay's created-items list (keep the larger count).
local function register_freeplay_items()
  local items = remote.call("freeplay", "get_created_items")
  for name, count in pairs(bonus_items()) do
    if (not items[name]) or items[name] < count then
      items[name] = count
    end
  end
  remote.call("freeplay", "set_created_items", items)
end

--------------------------------------------------------------------------------
-- Inventory helpers
--------------------------------------------------------------------------------

--- Insert one item stack if the prototype exists.
local function insert_item(character, name, count)
  if not prototypes.item[name] then
    return
  end
  character.insert { name = name, count = count }
end

--- Insert every bonus item into the character's inventories.
local function insert_all_bonus_items(character)
  for name, count in pairs(bonus_items()) do
    insert_item(character, name, count)
  end
end

--- Prefer the live character; fall back to the cutscene body during freeplay intro.
local function character_for(player)
  return player.character or player.cutscene_character
end

--------------------------------------------------------------------------------
-- Auto-equip
--------------------------------------------------------------------------------

--- Wear modular armour when the armour slot is empty.
--- Consumes one modular-armor from the main inventory when freeplay already granted it.
local function wear_modular_armor(character, main_inventory)
  local armor_inv = character.get_inventory(defines.inventory.character_armor)
  if not armor_inv or not armor_inv.is_empty() then
    return
  end
  if not prototypes.item["modular-armor"] then
    return
  end

  if main_inventory and main_inventory.get_item_count("modular-armor") > 0 then
    main_inventory.remove { name = "modular-armor", count = 1 }
  end
  armor_inv.insert { name = "modular-armor", count = 1 }
end

--- Try to place one equipment piece into the grid.
--- Only removes a matching inventory item after a successful put, so failed
--- placements (full / fragmented grid) leave the spare in the backpack.
--- @return boolean true if the piece was installed
local function try_put_equipment(grid, main_inventory, name)
  if not prototypes.equipment[name] then
    return false
  end

  local placed = grid.put { name = name }
  if not placed then
    return false
  end

  if main_inventory and main_inventory.get_item_count(name) > 0 then
    main_inventory.remove { name = name, count = 1 }
  end
  return true
end

--- Walk EQUIP_ORDER and fill the grid. Skips entries that do not fit and keeps
--- going so smaller 1x1/1x2 pieces can still fill gaps after a failed 2x2 put.
local function fill_equipment_grid(grid, main_inventory)
  for _, name in ipairs(EQUIP_ORDER) do
    try_put_equipment(grid, main_inventory, name)
  end
end

--- Wear modular armour and install as much of the balanced equipment order as fits.
local function equip_starting_loadout(character)
  if not character or not character.valid then
    return
  end

  local main = character.get_main_inventory()
  wear_modular_armor(character, main)

  local grid = character.grid
  if not grid then
    return
  end

  fill_equipment_grid(grid, main)
end

--------------------------------------------------------------------------------
-- Player grant paths
--------------------------------------------------------------------------------

--- Non-freeplay / mid-game: insert every bonus item, then auto-equip what fits.
local function grant_and_equip(player)
  local character = character_for(player)
  if not character then
    return
  end
  insert_all_bonus_items(character)
  equip_starting_loadout(character)
end

--- Defer equip by one tick so freeplay has finished inserting created items.
local function queue_equip(player_index)
  storage.pending_equip = storage.pending_equip or {}
  storage.pending_equip[player_index] = true

  if storage.equip_tick_registered then
    return
  end
  storage.equip_tick_registered = true

  script.on_nth_tick(1, function()
    local pending = storage.pending_equip or {}
    storage.pending_equip = {}
    storage.equip_tick_registered = false
    script.on_nth_tick(1, nil)

    for index, _ in pairs(pending) do
      local player = game.get_player(index)
      if player then
        local character = character_for(player)
        if character then
          equip_starting_loadout(character)
        end
      end
    end
  end)
end

--------------------------------------------------------------------------------
-- Event handlers
--------------------------------------------------------------------------------

script.on_init(function()
  -- New freeplay games: register items so freeplay inserts them on player create.
  if has_freeplay_created_items() then
    register_freeplay_items()
  end

  -- Mid-game mod add: freeplay will not re-fire on_player_created for existing players.
  for _, player in pairs(game.players) do
    grant_and_equip(player)
  end
end)

script.on_event(defines.events.on_player_created, function(event)
  local player = game.get_player(event.player_index)
  if not player then
    return
  end

  if has_freeplay_created_items() then
    -- Items come from freeplay; equip on the next tick after they land in inventory.
    queue_equip(player.index)
  else
    grant_and_equip(player)
  end
end)
