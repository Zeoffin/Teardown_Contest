#include "common.lua"

pTool = GetStringParam("tool", "none")

function init()
	body = FindBody("tool")
	snd = LoadSound("tool_pickup.ogg")
	SetTag(body, "interact", "Pick up")
end

function tick(dt)
	if GetBool("game.tool."..pTool..".enabled") then
		Delete(body)
		body = nil
	end
	if body ~= nil then
		if GetPlayerInteractBody() == body and InputPressed("interact") then
			PlaySound(snd)
			SetBool("savegame.tool."..pTool..".enabled", true)
			SetString("game.player.tool", pTool)
			SetBool("game.tool."..pTool..".enabled", true)
			Delete(body)
			body = nil
		end
	end
end
