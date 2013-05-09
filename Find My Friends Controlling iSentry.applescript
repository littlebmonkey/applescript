-- *************************************************************************************
-- This script will process Find my Friends email notifications, and turn on iSentry when no-one is home.
-- *************************************************************************************

-- *************************************************************************************
-- Configurable values:
-- *************************************************************************************
property emailAddress : "test@littlebluemonkey.com" -- Address for errors, and camera active/inactive errors
property device1ArrivedSubject : "Mr Monkey arrived at Home" -- Subject of email sent when device 1 returns.
property device2ArrivedSubject : "Mrs Monkey arrived at Home" -- Subject of email sent when device 2 returns 
property device1LeftSubject : "Mr Monkey left Home" -- Subject of email sent when device 1 leaves
property device2LeftSubject : "Mrs Monkey left Home" -- Subject of email sent when device 2 leaves 
property iMessageSendingAccount : "icloud@littlebluemonkey.com"

-- *************************************************************************************
-- Initial Values assumes all devices home, and camera inactive:
-- *************************************************************************************
property device1Here : 1
property device2Here : 1
property cameraActive : 0

-- *************************************************************************************
-- Main Code
-- *************************************************************************************

using terms from application "Mail"
	on perform mail action with messages theMessages for rule theRule
		tell application "Mail"
			
			
			repeat with eachMessage in theMessages
				set myList to ""
				set theSubject to subject of eachMessage
				try
					if theSubject is equal to device1ArrivedSubject then
						set device1Here to 1
					end if
					if theSubject is equal to device2ArrivedSubject then
						try
							if device2Here is equal to 0 and cameraActive then
								set myList to "HomePlaylist"
							end if
						end try
						set device2Here to 1
					end if
					if theSubject is equal to device1LeftSubject then
						set device1Here to 0
					end if
					if theSubject is equal to device2LeftSubject then
						set device2Here to 0
					end if
					if device1Here is equal to 0 and device2Here is equal to 0 and cameraActive is equal to 0 then
						try
							startCamera() of me
						on error errMsg
							sendEmail("Error:" & errMsg) of me
						end try
						sendEmail("Camera On") of me
						set cameraActive to 1
					end if
					if (device1Here is equal to 1 or device2Here is equal to 1) and cameraActive is equal to 1 then
						try
							tell application "iSentry" to quit
						on error errMsg
							do shell script "killall iSentry"
							
						end try
						sendEmail("Camera Off") of me
						set cameraActive to 0
					end if
					delete eachMessage
					if myList is not "" then
						--  onkyoOn("PC", 40) of me
						startPlayList(myList) of me
					end if
				end try
			end repeat
			
		end tell
	end perform mail action with messages
end using terms from

-- Code to start iSentry
on startCamera()
	tell application "Finder"
		activate
		
		open application file "iSentry.app" of folder "Applications" of startup disk
		delay 5
		tell application "System Events"
			tell process "iSentry"
				tell group 1 of window 1
					tell button 1
						click
					end tell
				end tell
			end tell
		end tell
	end tell
end startCamera

-- Code to send any emails
on sendEmail(theSubject)
	try
		tell application "Mail"
			set newMessage to make new outgoing message with properties {subject:theSubject, content:"", visible:true}
			tell newMessage
				make new to recipient with properties {name:emailAddress, address:emailAddress}
				
				##Send the Message
				send
			end tell
		end tell
	on error errMsg
		display dialog "Error sending email with subject: " & theSubject & " : " & errMsg
	end try
end sendEmail

-- Code to send an iMessage
on sendIMessage(myMessage, myRecipient)
	
	-- Open iMessage and wait for it to start if it's not running
	tell application "Finder"
		set x to name of processes
		if (x does not contain "Messages") then
			tell application "Messages"
				activate
				delay 5
			end tell
		end if
	end tell
	
	tell application "Messages"
		set serviceName to "E:" & iMessageSendingAccount
		send myMessage to buddy myRecipient of service named serviceName
	end tell
end sendIMessage

-- Code to start a playlist in iTunes
on startPlayList(aList)
	try
		
		tell application "iTunes"
			stop
		end tell
		
		
		tell application "iTunes"
			play user playlist aList
		end tell
		
	on error errMsg
		sendEmail("Error playing:" & aList & " - " & errMsg) of me
	end try
	
end startPlayList

-- Code to start up an onkyo Reciever
on onkyoOn(input, aVolume)
	try
		tell application "Finder"
			activate
			open application file "OnkyMote.app" of folder "Applications" of startup disk
			delay 0.5
		end tell
		
		tell application "System Events"
			tell process "OnkyMote"
				-- Click on top level menu, to load the menu, and then select the source
				click menu bar item 1 of menu bar 1
				click menu item input of menu 1 of menu bar item 1 of menu bar 1
				
				-- Click on top level menu, to load the menu, find and adjust the volume slider
				
				click menu bar item 1 of menu bar 1
				set names to name of menu items of menu 1 of menu bar item 1 of menu bar 1
				repeat with i from (count of names) to 1 by -1
					if item i of names starts with "Volume:" then
						set value of slider of menu item (i + 1) of menu 1 of menu bar item 1 of menu bar 1 to aVolume
						exit repeat
					end if
				end repeat
				
				-- Click on the Label to dismiss the menu
				click menu item "Devices:" of menu 1 of menu bar item 1 of menu bar 1
			end tell
		end tell
	end try
end onkyoOn

-- Code to turn off an Onkyo Receiver
on onkyoOff()
	try
		tell application "Finder"
			activate
			open application file "OnkyMote.app" of folder "Applications" of startup disk
			delay 0.5
		end tell
		
		tell application "System Events"
			tell process "OnkyMote"
				
				click menu bar item 1 of menu bar 1
				click menu item "Torn device off" of menu 1 of menu bar item 1 of menu bar
			end tell
		end tell
		
	end try
end onkyoOff

