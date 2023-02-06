
function init()

    UiMakeInteractive()

end

function tick()

    screen = UiGetScreen()

    DebugPrint(screen)

    numpad = FindShape("spacelock_screen", true)

	DebugPrint("Numpad: "..numpad)

	SetTag(numpad, "interact", "Enter floor")

    if screen ~= nill then
        DebugPrint("durvis?")
    end

    if InputPressed("interact") then
		local thing = GetPlayerInteractShape()
		if thing == numpad then
			RemoveTag(numpad, "interact")
			SetPlayerScreen(numpadScreen)
			changeState(NUMPAD)
		else
			if not INS then
			for i=1, #upButtons do
				if thing == upButtons[i] then
					currentButtonPressed = thing
					currentFloorPressed = i - 1
					press(currentButtonPressed)
					changeState(BUTTON_DOWN)
				end
			end
			end
		end
	end

end

function draw()
    UiColor(1,0,0)
    UiTranslate(UiCenter(), UiMiddle())
    UiAlign("center middle")
    UiRect(100,100)
    UiPush()
end

