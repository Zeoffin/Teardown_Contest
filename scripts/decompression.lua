--- File that deals with the airScanners to check for holes in the spaceship and apply the effect of decompression
--- Thanks to the guy who wrote Boeing 737 mod for the idea

function init()
	DebugPrint("Decompressing stuff...")
	airScanner = FindLocation("airScanner")	            --- Locations of the scanners
	DebugPrint(airScanner)
	pos = GetLocationTransform(airScanner).pos           --- Positional vector
	DebugPrint(string.format("Scanner position: %d %d %d", pos[1], pos[2], pos[3]))
	resolution = 24     							--- Still no clue wtf this is
	pressure = 100                                  --- Pressure
	activePosList = {}                              --- so that each hole can be saved and constantly checked
	activeDirList = {}                              --- List of all direction scanning
	activeTimeList = {}                             --- smt ?
	activated = false --changes when everything activates
	--losePressure = not GetBool("savegame.mod.cabin.depressurize_inf",false)
	timer = 0
end


function tick()

    --- TODO: Method of scanning the room. Requires a lot of scanners? Or not? Performance effects?
	--- TODO: airScanner position 0,0,0 wtf ?

	--DebugPrint(string.format("%d %d %d", pos[1], pos[2], pos[3]))

	if pressure > 0 then
		i = 0 --raycast counter

		--- copy the pos of probe
		local checkpos = VecCopy(pos)

		--- resolution ... ?
		for r=0,resolution do
			local quat = QuatEuler(0,0,r*360/resolution)	--- quaternion - basically kaut kas rotē wtf nezinu ?
			local dir = TransformToParentPoint(Transform(Vec(0,0,0),quat),Vec(1,0,0))	--- iet kopa vnk ar lidmasinu ?

			if activePosList[i] ~= checkpos and activeDirList[i] ~= dir then
				--DebugLine(checkpos,VecAdd(checkpos,dir),0,0,1) --debug the current checked position
				i = i + 1
				hit, dist = QueryRaycast(checkpos,dir,10)
				endpoint = VecAdd(checkpos, VecScale(dir, dist))
				DrawLine(checkpos, endpoint, 1, 0, 0)
				--if not hit then
				--	activePosList[i] = checkpos
				--	activeDirList[i] = dir
				--	activeTimeList[i] = 0
			end
		end
	end

		--- TODO: The rest

end