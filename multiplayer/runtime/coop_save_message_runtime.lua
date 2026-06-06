MP.NETWORKING_INTERNAL = MP.NETWORKING_INTERNAL or {}
MP.COOP_SAVE = MP.COOP_SAVE or {}
MP.COOP_SAVE.button_label = MP.COOP_SAVE.button_label or "Save"

local coop_save_message_runtime = {}
local BALATRO = MP.PLATFORM and MP.PLATFORM.BALATRO or {}
local match_domain = MP.DOMAIN and MP.DOMAIN.MATCH or {}
local COOP_SAVE_PERSISTENCE = MP.COOP_SAVE_PERSISTENCE or {}

local function show_notice(message)
	if MP.CONNECTION_FEEDBACK and MP.CONNECTION_FEEDBACK.show_notice then
		MP.CONNECTION_FEEDBACK.show_notice(message, { overlay = false })
	elseif MP.UI and MP.UI.UTILS and MP.UI.UTILS.overlay_message then
		MP.UI.UTILS.overlay_message(message)
	end
end

local function set_save_button_label(voters, required, committed)
	if MP.COOP_SAVE.set_save_button_label then
		return MP.COOP_SAVE.set_save_button_label(voters, required, committed)
	end

	if committed then
		MP.COOP_SAVE.button_label = "Saved"
	elseif (tonumber(voters) or 0) > 0 and (tonumber(required) or 0) > 0 then
		local action_label = MP.COOP_SAVE.has_voted and "Cancel" or "Save"
		MP.COOP_SAVE.button_label = string.format("%s %d/%d", action_label, tonumber(voters) or 0, tonumber(required) or 0)
	else
		MP.COOP_SAVE.button_label = "Save"
	end
	return MP.COOP_SAVE.button_label
end

local function set_text_node_text(node, text)
	if not node then
		return false
	end

	if node.config and node.config.text ~= nil then
		node.config.text = text
		node.config.lang = node.config.lang or G.LANG
		if node.config.text_drawable then
			node.config.text_drawable:set(text)
		elseif node.update_text then
			node:update_text()
		end
		return true
	end

	for _, child in pairs(node.children or {}) do
		if set_text_node_text(child, text) then
			return true
		end
	end

	return false
end

local function refresh_visible_save_button()
	local overlay = BALATRO.get_overlay_menu and BALATRO.get_overlay_menu() or G.OVERLAY_MENU
	local button = overlay and overlay.get_UIE_by_ID and overlay:get_UIE_by_ID("mp_coop_save_button") or nil
	if not button then
		return false
	end

	return MP.COOP_SAVE.update_button_node(button)
end

function MP.COOP_SAVE.update_button_node(button)
	local updated = set_text_node_text(button, MP.COOP_SAVE.button_label or "Save")
	if updated and button and button.UIBox and button.UIBox.recalculate then
		button.UIBox:recalculate()
	end
	return updated
end

local function refresh_coop_gamemode_panel()
	local overlay = BALATRO.get_overlay_menu and BALATRO.get_overlay_menu() or G.OVERLAY_MENU
	if not (overlay and MP.UI and MP.UI.UTILS and MP.UI.UTILS.replace_config_object) then
		return false
	end

	local gamemode_area = overlay:get_UIE_by_ID("gamemode_area")
	if not gamemode_area then
		return false
	end

	local lobby_domain = MP.DOMAIN and MP.DOMAIN.LOBBY or {}
	local current_gamemode = lobby_domain.get_creation_gamemode and lobby_domain.get_creation_gamemode()
		or MP.DEFAULT_LOBBY_CREATION_GAMEMODE
	if current_gamemode ~= "gamemode_mp_coop" then
		return false
	end

	return MP.UI.UTILS.replace_config_object(gamemode_area, UIBox({
		definition = G.UIDEF.gamemode_info("coop"),
		config = { align = "cm" },
	}), {
		recalculate_target = overlay,
	})
end

MP.COOP_SAVE.refresh_gamemode_panel = refresh_coop_gamemode_panel

local function refresh_local_save_list()
	if COOP_SAVE_PERSISTENCE.list_saves then
		MP.COOP_SAVE.saves = COOP_SAVE_PERSISTENCE.list_saves()
	else
		MP.COOP_SAVE.saves = MP.COOP_SAVE.saves or {}
	end
	refresh_coop_gamemode_panel()
end

function MP.COOP_SAVE.clear_active_resumed_save()
	MP.COOP_SAVE.active_save_id = nil
	MP.COOP_SAVE.has_voted = false
	MP.COOP_SAVE.vote_status = nil
	MP.COOP_SAVE.button_label = "Save"
end

function MP.COOP_SAVE.consume_active_resumed_save()
	local save_id = MP.COOP_SAVE.active_save_id
	if type(save_id) ~= "string" or save_id == "" then
		MP.COOP_SAVE.clear_active_resumed_save()
		return false
	end

	MP.COOP_SAVE.clear_active_resumed_save()
	if COOP_SAVE_PERSISTENCE.delete_save then
		local deleted = COOP_SAVE_PERSISTENCE.delete_save(save_id)
		refresh_local_save_list()
		return deleted
	end

	return false
end

local function decode_snapshot_payload(encoded_value, context)
	if not (MP.UTILS and MP.UTILS.str_decode_and_unpack) then
		return nil, "Snapshot decoding is unavailable."
	end

	return MP.UTILS.str_decode_and_unpack(encoded_value, context)
end

local function return_to_menu_after_saved_run()
	if MP.MATCH_LIFECYCLE and MP.MATCH_LIFECYCLE.suspend_team_card_sync then
		MP.MATCH_LIFECYCLE.suspend_team_card_sync()
	end

	if MP.CONNECTION_SESSION then
		if MP.CONNECTION_SESSION.request_overlay_menu_close then
			MP.CONNECTION_SESSION.request_overlay_menu_close()
		end
		if MP.CONNECTION_SESSION.clear_local_lobby_session then
			MP.CONNECTION_SESSION.clear_local_lobby_session({
				clear_reconnect = true,
				rebuild_main_menu_shell = false,
			})
		end
	end

	if match_domain.reset_state then
		match_domain.reset_state()
	end

	local root = BALATRO.get_root and BALATRO.get_root() or G
	if root and root.STAGE ~= root.STAGES.MAIN_MENU and BALATRO.go_to_menu then
		BALATRO.go_to_menu()
	end

	if MP.CONNECTION_SESSION and MP.CONNECTION_SESSION.refresh_connection_status_ui then
		MP.CONNECTION_SESSION.refresh_connection_status_ui()
	end
end

function coop_save_message_runtime.handle_coop_save_vote(voters, required, committed, save_id, save)
	if committed or (tonumber(voters) or 0) <= 0 then
		MP.COOP_SAVE.has_voted = false
	end
	MP.COOP_SAVE.vote_status = {
		voters = tonumber(voters) or 0,
		required = tonumber(required) or 0,
		committed = not not committed,
		save_id = save_id,
	}
	set_save_button_label(voters, required, committed)
	refresh_visible_save_button()

	if committed then
		if COOP_SAVE_PERSISTENCE.upsert_save and type(save) == "table" then
			COOP_SAVE_PERSISTENCE.upsert_save(save)
			refresh_local_save_list()
		end
		MP.COOP_SAVE.clear_active_resumed_save()
		return_to_menu_after_saved_run()
		MP.COOP_SAVE.button_label = "Save"
		MP.COOP_SAVE.has_voted = false
		show_notice(string.format("Co-op save: %s/%s\nRun saved.", tostring(voters or 0), tostring(required or 0)))
	else
		show_notice(string.format("Co-op save: %s/%s", tostring(voters or 0), tostring(required or 0)))
	end
end

function coop_save_message_runtime.handle_start_coop_save(action)
	local run_snapshot, run_err = decode_snapshot_payload(action.runData, "coop_save.run")
	if not run_snapshot then
		MP.UI.UTILS.overlay_message("Could not load co-op save.\n" .. tostring(run_err or "Unknown error."))
		return
	end

	local mp_state, state_err = decode_snapshot_payload(action.mpStateData, "coop_save.mp_state")
	if not mp_state then
		MP.UI.UTILS.overlay_message("Could not load co-op save state.\n" .. tostring(state_err or "Unknown error."))
		return
	end

	if not (MP.NETWORKING_INTERNAL and MP.NETWORKING_INTERNAL.resume_match_runtime) then
		MP.UI.UTILS.overlay_message("Co-op save restore runtime is unavailable.")
		return
	end

	MP.NETWORKING_INTERNAL.resume_match_runtime(run_snapshot, mp_state)
	MP.COOP_SAVE.active_save_id = action.saveId
	MP.COOP_SAVE.has_voted = false
	MP.COOP_SAVE.vote_status = nil
	MP.COOP_SAVE.button_label = "Save"
	show_notice("Co-op save resumed.")
end

MP.NETWORKING_INTERNAL.handle_coop_save_vote = coop_save_message_runtime.handle_coop_save_vote
MP.NETWORKING_INTERNAL.handle_start_coop_save = coop_save_message_runtime.handle_start_coop_save
