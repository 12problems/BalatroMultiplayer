MP.ACTIONS = MP.ACTIONS or {}
MP.COOP_SAVE = MP.COOP_SAVE or {}
MP.COOP_SAVE.button_label = MP.COOP_SAVE.button_label or "Save"

local coop_save_action_runtime = {}
local BALATRO = MP.PLATFORM and MP.PLATFORM.BALATRO or {}
local COOP_SAVE_PERSISTENCE = MP.COOP_SAVE_PERSISTENCE or {}
local teams_domain = MP.DOMAIN and MP.DOMAIN.TEAMS or {}

local function is_active_coop_run()
	return MP.LOBBY
		and MP.LOBBY.code
		and MP.is_lobby_match_in_progress
		and MP.is_lobby_match_in_progress()
		and MP.is_coop_gamemode
		and MP.is_coop_gamemode()
end

local function serialize_score(value)
	if MP.INSANE_INT and MP.INSANE_INT.to_string and value then
		return MP.INSANE_INT.to_string(value)
	end
	return tostring(value or "0")
end

local function get_current_player_score_text()
	if teams_domain.get_local_score_text then
		return tostring(teams_domain.get_local_score_text() or "0")
	end

	return tostring((MP.GAME and MP.GAME.score_text) or "0"):gsub(",", "")
end

local function build_save_metadata()
	local game = BALATRO.get_game and BALATRO.get_game() or G.GAME or {}
	local blind = BALATRO.get_current_blind and BALATRO.get_current_blind() or game.blind or {}
	local round_resets = game.round_resets or {}

	return {
		ante = tonumber(round_resets.ante or game.ante) or 1,
		blind = tostring(blind.name or MP.GAME.location or "Unknown"),
		maxScore = serialize_score(MP.GAME and MP.GAME.highest_score or game.round_scores and game.round_scores.hand),
		score = get_current_player_score_text(),
		handsLeft = tonumber(BALATRO.get_hands_left and BALATRO.get_hands_left() or nil) or 0,
	}
end

local function show_save_notice(message)
	if MP.CONNECTION_FEEDBACK and MP.CONNECTION_FEEDBACK.show_notice then
		MP.CONNECTION_FEEDBACK.show_notice(message, { overlay = false })
	else
		MP.UI.UTILS.overlay_message(message)
	end
end

local function refresh_coop_save_list()
	if COOP_SAVE_PERSISTENCE.list_saves then
		MP.COOP_SAVE.saves = COOP_SAVE_PERSISTENCE.list_saves()
	else
		MP.COOP_SAVE.saves = {}
	end

	if MP.COOP_SAVE.refresh_gamemode_panel then
		MP.COOP_SAVE.refresh_gamemode_panel()
	end

	return true
end

local function set_save_button_label(voters, required, committed)
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

function coop_save_action_runtime.request_coop_saves()
	return refresh_coop_save_list()
end

function coop_save_action_runtime.save_coop_run()
	if not is_active_coop_run() then
		MP.UI.UTILS.overlay_message("Co-op saves are only available during co-op runs.")
		return false
	end

	if MP.COOP_SAVE.has_voted then
		MP.COOP_SAVE.has_voted = false
		local status = MP.COOP_SAVE.vote_status or {}
		status.voters = math.max((tonumber(status.voters) or 1) - 1, 0)
		status.required = tonumber(status.required) or #(MP.LOBBY.players or {})
		status.committed = false
		MP.COOP_SAVE.vote_status = status
		set_save_button_label(status.voters, status.required, false)
		return Client.queue_send(MP.COOP_SAVE_WIRE.build_cancel_save_payload())
	end

	local snapshot, err
	if MP.RESUME and MP.RESUME.build_current_encoded_match_snapshot then
		snapshot, err = MP.RESUME.build_current_encoded_match_snapshot()
	end

	if not snapshot then
		MP.UI.UTILS.overlay_message(err or "Could not save this co-op run right now.")
		return false
	end

	local required = #(MP.LOBBY.players or {})
	local current_voters = tonumber(MP.COOP_SAVE.vote_status and MP.COOP_SAVE.vote_status.voters) or 0
	local optimistic_voters = math.min(current_voters + 1, required)
	MP.COOP_SAVE.has_voted = true
	MP.COOP_SAVE.vote_status = {
		voters = optimistic_voters,
		required = required,
		committed = false,
	}
	set_save_button_label(MP.COOP_SAVE.vote_status.voters, MP.COOP_SAVE.vote_status.required, false)

	local queued = Client.queue_send(MP.COOP_SAVE_WIRE.build_save_payload(snapshot, build_save_metadata()))
	if queued then
		show_save_notice(string.format(
			"Co-op save: %d/%d\nWaiting for all players.",
			MP.COOP_SAVE.vote_status.voters,
			MP.COOP_SAVE.vote_status.required
		))
	end
	return queued
end

MP.COOP_SAVE.set_save_button_label = set_save_button_label

function coop_save_action_runtime.resume_coop_save(save_id)
	if type(save_id) ~= "string" or save_id == "" then
		return false
	end

	local save = COOP_SAVE_PERSISTENCE.get_save and COOP_SAVE_PERSISTENCE.get_save(save_id) or nil
	if not save then
		refresh_coop_save_list()
		MP.UI.UTILS.overlay_message("Saved co-op run was not found.")
		return false
	end

	return Client.queue_send(MP.COOP_SAVE_WIRE.build_resume_payload(save))
end

function coop_save_action_runtime.delete_coop_save(save_id)
	if type(save_id) ~= "string" or save_id == "" then
		return false
	end

	local deleted = COOP_SAVE_PERSISTENCE.delete_save and COOP_SAVE_PERSISTENCE.delete_save(save_id)
	refresh_coop_save_list()
	if deleted then
		show_save_notice("Co-op save removed.")
	else
		MP.UI.UTILS.overlay_message("Saved co-op run was not found.")
	end
	return not not deleted
end

MP.ACTIONS.request_coop_saves = coop_save_action_runtime.request_coop_saves
MP.ACTIONS.save_coop_run = coop_save_action_runtime.save_coop_run
MP.ACTIONS.resume_coop_save = coop_save_action_runtime.resume_coop_save
MP.ACTIONS.delete_coop_save = coop_save_action_runtime.delete_coop_save
