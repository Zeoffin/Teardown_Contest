--- Main script

function init()
    sanitizeDoorLights()
end

function tick()

end

function sanitizeDoorLights()
    --- Turns off all door control lights at the beginning because the fucking lights can't be turned off in any
    --- other way at the beginning of the level

    doorLights = FindLights('doorControlLight', true)
    emergencyLights = FindLights('emergencyLight', true)

    for index, lightSource in pairs(doorLights) do
        SetLightEnabled(lightSource, false)
    end

    for index, lightSource in pairs(emergencyLights) do
        SetLightEnabled(lightSource, false)
    end

end