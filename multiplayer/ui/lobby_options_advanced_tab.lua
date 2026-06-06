local function normalize_custom_seed(value)
	value = tostring(value or "")
	return value == "" and "random" or value
end

local function get_custom_seed_input_value()
	return MP.LOBBY.config.custom_seed == "random" and "" or MP.LOBBY.config.custom_seed
end

local function get_custom_seed_disabled_text()
	local seed = get_custom_seed_input_value()
	return seed ~= "" and seed or localize("b_set_custom_seed")
end

local function update_custom_seed(value)
	MP.UI.send_lobby_option_update("custom_seed", normalize_custom_seed(value))
end

local function is_custom_seed_editable()
	return not not (MP.LOBBY.is_host and not MP.LOBBY.config.different_seeds)
end

local function create_custom_seed_reset_button()
	return MP.UI.Disableable_Button({
		id = "custom_seed_reset",
		button = "custom_seed_reset",
		colour = G.C.RED,
		minw = 1.65,
		minh = 0.6,
		label = {
			localize("b_reset"),
		},
		disabled_text = {
			localize("b_reset"),
		},
		scale = 0.45,
		col = true,
		enabled_ref_table = MP.UI.CUSTOM_SEED_INPUT_STATE,
		enabled_ref_value = "enabled",
	})
end

function G.FUNCS.custom_seed_reset(e)
	update_custom_seed("random")
end

local function create_custom_seed_text_input()
	return create_text_input({
		w = 3.65,
		h = 0.6,
		text_scale = 0.36,
		max_length = 8,
		all_caps = true,
		ref_table = MP.LOBBY.setup,
		ref_value = "temp_seed",
		prompt_text = localize("b_set_custom_seed"),
		keyboard_offset = 4,
		callback = function()
			update_custom_seed(MP.LOBBY.setup.temp_seed)
		end,
	})
end

local function create_disabled_custom_seed_input()
	return {
		n = G.UIT.C,
		config = {
			align = "cm",
			padding = 0.05,
			r = 0.1,
			minw = 3.65,
			minh = 0.6,
			colour = G.C.UI.BACKGROUND_INACTIVE,
			shadow = true,
		},
		nodes = {
			{
				n = G.UIT.T,
				config = {
					scale = 0.36,
					text = get_custom_seed_disabled_text(),
					colour = G.C.UI.TEXT_INACTIVE,
					shadow = false,
				},
			},
		},
	}
end

local function prepare_custom_seed_input_state()
	MP.LOBBY.setup.temp_seed = get_custom_seed_input_value()
	MP.UI.CUSTOM_SEED_INPUT_STATE = {
		enabled = is_custom_seed_editable(),
	}
end

local function create_custom_seed_control_nodes()
	prepare_custom_seed_input_state()
	local seed_input_node = create_disabled_custom_seed_input()
	if MP.UI.CUSTOM_SEED_INPUT_STATE.enabled then
		seed_input_node = create_custom_seed_text_input()
	end

	return {
		seed_input_node,
		{
			n = G.UIT.B,
			config = {
				w = 0.1,
				h = 0.1,
			},
		},
		create_custom_seed_reset_button(),
	}
end

function MP.UI.refresh_custom_seed_controls()
	local overlay = G and G.OVERLAY_MENU or nil
	local controls_row = overlay and overlay.get_UIE_by_ID and overlay:get_UIE_by_ID("custom_seed_controls_row") or nil
	if not (controls_row and controls_row.children and controls_row.UIBox and controls_row.UIBox.set_parent_child) then
		return false
	end

	if G.CONTROLLER then
		G.CONTROLLER.text_input_hook = nil
	end

	for i = #controls_row.children, 1, -1 do
		controls_row.children[i]:remove()
		table.remove(controls_row.children, i)
	end
	for _, node in ipairs(create_custom_seed_control_nodes()) do
		controls_row.UIBox:set_parent_child(node, controls_row)
	end
	controls_row.UIBox:recalculate()
	return true
end

local function create_custom_seed_section()
	return {
		n = G.UIT.R,
		config = { padding = 0.2, align = "cr" },
		nodes = {
			{
				n = G.UIT.C,
				config = {
					padding = 0,
					align = "cm",
				},
				nodes = {
					{
						n = G.UIT.R,
						config = {
							padding = 0,
							align = "cm",
						},
						nodes = {
							{
								n = G.UIT.T,
								config = {
									scale = 0.45,
									text = localize("b_set_custom_seed"),
									colour = G.C.UI.TEXT_LIGHT,
								},
							},
						},
					},
					{
						n = G.UIT.R,
						config = {
							id = "custom_seed_controls_row",
							padding = 0.1,
							align = "cm",
						},
						nodes = create_custom_seed_control_nodes(),
					},
				},
			},
		},
	}
end

function MP.UI.create_advanced_options_tab()
	local nodes = MP.UI.build_lobby_option_controls(MP.UI.LOBBY_OPTION_TAB_SPECS.advanced)
	nodes[#nodes + 1] = create_custom_seed_section()

	return MP.UI.create_lobby_option_page(nodes, 4)
end
