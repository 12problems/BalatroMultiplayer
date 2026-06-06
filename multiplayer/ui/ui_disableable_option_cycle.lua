function MP.UI.Disableable_Option_Cycle(args)
	local enabled = MP.UI.UTILS.resolve_enabled_flag(args)
	local cycle_args = {}
	for key, value in pairs(args or {}) do
		cycle_args[key] = value
	end
	if args then
		args._mp_effective_cycle_args = cycle_args
	end

	if not enabled then
		cycle_args.options = { cycle_args.options[cycle_args.current_option] }
		cycle_args.current_option = 1
	end

	return create_option_cycle(cycle_args)
end
