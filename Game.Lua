local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local CoreGui = game:GetService("CoreGui")
local LP = Players.LocalPlayer

-- =====================================================================
--  CUSTOM UI  (gaya "Quick Bar": kartu ungu, switch pink, bisa dilipat dengan - / +)
-- =====================================================================
local C = {
    bg       = Color3.fromRGB(58, 26, 66),    -- panel utama
    card     = Color3.fromRGB(76, 36, 84),    -- kartu section
    rowOff   = Color3.fromRGB(98, 50, 102),   -- baris mati
    rowOn    = Color3.fromRGB(138, 68, 128),  -- baris nyala
    head     = Color3.fromRGB(238, 218, 238),
    text     = Color3.fromRGB(255, 255, 255),
    dim      = Color3.fromRGB(210, 180, 210),
    pink     = Color3.fromRGB(255, 125, 170),
    track    = Color3.fromRGB(150, 108, 150),
    offTrack = Color3.fromRGB(128, 96, 134),
    line     = Color3.fromRGB(128, 76, 134),
}
-- alias untuk layar key
C.accent = C.pink
C.row = C.rowOff

local function create(class, props, parent)
    local o = Instance.new(class)
    for k, v in pairs(props) do
        o[k] = v
    end
    o.Parent = parent
    return o
end

local function corner(o, r)
    create("UICorner", { CornerRadius = UDim.new(0, r or 6) }, o)
end

local function stroke(o, color, thick)
    create("UIStroke", { Color = color or C.line, Thickness = thick or 1 }, o)
end

local function padding(o, p)
    create("UIPadding", {
        PaddingTop = UDim.new(0, p), PaddingBottom = UDim.new(0, p),
        PaddingLeft = UDim.new(0, p), PaddingRight = UDim.new(0, p),
    }, o)
end

local function label(parent, text, size, color, align)
    return create("TextLabel", {
        BackgroundTransparency = 1,
        Text = text,
        TextSize = size or 14,
        TextColor3 = color or C.text,
        Font = Enum.Font.GothamBold,
        TextXAlignment = align or Enum.TextXAlignment.Left,
        Size = UDim2.new(1, 0, 1, 0),
    }, parent)
end

local function tween(o, props, t)
    TweenService:Create(o, TweenInfo.new(t or 0.15), props):Play()
end

local function safe(fn, ...)
    if fn then
        pcall(fn, ...)
    end
end

local function isPointer(i)
    return i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch
end

local function isMove(i)
    return i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch
end

-- judul + (opsional) description di dalam baris
local function applyTitle(row, cfg, reserve)
    local hasDesc = cfg.Description ~= nil and cfg.Description ~= ""
    row.Size = UDim2.new(1, 0, 0, hasDesc and 52 or 40)

    local t = label(row, cfg.Title, 14, C.text)
    t.Font = Enum.Font.GothamMedium
    t.Position = UDim2.fromOffset(12, hasDesc and 6 or 0)
    t.Size = UDim2.new(1, -(24 + (reserve or 0)), 0, hasDesc and 20 or 40)

    if hasDesc then
        local d = label(row, cfg.Description, 11, C.dim)
        d.Font = Enum.Font.Gotham
        d.TextTruncate = Enum.TextTruncate.AtEnd
        d.Position = UDim2.fromOffset(12, 27)
        d.Size = UDim2.new(1, -(24 + (reserve or 0)), 0, 16)
    end
end

local function newRow(parent, order)
    local row = create("Frame", { BackgroundColor3 = C.rowOff, Size = UDim2.new(1, 0, 0, 40), LayoutOrder = order }, parent)
    corner(row, 8)
    return row
end

local function makeGroup(items, onAdd)
    local g = {}
    local order = 0
    local function nextOrder()
        order += 1
        if onAdd then
            onAdd(order)
        end
        return order
    end

    function g:Paragraph(text)
        local l = create("TextLabel", {
            BackgroundTransparency = 1,
            Text = text or "",
            TextWrapped = true,
            TextColor3 = C.text,
            TextSize = 13,
            Font = Enum.Font.GothamMedium,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextYAlignment = Enum.TextYAlignment.Top,
            Size = UDim2.new(1, 0, 0, 0),
            AutomaticSize = Enum.AutomaticSize.Y,
            LayoutOrder = nextOrder(),
        }, items)
        return { Set = function(_, s) l.Text = s end }
    end

    function g:Button(cfg)
        local row = newRow(items, nextOrder())
        applyTitle(row, cfg, 0)
        local hit = create("TextButton", { Text = "", BackgroundTransparency = 1, Size = UDim2.new(1, 0, 1, 0) }, row)
        hit.Activated:Connect(function()
            tween(row, { BackgroundColor3 = C.rowOn }, 0.08)
            task.delay(0.15, function()
                tween(row, { BackgroundColor3 = C.rowOff })
            end)
            safe(cfg.Callback)
        end)
    end

    function g:Toggle(cfg)
        local state = cfg.Default or false
        local row = newRow(items, nextOrder())
        applyTitle(row, cfg, 56)

        local track = create("Frame", { AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -12, 0.5, 0), Size = UDim2.fromOffset(46, 24), BackgroundColor3 = C.offTrack }, row)
        corner(track, 12)
        local knob = create("Frame", { AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 2, 0.5, 0), Size = UDim2.fromOffset(20, 20), BackgroundColor3 = Color3.new(1, 1, 1) }, track)
        corner(knob, 10)

        local function render(anim)
            local pos = state and UDim2.new(1, -22, 0.5, 0) or UDim2.new(0, 2, 0.5, 0)
            local trackColor = state and C.pink or C.offTrack
            local rowColor = state and C.rowOn or C.rowOff
            if anim then
                tween(knob, { Position = pos })
                tween(track, { BackgroundColor3 = trackColor })
                tween(row, { BackgroundColor3 = rowColor })
            else
                knob.Position = pos
                track.BackgroundColor3 = trackColor
                row.BackgroundColor3 = rowColor
            end
        end
        render(false)

        local hit = create("TextButton", { Text = "", BackgroundTransparency = 1, Size = UDim2.new(1, 0, 1, 0) }, row)
        hit.Activated:Connect(function()
            state = not state
            render(true)
            safe(cfg.Callback, state)
        end)

        return { Set = function(_, v) state = v; render(true) end }
    end

    function g:Slider(cfg)
        local min, max = cfg.Min, cfg.Max
        local value = cfg.Default or min

        local row = newRow(items, nextOrder())
        row.Size = UDim2.new(1, 0, 0, 56)

        local t = label(row, cfg.Title, 14, C.text)
        t.Font = Enum.Font.GothamMedium
        t.Position = UDim2.fromOffset(12, 4)
        t.Size = UDim2.new(1, -80, 0, 24)
        local v = label(row, tostring(value), 12, C.dim, Enum.TextXAlignment.Right)
        v.Font = Enum.Font.Code
        v.Position = UDim2.new(1, -72, 0, 4)
        v.Size = UDim2.new(0, 60, 0, 24)

        local bar = create("Frame", { BackgroundColor3 = C.track, BorderSizePixel = 0, Position = UDim2.fromOffset(14, 38), Size = UDim2.new(1, -28, 0, 6) }, row)
        corner(bar, 3)
        local fill = create("Frame", { BackgroundColor3 = C.pink, BorderSizePixel = 0, Size = UDim2.new(0, 0, 1, 0) }, bar)
        corner(fill, 3)
        local knob = create("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0, 0, 0.5, 0), Size = UDim2.fromOffset(14, 14), BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0 }, bar)
        corner(knob, 7)

        local function render()
            local a = (value - min) / (max - min)
            fill.Size = UDim2.new(a, 0, 1, 0)
            knob.Position = UDim2.new(a, 0, 0.5, 0)
            v.Text = tostring(value)
        end
        render()

        local dragging = false
        local function update(x)
            local a = math.clamp((x - bar.AbsolutePosition.X) / bar.AbsoluteSize.X, 0, 1)
            local nv = math.floor(min + a * (max - min) + 0.5)
            if nv ~= value then
                value = nv
                render()
                safe(cfg.Callback, value)
            end
        end

        local hit = create("TextButton", { Text = "", BackgroundTransparency = 1, Position = UDim2.fromOffset(0, 28), Size = UDim2.new(1, 0, 0, 28) }, row)
        hit.InputBegan:Connect(function(i)
            if isPointer(i) then
                dragging = true
                update(i.Position.X)
            end
        end)
        UIS.InputChanged:Connect(function(i)
            if dragging and isMove(i) then
                update(i.Position.X)
            end
        end)
        UIS.InputEnded:Connect(function(i)
            if isPointer(i) then
                dragging = false
            end
        end)
    end

    function g:Dropdown(cfg)
        local current = cfg.Default or cfg.Options[1]

        local box = create("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 40), AutomaticSize = Enum.AutomaticSize.Y, LayoutOrder = nextOrder() }, items)
        create("UIListLayout", { Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder }, box)

        local head = newRow(box, 1)
        applyTitle(head, cfg, 130)

        local sel = create("TextButton", {
            Text = current,
            AutoButtonColor = false,
            AnchorPoint = Vector2.new(1, 0.5),
            Position = UDim2.new(1, -8, 0.5, 0),
            Size = UDim2.fromOffset(116, 26),
            BackgroundColor3 = C.bg,
            TextColor3 = C.text,
            TextSize = 12,
            Font = Enum.Font.GothamMedium,
            TextTruncate = Enum.TextTruncate.AtEnd,
        }, head)
        corner(sel, 6)

        local list = create("Frame", { BackgroundTransparency = 1, Visible = false, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, LayoutOrder = 2 }, box)
        create("UIListLayout", { Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder }, list)

        for idx, opt in ipairs(cfg.Options) do
            local ob = create("TextButton", {
                Text = opt,
                AutoButtonColor = false,
                BackgroundColor3 = C.rowOff,
                TextColor3 = C.text,
                TextSize = 13,
                Font = Enum.Font.GothamMedium,
                Size = UDim2.new(1, 0, 0, 32),
                LayoutOrder = idx,
            }, list)
            corner(ob, 8)
            ob.Activated:Connect(function()
                current = opt
                sel.Text = opt
                list.Visible = false
                safe(cfg.Callback, opt)
            end)
        end

        sel.Activated:Connect(function()
            list.Visible = not list.Visible
        end)
    end

    return g
end

-- buat ScreenGui; coba beberapa parent (gethui -> CoreGui -> PlayerGui) sampai ada yang berhasil
local function makeGui(name)
    local gui = Instance.new("ScreenGui")
    gui.Name = name
    gui.ResetOnSpawn = false
    gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    gui.IgnoreGuiInset = true
    gui.DisplayOrder = 999

    if syn and syn.protect_gui then
        pcall(syn.protect_gui, gui)
    end

    local candidates = {
        function() return gethui and gethui() end,
        function() return CoreGui end,
        function() return LP:WaitForChild("PlayerGui", 5) end,
    }
    for _, getParent in ipairs(candidates) do
        local ok, p = pcall(getParent)
        if ok and p then
            local ok2 = pcall(function() gui.Parent = p end)
            if ok2 and gui.Parent == p then
                return gui
            end
        end
    end
    error("Tidak bisa menaruh UI di parent mana pun")
end

-- cfg: { Name = "...", Dev = "...", Description = "..." }
local function createWindow(cfg)
    local win = {}
    local gui = makeGui("YSSHub")

    local FULL = UDim2.fromOffset(330, 320)
    local FOLDED = UDim2.fromOffset(330, 84)

    local main = create("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(0.68, 0.55),
        Size = FULL,
        BackgroundColor3 = C.bg,
        BorderSizePixel = 0,
        ClipsDescendants = true,
    }, gui)
    corner(main, 14)
    stroke(main, C.line, 1.5)

    -- header: nama hub, developer, description (selalu terlihat, juga saat dilipat)
    local header = create("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 78) }, main)

    local nameLbl = label(header, cfg.Name, 18, C.text)
    nameLbl.Position = UDim2.fromOffset(14, 8)
    nameLbl.Size = UDim2.new(1, -70, 0, 22)

    local devLbl = label(header, cfg.Dev, 12, C.head)
    devLbl.Font = Enum.Font.GothamMedium
    devLbl.Position = UDim2.fromOffset(14, 32)
    devLbl.Size = UDim2.new(1, -70, 0, 16)

    local descLbl = label(header, cfg.Description or "", 11, C.dim)
    descLbl.Font = Enum.Font.Gotham
    descLbl.TextTruncate = Enum.TextTruncate.AtEnd
    descLbl.Position = UDim2.fromOffset(14, 50)
    descLbl.Size = UDim2.new(1, -70, 0, 16)

    local foldBtn = create("TextButton", {
        Text = "-",
        AutoButtonColor = false,
        BackgroundColor3 = C.rowOff,
        TextColor3 = C.text,
        TextSize = 24,
        Font = Enum.Font.GothamBold,
        AnchorPoint = Vector2.new(1, 0),
        Position = UDim2.new(1, -12, 0, 12),
        Size = UDim2.fromOffset(38, 38),
    }, header)
    corner(foldBtn, 10)

    -- geser window lewat header
    local dragging, dragStart, startPos = false, nil, nil
    header.InputBegan:Connect(function(i)
        if isPointer(i) then
            dragging = true
            dragStart = i.Position
            startPos = main.Position
        end
    end)
    UIS.InputChanged:Connect(function(i)
        if dragging and isMove(i) then
            local d = i.Position - dragStart
            main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y)
        end
    end)
    UIS.InputEnded:Connect(function(i)
        if isPointer(i) then
            dragging = false
        end
    end)

    -- isi: kartu-kartu section
    local body = create("ScrollingFrame", {
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Position = UDim2.fromOffset(8, 80),
        Size = UDim2.new(1, -16, 1, -88),
        CanvasSize = UDim2.new(),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        ScrollBarThickness = 2,
        ScrollingDirection = Enum.ScrollingDirection.Y,
    }, main)
    create("UIListLayout", { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder }, body)

    -- lipat / buka lagi (- dan +)
    local folded = false
    foldBtn.Activated:Connect(function()
        folded = not folded
        if folded then
            body.Visible = false
            foldBtn.Text = "+"
            TweenService:Create(main, TweenInfo.new(0.2), { Size = FOLDED }):Play()
        else
            foldBtn.Text = "-"
            TweenService:Create(main, TweenInfo.new(0.2), { Size = FULL }):Play()
            task.delay(0.2, function()
                if not folded then
                    body.Visible = true
                end
            end)
        end
    end)

    -- tombol logo (buka/tutup window) + FPS/ping, di bawah top bar Roblox
    local logo = create("TextButton", {
        Text = "V",
        Font = Enum.Font.GothamBold,
        TextSize = 26,
        TextColor3 = C.text,
        AutoButtonColor = false,
        BackgroundColor3 = C.bg,
        Position = UDim2.fromOffset(8, 46),
        Size = UDim2.fromOffset(48, 48),
    }, gui)
    corner(logo, 12)
    stroke(logo, C.line, 1.5)
    logo.Activated:Connect(function()
        main.Visible = not main.Visible
    end)

    local pill = create("Frame", { BackgroundColor3 = Color3.fromRGB(32, 22, 38), Position = UDim2.fromOffset(62, 53), Size = UDim2.fromOffset(150, 32) }, gui)
    corner(pill, 16)
    local fpsLbl = label(pill, "-- FPS - -- ms", 12, C.text, Enum.TextXAlignment.Center)
    fpsLbl.Font = Enum.Font.Code

    local frames, last = 0, tick()
    RunService.Heartbeat:Connect(function()
        frames += 1
        local now = tick()
        if now - last >= 0.5 then
            local fps = math.floor(frames / (now - last) + 0.5)
            frames, last = 0, now
            local ping = 0
            pcall(function()
                ping = math.floor(game:GetService("Stats").Network.ServerStatsItem["Data Ping"]:GetValue() + 0.5)
            end)
            fpsLbl.Text = fps .. " FPS - " .. ping .. " ms"
        end
    end)

    -- kartu section yang bisa dilipat (judul, badge jumlah item, chevron)
    local sectionCount = 0
    function win:AddSection(title, icon)
        sectionCount += 1
        local card = create("Frame", { BackgroundColor3 = C.card, Size = UDim2.new(1, 0, 0, 40), AutomaticSize = Enum.AutomaticSize.Y, LayoutOrder = sectionCount }, body)
        corner(card, 12)
        padding(card, 8)
        create("UIListLayout", { Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder }, card)

        local head = create("TextButton", { Text = "", AutoButtonColor = false, BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 26), LayoutOrder = 1 }, card)

        local ic = label(head, icon or "YSS CONFIG", 14, C.pink)
        ic.Position = UDim2.fromOffset(2, 0)
        ic.Size = UDim2.fromOffset(20, 26)

        local tl = label(head, string.upper(title), 12, C.head)
        tl.Position = UDim2.fromOffset(26, 0)
        tl.Size = UDim2.new(1, -90, 1, 0)

        local badge = create("Frame", { AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -26, 0.5, 0), Size = UDim2.fromOffset(26, 18), BackgroundColor3 = C.rowOff }, head)
        corner(badge, 9)
        local badgeLbl = label(badge, "0", 11, C.text, Enum.TextXAlignment.Center)

        local chev = label(head, "▾", 14, C.dim, Enum.TextXAlignment.Center)
        chev.AnchorPoint = Vector2.new(1, 0.5)
        chev.Position = UDim2.new(1, 0, 0.5, 0)
        chev.Size = UDim2.fromOffset(22, 26)

        local items = create("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, LayoutOrder = 2 }, card)
        create("UIListLayout", { Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder }, items)

        head.Activated:Connect(function()
            items.Visible = not items.Visible
            chev.Text = items.Visible and "▾" or "▸"
        end)

        return makeGroup(items, function(n)
            badgeLbl.Text = tostring(n)
        end)
    end

    function win:Notify(title, text, duration)
        local toast = create("Frame", {
            AnchorPoint = Vector2.new(0.5, 0),
            Position = UDim2.new(0.5, 0, 0, -70),
            Size = UDim2.fromOffset(260, 50),
            BackgroundColor3 = C.bg,
        }, gui)
        corner(toast, 10)
        stroke(toast, C.line, 1.5)
        local a = label(toast, title or "", 14)
        a.Position = UDim2.fromOffset(12, 4)
        a.Size = UDim2.new(1, -24, 0, 20)
        local b = label(toast, text or "", 12, C.dim)
        b.Font = Enum.Font.Gotham
        b.Position = UDim2.fromOffset(12, 25)
        b.Size = UDim2.new(1, -24, 0, 20)
        tween(toast, { Position = UDim2.new(0.5, 0, 0, 12) })
        task.delay(duration or 3, function()
            tween(toast, { Position = UDim2.new(0.5, 0, 0, -70) })
            task.wait(0.3)
            toast:Destroy()
        end)
    end

    return win
end

-- =====================================================================
--  DATA & LOGIKA STEAL AN EGG
-- =====================================================================
local START     = Vector3.new(595.56, 70.57, -326.47)  -- titik awal: TP ke sini dulu lalu ambil
local SAFE_ZONE = Vector3.new(542.15, 70.57, -364.79)  -- tujuan setelah egg diambil

-- nama zona = tebakan dari pemandangan screenshot, silakan ganti
local Zones = {
    { "1. Meadow A",    Vector3.new(742.09, 70.57, -411.35) },
    { "2. Desert",      Vector3.new(950.07, 70.57, -324.19) },
    { "3. Meadow B",    Vector3.new(1189.92, 70.57, -410.02) },
    { "4. Snow",        Vector3.new(1491.03, 70.57, -315.72) },
    { "5. Lava",        Vector3.new(1879.13, 70.57, -396.25) },
    { "6. Ocean",       Vector3.new(2279.83, 70.57, -328.63) },
    { "7. Yellow Zone", Vector3.new(2812.01, 70.57, -398.60) },
    { "8. Galaxy",      Vector3.new(3391.65, 70.57, -324.71) },
}

local STEP_DIST  = 15   -- jarak tiap step menuju Safe Zone (maks 800)
local STEP_DELAY = 0.9  -- jeda tiap step (detik), bisa diganti lewat dropdown
local ZIGZAG     = 8    -- lebar zig-zag ke kiri/kanan (studs)
local GRAB_TIME  = 1.5  -- lama menembak prompt egg (detik)

local ZoneNames = {}
for _, z in ipairs(Zones) do
    table.insert(ZoneNames, z[1])
end

local SpeedOptions = {
    "1.0 (LOW SPEED)",
    "0.9 (Reasonable SPEED)",
    "0.5 (HIGH SPEED)",
    "0.1 (NOT SAFE)",
    "0.09 (NOT SAFE+)",
}

local selected = ZoneNames[1]
local running = false      -- Auto Egg
local grabRunning = false  -- Dual Auto Grab
local state = "Idle"
local cycles = 0

local speedBoost = false
local boostSpeed = 100

local statusLabel = nil
local notify = function() end

local function refresh()
    if statusLabel then
        statusLabel:Set(string.format(
            "Zone: %s\nState: %s\nSiklus selesai: %d\nTP delay: %.2fs\nStep: %d | Zig-zag: %d | Boost: %d",
            selected, state, cycles, STEP_DELAY, STEP_DIST, ZIGZAG, boostSpeed
        ))
    end
end

local function setState(s)
    state = s
    refresh()
end

local function getParts()
    local char = LP.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    return hrp, hum
end

local function zonePos(name)
    for _, z in ipairs(Zones) do
        if z[1] == name then
            return z[2]
        end
    end
end

local function moveTo(hrp, cf)
    hrp.CFrame = cf
    hrp.AssemblyLinearVelocity = Vector3.zero
end

local function promptPos(d)
    local p = d.Parent
    if not p then
        return nil
    end
    if p:IsA("BasePart") then
        return p.Position
    end
    if p:IsA("Model") then
        return p:GetPivot().Position
    end
    local part = p:FindFirstChildWhichIsA("BasePart")
    return part and part.Position
end

-- ambil egg: fire sampai 2 ProximityPrompt dalam radius 100 studs
local function dualGrabEgg()
    local hrp = getParts()
    if not hrp then
        return
    end

    local prompts = {}
    for _, d in ipairs(workspace:GetDescendants()) do
        if d:IsA("ProximityPrompt") then
            local at = promptPos(d)
            if at and (at - hrp.Position).Magnitude <= 100 then
                table.insert(prompts, d)
            end
        end
    end

    if #prompts >= 2 then
        task.spawn(function() pcall(fireproximityprompt, prompts[1]) end)
        task.spawn(function() pcall(fireproximityprompt, prompts[2]) end)
    elseif #prompts == 1 then
        task.spawn(function() pcall(fireproximityprompt, prompts[1]) end)
    end
end

task.spawn(function()
    while true do
        if grabRunning then
            dualGrabEgg()
        end
        task.wait(0.1)
    end
end)

-- Speed boost: pertahankan WalkSpeed selama toggle nyala
task.spawn(function()
    while true do
        if speedBoost then
            local _, hum = getParts()
            if hum then
                hum.WalkSpeed = boostSpeed
            end
        end
        task.wait(0.1)
    end
end)

local function grabFor(seconds)
    local t = tick()
    while running and tick() - t < seconds do
        dualGrabEgg()
        task.wait(0.1)
    end
end

-- ===== SET RESPAWN =====
-- Cara set respawn di game belum diketahui. Default: tembak ProximityPrompt di sekitar
-- yang teksnya mengandung "spawn" / "checkpoint" / "titik". Kalau di game caranya lain
-- (tombol, remote, dll), ganti isi fungsi ini.
local function setRespawnHere()
    local hrp = getParts()
    if not hrp or not fireproximityprompt then
        return false
    end
    local found = false
    for _, d in ipairs(workspace:GetDescendants()) do
        if d:IsA("ProximityPrompt") then
            local text = string.lower((d.ActionText or "") .. " " .. (d.ObjectText or "") .. " " .. d.Name)
            if text:find("spawn") or text:find("checkpoint") or text:find("titik") then
                local at = promptPos(d)
                if at and (at - hrp.Position).Magnitude <= 100 then
                    pcall(fireproximityprompt, d)
                    found = true
                end
            end
        end
    end
    return found
end

-- reset karakter lalu tunggu karakter baru siap
local function resetCharacter()
    local old = LP.Character
    local hum = old and old:FindFirstChildOfClass("Humanoid")
    if hum then
        hum.Health = 0
    elseif old then
        old:BreakJoints()
    end

    local t0 = tick()
    while running and tick() - t0 < 15 do
        local c = LP.Character
        if c and c ~= old and c:FindFirstChild("HumanoidRootPart") and c:FindFirstChildOfClass("Humanoid") then
            task.wait(1)
            return true
        end
        task.wait(0.2)
    end
    return false
end

local function runOnce(zone)
    local hrp = getParts()
    if not hrp then
        return
    end

    -- 1) TP ke titik awal, lalu ambil egg
    setState("TP ke titik awal")
    moveTo(hrp, CFrame.new(START))
    task.wait(0.1)
    setState("Ambil egg (awal)")
    grabFor(GRAB_TIME)
    if not running then
        return
    end

    -- 2) TP ke zone terpilih, set respawn di sana
    hrp = getParts()
    if not hrp then
        return
    end
    setState("TP ke zone")
    moveTo(hrp, CFrame.new(zone))
    task.wait(0.5)
    setState("Set respawn")
    if not setRespawnHere() then
        notify("Respawn", "Prompt set respawn tidak ditemukan", 3)
    end
    task.wait(0.5)
    if not running then
        return
    end

    -- 3) reset karakter
    setState("Reset karakter")
    if not resetCharacter() then
        return
    end
    hrp = getParts()
    if not hrp then
        return
    end
    if (hrp.Position - zone).Magnitude > 150 then
        -- respawn tidak di zone, TP manual ke zone
        moveTo(hrp, CFrame.new(zone))
        task.wait(0.4)
    end

    -- 4) ambil egg di zone
    setState("Ambil egg (zone)")
    grabFor(GRAB_TIME)
    if not running then
        return
    end

    -- 5) balik ke Safe Zone: step zig-zag
    setState("Balik ke Safe Zone")
    hrp = getParts()
    if not hrp then
        return
    end
    local startPos = hrp.Position
    local flat = Vector3.new(SAFE_ZONE.X - startPos.X, 0, SAFE_ZONE.Z - startPos.Z)
    local total = flat.Magnitude
    if total > 0 then
        local dir = flat.Unit
        local side = Vector3.new(-dir.Z, 0, dir.X)
        local travelled, i = 0, 0
        while running and travelled < total do
            i += 1
            travelled = math.min(travelled + STEP_DIST, total)
            local odd = (i % 2 == 1)
            local pos = startPos + dir * travelled
                + side * (odd and ZIGZAG or -ZIGZAG)
            local h = getParts()
            if h then
                moveTo(h, CFrame.new(pos))
            end
            task.wait(STEP_DELAY)
        end
    end
    if not running then
        return
    end

    local h = getParts()
    if h then
        moveTo(h, CFrame.new(SAFE_ZONE))
    end
    cycles += 1
    refresh()
    task.wait(0.5)
end

-- =====================================================================
--  BUILD UI
-- =====================================================================
local function BuildHub()
    local Window = createWindow({
        Name = "YSS HUB",
        Dev = "DEV: GG SIH LUH",
        Description = "https://discord.gg/6VeEjrRYy",
    })
    notify = function(title, text, duration)
        Window:Notify(title, text, duration)
    end

    -- ===== QUICK BAR 1 =====
    local Q = Window:AddSection("Quick Bar 1")

    Q:Toggle({
        Title = "Auto Egg",
        Description = "Awal, zone, respawn, reset, ambil, Safe Zone",
        Default = false,
        Callback = function(v)
            running = v
            if v then
                task.spawn(function()
                    while running do
                        local pos = zonePos(selected)
                        if pos then
                            runOnce(pos)
                        end
                        task.wait(1)
                    end
                    setState("Idle")
                end)
            else
                setState("Idle")
            end
        end,
    })

    Q:Toggle({
        Title = "Auto Grab",
        Description = "Ambil egg otomatis radius 100 studs",
        Default = false,
        Callback = function(v)
            grabRunning = v
        end,
    })

    Q:Toggle({
        Title = "Speed boost",
        Default = false,
        Callback = function(v)
            speedBoost = v
            if not v then
                local _, hum = getParts()
                if hum then
                    hum.WalkSpeed = 16
                end
            end
        end,
    })

    Q:Slider({
        Title = "Boost speed",
        Min = 16,
        Max = 800,
        Default = boostSpeed,
        Callback = function(v)
            boostSpeed = v
            refresh()
        end,
    })

    -- ===== ZONE =====
    local Z = Window:AddSection("Zone")

    Z:Dropdown({
        Title = "Pilih Zone",
        Description = "Zona tujuan ambil egg",
        Options = ZoneNames,
        Default = ZoneNames[1],
        Callback = function(v)
            selected = v
            refresh()
        end,
    })

    Z:Dropdown({
        Title = "Teleport Speed",
        Description = "Jeda tiap step ke Safe Zone",
        Options = SpeedOptions,
        Default = SpeedOptions[2],
        Callback = function(v)
            local num = tonumber(tostring(v):match("^[%d%.]+"))
            if num then
                STEP_DELAY = num
                refresh()
            end
        end,
    })

    Z:Slider({
        Title = "Step Distance",
        Min = 5,
        Max = 800,
        Default = STEP_DIST,
        Callback = function(v)
            STEP_DIST = v
            refresh()
        end,
    })

    Z:Slider({
        Title = "Zig-Zag",
        Min = 2,
        Max = 30,
        Default = ZIGZAG,
        Callback = function(v)
            ZIGZAG = v
            refresh()
        end,
    })

    -- ===== TELEPORT =====
    local T = Window:AddSection("Teleport")
    local tpZone = ZoneNames[1]

    T:Dropdown({
        Title = "Zone",
        Description = "Pilih tujuan teleport",
        Options = ZoneNames,
        Default = ZoneNames[1],
        Callback = function(v)
            tpZone = v
        end,
    })

    T:Button({
        Title = "Tap To Tp",
        Description = "Langsung ke zone terpilih",
        Callback = function()
            local hrp = getParts()
            local pos = zonePos(tpZone)
            if hrp and pos then
                moveTo(hrp, CFrame.new(pos))
            end
        end,
    })

    T:Button({
        Title = "TP Titik Awal",
        Description = "595.56, 70.57, -326.47",
        Callback = function()
            local hrp = getParts()
            if hrp then
                moveTo(hrp, CFrame.new(START))
            end
        end,
    })

    T:Button({
        Title = "TP Safe Zone",
        Description = "Langsung ke Safe Zone",
        Callback = function()
            local hrp = getParts()
            if hrp then
                moveTo(hrp, CFrame.new(SAFE_ZONE))
            end
        end,
    })

    -- ===== STATUS =====
    local S = Window:AddSection("Status Server")
    statusLabel = S:Paragraph("")
    refresh()
    S:Paragraph("YSS HUB | DEV: GG SIH LUH\nTombol - di pojok melipat UI, + membukanya lagi. Tombol V membuka/menutup window.")

    Window:Notify("YSS HUB", "DEV: GG SIH LUH", 3)
end

-- =====================================================================
--  KEY SYSTEM + LAUNCH
-- =====================================================================
local KEY = "UPDATE-9.5"

local function showError(err)
    warn("[YSS HUB] " .. tostring(err))
    pcall(function()
        game:GetService("StarterGui"):SetCore("SendNotification", {
            Title = "YSS HUB Error",
            Text = tostring(err):sub(1, 180),
            Duration = 20,
        })
    end)
end

local function showKeyScreen(onSuccess)
    local gui = makeGui("YSSHubKey")

    local frame = create("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(0.5, 0.5),
        Size = UDim2.fromOffset(320, 210),
        BackgroundColor3 = C.bg,
        BorderSizePixel = 0,
    }, gui)
    corner(frame, 10)
    stroke(frame, C.accent, 1)

    local title = label(frame, "YSS HUB", 22, C.accent, Enum.TextXAlignment.Center)
    title.Font = Enum.Font.GothamBold
    title.Position = UDim2.fromOffset(0, 12)
    title.Size = UDim2.new(1, 0, 0, 28)

    local dev = label(frame, "DEV: GG SIH LUH", 13, Color3.fromRGB(150, 150, 150), Enum.TextXAlignment.Center)
    dev.Position = UDim2.fromOffset(0, 42)
    dev.Size = UDim2.new(1, 0, 0, 20)

    local box = create("TextBox", {
        PlaceholderText = "Masukkan key...",
        PlaceholderColor3 = Color3.fromRGB(120, 120, 120),
        Text = "",
        ClearTextOnFocus = false,
        BackgroundColor3 = C.row,
        TextColor3 = C.text,
        TextSize = 14,
        Font = Enum.Font.Gotham,
        Position = UDim2.new(0, 20, 0, 76),
        Size = UDim2.new(1, -40, 0, 38),
    }, frame)
    corner(box, 6)

    local msg = label(frame, "", 12, Color3.fromRGB(255, 100, 100), Enum.TextXAlignment.Center)
    msg.Position = UDim2.fromOffset(0, 119)
    msg.Size = UDim2.new(1, 0, 0, 18)

    local btn = create("TextButton", {
        Text = "Verify",
        AutoButtonColor = false,
        BackgroundColor3 = C.accent,
        TextColor3 = Color3.new(1, 1, 1),
        TextSize = 15,
        Font = Enum.Font.GothamBold,
        Position = UDim2.new(0, 20, 0, 148),
        Size = UDim2.new(1, -40, 0, 38),
    }, frame)
    corner(btn, 6)

    btn.Activated:Connect(function()
        local entered = string.match(box.Text, "^%s*(.-)%s*$")
        if entered == KEY then
            gui:Destroy()
            onSuccess()
        else
            msg.Text = "Key salah!"
        end
    end)
end

local function launch()
    local ok, err = xpcall(BuildHub, debug.traceback)
    if not ok then
        showError(err)
    end
end

local ok, err = xpcall(function()
    showKeyScreen(launch)
end, debug.traceback)
if not ok then
    showError(err)
end
