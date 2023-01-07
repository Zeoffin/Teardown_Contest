--- File that deals with the airScanners to check for holes in the spaceship and apply the effect of decompression
--- Thanks to the guy who wrote Boeing 737 mod for the idea

--- TODO: Query everything with tag rayCanPass to set as rejectBody

starCount = 24     											--- Number of star directions

function init()
	scanners = FindLocations("airScanner", true)	            	--- Locations of the scanners
	DebugPrint(scanners)
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

	if rotationVal ~=360 then
		rotationVal =  rotationVal + 2
	else
		rotationVal = 0
	end

	--- Check for holes
	if pressure > 0 then
		i = 0 --raycast counter

			for r=0,starCount do
				
				local quat = QuatEuler(0,0,r*360/starCount)
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

						for rayTracingLimits=1,4 do
							hit, dist, normal = QueryRaycast(rayPosition,rotatedVector,50)
							endpoint = VecAdd(rayPosition, VecScale(rotatedVector, dist))
							--DrawLine(rayPosition, endpoint, 1, 0, 0)
							if not hit then
								DebugPrint("FOUND HOLE")
								activePosList[i] = rayPosition
								activeDirList[i] = rotatedVector
								activeTimeList[i] = 0
								break
							else
								rayPosition = VecCopy(endpoint)
								rotatedVector = VecSub(rotatedVector, VecScale(normal, VecDot(normal, rotatedVector)*2))
							end
						end
					end
				end

			end

		for p in pairs(activePosList) do
			local pos = activePosList[p]
			local dir = activeDirList[p]

			--DebugLine(pos,VecAdd(pos,dir),1,0,0) --debug active holes

			ParticleReset()
			ParticleColor(0.9,0.9,0.9)
			ParticleRadius(1)
			ParticleType("plain")
			ParticleAlpha(0.3,0.0, "easeout")
			ParticleCollide(0)

			if math.random(1,10) > 8 then
				local velocity = math.random(-6,6)
				SpawnParticle(VecAdd(pos,Vec(0,0,math.random(-5,5))),Vec(0,0,velocity),1)
			end

			local holepos = VecAdd(pos,VecScale(dir,7))

			--if holepos[3] < -44 then
			--	holepos[3] = -50
			--end

			bodies = QueryAabbBodies(VecSub(pos,Vec(6,6,20)),VecAdd(pos,Vec(6,6,20)))
			for b, body in pairs(bodies) do
				QueryRejectBody(body)
				local center = TransformToParentPoint(GetBodyTransform(body),GetBodyCenterOfMass(body))
				ApplyBodyImpulse(body,center,VecScale(VecSub(holepos,center),0.5))
			end
			local ptrans = GetPlayerTransform()
			local vec = VecSub(holepos,ptrans.pos)
			if VecLength(vec) < 20 then
				SetPlayerVelocity(VecAdd(GetPlayerVelocity(),VecScale(dir,0.02)))
			end
			hit, dist = QueryRaycast(pos,dir,10)
			if hit then
				activeTimeList[p] = activeTimeList[p] + dt
				if activeTimeList[p] > 5 then
					activePosList[p] = nil
					activeDirList[p] = nil
				end
			end
		end

	end

end