
function init()

    UiMakeInteractive()

end

function tick()

    --screen = UiGetScreen()

    DebugPrint(screen)

    if screen ~= nill then
        --DebugPrint("durvis?")
    end

end

function draw()
    UiColor(1,0,0)
    UiTranslate(UiCenter(), UiMiddle())
    UiAlign("center middle")
    UiRect(100,100)
    UiPush()
end

