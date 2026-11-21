-- This is a port made by BloonyFox

local function isDoodleStrumsEnabled()
	local val = getPropertyFromClass('backend.ClientPrefs', 'data.doodleStrums')
	if val == nil then
		val = getPropertyFromClass('ClientPrefs', 'data.doodleStrums')
	end
	if val == nil then
		val = getProperty('ClientPrefs.data.doodleStrums')
	end
	return val ~= false
end

function onCreatePost()
	if not isDoodleStrumsEnabled() then return end
	colorizeStrums()
end

function onCountdownTick()
	if not isDoodleStrumsEnabled() then return end
	colorizeStrums()
end

function onEvent(name, val1, val2)
	if not isDoodleStrumsEnabled() then return end
	if name == "Change Character" then
		colorizeStrums()
	end
end

function colorizeStrums()
	strumColFix(4, 7, getProperty('boyfriend.healthColorArray'))
	strumColFix(0, 3, getProperty('dad.healthColorArray'))
end

function strumColFix(stFrom, stTo, stCol)
	if stCol == nil then return end
	stCol = getColorFromHex(rgbToHex(stCol))

	for i = 0, 7 do
		if i >= stFrom and i <= stTo then
			setPropertyFromGroup('strumLineNotes', i, 'color', stCol)
		end
	end
end

function rgbToHex(array)
	return string.format('%.2x%.2x%.2x', array[1], array[2], array[3])
end