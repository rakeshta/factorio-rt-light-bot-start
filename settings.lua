--
--  control.lua
--  factorio-rt-light-bot-start
--
--  Created by Rakesh Ayyaswami on 28 Oct 2024.
--

-- settings.lua
data:extend({
  {
    type = "bool-setting",
    name = "rt-lbt-cliff-explosives",
    setting_type = "startup",
    default_value = false,
    order = "101"
  },
  {
    type = "bool-setting",
    name = "rt-lbt-landfill",
    setting_type = "startup",
    default_value = false,
    order = "102"
  },
  {
    type = "bool-setting",
    name = "rt-lbt-car",
    setting_type = "startup",
    default_value = false,
    order = "103"
  }
})
