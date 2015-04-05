if not gTwitch or not gTwitch.config then return end
/* DO NOT EDIT ANYTHING ABOVE */

/* ##### CONFIG STARTS HERE ##### */
	-- Your Twitch nickname.
gTwitch.config.nick							= "nickname"
	-- Your Twitch oauth pass, you can get it here: http://twitchapps.com/tmi/
gTwitch.config.pass							= "oauth:password"
	-- Auto connect to IRC on server start.
gTwitch.config.autoconnect					= true	-- Default - true
	-- If true, everyone will see messages from Twitch, else - only you.
gTwitch.config.everyone_can_see				= false	-- Default - false
	-- Will show you current amount of viewers on your channel.
gTwitch.config.show_viewers					= true	-- Default - true
	-- The position based on your screen width for viewers info.
gTwitch.config.viewers_xpos					= 0.01	-- Default - 0.01 (left)
	-- The position based on your screen height for viewers info.
gTwitch.config.viewers_ypos					= 0.02	-- Default - 0.02 (top)
	-- Time between checks in seconds.
gTwitch.config.viewers_check_time			= 30	-- Default - 30
/* #####  ADVANCED CONFIGS  ##### */
	-- Debugging.
gTwitch.config.debug_enable					= true	-- Default - false
	-- Will tell you about addon updates.
gTwitch.config.check_for_newer_versions		= true	-- Default - true
/* #####   END OF CONFIGS   ##### */