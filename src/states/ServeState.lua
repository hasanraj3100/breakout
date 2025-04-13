ServeState = Class({ __includes = BaseState })

function ServeState:enter(params)
	self.paddle = params.paddle
	self.bricks = params.bricks
	self.health = params.health
	self.score = params.score
	self.level = params.level
	self.highScores = params.highScores
	self.recoverPoints = params.recoverPoints
	self.powerups = params.powerups

	self.ball = Ball()
	self.ball.skin = math.random(7)
end

function ServeState:update(dt)
	self.paddle:update(dt) -- to get the current position of the paddle

	self.ball.x = self.paddle.x + self.paddle.width / 2 - 4
	self.ball.y = self.paddle.y - 8

	if love.keyboard.wasPressed("enter") or love.keyboard.wasPressed("return") then
		-- Remove powerups that I touched but failed to claim in the last round

		for i, powerUp in pairs(self.powerups) do
			if powerUp.claimed then
				table.remove(self.powerups, powerUp)
			end
		end

		gStateMachine:change("play", {
			paddle = self.paddle,
			bricks = self.bricks,
			health = self.health,
			score = self.score,
			balls = { self.ball },
			level = self.level,
			highScores = self.highScores,
			recoverPoints = self.recoverPoints,
			powerups = self.powerups,
		})
	end

	if love.keyboard.wasPressed("escape") then
		love.event.quit()
	end
end

function ServeState:render()
	self.paddle:render()
	self.ball:render()

	for _, brick in pairs(self.bricks) do
		brick:render()
	end

	renderScore(self.score)
	renderHealth(self.health)

	love.graphics.setFont(gFonts["large"])
	love.graphics.printf("Level " .. tostring(self.level), 0, VIRTUAL_HEIGHT / 3, VIRTUAL_WIDTH, "center")

	love.graphics.setFont(gFonts["medium"])
	love.graphics.printf("Press Enter to serve!", 0, VIRTUAL_HEIGHT / 2, VIRTUAL_WIDTH, "center")
end
