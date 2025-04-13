PowerUp = Class({})

function PowerUp:init(skin, x, y)
	self.skin = skin
	self.x = x
	self.y = y
	self.dy = math.random(50, 100)
	self.width = 16
	self.height = 16

	self.touched = false -- whether user has discovered it
	self.expired = false -- Expired means either claimed or missed
end

function PowerUp:setPosition(x, y)
	self.x = x
	self.y = y
end

function PowerUp:touch()
	self.touched = true
end

function PowerUp:expire()
	self.expired = true
end

function PowerUp:update(dt)
	if self.touched and not self.expired then
		self.y = self.y + self.dy * dt
	end

	if self.y >= VIRTUAL_HEIGHT then -- Expire it if reaches ground
		self.expired = true
	end
end

function PowerUp:render()
	if self.touched and not self.expired then
		love.graphics.draw(gTextures["main"], gFrames["powerups"][self.skin], self.x, self.y)
	end
end
