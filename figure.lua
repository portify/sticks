local joint = require "joint"

local figure = {}
figure.__index = figure

-- Class methods
function figure:new()
    return setmetatable({}, self)
end

function figure:new_poly(cx, cy, radius, count)
	local f = figure:new()
	local j

	for i=0, count-1 do
		local x = cx + radius * math.cos(math.pi * 2 * (i / count))
		local y = cy + radius * math.sin(math.pi * 2 * (i / count))

		if i == 0 then
			j = joint:new{x, y}
			f.root = j
		else
			j = j:connect(joint:new{x, y})
		end
	end

	f.root.poly_loop = j
	return f
end

function figure:from_save(t)
    local f = self:new()

    if t ~= nil then
        f.root = joint:from_save(t)
    end

    return f
end

-- Instance methods
function figure:make_save()
    if self.root == nil then
        return nil
    end

    return self.root:make_save()
end

function figure:find_handle(x, y)
    if self.root ~= nil then
        return self.root:find_handle(x, y)
    end
end

function figure:count_joints()
    local count = 0

    local stack = {self.root}
    local visit = {[self.root] = true}

    while stack[1] ~= nil do
        local top = table.remove(stack)
        count = count + 1

        for i, j in ipairs(top.children) do
            if not visit[j] then
                table.insert(stack, j)
                visit[j] = true
            end
        end
    end

    return count
end

function figure:draw()
    if self.root ~= nil then
        self.root:draw()
    end
end

return figure
