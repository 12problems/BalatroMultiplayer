local BALATRO = MP.PLATFORM and MP.PLATFORM.BALATRO or {}
local ALONE_JIMBO_QUIP_KEY = "mp_alone_1"
local ALONE_JIMBO_FALLBACK_FONT = "6"

local function fallback_text_part(text)
	return {
		strings = { text },
		control = { f = ALONE_JIMBO_FALLBACK_FONT },
	}
end

local function text_part(text)
	return {
		strings = { text },
		control = {},
	}
end

local function create_alone_jimbo_parsed_line()
	-- The default Balatro English font does not include these Unicode punctuation glyphs.
	return {
		text_part("So"),
		fallback_text_part("…"),
		text_part(" it"),
		fallback_text_part("’"),
		text_part("s just you and me"),
	}
end

local function ensure_alone_jimbo_quip()
	if not (G and G.localization) then
		return ALONE_JIMBO_QUIP_KEY
	end

	G.localization.quips_parsed = G.localization.quips_parsed or {}
	G.localization.quips_parsed[ALONE_JIMBO_QUIP_KEY] = {
		multi_line = true,
		create_alone_jimbo_parsed_line(),
	}

	return ALONE_JIMBO_QUIP_KEY
end

BALATRO.set_ui_function("open_kofi", function()
	BALATRO.open_url("https://ko-fi.com/virtualized")
end)

BALATRO.set_ui_function("overlay_endgame_menu", function()
	local is_alone = MP.GAME and MP.GAME.end_game_result == "alone"
	BALATRO.open_overlay_menu({
		definition = MP.GAME.won and create_UIBox_win() or create_UIBox_game_over(),
		config = { no_esc = true },
	})
	BALATRO.queue_event({
		trigger = "after",
		delay = 2.5,
		blocking = false,
		func = function()
			if BALATRO.get_overlay_element_by_id("jimbo_spot") then
				local Jimbo = Card_Character({ x = 0, y = 5 })
				local spot = BALATRO.get_overlay_element_by_id("jimbo_spot")
				MP.UI.UTILS.replace_config_object(spot, Jimbo, {
					recalculate_object = false,
					recalculate_ui_box = false,
				})
				Jimbo.ui_object_updated = true
				if is_alone then
					Jimbo:add_speech_bubble(ensure_alone_jimbo_quip(), nil, { quip = true })
				else
					local jimbo_words = MP.GAME.won and "wq_" .. math.random(1, 7) or "lq_" .. math.random(1, 10)
					Jimbo:add_speech_bubble(jimbo_words, nil, { quip = true })
				end
				Jimbo:say_stuff(5)
			end
			return true
		end,
	})
end)

BALATRO.set_ui_function("change_end_game_view_target", function(args)
	MP.UI.END_GAME_VIEW_MODEL.change_view_target(args.to_key)
end)

BALATRO.set_ui_function("toggle_players_jokers", function()
	MP.UI.END_GAME_VIEW_MODEL.toggle_players_jokers()
end)

BALATRO.set_ui_function("view_nemesis_deck", function()
	MP.UI.END_GAME_VIEW_MODEL.open_nemesis_deck_overlay()
end)
