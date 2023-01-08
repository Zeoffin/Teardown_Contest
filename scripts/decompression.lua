--- File that deals with the airScanners to check for holes in the spaceship and apply the effect of decompression
--- Thanks to the guy who wrote Boeing 737 mod for the idea

--- TODO: Query everything with tag rayCanPass to set as rejectBody

starCount = 24     											--- Number of star directions
bodyPressureSpeed = 0.5
playerPressureSpeed = 0.01

function init()

	scanners = FindLocations("airScanner", true)	            	--- Locations of the scanners
	roomTriggers = FindTriggers('airTrigger', true)

	pressure = true                                 					--- Pressure
	activeHolesList = {}                              --- so that each hole can be saved and constantly checked
	activeDirList = {}                              --- List of all direction scanning
	activeTimeList = {}                             --- smt ?
	scannerTriggerTable = {}						--- scanner: trigger     K:V
	triggerToTriggerLeaks = {}
	activated = false --changes when everything activates
	--losePressure = not GetBool("savegame.mod.cabin.depressurize_inf",false)
	timer = 0
	rotationVal = 0

	--- Map scanners to triggers
	mapScannerToTrigger(scannerTriggerTable)

end


function tick(dt)

	if pressure then

		findHoles()
		setDecompression(dt)

	end

end

--- Find holes to the space by shooting rays in rooms and checking if the ray hits a wall
function findHoles()

	if rotationVal ~=360 then
		rotationVal =  rotationVal + 2
	else
		rotationVal = 0
	end

	-- Trigger : TableOfHoles
	triggerHolesMap = {}
	triggerToTriggerLeaks = {}

	i = 0 --raycast counter

	for r=0,starCount do

		local quat = QuatEuler(0,0,r*360/starCount)
		local dir = TransformToParentPoint(Transform(Vec(0,0,0),quat),Vec(1,0,0))

		local rotationQuat = QuatEuler(rotationVal, rotationVal, rotationVal)
		local rotatedVector = QuatRotateVec(rotationQuat, dir)

		for scannerIndex, scanner in pairs(scanners) do

			-- A map of all rooms in which the rays are leaking
			leakingRooms = {}

			-- Positional vector of the scanner
			scannerPosition = GetLocationTransform(scanner).pos

			local rayPosition = VecCopy(scannerPosition)

			if activeHolesList[i] ~= rayPosition and activeDirList[i] ~= rotatedVector then

				--DebugLine(rayPosition,VecAdd(rayPosition,dir),0,0,1) --debug the current checked position

				i = i + 1

				--- Ray tracing loop
				for rayTracingLimits=1,4 do

					hit, dist, normal = QueryRaycast(rayPosition,rotatedVector,50)
					endpoint = VecAdd(rayPosition, VecScale(rotatedVector, dist))
					--DrawLine(rayPosition, endpoint, 1, 0, 0)

					--- Detect if the ray is leaking from one room trigger to another
					for secondScanner, roomTrigger in pairs(scannerTriggerTable) do

						if (IsPointInTrigger(roomTrigger, endpoint) or IsPointInTrigger(roomTrigger, rayPosition)) and scanner ~= secondScanner then
							DebugCross(endpoint, 1,0,0)		-- Draw rays that are outside its parent trigger
							table.insert(leakingRooms, roomTrigger)
						end

					end

					if not hit then
						DebugPrint("FOUND HOLE")
						activeHolesList[i] = rayPosition
						activeDirList[i] = rotatedVector
						activeTimeList[i] = 0
						triggerHolesMap[scannerTriggerTable[scanner]] = activeHolesList
						break
					else
						rayPosition = VecCopy(endpoint)
						rotatedVector = VecSub(rotatedVector, VecScale(normal, VecDot(normal, rotatedVector)*2))
					end

				end
			end

			--local count = 0
			--for _ in pairs(leakingRooms) do count = count + 1 end
			--DebugPrint(string.format("Leak2: %d", count))

			-- Set trigger to trigger leakage map
			--- Basically vajag likt tikai tad, ja ir tukss... ?

			if table.getn(leakingRooms) > 0 then
				triggerToTriggerLeaks[scannerTriggerTable[scanner]] = leakingRooms
			end

		end

	end

end


function setDecompression(dt)

	--- Decompression
	for p in pairs(activeHolesList) do
		local pos = activeHolesList[p]
		local dir = activeDirList[p]

		--DebugLine(pos,VecAdd(pos,dir),1,0,0) --debug active holes

		ParticleReset()
		ParticleColor(0.9,0.9,0.9)
		ParticleRadius(1)
		ParticleType("plain")
		ParticleAlpha(0.25,0.0, "easeout")
		ParticleCollide(0)

		if math.random(1,10) > 8 then
			local velocity = math.random(-6,6)
			SpawnParticle(VecAdd(pos,Vec(0,0,math.random(-5,5))),Vec(0,0,velocity),1)
		end

		local holepos = VecAdd(pos,VecScale(dir,5))		--- Nezinu wtf

		-- Loop through rooms which have air leaks
		for roomTrigger, holesMap in pairs(triggerHolesMap) do

			-- Bound boxes of the room trigger
			local boundMin, boundMax = GetTriggerBounds(roomTrigger)

			-- Query for bodies only within the trigger of that room
			bodies = QueryAabbBodies(boundMin, boundMax)

			-- Get triggers which have a leak with the room in question
			if triggerToTriggerLeaks[roomTrigger] ~= nil then

				local leakingRoomsTable = triggerToTriggerLeaks[roomTrigger]
				DebugPrint("LEAKING ROOMS NOT NILL")
				DebugPrint(string.format("Leaking room count: %d", table.getn(leakingRoomsTable)))

				for index, leakingRoom in pairs(leakingRoomsTable) do
					local leakingMin, leakingMax = GetTriggerBounds(leakingRoom)
					otherBodies = QueryAabbBodies(leakingMin, leakingMax)

					for x, otherBody in pairs(otherBodies) do
						table.insert(bodies, otherBody)
					end

				end

			end

			-- Apply impulse towards the hole
			for b, body in pairs(bodies) do
				QueryRejectBody(body)
				local bodyCenter = TransformToParentPoint(GetBodyTransform(body),GetBodyCenterOfMass(body))
				ApplyBodyImpulse(body,bodyCenter,VecScale(VecSub(holepos,bodyCenter),bodyPressureSpeed))
			end

		end

		local ptrans = GetPlayerTransform()
		local vec = VecSub(holepos,ptrans.pos)	--- If player in the trigger(s)

		if VecLength(vec) < 20 then
			SetPlayerVelocity(VecAdd(GetPlayerVelocity(),VecScale(dir,playerPressureSpeed)))
		end

		hit, dist = QueryRaycast(pos,dir,10)
		if hit then
			activeTimeList[p] = activeTimeList[p] + dt
			if activeTimeList[p] > 5 then
				activeHolesList[p] = nil
				activeDirList[p] = nil
			end
		end
	end

end


function setTriggerToTriggerLeakMap()

end


--- Map a scanner object to a trigger object
function mapScannerToTrigger(scannerTriggerTable)
	for scannerIndex, scanner in pairs(scanners) do

		scannerPosition = GetLocationTransform(scanner).pos          --- Positional vector of the scanner

		--- Find the corresponding room trigger that the scanner is in and map them
		for triggerIndex, trigger in pairs(roomTriggers) do
			if IsPointInTrigger(trigger, scannerPosition) then
				scannerTriggerTable[scanner] = trigger
			end
		end

	end
end