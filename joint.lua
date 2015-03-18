local joint = {}
joint.__index = joint

-- Class methods
function joint:new(pos)
    return setmetatable({
        pos = pos,
        width = 2,
        is_circle = false,
        parent = nil,
        children = {},
        locked = false,
        vel = {0, 0}
    }, self)
end

function joint:from_save(t)
    local j = self:new(t.p)
    j.width = t.w

    if t.l then j.locked    = true end
    if t.r then j.is_circle = true end

    if t.c ~= nil then
        for i, data in ipairs(t.c) do
            j:connect(self:from_save(data))
        end
    end

    return j
end

-- Instance methods
function joint:make_save()
    local t = {
        p = self.pos,
        w = self.width
    }

    if self.locked    then t.l = true end
    if self.is_circle then t.r = true end

    if self.children[1] ~= nil then
        t.c = {}

        for i, j in ipairs(self.children) do
            table.insert(t.c, j:make_save())
        end
    end

    return t
end

function joint:connect(other)
    other:disconnect()
    other.parent = self
    table.insert(self.children, other)
    return other
end

function joint:disconnect()
    if self.parent ~= nil then
        for i, other in ipairs(self.parent.children) do
            if other == self then
                table.remove(self.parent.children, i)
                break
            end
        end

        self.parent = nil
    end
end

function joint:move_to(nx, ny, from)
    if self.locked and from ~= nil then
        return nx - self.pos[1], ny - self.pos[2]
    end

    -- Figure out what joints would be affected by moving this one
    local others = {}

    if self.parent ~= nil and from ~= self.parent then
        table.insert(others, self.parent)
    end

    for i, other in ipairs(self.children) do
        if from ~= other then
            table.insert(others, other)
        end
    end

    -- Move this joint
    local ox, oy = self.pos[1], self.pos[2]
    self.pos = {nx, ny}

    local total_resistutationing_x = 0
    local total_resistutationing_y = 0

    -- Try to move all the affected joints
    for i, other in ipairs(others) do
        -- This is pretty ugly
        local jx, jy = other.pos[1], other.pos[2] -- other joint pos

        -- Difference to old position
        local dx = ox - jx
        local dy = oy - jy
        local dlen = math.sqrt(dx^2 + dy^2)

        -- Difference to new position
        local lx = jx - nx
        local ly = jy - ny
        local llen = math.sqrt(lx^2 + ly^2)

        -- Try to pull the joint
        local rx, ry = other:move_to(
            nx + (lx / llen) * dlen,
            ny + (ly / llen) * dlen,
            self)

        -- The other joint resisted
        if math.abs(rx) > 0 or math.abs(ry) > 0 then
            -- Change our own position since the other end is acting on us
            -- Return how much this moved us away from our goal
            -- In reality for this to work well we need should recurse up the
            -- chain of affected joints and run a modified algorithm down to
            -- the locked joint if one is found from the start

            -- just out of curiosity
            -- what happens if i do this
            -- self.pos[1] = self.pos[1] - rx
            -- self.pos[2] = self.pos[2] - ry

            total_resistutationing_x = total_resistutationing_x + rx
            total_resistutationing_y = total_resistutationing_y + ry
        end
    end

    self.pos[1] = self.pos[1] - total_resistutationing_x
    self.pos[2] = self.pos[2] - total_resistutationing_y

    self.vel[1] = self.vel[1] - (ox - nx)
    self.vel[2] = self.vel[2] - (oy - ny)

    return total_resistutationing_x, total_resistutationing_y
end

function joint:find_handle(x, y)
    if
        x >= self.pos[1] - 4 and x <= self.pos[1] + 4 and
        y >= self.pos[2] - 4 and y <= self.pos[2] + 4
    then
        return self
    end

    for i, other in ipairs(self.children) do
        local find = other:find_handle(x, y)

        if find ~= nil then
            return find
        end
    end
end

function joint:draw_to(parent)
    if self.is_circle then
        local dx = self.pos[1] - parent.pos[1]
        local dy = self.pos[2] - parent.pos[2]

        local r = math.sqrt(dx^2 + dy^2) / 2

        local x = parent.pos[1] + dx / 2
        local y = parent.pos[2] + dy / 2

        love.graphics.circle("line", x, y, r, r*2)
    else
        love.graphics.line(parent.pos[1], parent.pos[2], self.pos[1], self.pos[2])
    end
end

function joint:update(dt)
    if #self.children > 0 then
        for i, child in ipairs(self.children) do
            child:update(dt)
        end

        return
    end

    -- self.vel[1] = self.vel[1] + 600 * dt
    -- self.vel[2] = self.vel[2] * 0.9999

    if GRAVITY_IS_A_THING then
        self.vel[1] = self.vel[1] + 600 * dt
        self.vel[2] = self.vel[2] + 800 * dt
    end

    local x = self.pos[1] + self.vel[1] * dt
    local y = self.pos[2] + self.vel[2] * dt

    self:move_to(x, y)
end

function joint:draw()
    love.graphics.setColor(0, 0, 0)
    love.graphics.setLineWidth(self.width)

    if self.parent then
        self:draw_to(self.parent)
    end

    if self.poly_loop then
        self:draw_to(self.poly_loop)
    end

    for i, other in ipairs(self.children) do
        other:draw()
    end

    if editor.draw_handles and editor.drag_handle == nil then
        if self == editor.active_joint then
            love.graphics.setColor(0, 255, 0)
        elseif self.locked then
            love.graphics.setColor(255, 0, 0)
        else
            love.graphics.setColor(0, 0, 255)
        end

        love.graphics.rectangle("fill", self.pos[1] - 4, self.pos[2] - 4, 8, 8)
    end
end

return joint
