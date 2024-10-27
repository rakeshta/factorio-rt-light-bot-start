--
--  control.lua
--  factorio-rt-light-bot-start
--
--  Created by Rakesh Ayyaswami on 04 Jan 2023.
--

--- Insert bonus items into the given player's inventory.
local function insert_bonus_items(player)
  -- abort if player doesn't have a physical body (example: sandbox mode)
  local character = player.character or player.cutscene_character
  if not character then
    return
  end

  -- insert bonus items into player's inventory
  character.insert { name = "modular-armor", count = 1 }
  character.insert { name = "personal-roboport-equipment", count = 2 }
  character.insert { name = "battery-equipment", count = 4 }
  character.insert { name = "solar-panel-equipment", count = 9 }
  character.insert { name = "construction-robot", count = 40 }

  -- insert optional bonus items if enabled in the settings
  if settings.startup["rt-lbt-cliff-explosives"].value then
    character.insert { name = "cliff-explosives", count = 40 }
  end
  if settings.startup["rt-lbt-landfill"].value then
    character.insert { name = "landfill", count = 200 }
  end
  if settings.startup["rt-lbt-car"].value then
    character.insert { name = "car", count = 1 }
  end
end

-- Insert items on all players who were present when the game started
script.on_init(function(event)
  for _, player in pairs(game.players) do
    insert_bonus_items(player)
  end
end)

-- Insert items on all players who join the game after it started
script.on_event(defines.events.on_player_created, function(event)
  local player = game.get_player(event.player_index)
  insert_bonus_items(player)
end)
