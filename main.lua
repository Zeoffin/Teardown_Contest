--- Starting point when loading in the mod initially

function init()
    sanitizeDoorLights()
end

function tick()

end

function sanitizeDoorLights()
    --- Turns off all door control lights at the beginning because API is dogshit

    allLights = FindLights('doorControlLight', true)
    for idx, lightSource in pairs(allLights) do
        SetLightEnabled(lightSource, false)
    end
end