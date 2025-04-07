PlayState = Class({ __includes = BaseState })

function PlayState:enter(params)
	self.paddle = params.paddle
	self.bricks = params.bricks
	self.health = params.health
	self.score = params.score
	self.ball = params.ball
	self.level = params.level
	self.highScores = params.highScores
	self.recoverPoints = params.recoverPoints

	self.ball.dx = math.random(-200, 200)
	self.ball.dy = math.random(50, 200)
end

function PlayState:update(dt)
	if self.paused then
		if love.keyboard.wasPressed("space") then
			self.paused = false
			gSounds["pause"]:play()
		else
			return
		end
	elseif love.keyboard.wasPressed("space") then
		self.paused = true
		gSounds["pause"]:play()
		return
	end

	self.paddle:update(dt)
	self.ball:update(dt)
	for _, brick in pairs(self.bricks) do
		brick:update(dt)
	end

	-- Ball collides the Paddle
	if self.ball:collides(self.paddle) then
		self.ball.y = self.paddle.y - 8
		self.ball.dy = -self.ball.dy

		-- Tweak Angle of Bounce

		if self.ball.x < self.paddle.x + self.paddle.width / 2 and self.paddle.dx < 0 then
			self.ball.dx = -50 + -(8 * (self.paddle.x + self.paddle.width / 2 - self.ball.x))
		elseif self.ball.x > self.paddle.x + self.paddle.width / 2 and self.paddle.dx > 0 then
			self.ball.dx = 50 + (8 * math.abs(self.paddle.x + self.paddle.width / 2 - self.ball.x))
		end

		gSounds["paddle-hit"]:play()
	end

	-- Ball collides the bricks

	for _, brick in pairs(self.bricks) do
		if brick.inPlay and self.ball:collides(brick) then
			brick:hit()

			-- Is this victory

			if self:checkVictory() then
				gSounds["victory"]:play()

				gStateMachine:change("victory", {
					level = self.level,
					paddle = self.paddle,
					health = self.health,
					score = self.score,
					ball = self.ball,
					recoverPoints = self.recoverPoints,
					highScores = self.highScores,
				})
			end

			self.score = self.score + (brick.tier * 200 + brick.color * 25)

			if self.score > self.recoverPoints then
				self.health = math.min(3, self.health + 1)
				self.recoverPoints = math.min(100000, self.recoverPoints * 2)
				gSounds["recover"]:play()
				print("new recover points : " .. tostring(self.recoverPoints))
			end

			if self.ball.x + 2 < brick.x and self.ball.dx > 0 then
				self.ball.dx = -self.ball.dx
				self.ball.x = brick.x - 8
			elseif self.ball.x + 6 > brick.x and self.ball.dx < 0 then
				self.ball.dx = -self.ball.dx
				self.ball.x = brick.x + 32
			elseif self.ball.y < brick.y then
				self.ball.dy = -self.ball.dy
				self.ball.y = brick.y - 8
			else
				self.ball.dy = -self.ball.dy
				self.ball.y = brick.y + 16
			end

			self.ball.dy = self.ball.dy * 1.02
		end
	end

	-- Ball goes beyond the bottom the of the screen

	if self.ball.y >= VIRTUAL_HEIGHT then
		self.health = self.health - 1
		gSounds["hurt"]:play()

		if self.health == 0 then
			gStateMachine:change("game-over", {
				score = self.score,
				highScores = self.highScores,
			})
		else
			gStateMachine:change("serve", {
				paddle = self.paddle,
				bricks = self.bricks,
				health = self.health,
				score = self.score,
				level = self.level,
				highScores = self.highScores,
				recoverPoints = self.recoverPoints,
			})
		end
	end

	if love.keyboard.wasPressed("escape") then
		love.event.quit()
	end
end

function PlayState:checkVictory()
	for _, brick in pairs(self.bricks) do
		if brick.inPlay then
			return false
		end
	end

	return true
end

---- RENDER -----
function PlayState:render()
	for _, brick in pairs(self.bricks) do
		brick:render()
	end

	for _, brick in pairs(self.bricks) do
		brick:renderParticles()
	end
	self.paddle:render()
	self.ball:render()

	renderScore(self.score)
	renderHealth(self.health)

	if self.paused then
		love.graphics.setFont(gFonts["large"])
		love.graphics.printf("PAUSED", 0, VIRTUAL_HEIGHT / 2 - 16, VIRTUAL_WIDTH, "center")
	end
end
