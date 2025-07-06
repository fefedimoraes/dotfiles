-- focus-tab.scpt
-- AppleScript to open or focus tabs in a browser
-- Usage: osascript focus-tab.scpt <url> [browser]
-- 
-- For Chrome: Attempts to find and focus existing tabs with matching URLs
-- For other browsers: Simply opens the URL in a new tab

on run argv
	set targetURL to item 1 of argv
	set browserName to "Google Chrome"
	
	if (count of argv) > 1 then
		set browserName to item 2 of argv
	end if
	
	tell application browserName
		activate
	end tell
	
	-- Make sure the browser is frontmost
	tell application "System Events"
		tell process browserName
			set frontmost to true
		end tell
	end tell
	
	-- Special handling for Chrome - try to find existing tabs
	if browserName is "Google Chrome" then
		set foundTab to false
		
		tell application "Google Chrome"
			-- First check if Chrome has any windows
			if (count of windows) > 0 then
				-- Prepare URL for comparison without http/https
				set searchTerm to targetURL
				
				-- Try to find and focus an existing tab
				repeat with w in windows
					try
						set tabIndex to 1
						repeat with t in tabs of w
							try
								set tabUrl to URL of t
								if tabUrl contains searchTerm then
									set active tab index of w to tabIndex
									set index of w to 1
									set foundTab to true
									exit repeat
								end if
								set tabIndex to tabIndex + 1
							on error
								-- Skip any tab that causes an error
								set tabIndex to tabIndex + 1
							end try
						end repeat
						
						if foundTab then exit repeat
					on error
						-- Skip any window that causes an error
					end try
				end repeat
				
				if foundTab then
					return "Focused existing tab with URL containing: " & targetURL
				end if
			end if
			
			-- If we reach here, we didn't find a matching tab
			-- Format URL and open it
			if targetURL does not start with "http" then
				set targetURL to "https://" & targetURL
			end if
			open location targetURL
		end tell
	else
		-- For other browsers, just open the URL
		tell application browserName
			if targetURL does not start with "http" then
				set targetURL to "https://" & targetURL
			end if
			open location targetURL
		end tell
	end if
	
	return targetURL
end run
