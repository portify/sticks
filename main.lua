editor = {
	figures = {},
	draw_handles = true,
	drag_use_ik = true,
	joint_count = 0
}

local joint = require "joint"
local figure = require "figure"

local function update_joint_count(curr)
	if curr == nil then
		editor.joint_count = 0

		for i, fig in ipairs(editor.figures) do
			if fig.root ~= nil then
				update_joint_count(fig.root)
			end
		end
	else
		editor.joint_count = editor.joint_count + 1

		for i, j in ipairs(curr.children) do
			update_joint_count(j)
		end
	end
end

local function find_handle(x, y)
	-- Could be made a lot more efficient
	-- Should use quadtrees
	for i, fig in ipairs(editor.figures) do
		local j = fig:find_handle(x, y)

		if j ~= nil then
			return j
		end
	end
end

function love.load()
	love.graphics.setBackgroundColor(222, 222, 222)

	-- Add a basic test figure
	local f = figure:new()
	f.root = joint:new{50, 50}
	f.root:connect(joint:new{ 50, 150})
	f.root:connect(joint:new{150,  50})
	table.insert(editor.figures, f)
	update_joint_count()
end

function love.mousepressed(x, y, button)
	-- If handles are invisible none of this should work
	if not editor.draw_handles then
		return
	end

	if button == "l" then
		-- Start dragging a joint
		editor.drag_handle = find_handle(x, y)

		if editor.drag_handle ~= nil then
			editor.active_joint = editor.drag_handle

			editor.drag_x = editor.drag_handle.pos[1] - x
			editor.drag_y = editor.drag_handle.pos[2] - y
		end
	elseif button == "r" and editor.active_joint ~= nil then
		-- Connect new joint to active joint
		editor.active_joint = editor.active_joint:connect(joint:new{x, y})
		editor.joint_count = editor.joint_count + 1
	elseif button == "m" then
		-- Lock a joint in place
		local j = find_handle(x, y)

		if j ~= nil then
			j.locked = not j.locked
		end
	end
end

function love.mousereleased(x, y, button)
	if button == "l" then
		editor.drag_handle = nil
		editor.drag_x = nil
		editor.drag_y = nil
	end
end

function love.update(dt)
	if editor.drag_handle ~= nil then
		local mx, my = love.mouse.getPosition()
		if editor.drag_use_ik then
			editor.drag_handle:move_to(
				mx + editor.drag_x,
				my + editor.drag_y,
				nil)
		else
			editor.drag_handle.pos[1] = mx + editor.drag_x
			editor.drag_handle.pos[2] = my + editor.drag_y
		end
	end
end

function love.draw()
	for i, fig in ipairs(editor.figures) do
		fig:draw()
	end

	local width, height = love.graphics.getDimensions()

	local stats_w = width - 8
	local stats_h = love.graphics.getFont():getHeight("X") + 8
	local stats_x = 8
	local stats_y = height - stats_h + 4

	local text =
		"FPS: " .. love.timer.getFPS() .. "  |  " ..
		"Figures: " .. #editor.figures .. "  |  " ..
		"Joints: " .. editor.joint_count

	love.graphics.setColor(163, 163, 163, 83)
	love.graphics.rectangle("fill", 0, height - stats_h, width, stats_h)

	love.graphics.setColor(0, 0, 0, 183)
	love.graphics.print(text, stats_x, stats_y)
end
