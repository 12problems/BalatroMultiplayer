MP.COOP_SAVE_WIRE = MP.COOP_SAVE_WIRE or {}

local function build_coop_save_intent(action_name, extra_fields)
	return MP.PROTOCOL.build_v2_packet_for_schema("coopSave", "intent", action_name, extra_fields)
end

function MP.COOP_SAVE_WIRE.build_save_payload(snapshot, metadata)
	snapshot = snapshot or {}
	metadata = metadata or {}

	return build_coop_save_intent("save", {
		runData = snapshot.runData,
		mpStateData = snapshot.mpStateData,
		ante = metadata.ante,
		blind = metadata.blind,
		maxScore = metadata.maxScore,
		score = metadata.score,
		handsLeft = metadata.handsLeft,
	})
end

function MP.COOP_SAVE_WIRE.build_cancel_save_payload()
	return build_coop_save_intent("save", {
		cancel = true,
	})
end

function MP.COOP_SAVE_WIRE.build_resume_payload(save)
	return build_coop_save_intent("resume", {
		save = save,
	})
end
