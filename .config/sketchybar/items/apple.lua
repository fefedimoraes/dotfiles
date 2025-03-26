local settings = require("settings")

local apple = sbar.add("item", {
	icon = {
		font = {
			size = 22.0,
		},
		string = settings.modes.main.icon,
		padding_right = 8,
		padding_left = 8,
	},
	label = {
		drawing = false,
	},

	padding_left = 1,
	padding_right = 1,
	click_script = "$CONFIG_DIR/helpers/menus/bin/menus -s 0",
})

apple:subscribe("aerospace_enter_service_mode", function(_)
	sbar.animate("tanh", 10, function()
		apple:set({
			icon = {
				highlight = true,
			},
		})
	end)
end)

apple:subscribe("aerospace_leave_service_mode", function(_)
	sbar.animate("tanh", 10, function()
		apple:set({
			icon = {
				highlight = false,
			},
		})
	end)
end)

-- Padding to the right of the main button
sbar.add("item", {
	width = 7,
})
