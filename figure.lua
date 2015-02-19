local figure = {}
figure.__index = figure

function figure:new()
    return setmetatable({}, self)
end

function figure:new_poly(cx, cy, radius, count)
	local f = figure:new()
	local j

	for i=0, count do
		local x = cx + radius * math.cos(math.pi * 2 * (i / count))
		local y = cy + radius * math.sin(math.pi * 2 * (i / count))

		if i == 0 then
			j = joint:new{x, y}
			f.root = j
		else
			j = j:connect(joint:new{x, y})
		end
	end

	j.circle_connect = f.root
	return f
end

function figure:find_handle(x, y)
    if self.root ~= nil then
        return self.root:find_handle(x, y)
    end
end

function figure:draw()
    if self.root ~= nil then
        self.root:draw()
    end
end

return figure
