--- File that deals with the airScanners to check for holes in the spaceship and apply the effect of decompression
--- Thanks to the guy who wrote Boeing 737 mod for the idea

--- TODO: Query everything with tag rayCanPass to set as rejectBody

function init()
	scanners = FindLocations("airScanner", true)	            	--- Locations of the scanners
	DebugPrint(scanners)
	resolution = 12     											--- Number of star directions
	pressure = 100                                 					--- Pressure
	activePosList = {}                              --- so that each hole can be saved and constantly checked
	activeDirList = {}                              --- List of all direction scanning
	activeTimeList = {}                             --- smt ?
	activated = false --changes when everything activates
	--losePressure = not GetBool("savegame.mod.cabin.depressurize_inf",false)
	timer = 0
	rotationVal = 0

end


function tick()

    --- TODO: Method of scanning the room. Requires a lot of scanners? Or not? Performance effects?
	--- TODO: airScanner position 0,0,0 wtf ?

	if rotationVal ~=360 then
		rotationVal =  rotationVal + 5
	else
		rotationVal = 0
	end

	if pressure > 0 then
		i = 0 --raycast counter

			--- resolution ... ?
			for r=0,resolution do
				
				local quat = QuatEuler(0,0,r*360/resolution)
				local dir = TransformToParentPoint(Transform(Vec(0,0,0),quat),Vec(1,0,0))

				local rotationQuat = QuatEuler(rotationVal, rotationVal, rotationVal)
				local rotatedVector = QuatRotateVec(rotationQuat, dir)

				for index, scanner in pairs(scanners) do

					scannerPosition = GetLocationTransform(scanner).pos          --- Positional vector

					--- copy the pos of probe
					local rayPosition = VecCopy(scannerPosition)

					if activePosList[i] ~= rayPosition and activeDirList[i] ~= rotatedVector then

						--DebugLine(rayPosition,VecAdd(rayPosition,dir),0,0,1) --debug the current checked position

						i = i + 1
						hit, dist = QueryRaycast(rayPosition,rotatedVector,100)
						endpoint = VecAdd(rayPosition, VecScale(rotatedVector, dist))
						DrawLine(rayPosition, endpoint, 1, 0, 0)
						if not hit then
							DebugPrint("FOUND HOLE")
							activePosList[i] = rayPosition
							activeDirList[i] = rotatedVector
							activeTimeList[i] = 0

						end
					end
				end

			end

	end

		--- TODO: The rest

end