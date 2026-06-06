MP.UI = MP.UI or {}
MP.UI.MAIN_MENU_SELECTION = MP.UI.MAIN_MENU_SELECTION or {}

local selection = MP.UI.MAIN_MENU_SELECTION
local lobby_domain = MP.DOMAIN and MP.DOMAIN.LOBBY or {}
local selection_utils = MP.UTILS

local function build_default_area(definition)
	return UIBox({
		definition = definition,
		config = { align = "cm" },
	})
end

local function get_gamemode_selection_name(gamemode_key)
	return selection_utils.strip_selection_prefix(gamemode_key, "gamemode_mp_")
end

function selection.get_gamemode_selection_button_id(gamemode_key)
	return get_gamemode_selection_name(gamemode_key) .. "_gamemode_button"
end

function selection.build_gamemode_selection_buttons_data()
	return selection_utils.build_grouped_selection_buttons_data(MP.Gamemodes, {
		key_prefix = "gamemode_mp_",
		default_group_key = "k_challenge",
		get_button_id = function(gamemode)
			return selection.get_gamemode_selection_button_id(gamemode.key)
		end,
	})
end

local function get_ruleset_selection_name(ruleset_key)
	return selection_utils.strip_selection_prefix(ruleset_key, "ruleset_mp_")
end

function selection.get_ruleset_selection_button_id(ruleset_key)
	return get_ruleset_selection_name(ruleset_key) .. "_ruleset_button"
end

function selection.build_ruleset_selection_buttons_data()
	return selection_utils.build_grouped_selection_buttons_data(MP.Rulesets, {
		key_prefix = "ruleset_mp_",
		default_group_key = "k_custom",
		get_button_id = function(ruleset)
			return selection.get_ruleset_selection_button_id(ruleset.key)
		end,
	})
end

function selection.build_gamemode_selection_options(initial_gamemode_key)
	local fallback_gamemode_key = MP.DEFAULT_LOBBY_CREATION_GAMEMODE or "gamemode_mp_attrition"
	local gamemode_key = initial_gamemode_key or fallback_gamemode_key
	if not (MP.Gamemodes and MP.Gamemodes[gamemode_key]) then
		gamemode_key = fallback_gamemode_key
	end
	lobby_domain.set_creation_gamemode(gamemode_key)
	local gamemode_name = get_gamemode_selection_name(gamemode_key)

	local gamemode_buttons_data = selection.build_gamemode_selection_buttons_data()
		or {}

	return MP.UI.Main_Lobby_Options(
		"gamemode_area",
		build_default_area(G.UIDEF.gamemode_info(gamemode_name)),
		"change_gamemode_selection",
		gamemode_buttons_data,
		selection.get_gamemode_selection_button_id(gamemode_key)
	)
end

function selection.apply_ruleset_selection(ruleset_name)
	lobby_domain.set_creation_ruleset("ruleset_mp_" .. ruleset_name)
	MP.LoadReworks(ruleset_name)
end

local function apply_default_ruleset(ruleset_name)
	if lobby_domain.set_setup_fetched_weekly then
		lobby_domain.set_setup_fetched_weekly("smallworld")
	end

	selection.apply_ruleset_selection(ruleset_name)
end

function selection.build_ruleset_selection_options()
	local default_ruleset = string.sub(MP.DEFAULT_LOBBY_CREATION_RULESET, 12, -1)
	apply_default_ruleset(default_ruleset)

	local ruleset_buttons_data = selection.build_ruleset_selection_buttons_data()
		or {}

	return MP.UI.Main_Lobby_Options(
		"ruleset_area",
		build_default_area(G.UIDEF.ruleset_info(default_ruleset)),
		"change_ruleset_selection",
		ruleset_buttons_data
	)
end
