local BALATRO = MP.PLATFORM and MP.PLATFORM.BALATRO or {}

local function create_end_game_action_spacer(has_won)
	local width = has_won and 0.4 or 0.5
	return {
		n = G.UIT.C,
		config = {
			maxw = width,
			minw = width,
			minh = 0.7,
			colour = G.C.CLEAR,
			no_fill = false,
		},
	}
end

local function create_end_game_action_button(button, label_key, id, focus_args)
	return {
		n = G.UIT.C,
		config = {
			id = id,
			button = button,
			align = "cm",
			padding = 0.12,
			colour = G.C.BLUE,
			emboss = 0.05,
			minh = 0.7,
			minw = 1.7,
			maxw = 1.7,
			r = 0.1,
			shadow = true,
			hover = true,
			focus_args = focus_args,
		},
		nodes = {
			{
				n = G.UIT.T,
				config = {
					text = localize(label_key),
					colour = G.C.UI.TEXT_LIGHT,
					scale = 0.55,
					col = true,
				},
			},
		},
	}
end

local function create_kofi_message_row(index)
	return {
		n = G.UIT.R,
		config = { align = "cm", padding = 0.08, minw = 2 },
		nodes = {
			{
				n = G.UIT.T,
				config = {
					text = localize("ml_mp_kofi_message")[index],
					scale = 0.35,
					colour = G.C.UI.TEXT_LIGHT,
					col = true,
				},
			},
		},
	}
end

local function get_end_game_screen_style(has_won)
	local is_alone = MP.GAME and MP.GAME.end_game_result == "alone"
	if is_alone then
		return {
			win_like = true,
			title = "YOU ARE ALONE",
			title_colour = G.C.BLUE,
			background_colour = G.C.BLUE,
			background_alpha = 0.55,
			panel_colour = G.C.BLACK,
			outline_colour = G.C.BLUE,
			spacing = 4,
			rotate = false,
		}
	end

	if has_won then
		return {
			win_like = true,
			title = localize("ph_you_win"),
			title_colour = G.C.EDITION,
			background_colour = G.C.GREEN,
			background_alpha = 0.5,
			panel_colour = G.C.BLACK,
			outline_colour = G.C.EDITION,
			spacing = 10,
			rotate = true,
		}
	end

	return {
		win_like = false,
		title = localize("ph_game_over"),
		title_colour = G.C.RED,
		background_colour = G.C.RED,
		background_alpha = 0.8,
		panel_colour = nil,
		outline_colour = nil,
		spacing = nil,
		rotate = nil,
	}
end

function MP.UI.create_UIBox_mp_game_end(has_won)
	local screen_state = MP.UI.END_GAME_VIEW_MODEL.prepare_screen_state()
	local end_game_view = screen_state.runtime
	local viewable_players = screen_state.players
	local view_target_index = screen_state.target_index
	local screen_style = get_end_game_screen_style(has_won)

	if BALATRO.set_paused then
		BALATRO.set_paused(false)
	end

	local eased_bg_colour = copy_table(screen_style.background_colour)
	eased_bg_colour[4] = 0
	ease_value(eased_bg_colour, 4, screen_style.background_alpha, nil, nil, true)

	local t = create_UIBox_generic_options({
		padding = 0,
		bg_colour = eased_bg_colour,
		colour = screen_style.panel_colour,
		outline_colour = screen_style.outline_colour,
		no_back = true,
		no_esc = screen_style.win_like,
		contents = {
			{
				n = G.UIT.R,
				config = { align = "cm" },
				nodes = {
					{
						n = G.UIT.O,
						config = {
							object = DynaText({
								string = { screen_style.title },
								colours = { screen_style.title_colour },
								shadow = true,
								float = true,
								spacing = screen_style.spacing,
								rotate = screen_style.rotate,
								scale = 1.5,
								pop_in = 0.4,
								maxw = 6.5,
							}),
						},
					},
				},
			},
			{
				n = G.UIT.R,
				config = { align = "cm", padding = 0.15 },
				nodes = {
					{
						n = G.UIT.C,
						config = { align = "cm" },
						nodes = {
							{
								n = G.UIT.R,
								config = { align = "cm", padding = 0.08 },
								nodes = {
									{
										n = G.UIT.T,
										config = {
											ref_table = end_game_view,
											ref_value = "jokers_text",
											scale = 0.8,
											maxw = 5,
											shadow = true,
										},
									},
								},
							},
							{
								n = G.UIT.R,
								config = { align = "cm", padding = 0.08 },
								nodes = {
									{ n = G.UIT.O, config = { object = end_game_view.jokers_area } },
								},
							},
							{
								n = G.UIT.R,
								config = { align = "cm", padding = 0.08 },
								nodes = {
									create_end_game_action_spacer(screen_style.win_like),
									create_end_game_action_button("toggle_players_jokers", "b_toggle_jokers"),
									{
										n = G.UIT.C,
										config = { align = "cm", padding = 0.02, colour = G.C.CLEAR },
										nodes = {
											create_option_cycle({
												id = "end_game_view_target_cycle",
												label = localize("b_switch_player"),
												options = screen_state.target_options,
												current_option = view_target_index or 1,
												opt_callback = (#viewable_players > 0) and "change_end_game_view_target" or nil,
												w = 3.1,
												scale = 0.6,
												colour = G.C.BLUE,
												no_pips = true,
												cycle_shoulders = true,
											}),
										},
									},
									create_end_game_action_button(
										"view_nemesis_deck",
										"b_view_nemesis_deck",
										"view_nemesis_deck_button",
										screen_style.win_like and { nav = "wide" } or nil
									),
									create_end_game_action_spacer(screen_style.win_like),
								},
							},
							{
								n = G.UIT.R,
								config = { align = "cm" },
								nodes = {
									{
										n = G.UIT.C,
										config = { align = "cm", padding = 0.08 },
										nodes = {
											create_UIBox_round_scores_row("hand"),
											create_UIBox_round_scores_row("poker_hand"),
											create_kofi_message_row(1),
											create_kofi_message_row(2),
											create_kofi_message_row(3),
											create_kofi_message_row(4),
											{
												n = G.UIT.R,
												config = {
													id = "ko-fi_button",
													align = "cm",
													padding = 0.1,
													r = 0.1,
													hover = true,
													colour = HEX("72A5F2"),
													button = "open_kofi",
													shadow = true,
												},
												nodes = {
													{
														n = G.UIT.R,
														config = {
															align = "cm",
															padding = 0,
															no_fill = true,
															maxw = 3,
														},
														nodes = {
															{
																n = G.UIT.T,
																config = {
																	text = localize("b_mp_kofi_button"),
																	scale = 0.35,
																	colour = G.C.UI.TEXT_LIGHT,
																},
															},
														},
													},
												},
											},
										},
									},
									{
										n = G.UIT.C,
										config = { align = "tr", padding = 0.08 },
										nodes = {
											create_UIBox_round_scores_row("furthest_ante", G.C.FILTER),
											create_UIBox_round_scores_row("furthest_round", G.C.FILTER),
											create_UIBox_round_scores_row("seed", G.C.WHITE),
											UIBox_button({
												id = "copy_seed_button",
												button = "copy_seed",
												label = { localize("b_copy") },
												colour = G.C.BLUE,
												scale = 0.3,
												minw = 2.3,
												minh = 0.4,
											}),
											{
												n = G.UIT.R,
												config = { align = "cm", minh = 0.4, minw = 0.1 },
												nodes = {},
											},
											UIBox_button({
												id = "from_game_won",
												button = "mp_end_game_return_to_lobby",
												label = { localize("b_return_lobby") },
												minw = 2.5,
												maxw = 2.5,
												minh = 1,
												focus_args = { nav = "wide", snap_to = true },
											}),
											UIBox_button({
												button = "mp_end_game_leave_lobby",
												label = { localize("b_leave_lobby") },
												minw = 2.5,
												maxw = 2.5,
												minh = 1,
												focus_args = { nav = "wide" },
											}),
										},
									},
								},
							},
						},
					},
				},
			},
		},
	})

	t.nodes[1] = {
		n = G.UIT.R,
		config = { align = "cm", padding = 0.1 },
		nodes = {
			{
				n = G.UIT.C,
				config = { align = "cm", padding = 2 },
				nodes = {
					{
						n = G.UIT.O,
						config = {
							padding = 0,
							id = "jimbo_spot",
							object = Moveable(0, 0, G.CARD_W * 1.1, G.CARD_H * 1.1),
						},
					},
				},
			},
			{ n = G.UIT.C, config = { align = "cm", padding = 0.1 }, nodes = { t.nodes[1] } },
		},
	}

	if screen_style.win_like then t.config.id = "you_win_UI" end

	return t
end
