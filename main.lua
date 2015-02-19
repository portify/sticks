editor = {
	figures = {},
	draw_handles = true,
	drag_use_ik = true,
	joint_count = 0
}

local msgpack = require "lib/msgpack"

local joint = require "joint"
local figure = require "figure"

local function update_joint_count()
	local count = 0

	for i, f in ipairs(editor.figures) do
		count = count + f:count_joints()
	end

	editor.joint_count = count
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

local function from_save(t)
	editor.figures = {}

	for i, data in ipairs(t) do
		table.insert(editor.figures, figure:from_save(data))
	end

	update_joint_count()
end

local function make_save()
	local t = {}

	for i, j in ipairs(editor.figures) do
		table.insert(t, j:make_save())
	end

	return t
end

function love.load()
	love.graphics.setBackgroundColor(222, 222, 222)

	-- Add a basic test figure
	local f = figure:new()
	f.root = joint:new{50, 50}
	-- f.root:connect(joint:new{ 50, 150})
	-- f.root:connect(joint:new{150,  50})
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

function love.keypressed(key, scancode)
	--  hardcoded filename for now
	local name = "scene.mps"

	if key == "s" then
		love.filesystem.write(name, msgpack.pack(make_save()))
	elseif key == "l" then
		from_save(msgpack.unpack(love.filesystem.read(name)))
	end

	-- stuff
	if editor.active_joint ~= nil then
		local j = editor.active_joint

		if key == "c" then
			j.is_circle = not j.is_circle
		end
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
