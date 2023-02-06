#include "common.lua"
#include "game.lua"

pTime = GetFloatParam("time", 10)
pLetterbox = GetBoolParam("letterbox", false)

tim = 0
cinematic = nil
index = 1
cam = false


function init()
	local missionId = GetString("game.levelid")
	for _,c in pairs(gCinematic) do
		for i=1,#c.parts do
			if c.parts[i].id == missionId then
				cinematic = c
				index = i
			end
		end
	end
	
	if not cinematic then
		cinematic = {}
		cinematic.music = ""
		cinematic.esc = "nothing"
		cinematic.parts = { { id="", file="", layers="", time=10} }
	end
	
	PlayMusic(cinematic.music)
	
	local locs = FindLocations()
	if #locs >= 2 then
		cam = true
		camStart = GetLocationTransform(locs[1])
		camEnd = GetLocationTransform(locs[2])
	end
end



function tick(dt)
	SetBool("game.disablepause", true)
	SetBool("game.disablemap", true)

	if InputPressed("esc") then
		exitSequence()
	end	

	tim = tim + dt
	
	if cam then
		local t0 = GetLocationTransform(loc0)
		local t1 = GetLocationTransform(loc1)
		local t = tim/pTime
		t = clamp(t, 0.0, 1.0)
		local cam = Transform(VecLerp(camStart.pos, camEnd.pos, t), QuatSlerp(camStart.rot, camEnd.rot, t))
		SetCameraTransform(cam)
	end

	UiMute(1)

	if not done then
		if tim > pTime then
			local nextPart = cinematic.parts[index+1]
			if nextPart then
				StartLevel(nextPart.id, nextPart.file, nextPart.layers, true)
				done = true
			else
				exitSequence()
			end			
		end
	end
end


function exitSequence()
	if cinematic.esc=="hub" then
		startHub()
		done = true
	elseif cinematic.esc=="nothing" then
		done = true
	else
		Menu()
		done = true
	end
end


function draw()
	if pLetterbox then
		UiPush()
			UiColor(0,0,0)
			UiRect(UiWidth(), 100)
			UiTranslate(0, UiHeight()-100)
			UiRect(UiWidth(), 100)
		UiPop()
	end
	
	if pCredits then
		UiPush()
			UiColor(1,1,1)
			UiFont("bold.ttf", 64)
			UiTextOutline(0,0,0,1.0,0.6)
			
			UiTranslate(100, UiHeight()-250)
			UiFont("bold.ttf", 32)
			UiText("A game by")
			UiFont("bold.ttf", 64)
			UiTranslate(0, 50)
			UiText("Tuxedo Labs")
		UiPop()
	end
	
	local black = 0
	if index == #cinematic.parts then
		if tim < 1 then
			black = 1-tim
		end
		if pTime-tim < 5 then
			black = 1-(pTime-tim)/3.0
			UiMute(black, true)
		end
	else
		if tim < 1 then
			black = 1-tim
		end
		if pTime-tim < 1 then
			black = 1-(pTime-tim)
		end
	end
	UiPush()
		UiColor(0,0,0, clamp(black, 0, 1))
		UiRect(UiWidth(), UiHeight())
	UiPop()
end

