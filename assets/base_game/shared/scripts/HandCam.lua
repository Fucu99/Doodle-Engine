-- Realistic HandCam effect for Doodle Engine
local handTime = 0

local function isHandCamEnabled()
	local val = getPropertyFromClass('backend.ClientPrefs', 'data.doodleHandCam')
	if val == nil then
		val = getPropertyFromClass('ClientPrefs', 'data.doodleHandCam')
	end
	if val == nil then
		val = getProperty('ClientPrefs.data.doodleHandCam')
	end
	return val ~= false
end

function onUpdatePost(elapsed)
	if not isHandCamEnabled() then
		setProperty('camGame.angle', 0)
		return
	end

	handTime = handTime + elapsed

	-- Multi-frequency organic handheld sway (breathing + micro hand tremor)
	local swayX = math.sin(handTime * 1.45) * 4.5 + math.sin(handTime * 3.7) * 1.4
	local swayY = math.cos(handTime * 1.85) * 3.8 + math.sin(handTime * 4.3) * 1.1
	local tiltAngle = math.sin(handTime * 1.15) * 0.65 + math.cos(handTime * 2.9) * 0.22

	local curScrollX = getProperty('camGame.scroll.x')
	local curScrollY = getProperty('camGame.scroll.y')

	setProperty('camGame.scroll.x', curScrollX + swayX * elapsed * 14)
	setProperty('camGame.scroll.y', curScrollY + swayY * elapsed * 14)
	setProperty('camGame.angle', tiltAngle)
end