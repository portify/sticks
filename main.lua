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

	-- local f = figure:new_poly(300, 300, 160, 12)

	-- Add a basic test figure
	local f = figure:new()
	f.root = joint:new{50, 50}
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
	elseif key == "r" then
		local f = figure:new()
		f.root = joint:new{50, 50}
		editor.figures = {f}
		update_joint_count()
	elseif key == "g" then
		GRAVITY_IS_A_THING = not GRAVITY_IS_A_THING
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

	-- for i, fig in ipairs(editor.figures) do
	-- 	fig:update(dt)
	-- end
end

local function draw_menu()
	local width, height = love.graphics.getDimensions()

	local bar_height = 22

	local label_space = 8
	local label_width = 64

	local labels = {"File", "Edit", "Tools", "Render", "Help"}

	love.graphics.setColor(196, 196, 196)
	love.graphics.rectangle("fill", 0, 0, width, bar_height)
	love.graphics.setColor(0, 0, 0, 183)

	local font = love.graphics.getFont()
	local x = 0

	local mx, my = love.mouse.getPosition()

	for i, label in ipairs(labels) do
		local w = font:getWidth(label) + label_space * 2

		if my < bar_height and mx >= x and mx < x + w then
			love.graphics.setColor(0, 0, 0, 32)
			love.graphics.rectangle("fill", x, 0, w, bar_height)
			love.graphics.setColor(0, 0, 0, 183)
		end

		love.graphics.print(label, x + label_space, 4)

		x = x + w
	end
end

local function draw_status()
	local width, height = love.graphics.getDimensions()
	local h = 22

	local text =
		"FPS: " .. love.timer.getFPS() .. "  |  " ..
		"Figures: " .. #editor.figures .. "  |  " ..
		"Joints: " .. editor.joint_count

	love.graphics.setColor(196, 196, 196)
	love.graphics.rectangle("fill", 0, height - h, width, h)
	love.graphics.setColor(0, 0, 0, 183)
	love.graphics.print(text, 8, height - h + 4)
end

local function draw_timeline()
	local width, height = love.graphics.getDimensions()

	local w = width
	local h = 64

	local x = 0
	local y = height - 22 - h

	local names_w = 96
	local times_h = 22

	love.graphics.setColor(206, 206, 206)
	love.graphics.rectangle("fill", x, y, w, h)

	-- Name background
	love.graphics.setColor(0, 0, 0, 32)
	love.graphics.rectangle("fill", x, y + times_h, names_w, h - times_h)

	-- Time ticks
	local tx = 0

	love.graphics.setColor(0, 0, 0, 72)

	while tx < w - names_w do
		love.graphics.print(tx / 50, names_w + tx, y + 4)
		--love.graphics.line(names_w + tx, y + times_h, names_w + tx, y + h)
		love.graphics.rectangle("fill", names_w + tx, y + times_h, 1, h - times_h)
		tx = tx + 50
	end

	-- Frame indicator
	love.graphics.setColor(255, 0, 0)
	love.graphics.rectangle("fill", x + names_w, y + times_h, 2, h - times_h)
end

function love.draw()
	for i, fig in ipairs(editor.figures) do
		fig:draw()
	end

	draw_menu()
	draw_status()
	draw_timeline()
end
