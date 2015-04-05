	/*=========================================================*\
	| gTwitch - Garry's Mod Twitch integration					|
	| Made by maximmax42 (c) 2014-2015							|
	| Edit this file only if you know what you doing.			|
	|															|
	| P.S. I can have some mistakes in English, cuz I'm Russian	|
	| P.P.S I suck at commenting, especially on other language	|
	\*=========================================================*/

if gTwitch and gTwitch.sock then
	gTwitch.sock:Close()
end -- Avoid multi-user

gTwitch = {} -- Nice table
gTwitch.config = {}
gTwitch.version = tonumber( file.Read( "gTwitch_ver.txt", "GAME" ) )

-- Let's add some color vars
color_twitch_purple = Color( 100, 65, 165 )
color_twitch_lightpurple = Color( 185, 163, 227 )
color_twitch_darkgray = Color( 38, 38, 38 )
color_twitch_lightgray = Color( 241, 241, 241 )

include( "gTwitch_config.lua" ) -- Including our config

function gTwitch.debug( msg )
	if not gTwitch.config.debug_enable then return end
	
	MsgC( Color( 150, 200, 100 ), "[gTwitch Debug] ", color_white, msg.."\n" )
end

function gTwitch.print( msg, err )
	local c = err and Color( 255, 10, 10 ) or color_twitch_lightpurple
	local err_msg = err and " Error" or ""
	
	MsgC( c, "[gTwitch"..err_msg.."] ", color_white, msg.."\n" )
end

if not system.IsWindows() then
	if SERVER then -- Why I print this only serverside? Dunno
		gTwitch.print( "This version of addon is Windows-only. Sorry :c", true )
		gTwitch.print( "But if you have working GLSock2 for Linux/Mac... send it to me." )
		gTwitch.print( "Or wait for the moment when I will re-write this code for another socket addon (BromSock)." )
	end
	
	return
end

if gTwitch.config.nick == "nickname" or gTwitch.config.pass == "oauth:password" then
	if SERVER then gTwitch.print( "Login and/or pass not set! Aborting.", true ) end
	return
end


if CLIENT then
	net.Receive( "gTwitch.Chat", function()
		local nick = net.ReadString()
		local msg = net.ReadString()
		
		chat.AddText( color_twitch_purple, "[Twitch] ", color_twitch_lightpurple, nick, color_white, ": "..msg )
		surface.PlaySound( "common/talk.wav" )
	end )
	
	surface.CreateFont( "gTwitch.Font", {
		font = "Impact",
		size = 30
	} )
	
	local stream_online = false
	local viewers = 0
	local v -- Previous viewers amount
	local next_check = CurTime()
	
	function gTwitch.GetViewers()
		if not gTwitch.config.show_viewers then return end
		
		if next_check < CurTime() then
			next_check = CurTime() + gTwitch.config.viewers_check_time
			
			http.Fetch( "https://api.twitch.tv/kraken/streams/"..gTwitch.config.nick, function( body )
				local tbl = util.JSONToTable( body )
				
				if not tbl then return end
				
				if tbl["stream"] then
					stream_online = true
					v = viewers
					viewers = tbl["stream"]["viewers"]
					
					if v != viewers then gTwitch.debug( "Amount of viewers changed from "..v.." to "..viewers ) end
				else
					stream_online = false
				end
			end )
		end
	end
	
	function gTwitch.ShowViewers()
		if not gTwitch.config.show_viewers then return end
		
		local x = ScrW() * gTwitch.config.viewers_xpos
		local y = ScrH() * gTwitch.config.viewers_ypos
		
		local text = stream_online and "Viewers: "..viewers or "Stream Offline!"
		local c1 = stream_online and color_twitch_purple or color_twitch_darkgray
		local c2 = stream_online and color_twitch_lightpurple or color_twitch_lightgray
		
		draw.RoundedBox( 20, x, y, 170, 50, c1 )
		draw.DrawText( text, "gTwitch.Font", x + 10, y + 10, c2, TEXT_ALIGN_LEFT )
	end
	
	hook.Add( "Think", "gTwitch.GetViewers", gTwitch.GetViewers )
	hook.Add( "HUDPaint", "gTwitch.ShowViewers", gTwitch.ShowViewers )
	
	return
end

util.AddNetworkString( "gTwitch.Chat" )

function f( _, bytes ) gTwitch.debug( "Sent "..bytes.." bytes to server." ) end

if not require( "glsock2" ) then gTwitch.print( "GLSock isn't installed!", true ) end

function gTwitch.CheckVersion()	
	http.Fetch( "https://raw.githubusercontent.com/maximmax42/gTwitch/master/gTwitch_ver.txt", function( body )
		if not body then gTwitch.print( "Failed to verify version", true ) end
		
		local curver = tonumber( body )
		
		if gTwitch.version == curver then
			gTwitch.print( "Your have latest version of addon." )
		elseif gTwitch.version < curver then
			gTwitch.print( "Newer version available! Please, update addon using SVN." )
		elseif gTwitch.version > curver then
			gTwitch.print( "Don't forget to push!" ) -- Yeth, this is for me
		end
	end, function( err ) gTwitch.print( "Failed to verify version. Err #"..err, true ) end )
end

function gTwitch.Connect( chan )
	gTwitch.print( "Connecting to Twitch IRC Server..." )
	
	gTwitch.sock = GLSock( GLSOCK_TYPE_TCP )
	gTwitch.sock:Connect( "irc.twitch.tv", 6667, function( sock, err )
		if err == GLSOCK_ERROR_SUCCESS then -- Success c:
			local chan = chan or gTwitch.config.nick
			
			local buff = GLSockBuffer()
			buff:Write( "PASS "..gTwitch.config.pass.."\n" ) -- Sending our pass
			buff:Write( "NICK "..gTwitch.config.nick.."\n" ) -- Sending our nick
			buff:Write( "JOIN #"..chan.."\n" ) -- Joining our own (or not) channel in IRC
			
			gTwitch.debug( "Sending credentials and joining to the channel..." )
			sock:Send( buff, f )
			gTwitch.print( "Connected." )
			
			sock:Read( 1000, gTwitch.Read ) -- Receiving info...
		else -- Not success :c
			gTwitch.print( "Error! #"..err, true )
		end
	end )
end

function gTwitch.Read( sock, buff, err )
	if err == GLSOCK_ERROR_SUCCESS then
		local count, data = buff:Read( buff:Size() )
		data = string.sub( data, 1, #data - 1 ) -- Deleting \n at the end of data
		
		if count == 0 then return end
		
		gTwitch.debug( data ) -- Server responses
		
		local exp = string.Explode( " ", data )
		local cmd = exp[2]
		
		if cmd == "PRIVMSG" then
			local nick = string.sub( exp[1], 2, string.find( data, "!" ) - 1 )
			
			if nick != "jtv" then -- Bot nickname
				for i = 1, 3 do table.remove( exp, 1 ) end
				
				local msg = string.sub( string.Implode( " ", exp ), 2 )
				
				net.Start( "gTwitch.Chat" )
				net.WriteString( nick )
				net.WriteString( msg )
				
				if gTwitch.config.everyone_can_see then
					net.Broadcast()
				else
					for _, ply in pairs( player.GetAll() ) do if ply:IsListenServerHost() then net.Send( ply ) end end
				end
			end
		elseif cmd == "PING" then
			local buff = GLSockBuffer()
			buff:Write( "PONG\n" )
			sock:Send( buff, f )
		end
		
		-- Cycle reading
		sock:Read( 1000, gTwitch.Read )
	else
		gTwitch.print( "Connection closed: Error #"..err, true )
		sock:Close()
		gTwitch.sock = nil
	end
end

concommand.Add( "gtwitch_on", function( _, _, args ) -- Can't use "connect" in concommand name
	if gTwitch.sock then
		gTwitch.print( "You are already connected!", true )
		return
	end
	
	gTwitch.Connect( args[1] ) -- If not specified - nil
end, function( c ) return { c.." (channel)" } end, "Connect to IRC" )

concommand.Add( "gtwitch_off", function() -- Can't use "disconnect" in concommand name
	if not gTwitch.sock then
		gTwitch.print( "You are not connected!", true )
		return
	end

	gTwitch.print( "Disconnecting from IRC..." )
	
	local buff = GLSockBuffer()
	buff:Write( "QUIT Disconnected.\n" )
	gTwitch.sock:Send( buff, f )
	gTwitch.sock:Close()
	gTwitch.sock = nil
	
	gTwitch.print( "Disconnected. To re-connect, type \"gtwitch_on (channel)\"" )
end, nil, "Disconnect from IRC" )

concommand.Add( "_gtw_send", function( _, _, args ) -- Debug command
	if not gTwitch.sock then
		gTwitch.print( "You are not connected!", true )
		return
	end
	
	local buff = GLSockBuffer()
	buff:Write( string.Implode( " ", args ).."\n" )
	gTwitch.sock:Send( buff, f )
end, nil, "Sends raw data to IRC server." )

-- And finally, let's init whole script
gTwitch.print( "by maximmax42 initialized." )
if gTwitch.config.check_for_newer_versions then gTwitch.CheckVersion() end
if gTwitch.config.autoconnect then gTwitch.Connect() end
