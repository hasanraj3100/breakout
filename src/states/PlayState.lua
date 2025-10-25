PlayState = Class({ __includes = BaseState })

function PlayState:enter(params)
	self.paddle = params.paddle
	self.bricks = params.bricks
	self.health = params.health
	self.score = params.score
	self.balls = params.balls
	self.level = params.level
	self.highScores = params.highScores
	self.recoverPoints = params.recoverPoints
	self.powerups = params.powerups
	self.sizeIncScore = params.sizeIncScore

	self.balls[1].dx = math.random(-200, 200) -- Speed for the first ball we got from the serve state
	self.balls[1].dy = math.random(50, 200)
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

	for _, ball in pairs(self.balls) do
		ball:update(dt)
	end

	for _, brick in pairs(self.bricks) do
		brick:update(dt)
	end

	-- Ball collides the Paddle
	for _, ball in pairs(self.balls) do
		if ball:collides(self.paddle) then
			ball.y = self.paddle.y - 8
			ball.dy = -ball.dy

			-- Tweak Angle of Bounce

			if ball.x < self.paddle.x + self.paddle.width / 2 and self.paddle.dx < 0 then
				ball.dx = -50 + -(8 * (self.paddle.x + self.paddle.width / 2 - ball.x))
			elseif ball.x > self.paddle.x + self.paddle.width / 2 and self.paddle.dx > 0 then
				ball.dx = 50 + (8 * math.abs(self.paddle.x + self.paddle.width / 2 - ball.x))
			end

			gSounds["paddle-hit"]:play()
		end
	end

	-- Ball collides the bricks

	for _, ball in pairs(self.balls) do
		for _, brick in pairs(self.bricks) do
			if brick.inPlay and ball:collides(brick) then
				brick:hit()

				-- Is this victory

				if self:checkVictory() then
					gSounds["victory"]:play()

					gStateMachine:change("victory", {
						level = self.level,
						paddle = self.paddle,
						health = self.health,
						score = self.score,
						ball = self.balls[1], -- Sending only one ball to the victory state
						recoverPoints = self.recoverPoints,
						highScores = self.highScores,
						sizeIncScore = self.sizeIncScore,
					})
				end

				self.score = self.score + (brick.tier * 200 + brick.color * 25)

				if self.score > self.sizeIncScore then
					self.paddle:increaseSize()
					self.sizeIncScore = self.sizeIncScore + 2000
				end

				if self.score > self.recoverPoints then
					self.health = math.min(3, self.health + 1)
					self.recoverPoints = math.min(100000, self.recoverPoints * 2)
					gSounds["recover"]:play()
				end

				if ball.x + 2 < brick.x and ball.dx > 0 then
					ball.dx = -ball.dx
					ball.x = brick.x - 8
				elseif ball.x + 6 > brick.x and ball.dx < 0 then
					ball.dx = -ball.dx
					ball.x = brick.x + 32
				elseif ball.y < brick.y then
					ball.dy = -ball.dy
					ball.y = brick.y - 8
				else
					ball.dy = -ball.dy
					ball.y = brick.y + 16
				end

				ball.dy = ball.dy * 1.02

				-- If the bricks is destroyed, run the powerup associatead with it (if any)

				if not brick.inPlay then
					for _, powerup in pairs(self.powerups) do
						if powerup.x == brick.x and powerup.y == brick.y then
							powerup:touch()
						end
					end
				end
			end
		end
	end

	-- Ball goes beyond the bottom the of the screen

	for i, ball in pairs(self.balls) do
		if ball.y >= VIRTUAL_HEIGHT then
			gSounds["hurt"]:play()

			table.remove(self.balls, i)
			if #self.balls == 0 then
				self.health = self.health - 1

				self.paddle:decreaseSize()

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
						powerups = self.powerups,
						sizeIncScore = self.sizeIncScore,
					})
				end
			end
		end
	end

	-- Update the powerups
	for _, powerup in pairs(self.powerups) do
		powerup:update(dt)
	end

	-- If powerup touches the paddle
	for _, powerup in pairs(self.powerups) do
		if powerup.touched then
			if
				powerup.x >= self.paddle.x
				and powerup.x <= self.paddle.x + self.paddle.width
				and powerup.y + powerup.height >= self.paddle.y
			then
				powerup:expire()
				self:addNewBall()
			elseif
				powerup.x + powerup.width >= self.paddle.x
				and powerup.x + powerup.width <= self.paddle.x + self.paddle.width
				and powerup.y + powerup.height >= self.paddle.y
			then
				powerup:expire()
				self:addNewBall()
			end
		end
	end

	-- Remove the powerups that are claimed

	for pos, powerup in pairs(self.powerups) do
		if powerup.expired then
			table.remove(self.powerups, pos)
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

	for _, powerup in pairs(self.powerups) do
		powerup:render()
	end

	for _, ball in pairs(self.balls) do
		ball:render()
	end

	self.paddle:render()

	renderScore(self.score)
	renderHealth(self.health)

	if self.paused then
		love.graphics.setFont(gFonts["large"])
		love.graphics.printf("PAUSED", 0, VIRTUAL_HEIGHT / 2 - 16, VIRTUAL_WIDTH, "center")
	end
end

function PlayState:addNewBall()
	local newBall = Ball(math.random(7))
	newBall:reset()
	newBall.dy = math.random(50, 100)

	table.insert(self.balls, newBall)
end
