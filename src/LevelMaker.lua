LevelMaker = Class({})

function LevelMaker:createMap(level)
	local bricks = {}

	local numRows = math.random(1, 5)
	local numCols = math.random(7, 13)
	numCols = numCols % 2 == 0 and (numCols + 1) or numCols

	-- max spawned brick color
	local highestTier = math.min(3, math.floor(level / 5))
	local highestColor = math.min(5, level % 5 + 3)

	for y = 1, numRows do
		local skipPattern = math.random(1, 2) == 1 and true or false
		local alternativePattern = math.random(1, 2) == 1 and true or false

		local alternatingColor1 = math.random(1, highestColor)
		local alternatingColor2 = math.random(1, highestColor)
		local alternatingTier1 = math.random(0, highestTier)
		local alternatingTier2 = math.random(0, highestTier)

		local skipFlag = math.random(2) == 1 and true or false
		local alternateFlag = math.random(2) == 1 and true or false

		local solidColor = math.random(1, highestColor)
		local solidTier = math.random(0, highestTier)

		for x = 1, numCols do
			if skipPattern and skipFlag then
				skipFlag = not skipFlag
				goto continue
			else
				skipFlag = not skipFlag
			end

			local b = Brick((x - 1) * 32 + 8 + (13 - numCols) * 16, y * 16)

			if alternativePattern and alternateFlag then
				b.color = alternatingColor1
				b.tier = alternatingTier1
				alternateFlag = not alternateFlag
			else
				b.color = alternatingColor2
				b.tier = alternatingTier2
				alternateFlag = not alternateFlag
			end

			if not alternativePattern then
				b.color = solidColor
				b.tier = solidTier
			end

			table.insert(bricks, b)

			::continue::
		end
	end

	if #bricks == 0 then
		return self.createMap(level)
	else
		return bricks
	end
end
