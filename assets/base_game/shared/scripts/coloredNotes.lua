-- This is a mod made by BloonyFox
dadCols = {150, 150, 150}
dadColsDark = {50, 50, 50}

bfCols = {150, 150, 150}
bfColsDark = {50, 50, 50}

dadColsKap = {150, 150, 150}
dadColsDarkKap = {50, 50, 50}

bfColsKap = {150, 150, 150}
bfColsDarkKap = {50, 50, 50}

kapSt = true
kapStVal = 100

kapStNote1 = 1
kapStNote2 = 3

local function isDoodleNotesEnabled()
	local val = getPropertyFromClass('backend.ClientPrefs', 'data.doodleNotes')
	if val == nil then
		val = getPropertyFromClass('ClientPrefs', 'data.doodleNotes')
	end
	if val == nil then
		val = getProperty('ClientPrefs.data.doodleNotes')
	end
	return val ~= false
end

function onCreatePost()
	if not isDoodleNotesEnabled() then return end
	colorizeNotes()
end

function onCountdownTick()
	if not isDoodleNotesEnabled() then return end
	colorizeNotes()
end

function onEvent(name, val1, val2)
	if not isDoodleNotesEnabled() then return end
	if name == "Change Character" then
		colorizeNotes()
	end
end

function colorizeNotes()
	for i = 1, 3 do
		bfCols[i] = getProperty('boyfriend.healthColorArray')[i] or 150
		dadCols[i] = getProperty('dad.healthColorArray')[i] or 150
		
		bfColsDark[i] = bfCols[i] - 125
		dadColsDark[i] = dadCols[i] - 125

		bfColsKap[i] = bfCols[i] + kapStVal
		dadColsKap[i] = dadCols[i] + kapStVal
		
		bfColsDarkKap[i] = bfColsDark[i] + kapStVal
		dadColsDarkKap[i] = dadColsDarkKap[i] + kapStVal
		
		bfCols[i] = math.max(0, math.min(255, bfCols[i]))
		dadCols[i] = math.max(0, math.min(255, dadCols[i]))
		bfColsDark[i] = math.max(0, math.min(255, bfColsDark[i]))
		dadColsDark[i] = math.max(0, math.min(255, dadColsDark[i]))
		bfColsKap[i] = math.max(0, math.min(255, bfColsKap[i]))
		dadColsKap[i] = math.max(0, math.min(255, dadColsKap[i]))
		bfColsDarkKap[i] = math.max(0, math.min(255, bfColsDarkKap[i]))
		dadColsDarkKap[i] = math.max(0, math.min(255, dadColsDarkKap[i]))
    end

	noteColFix(bfCols, bfColsDark, bfColsKap, bfColsDarkKap, true)
	noteColFix(dadCols, dadColsDark, dadColsKap, dadColsDarkKap, false)
end

function noteColFix(stCol, stColDark, stColKap, stColDarkKap, stHit)
	stCol = getColorFromHex(rgbToHex(stCol))
	stColDark = getColorFromHex(rgbToHex(stColDark))
	stColKap = getColorFromHex(rgbToHex(stColKap))
	stColDarkKap = getColorFromHex(rgbToHex(stColDarkKap))

	for i = 0, getProperty('unspawnNotes.length') - 1 do
		local tmpNoteData = getPropertyFromGroup('unspawnNotes', i, 'noteData')
	
		if getPropertyFromGroup('unspawnNotes', i, 'mustPress') == stHit then
			if (kapSt == true and tmpNoteData ~= kapStNote1 and tmpNoteData ~= kapStNote2) or kapSt == false then
				setPropertyFromGroup('unspawnNotes', i, 'rgbShader.r', stCol)
				setPropertyFromGroup('unspawnNotes', i, 'rgbShader.b', stColDark)
			else
				setPropertyFromGroup('unspawnNotes', i, 'rgbShader.r', stColKap)
				setPropertyFromGroup('unspawnNotes', i, 'rgbShader.b', stColDarkKap)
			end
		end
    end
end

function rgbToHex(array)
	return string.format('%.2x%.2x%.2x', array[1], array[2], array[3])
end