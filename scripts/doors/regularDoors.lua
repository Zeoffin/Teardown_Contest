--- This script deals with all the regular doors.

internalClock = 0       -- Door clock
closingFlag = false     -- Door clock
closingClock = 0
doorOpeningTime = 3     -- Time doors remain open
doorClosingTime = 1
doorSpeed = 1           -- Meters/second. How fast to open/close the doors
doorStrength = 500      -- Strength parameter when setting joint motor.
doorsOpen = false       -- Door status

function init()

    doorButtons = FindShapes("doorButton")
    doors = FindShapes("regularDoor")

    greenLights, redLights = findDoorLights()

end

function tick(dt)
    checkForDoorInteraction(dt)
end

function checkForDoorInteraction(dt)

    -- User interacts with door button
    for doorIndex, doorButton in pairs(doorButtons) do
        if GetPlayerInteractShape() == doorButton and InputPressed('interact') then

            if not doorsOpen and not closingFlag then
                internalClock = doorOpeningTime
                enableSetOfLights(greenLights, true)
                doorsOpen = true
                moveDoor(doors[1], true)
                moveDoor(doors[2], true)

            end

        end

    end

    -- When doors are opening
    if doorsOpen then
        if internalClock > 0 then
            internalClock = internalClock - dt
        else
            internalClock = 0
            closingFlag = true
            doorsOpen = false
            closingClock = doorClosingTime
            enableSetOfLights(greenLights, false)
            enableSetOfLights(redLights, true)
            moveDoor(doors[1], false)
            moveDoor(doors[2], false)
        end
    end

    -- When doors are closing
    if closingFlag then
        if closingClock > 0 then
            closingClock = closingClock - dt
        else
            closingFlag = false
            doorsOpen = false
            closingClock = 0
            enableSetOfLights(redLights, false)
        end
    end


    end

function findDoorLights()

    doorLights = FindLights('doorControlLight')

    local greenLights={}
    local redLights={}

    for index, light in pairs(doorLights) do
        if HasTag(light, 'green') then
            table.insert(greenLights, light)
        else
            table.insert(redLights, light)
        end
    end

    return greenLights, redLights

end

function enableSetOfLights(lightSet, enabled)
    for idx, light in pairs(lightSet) do
        SetLightEnabled(light, enabled)
    end
end

function moveDoor(door, open)
	local motor = GetShapeJoints(door)[1]
	local min, max = GetJointLimits(motor)

	if open then
		SetJointMotorTarget(motor, max, doorSpeed, doorStrength)
	else
		SetJointMotorTarget(motor, min, doorSpeed, doorStrength)
    end
end