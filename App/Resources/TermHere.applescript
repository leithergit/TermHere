-- TermHere: drive iTerm2 from the Finder extension.
-- Handlers are looked up by lowercase name (openwindow / opentab).

on openwindow(cmd)
	openIn(cmd, false)
end openwindow

on opentab(cmd)
	openIn(cmd, true)
end opentab

on openIn(cmd, preferTab)
	set wasRunning to isITermRunning()
	tell application id "com.googlecode.iterm2"
		if not wasRunning then
			launch
			-- Cold start: reuse the launch window instead of leaving an empty one.
			set waited to 0
			repeat while (count of windows) is 0 and waited < 50
				delay 0.1
				set waited to waited + 1
			end repeat
			if (count of windows) is 0 then
				create window with default profile
			end if
			-- The window can exist before its session is ready.
			set waited to 0
			repeat while waited < 50
				try
					get current session of current window
					exit repeat
				end try
				delay 0.1
				set waited to waited + 1
			end repeat
			tell current session of current window to write text cmd
		else if preferTab and (count of windows) > 0 then
			tell current window
				create tab with default profile
				tell current session to write text cmd
			end tell
		else
			create window with default profile
			tell current session of current window to write text cmd
		end if
		activate
	end tell
end openIn

on isITermRunning()
	-- "is running" does not launch the app and needs no System Events permission.
	return application id "com.googlecode.iterm2" is running
end isITermRunning
