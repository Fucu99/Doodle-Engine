local function getPref(name, fallback)
	local val = getPropertyFromClass('backend.ClientPrefs', 'data.' .. name)
	if val == nil then
		val = getPropertyFromClass('ClientPrefs', 'data.' .. name)
	end
	if val == nil then
		val = getProperty('ClientPrefs.data.' .. name)
	end
	if val == nil then
		return fallback
	end
	return val
end

local function styleSingleNote(groupName, index)
	if getPref('accHighContrastNotes', false) then
		setPropertyFromGroup(groupName, index, 'rgbShader.b', getColorFromHex('111827'))
		setPropertyFromGroup(groupName, index, 'alpha', 1)
	end
end

local function applyContrastStyling()
	if not getPref('accHighContrastNotes', false) then return end

	for i = 0, 7 do
		setPropertyFromGroup('strumLineNotes', i, 'color', getColorFromHex('FFFFFF'))
	end

	local notesLen = getProperty('notes.length') - 1
	for i = 0, notesLen do
		styleSingleNote('notes', i)
	end

	local unspawnLen = getProperty('unspawnNotes.length') - 1
	for i = 0, unspawnLen do
		styleSingleNote('unspawnNotes', i)
	end
end

function onCreatePost()
	-- 1. Background Dim
	local dimVal = tonumber(getPref('accDimBackground', 0)) or 0
	if dimVal > 0 then
		makeLuaSprite('accBgDim', '', -200, -200)
		makeGraphic('accBgDim', screenWidth * 2, screenHeight * 2, '000000')
		setScrollFactor('accBgDim', 0, 0)
		setProperty('accBgDim.alpha', math.min(0.9, dimVal))
		addLuaSprite('accBgDim', false)
	end

	-- 2. Lane Guide Columns
	if getPref('accLaneDividers', false) then
		for i = 0, 7 do
			local sx = getPropertyFromGroup('strumLineNotes', i, 'x')
			local sw = getPropertyFromGroup('strumLineNotes', i, 'width')
			makeLuaSprite('accLaneDiv_' .. i, '', sx + sw + 2, 50)
			makeGraphic('accLaneDiv_' .. i, 2, screenHeight - 100, 'FFFFFF')
			setObjectCamera('accLaneDiv_' .. i, 'hud')
			setProperty('accLaneDiv_' .. i .. '.alpha', 0.22)
			addLuaSprite('accLaneDiv_' .. i, false)
		end
	end

	-- 3. High Contrast Notes
	applyContrastStyling()
end

function onCountdownTick()
	applyContrastStyling()
end

function onSpawnNote(id, noteData, noteType, isSustainNote)
	styleSingleNote('notes', id)
end

function onUpdatePost(elapsed)
	if getPref('accDisableCameraShake', false) then
		setProperty('camGame.shakeIntensity', 0)
		setProperty('camHUD.shakeIntensity', 0)
	end

	if getPref('accDisableCameraZoom', false) then
		setProperty('camZooming', false)
		setProperty('camGame.zoom', 1)
		setProperty('camHUD.zoom', 1)
	end
end