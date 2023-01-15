--- File that deals with the airScanners to check for holes in the spaceship and apply the effect of decompression
--- Thanks to the guy who wrote Boeing 737 mod for the idea <3

emergencyStatus = false

starCount = 24     													-- Number of star directions
bodyPressureSpeed = 0.5												-- Force on the bodies
playerPressureSpeed = 0.01											-- Force on the player
starTracingLimit = 4												-- Number of times ray bounces off surface

-- RGB values for emergency light color and normal color
emergencyLighting = {1,0,0}
normalLighting = {0.42, 0.75, 1.0}

emergencyLightFreq = 0.8

function init()
	--- TEARDOWN INIT FUNCTION

	scanners = FindLocations("airScanner", true)	            	-- Locations of the scanners (global)
	roomTriggers = FindTriggers('airTrigger', true)					-- All triggers (global)

	accentLights = FindLights('accentLight', true)					-- Get all accent lights (global)
	accentLightsShapes = FindLights('accentLight', true)			-- Get all accent light shapes (global)

	emergencyLights = FindLights('emergencyLight', true)			-- Get all emergency lights (global)
	emergencyLightsShapes = FindShapes('emergencyLight', true)		-- Get all shapes of emergency lights (global)

	pressure = true                                 				-- Pressure
	activeHolesList = {}                              				-- List of all holes
	activeDirList = {}                              				-- List of all direction scanning
	activeTimeList = {}                             				-- smt ?
	scannerTriggerTable = {}										-- Hash table in form {scanner: trigger}
	triggerToTriggerLeaks = {}
	activated = false 												-- Changes when everything activates
	timer = 0
	rotationVal = 0

	mapScannerToTrigger(scannerTriggerTable)						-- Map each scanner to a trigger

end


function tick(dt)
	--- TEARDOWN TICK FUNCTION

	if pressure then

		findHoles()
		setDecompression(dt)

	end

end


function findHoles()
	--- Find holes in the space station by shooting rays in rooms and checking if the ray hits a wall

	-- Deals with the speed of the rays
	if rotationVal ~=360 then
		rotationVal =  rotationVal + 2
	else
		rotationVal = 0
	end

	triggerHolesMap = {}			-- Hash map {Trigger : TableOfHoles}
	triggerToTriggerLeaks = {}		-- Hash map {Trigger : [Trigger]}

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

				-- Ray tracing loop
				for rayTracingLimits=1, starTracingLimit do

					hit, dist, normal = QueryRaycast(rayPosition,rotatedVector,200)
					endpoint = VecAdd(rayPosition, VecScale(rotatedVector, dist))
					--DrawLine(rayPosition, endpoint, 1, 0, 0)		-- Draws the rays

					-- Detect if the ray is leaking from one room trigger to another
					for secondScanner, roomTrigger in pairs(scannerTriggerTable) do

						if (IsPointInTrigger(roomTrigger, endpoint) or IsPointInTrigger(roomTrigger, rayPosition)) and scanner ~= secondScanner then
							--DebugCross(endpoint, 0,1,0)		-- Draw rays that are outside its parent trigger
							table.insert(leakingRooms, roomTrigger)
						end

					end

					-- Check for a hole here
					if not hit then
						DebugPrint("FOUND HOLE")
						emergencyStatus = true
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

			-- Set the new values only if leakage exists
			if table.getn(leakingRooms) > 0 then
				triggerToTriggerLeaks[scannerTriggerTable[scanner]] = leakingRooms
			end

		end

	end

end


function setDecompression(dt)
	--- Sets the decompression effect when hole(s) are detected in the walls and further leakage has been found

	--DebugPrint(string.format("Number of holes: %d", #triggerHolesMap))

	if emergencyStatus then
		emergencySystem(emergencyStatus, dt)
	end

	-- Decompression
	for p in pairs(activeHolesList) do
		local pos = activeHolesList[p]
		local dir = activeDirList[p]

		--DebugLine(pos,VecAdd(pos,dir),1,0,0) --debug active holes

		decompressionParticles()	-- Set particle effect

		local holepos = VecAdd(pos,VecScale(dir,5))		-- Nezinu wtf

		-- Loop through rooms which have air leaks
		for roomTrigger, holesMap in pairs(triggerHolesMap) do

			-- Bound boxes of the room trigger
			local boundMin, boundMax = GetTriggerBounds(roomTrigger)

			-- Remove fire in the original room
			extinguishFire(boundMin, boundMax)

			-- Query for bodies only within the trigger of that room
			bodies = QueryAabbBodies(boundMin, boundMax)

			-- Get triggers which have a leak with the room in question
			if triggerToTriggerLeaks[roomTrigger] ~= nil then

				local leakingRoomsTable = triggerToTriggerLeaks[roomTrigger]
				DebugPrint(string.format("Leaking room count: %d", table.getn(leakingRoomsTable)))

				for index, leakingRoom in pairs(leakingRoomsTable) do
					local leakingMin, leakingMax = GetTriggerBounds(leakingRoom)

					extinguishFire(boundMin, boundMax)							-- Remove fire in leaking rooms
					otherBodies = QueryAabbBodies(leakingMin, leakingMax)		-- Get leaking room's bodies

					for x, otherBody in pairs(otherBodies) do
						table.insert(bodies, otherBody)
					end

				end

			end

			-- Apply body impulse towards the hole
			for b, body in pairs(bodies) do
				QueryRejectBody(body)
				local bodyCenter = TransformToParentPoint(GetBodyTransform(body),GetBodyCenterOfMass(body))
				ApplyBodyImpulse(body,bodyCenter,VecScale(VecSub(holepos,bodyCenter),bodyPressureSpeed))
			end

		end

		local ptrans = GetPlayerTransform()			-- Get player transform
		local vec = VecSub(holepos,ptrans.pos)		-- If player in the trigger(s)

		--- TODO: Saprast, kas te nahuj notiek
		if VecLength(vec) < 20 then
			SetPlayerVelocity(VecAdd(GetPlayerVelocity(),VecScale(dir,playerPressureSpeed)))
		end

		hit, dist = QueryRaycast(pos,dir,200)
		if hit then
			activeTimeList[p] = activeTimeList[p] + dt
			if activeTimeList[p] > 5 then
				activeHolesList[p] = nil
				activeDirList[p] = nil
			end
		end
	end

end

function mapScannerToTrigger(scannerTriggerTable)
	--- Map a scanner object to a trigger object

	for scannerIndex, scanner in pairs(scanners) do

		scannerPosition = GetLocationTransform(scanner).pos          -- Positional vector of the scanner

		-- Find the corresponding room trigger that the scanner is in and map them
		for triggerIndex, trigger in pairs(roomTriggers) do
			if IsPointInTrigger(trigger, scannerPosition) then
				scannerTriggerTable[scanner] = trigger
			end
		end

	end
end

function decompressionParticles()
	--- Generates particles in the hole

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

end

function emergencySystem(emergency, dt)
	--- Sets the global emergency system enabled / disabled
	setEmergencyLights(emergency, dt)
end

function setEmergencyLights(emergency, dt)
	--- Sets the accent lights according to if emergency is in progress or not

	if emergency then

		-- Turn off accent lights
		for index, light in pairs(accentLights) do
			SetLightEnabled(light, false)
		end

		-- Turn off emission from accent light shapes
		for index, lightShape in pairs(accentLightsShapes) do
			SetShapeEmissiveScale(lightShape, 0)
		end

		-- Change light color to red in emergency
		for index, light in pairs(emergencyLights) do
			SetLightColor(light, emergencyLighting[1],emergencyLighting[2],emergencyLighting[3])
		end

		-- Set the light to pulsate
		for index, lightShape in pairs(emergencyLightsShapes) do
			local scale = math.sin(GetTime())*emergencyLightFreq + 1
			SetShapeEmissiveScale(lightShape, scale)
		end

	else

		for index, light in pairs(emergencyLights) do
			SetLightColor(light, normalLighting[1],normalLighting[2],normalLighting[3])
		end

	end

end

function extinguishFire(min, max)
	--- When decompression happens in a room, the fire will be extinguished as it lacks oxygen in
	--- that particular room.
	RemoveAabbFires(min, max)

end