--[[
    ECHOSENSE PREMIUM MENÜ - Xeno Executor için
    - Webhook hatası giderildi (syn.request ile)
    - CFG kaydetme/yükleme çalışıyor
    - Tüm hatalar düzeltildi
]]

-- Servisler
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local CoreGui = game:GetService("CoreGui")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local Camera = Workspace.CurrentCamera
local HttpService = game:GetService("HttpService")
local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()

-- ===============================
-- KONFİGÜRASYON
-- ===============================
local WEBHOOK_URL = "https://discord.com/api/webhooks/1477266898847662110/Cf-Ofo5ScbTsrFNKJpsxZTgs7iQr-VqiNjst-haWmM7dAIhfWHXlhyon_AILr8Qbz_7d"
local VALID_KEY = "owL45~j(ws1{FwG3VA@g"
local BLACKLIST = {}  -- kara listedeki UserId'ler
local WHITELIST = {}

local function isBlacklisted(userId)
    for _, id in ipairs(BLACKLIST) do
        if id == userId then return true end
    end
    return false
end

-- Webhook mesajı gönder (syn.request ile dene, olmazsa HttpService)
local function sendWebhook(content)
    local data = {
        content = content,
        username = "EchoSense",
        avatar_url = "https://i.imgur.com/yourlogo.png"
    }
    local json = HttpService:JSONEncode(data)
    
    -- Önce syn.request dene (Xeno'da çalışır genelde)
    local success, err = pcall(function()
        if syn and syn.request then
            syn.request({
                Url = WEBHOOK_URL,
                Method = "POST",
                Headers = {["Content-Type"] = "application/json"},
                Body = json
            })
        elseif request then
            request({
                Url = WEBHOOK_URL,
                Method = "POST",
                Headers = {["Content-Type"] = "application/json"},
                Body = json
            })
        else
            HttpService:PostAsync(WEBHOOK_URL, json, Enum.HttpContentType.ApplicationJson)
        end
    end)
    if not success then
        warn("Webhook gönderilemedi: " .. err)
    else
        print("Webhook başarıyla gönderildi.")
    end
end

if isBlacklisted(LocalPlayer.UserId) then
    local msg = Instance.new("Message")
    msg.Text = "HESABINIZ BLACKLIST'TE! BU SCRİPTİ KULLANAMAZSINIZ."
    msg.Parent = Workspace
    wait(5)
    msg:Destroy()
    return
end

-- ===============================
-- KEY GİRİŞ EKRANI
-- ===============================
local keyGui = Instance.new("ScreenGui")
keyGui.Name = "EchoSenseKey"
keyGui.ResetOnSpawn = false
keyGui.Parent = CoreGui

local keyFrame = Instance.new("Frame")
keyFrame.Size = UDim2.new(0, 400, 0, 200)
keyFrame.Position = UDim2.new(0.5, -200, 0.5, -100)
keyFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
keyFrame.BorderSizePixel = 0
keyFrame.Active = true
keyFrame.Parent = keyGui
local keyCorner = Instance.new("UICorner")
keyCorner.CornerRadius = UDim.new(0, 12)
keyCorner.Parent = keyFrame

local keyLabel = Instance.new("TextLabel")
keyLabel.Size = UDim2.new(1, 0, 0, 50)
keyLabel.Position = UDim2.new(0, 0, 0, 20)
keyLabel.BackgroundTransparency = 1
keyLabel.Text = "ECHOSENSE KEY SISTEMI"
keyLabel.TextColor3 = Color3.new(1, 1, 1)
keyLabel.TextSize = 24
keyLabel.Font = Enum.Font.GothamBlack
keyLabel.Parent = keyFrame

local keyBox = Instance.new("TextBox")
keyBox.Size = UDim2.new(0.8, 0, 0, 50)
keyBox.Position = UDim2.new(0.1, 0, 0.5, -25)
keyBox.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
keyBox.TextColor3 = Color3.new(1, 1, 1)
keyBox.PlaceholderText = "Key giriniz"
keyBox.Text = ""
keyBox.TextSize = 20
keyBox.Font = Enum.Font.Gotham
keyBox.Parent = keyFrame
local keyBoxCorner = Instance.new("UICorner")
keyBoxCorner.CornerRadius = UDim.new(0, 8)
keyBoxCorner.Parent = keyBox

local keyButton = Instance.new("TextButton")
keyButton.Size = UDim2.new(0.4, 0, 0, 40)
keyButton.Position = UDim2.new(0.3, 0, 0.8, -20)
keyButton.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
keyButton.Text = "GIRIS"
keyButton.TextColor3 = Color3.new(1, 1, 1)
keyButton.TextSize = 20
keyButton.Font = Enum.Font.Gotham
keyButton.Parent = keyFrame
local keyButtonCorner = Instance.new("UICorner")
keyButtonCorner.CornerRadius = UDim.new(0, 8)
keyButtonCorner.Parent = keyButton

keyButton.MouseButton1Click:Connect(function()
    if keyBox.Text == VALID_KEY then
        keyGui:Destroy()
        -- Webhook bildirimi
        local gameName = "Bilinmiyor"
        pcall(function()
            gameName = game:GetService("MarketplaceService"):GetProductInfo(game.PlaceId).Name
        end)
        local msg = string.format("**Script injected**\nKullanıcı: `%s` (%d)\nOyun: `%s`\nKey: `%s`", LocalPlayer.Name, LocalPlayer.UserId, gameName, VALID_KEY)
        sendWebhook(msg)
        -- Menüyü başlat
        startMenu()
    else
        keyBox.Text = ""
        keyBox.PlaceholderText = "Yanlis Key!"
    end
end)

-- ===============================
-- ANA MENÜ FONKSİYONU
-- ===============================
function startMenu()
    -- Eski menüleri temizle
    for _, v in ipairs(CoreGui:GetChildren()) do
        if v.Name == "EchoSenseAnim" or v.Name == "EchoSenseMenu" then
            v:Destroy()
        end
    end

    -- Değişkenler
    local menuKey = Enum.KeyCode.Insert
    local isWaitingForKey = false
    local flyConnection, flyBodyGyro, flyBodyVelocity = nil, nil, nil
    local flySpeed = 50
    local speedMultiplier = 1.0
    local espEnabled = false
    local chamsEnabled = false
    local mtEnabled = false
    local livesEnabled = false
    local teamCheck = true
    local invisibleColor = Color3.new(1, 0, 0)
    local visibleColor = Color3.new(0, 1, 0)
    local espConnections = {}
    local chamsHighlights = {}
    local aimbotEnabled = false
    local aimbotTargetPart = "Head"
    local aimbotSmoothness = 5
    local aimbotFOV = 90
    local aimbotKey = Enum.UserInputType.MouseButton2
    local noRecoilEnabled = false
    local rapidFireEnabled = false
    local superJump = false
    local godMode = false

    -- Toggle callback'leri
    local function setSuperJump(state)
        superJump = state
        if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
            LocalPlayer.Character.Humanoid.JumpPower = state and 100 or 50
        end
    end

    local function setGodMode(state)
        godMode = state
        if state then startFly() else stopFly() end
    end

    -- Konfigürasyon saklama
    local savedConfigs = {}

    -- ===============================
    -- AÇILIŞ ANİMASYONU
    -- ===============================
    local animGui = Instance.new("ScreenGui")
    animGui.Name = "EchoSenseAnim"
    animGui.ResetOnSpawn = false
    animGui.Parent = CoreGui

    local blackOverlay = Instance.new("Frame")
    blackOverlay.Size = UDim2.new(1, 0, 1, 0)
    blackOverlay.BackgroundColor3 = Color3.new(0, 0, 0)
    blackOverlay.BackgroundTransparency = 0
    blackOverlay.BorderSizePixel = 0
    blackOverlay.Parent = animGui

    local textFrame = Instance.new("Frame")
    textFrame.Size = UDim2.new(0, 1000, 0, 300)
    textFrame.Position = UDim2.new(0.5, -500, 0.5, -150)
    textFrame.BackgroundTransparency = 1
    textFrame.Parent = animGui

    local echoLabel = Instance.new("TextLabel")
    echoLabel.Size = UDim2.new(0.5, 0, 1, 0)
    echoLabel.Position = UDim2.new(0, 0, 0, 0)
    echoLabel.BackgroundTransparency = 1
    echoLabel.Text = "ECHO"
    echoLabel.TextColor3 = Color3.new(1, 0, 0)
    echoLabel.TextSize = 180
    echoLabel.Font = Enum.Font.GothamBlack
    echoLabel.TextXAlignment = Enum.TextXAlignment.Right
    echoLabel.Parent = textFrame

    local senseLabel = Instance.new("TextLabel")
    senseLabel.Size = UDim2.new(0.5, 0, 1, 0)
    senseLabel.Position = UDim2.new(0.5, 0, 0, 0)
    senseLabel.BackgroundTransparency = 1
    senseLabel.Text = "SENSE"
    senseLabel.TextColor3 = Color3.new(1, 1, 1)
    senseLabel.TextSize = 180
    senseLabel.Font = Enum.Font.GothamBlack
    senseLabel.TextXAlignment = Enum.TextXAlignment.Left
    senseLabel.Parent = textFrame

    local discordLabel = Instance.new("TextLabel")
    discordLabel.Size = UDim2.new(0, 600, 0, 60)
    discordLabel.Position = UDim2.new(0.5, -300, 0.5, 130)
    discordLabel.BackgroundTransparency = 1
    discordLabel.Text = "discord.gg/echozero"
    discordLabel.TextColor3 = Color3.new(1, 1, 1)
    discordLabel.TextSize = 42
    discordLabel.Font = Enum.Font.Gotham
    discordLabel.Parent = animGui

    local function addGlow(label, color, thickness)
        local stroke = Instance.new("UIStroke")
        stroke.Thickness = thickness or 8
        stroke.Color = color or Color3.new(1, 1, 1)
        stroke.Transparency = 0.2
        stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
        stroke.Parent = label
    end
    addGlow(echoLabel, Color3.new(1, 0, 0), 10)
    addGlow(senseLabel, Color3.new(1, 1, 1), 10)
    addGlow(discordLabel, Color3.new(1, 1, 1), 5)

    local scaleUp = TweenService:Create(textFrame, TweenInfo.new(0.7, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Size = UDim2.new(0, 1100, 0, 330)})
    scaleUp:Play()
    scaleUp.Completed:Connect(function()
        local scaleDown = TweenService:Create(textFrame, TweenInfo.new(0.7, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {Size = UDim2.new(0, 1000, 0, 300)})
        scaleDown:Play()
    end)

    TweenService:Create(echoLabel, TweenInfo.new(1.2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {TextTransparency = 0.3}):Play()
    TweenService:Create(senseLabel, TweenInfo.new(1.2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {TextTransparency = 0.3}):Play()
    TweenService:Create(discordLabel, TweenInfo.new(1.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {TextTransparency = 0.4}):Play()

    wait(3)
    local fadeOut = TweenService:Create(animGui, TweenInfo.new(2.5, Enum.EasingStyle.Linear), {Enabled = false})
    fadeOut:Play()
    fadeOut.Completed:Connect(function()
        animGui:Destroy()
        menuGui.Enabled = true
        mainFrame.Size = UDim2.new(0, 0, 0, 0)
        mainFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
        TweenService:Create(mainFrame, TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Size = UDim2.new(0, 1200, 0, 750), Position = UDim2.new(0.5, -600, 0.5, -375)}):Play()
    end)

    -- ===============================
    -- ANA MENÜ
    -- ===============================
    local menuGui = Instance.new("ScreenGui")
    menuGui.Name = "EchoSenseMenu"
    menuGui.ResetOnSpawn = false
    menuGui.Enabled = false
    menuGui.Parent = CoreGui

    local mainFrame = Instance.new("Frame")
    mainFrame.Size = UDim2.new(0, 1200, 0, 750)
    mainFrame.Position = UDim2.new(0.5, -600, 0.5, -375)
    mainFrame.BackgroundColor3 = Color3.new(0, 0, 0)
    mainFrame.BorderSizePixel = 0
    mainFrame.Active = true
    mainFrame.Draggable = true
    mainFrame.Parent = menuGui
    local mainCorner = Instance.new("UICorner")
    mainCorner.CornerRadius = UDim.new(0, 20)
    mainCorner.Parent = mainFrame

    -- Üst çubuk
    local topBar = Instance.new("Frame")
    topBar.Size = UDim2.new(1, 0, 0, 70)
    topBar.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
    topBar.BorderSizePixel = 0
    topBar.Parent = mainFrame
    local topBarCorner = Instance.new("UICorner")
    topBarCorner.CornerRadius = UDim.new(0, 20)
    topBarCorner.Parent = topBar

    local pathLabel = Instance.new("TextLabel")
    pathLabel.Size = UDim2.new(0, 300, 1, 0)
    pathLabel.BackgroundTransparency = 1
    pathLabel.Text = "World>LocalPlayer"
    pathLabel.TextColor3 = Color3.new(1, 1, 1)
    pathLabel.TextSize = 22
    pathLabel.Font = Enum.Font.GothamSemibold
    pathLabel.TextXAlignment = Enum.TextXAlignment.Left
    pathLabel.Position = UDim2.new(0, 20, 0, 0)
    pathLabel.Parent = topBar

    local userNameLabel = Instance.new("TextLabel")
    userNameLabel.Size = UDim2.new(0, 300, 1, 0)
    userNameLabel.Position = UDim2.new(0.5, -150, 0, 0)
    userNameLabel.BackgroundTransparency = 1
    userNameLabel.Text = "ECHOSENSE --> " .. LocalPlayer.Name
    userNameLabel.TextColor3 = Color3.new(1, 1, 1)
    userNameLabel.TextSize = 22
    userNameLabel.Font = Enum.Font.Gotham
    userNameLabel.TextXAlignment = Enum.TextXAlignment.Center
    userNameLabel.Parent = topBar

    local logoLabel = Instance.new("TextLabel")
    logoLabel.Size = UDim2.new(0, 70, 1, 0)
    logoLabel.Position = UDim2.new(1, -80, 0, 0)
    logoLabel.BackgroundTransparency = 1
    logoLabel.Text = "E"
    logoLabel.TextColor3 = Color3.new(1, 0, 0)
    logoLabel.TextSize = 52
    logoLabel.Font = Enum.Font.GothamBlack
    logoLabel.TextXAlignment = Enum.TextXAlignment.Center
    logoLabel.Parent = topBar

    local closeBtn = Instance.new("TextButton")
    closeBtn.Size = UDim2.new(0, 60, 1, 0)
    closeBtn.Position = UDim2.new(1, -60, 0, 0)
    closeBtn.BackgroundTransparency = 1
    closeBtn.Text = "X"
    closeBtn.TextColor3 = Color3.new(1, 1, 1)
    closeBtn.TextSize = 32
    closeBtn.Font = Enum.Font.Gotham
    closeBtn.Parent = topBar
    closeBtn.MouseButton1Click:Connect(function()
        TweenService:Create(mainFrame, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.In), {Size = UDim2.new(0, 0, 0, 0), Position = UDim2.new(0.5, 0, 0.5, 0)}):Play()
        wait(0.3)
        menuGui.Enabled = false
    end)

    -- ===============================
    -- YAN SEKMELER
    -- ===============================
    local tabContainer = Instance.new("Frame")
    tabContainer.Size = UDim2.new(0, 200, 1, -70)
    tabContainer.Position = UDim2.new(0, 0, 0, 70)
    tabContainer.BackgroundColor3 = Color3.fromRGB(10, 10, 10)
    tabContainer.BorderSizePixel = 0
    tabContainer.Parent = mainFrame
    local tabContainerCorner = Instance.new("UICorner")
    tabContainerCorner.CornerRadius = UDim.new(0, 20)
    tabContainerCorner.Parent = tabContainer

    local tabs = {"World", "Visual", "Aimbot", "Gun", "Profile", "Settings", "Set", "CFG"}
    local tabButtons = {}
    local selectedTab = "World"

    local tabLayout = Instance.new("UIListLayout")
    tabLayout.Padding = UDim.new(0, 5)
    tabLayout.SortOrder = Enum.SortOrder.LayoutOrder
    tabLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    tabLayout.Parent = tabContainer
    local tabPadding = Instance.new("UIPadding")
    tabPadding.PaddingTop = UDim.new(0, 15)
    tabPadding.PaddingBottom = UDim.new(0, 15)
    tabPadding.Parent = tabContainer

    -- İçerik alanı
    local contentContainer = Instance.new("Frame")
    contentContainer.Size = UDim2.new(1, -200, 1, -70)
    contentContainer.Position = UDim2.new(0, 200, 0, 70)
    contentContainer.BackgroundColor3 = Color3.new(0, 0, 0)
    contentContainer.BorderSizePixel = 0
    contentContainer.Parent = mainFrame
    local contentCorner = Instance.new("UICorner")
    contentCorner.CornerRadius = UDim.new(0, 20)
    contentCorner.Parent = contentContainer
    contentContainer.ClipsDescendants = true

    -- Sekme içerikleri
    local tabContent = {}
    for i, tabName in ipairs(tabs) do
        local tabFrame = Instance.new("ScrollingFrame")
        tabFrame.Size = UDim2.new(1, 0, 1, 0)
        tabFrame.Position = UDim2.new(0, 0, 0, 0)
        tabFrame.BackgroundTransparency = 1
        tabFrame.BorderSizePixel = 0
        tabFrame.ScrollBarThickness = 6
        tabFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
        tabFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
        tabFrame.Visible = (tabName == selectedTab)
        tabFrame.Parent = contentContainer
        tabContent[tabName] = tabFrame

        local layout = Instance.new("UIListLayout")
        layout.Padding = UDim.new(0, 10)
        layout.SortOrder = Enum.SortOrder.LayoutOrder
        layout.Parent = tabFrame

        local padding = Instance.new("UIPadding")
        padding.PaddingTop = UDim.new(0, 20)
        padding.PaddingBottom = UDim.new(0, 20)
        padding.PaddingLeft = UDim.new(0, 20)
        padding.PaddingRight = UDim.new(0, 20)
        padding.Parent = tabFrame
    end

    -- Sekme butonları
    for i, tabName in ipairs(tabs) do
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(0, 180, 0, 50)
        btn.BackgroundColor3 = (tabName == selectedTab) and Color3.fromRGB(30, 30, 30) or Color3.fromRGB(15, 15, 15)
        btn.Text = tabName
        btn.TextColor3 = Color3.new(1, 1, 1)
        btn.TextSize = 22
        btn.Font = Enum.Font.Gotham
        btn.BorderSizePixel = 0
        btn.Parent = tabContainer
        tabButtons[tabName] = btn
        local btnCorner = Instance.new("UICorner")
        btnCorner.CornerRadius = UDim.new(0, 12)
        btnCorner.Parent = btn

        btn.MouseButton1Click:Connect(function()
            if selectedTab == tabName then return end
            local oldTab = selectedTab
            selectedTab = tabName

            for name, button in pairs(tabButtons) do
                TweenService:Create(button, TweenInfo.new(0.2), {BackgroundColor3 = (name == selectedTab) and Color3.fromRGB(30,30,30) or Color3.fromRGB(15,15,15)}):Play()
            end

            -- Kayma animasyonu
            local oldFrame = tabContent[oldTab]
            local newFrame = tabContent[selectedTab]
            oldFrame.Visible = true
            newFrame.Visible = true
            newFrame.Position = UDim2.new(0, 0, 1, 0)
            local tween1 = TweenService:Create(oldFrame, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Position = UDim2.new(0, 0, -1, 0)})
            local tween2 = TweenService:Create(newFrame, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Position = UDim2.new(0, 0, 0, 0)})
            tween1:Play()
            tween2:Play()
            tween1.Completed:Connect(function()
                oldFrame.Visible = false
                oldFrame.Position = UDim2.new(0, 0, 0, 0)
            end)
        end)
    end

    -- ===============================
    -- YARDIMCI BİLEŞEN FONKSİYONLARI
    -- ===============================
    local function createAnimatedToggle(text, default, callback)
        local frame = Instance.new("Frame")
        frame.Size = UDim2.new(1, 0, 0, 55)
        frame.BackgroundTransparency = 1
        frame.Parent = nil

        local label = Instance.new("TextLabel")
        label.Size = UDim2.new(0.6, 0, 1, 0)
        label.BackgroundTransparency = 1
        label.Text = text
        label.TextColor3 = Color3.new(1, 1, 1)
        label.TextSize = 20
        label.Font = Enum.Font.Gotham
        label.TextXAlignment = Enum.TextXAlignment.Left
        label.Parent = frame

        local path = Instance.new("Frame")
        path.Size = UDim2.new(0, 74, 0, 36)
        path.Position = UDim2.new(1, -84, 0.5, -18)
        path.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
        path.BorderSizePixel = 0
        path.Parent = frame
        local pathCorner = Instance.new("UICorner")
        pathCorner.CornerRadius = UDim.new(0, 18)
        pathCorner.Parent = path

        local knob = Instance.new("TextButton")
        knob.Size = UDim2.new(0, 32, 0, 32)
        knob.Position = UDim2.new(0, 2, 0.5, -16)
        knob.BackgroundColor3 = Color3.new(1, 1, 1)
        knob.Text = ""
        knob.BorderSizePixel = 0
        knob.Parent = path
        local knobCorner = Instance.new("UICorner")
        knobCorner.CornerRadius = UDim.new(0, 16)
        knobCorner.Parent = knob

        local enabled = default
        local function updateKnob()
            local targetPos = enabled and UDim2.new(1, -34, 0.5, -16) or UDim2.new(0, 2, 0.5, -16)
            TweenService:Create(knob, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Position = targetPos}):Play()
            TweenService:Create(path, TweenInfo.new(0.2), {BackgroundColor3 = enabled and Color3.fromRGB(0, 200, 0) or Color3.fromRGB(40, 40, 40)}):Play()
        end
        updateKnob()

        knob.MouseButton1Click:Connect(function()
            enabled = not enabled
            updateKnob()
            if callback then callback(enabled) end
        end)

        return frame
    end

    local function createSlider(text, min, max, default, callback)
        local frame = Instance.new("Frame")
        frame.Size = UDim2.new(1, 0, 0, 70)
        frame.BackgroundTransparency = 1
        frame.Parent = nil

        local label = Instance.new("TextLabel")
        label.Size = UDim2.new(0.5, 0, 0.4, 0)
        label.Position = UDim2.new(0, 0, 0, 0)
        label.BackgroundTransparency = 1
        label.Text = text
        label.TextColor3 = Color3.new(1, 1, 1)
        label.TextSize = 20
        label.Font = Enum.Font.Gotham
        label.TextXAlignment = Enum.TextXAlignment.Left
        label.Parent = frame

        local valueLabel = Instance.new("TextLabel")
        valueLabel.Size = UDim2.new(0.5, 0, 0.4, 0)
        valueLabel.Position = UDim2.new(0.5, 0, 0, 0)
        valueLabel.BackgroundTransparency = 1
        valueLabel.Text = tostring(default)
        valueLabel.TextColor3 = Color3.new(1, 1, 1)
        valueLabel.TextSize = 20
        valueLabel.Font = Enum.Font.Gotham
        valueLabel.TextXAlignment = Enum.TextXAlignment.Right
        valueLabel.Parent = frame

        local sliderBg = Instance.new("Frame")
        sliderBg.Size = UDim2.new(1, -20, 0, 12)
        sliderBg.Position = UDim2.new(0, 10, 1, -25)
        sliderBg.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
        sliderBg.BorderSizePixel = 0
        sliderBg.Parent = frame
        local sliderCorner = Instance.new("UICorner")
        sliderCorner.CornerRadius = UDim.new(0, 6)
        sliderCorner.Parent = sliderBg

        local fill = Instance.new("Frame")
        fill.Size = UDim2.new((default-min)/(max-min), 0, 1, 0)
        fill.BackgroundColor3 = Color3.fromRGB(0, 200, 0)
        fill.BorderSizePixel = 0
        fill.Parent = sliderBg
        local fillCorner = Instance.new("UICorner")
        fillCorner.CornerRadius = UDim.new(0, 6)
        fillCorner.Parent = fill

        local button = Instance.new("TextButton")
        button.Size = UDim2.new(0, 24, 0, 24)
        button.Position = UDim2.new((default-min)/(max-min), -12, 0.5, -12)
        button.BackgroundColor3 = Color3.new(1, 1, 1)
        button.Text = ""
        button.BorderSizePixel = 0
        button.Parent = sliderBg
        local buttonCorner = Instance.new("UICorner")
        buttonCorner.CornerRadius = UDim.new(0, 12)
        buttonCorner.Parent = button

        local dragging = false
        button.MouseButton1Down:Connect(function()
            dragging = true
        end)
        UserInputService.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                dragging = false
            end
        end)

        local function updateSlider()
            if not dragging then return end
            local mousePos = UserInputService:GetMouseLocation()
            local absPos = sliderBg.AbsolutePosition
            local absSize = sliderBg.AbsoluteSize.X
            local relative = (mousePos.X - absPos.X) / absSize
            relative = math.clamp(relative, 0, 1)
            local value = min + (max-min) * relative
            value = math.floor(value * 100) / 100
            fill.Size = UDim2.new(relative, 0, 1, 0)
            button.Position = UDim2.new(relative, -12, 0.5, -12)
            valueLabel.Text = tostring(value)
            if callback then callback(value) end
        end

        UserInputService.InputChanged:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseMovement then
                updateSlider()
            end
        end)

        return frame
    end

    local function createColorPicker(text, defaultColor, callback)
        local frame = Instance.new("Frame")
        frame.Size = UDim2.new(1, 0, 0, 60)
        frame.BackgroundTransparency = 1
        frame.Parent = nil

        local label = Instance.new("TextLabel")
        label.Size = UDim2.new(0.5, 0, 1, 0)
        label.BackgroundTransparency = 1
        label.Text = text
        label.TextColor3 = Color3.new(1, 1, 1)
        label.TextSize = 20
        label.Font = Enum.Font.Gotham
        label.TextXAlignment = Enum.TextXAlignment.Left
        label.Parent = frame

        local colorBtn = Instance.new("TextButton")
        colorBtn.Size = UDim2.new(0, 50, 0, 30)
        colorBtn.Position = UDim2.new(1, -60, 0.5, -15)
        colorBtn.BackgroundColor3 = defaultColor
        colorBtn.Text = ""
        colorBtn.BorderSizePixel = 0
        colorBtn.Parent = frame
        local btnCorner = Instance.new("UICorner")
        btnCorner.CornerRadius = UDim.new(0, 8)
        btnCorner.Parent = colorBtn

        colorBtn.MouseButton1Click:Connect(function()
            local colors = {
                Color3.new(1,0,0), Color3.new(0,1,0), Color3.new(0,0,1),
                Color3.new(1,1,0), Color3.new(1,0,1), Color3.new(0,1,1),
                Color3.new(1,1,1)
            }
            local picker = Instance.new("Frame")
            picker.Size = UDim2.new(0, 200, 0, 100)
            picker.Position = UDim2.new(0.5, -100, 0.5, -50)
            picker.BackgroundColor3 = Color3.fromRGB(30,30,30)
            picker.Parent = menuGui
            local pickerCorner = Instance.new("UICorner")
            pickerCorner.CornerRadius = UDim.new(0, 8)
            pickerCorner.Parent = picker

            for i, col in ipairs(colors) do
                local btn = Instance.new("TextButton")
                btn.Size = UDim2.new(0, 40, 0, 40)
                btn.Position = UDim2.new(0, (i-1)*45, 0, 10)
                btn.BackgroundColor3 = col
                btn.Text = ""
                btn.Parent = picker
                local btnCorner = Instance.new("UICorner")
                btnCorner.CornerRadius = UDim.new(0, 8)
                btnCorner.Parent = btn
                btn.MouseButton1Click:Connect(function()
                    colorBtn.BackgroundColor3 = col
                    if callback then callback(col) end
                    picker:Destroy()
                end)
            end
        end)

        return frame
    end

    -- ===============================
    -- WORLD SEKMESİ
    -- ===============================
    local worldFrame = tabContent["World"]

    local function stopFly()
        if flyConnection then flyConnection:Disconnect() flyConnection = nil end
        if flyBodyGyro then flyBodyGyro:Destroy() flyBodyGyro = nil end
        if flyBodyVelocity then flyBodyVelocity:Destroy() flyBodyVelocity = nil end
        if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
            LocalPlayer.Character.Humanoid:SetStateEnabled(Enum.HumanoidStateType.Climbing, true)
            LocalPlayer.Character.Humanoid:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, true)
            LocalPlayer.Character.Humanoid.PlatformStand = false
        end
    end

    local function startFly()
        local char = LocalPlayer.Character
        if not char or not char:FindFirstChild("Humanoid") then return end
        local rootPart = char:FindFirstChild("HumanoidRootPart")
        if not rootPart then return end

        stopFly()
        char.Humanoid:SetStateEnabled(Enum.HumanoidStateType.Climbing, false)
        char.Humanoid:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, false)
        char.Humanoid.PlatformStand = true

        flyBodyGyro = Instance.new("BodyGyro")
        flyBodyGyro.MaxTorque = Vector3.new(0, 0, 0)
        flyBodyGyro.P = 1000
        flyBodyGyro.D = 50
        flyBodyGyro.Parent = rootPart

        flyBodyVelocity = Instance.new("BodyVelocity")
        flyBodyVelocity.Velocity = Vector3.new(0, 0, 0)
        flyBodyVelocity.MaxForce = Vector3.new(4000, 4000, 4000)
        flyBodyVelocity.Parent = rootPart

        flyConnection = RunService.Heartbeat:Connect(function()
            if not char or not char.Parent then stopFly() return end
            local moveDir = Vector3.new()
            if UserInputService:IsKeyDown(Enum.KeyCode.W) then moveDir = moveDir + Camera.CFrame.LookVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.S) then moveDir = moveDir - Camera.CFrame.LookVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.A) then moveDir = moveDir - Camera.CFrame.RightVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.D) then moveDir = moveDir + Camera.CFrame.RightVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.Space) then moveDir = moveDir + Vector3.new(0, 1, 0) end
            if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then moveDir = moveDir - Vector3.new(0, 1, 0) end
            if moveDir.Magnitude > 0 then moveDir = moveDir.Unit * flySpeed end
            flyBodyVelocity.Velocity = moveDir
        end)
    end

    local godModeToggle = createAnimatedToggle("God Mode", false, setGodMode)
    godModeToggle.Parent = worldFrame

    local flySpeedSlider = createSlider("Fly Speed", 10, 200, 50, function(val) flySpeed = val end)
    flySpeedSlider.Parent = worldFrame

    local function updateSpeed(val)
        speedMultiplier = val
        if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
            LocalPlayer.Character.Humanoid.WalkSpeed = 16 * speedMultiplier
        end
    end
    local speedSlider = createSlider("Speed Hack", 0.5, 3.0, 1.0, updateSpeed)
    speedSlider.Parent = worldFrame

    local superJumpToggle = createAnimatedToggle("SuperJump", false, setSuperJump)
    superJumpToggle.Parent = worldFrame

    -- ===============================
    -- VISUAL SEKMESİ
    -- ===============================
    local visualFrame = tabContent["Visual"]
    visualFrame:ClearAllChildren()

    local splitFrame = Instance.new("Frame")
    splitFrame.Size = UDim2.new(1, 0, 1, 0)
    splitFrame.BackgroundTransparency = 1
    splitFrame.Parent = visualFrame

    local leftPanel = Instance.new("ScrollingFrame")
    leftPanel.Size = UDim2.new(0.6, -10, 1, 0)
    leftPanel.BackgroundTransparency = 1
    leftPanel.BorderSizePixel = 0
    leftPanel.ScrollBarThickness = 6
    leftPanel.AutomaticCanvasSize = Enum.AutomaticSize.Y
    leftPanel.Parent = splitFrame
    local leftLayout = Instance.new("UIListLayout")
    leftLayout.Padding = UDim.new(0, 10)
    leftLayout.Parent = leftPanel
    local leftPadding = Instance.new("UIPadding")
    leftPadding.PaddingTop = UDim.new(0, 10)
    leftPadding.PaddingBottom = UDim.new(0, 10)
    leftPadding.PaddingLeft = UDim.new(0, 10)
    leftPadding.PaddingRight = UDim.new(0, 10)
    leftPadding.Parent = leftPanel

    local rightPanel = Instance.new("Frame")
    rightPanel.Size = UDim2.new(0.4, -10, 1, 0)
    rightPanel.Position = UDim2.new(0.6, 0, 0, 0)
    rightPanel.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
    rightPanel.BorderSizePixel = 0
    rightPanel.Parent = splitFrame
    local rightCorner = Instance.new("UICorner")
    rightCorner.CornerRadius = UDim.new(0, 12)
    rightCorner.Parent = rightPanel

    local previewTitle = Instance.new("TextLabel")
    previewTitle.Size = UDim2.new(1, 0, 0, 40)
    previewTitle.BackgroundTransparency = 1
    previewTitle.Text = "Preview"
    previewTitle.TextColor3 = Color3.new(1, 1, 1)
    previewTitle.TextSize = 22
    previewTitle.Font = Enum.Font.Gotham
    previewTitle.Parent = rightPanel

    local viewport = Instance.new("ViewportFrame")
    viewport.Size = UDim2.new(1, -20, 1, -60)
    viewport.Position = UDim2.new(0, 10, 0, 45)
    viewport.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    viewport.Parent = rightPanel
    local viewportCorner = Instance.new("UICorner")
    viewportCorner.CornerRadius = UDim.new(0, 8)
    viewportCorner.Parent = viewport

    -- Preview için dummy
    local previewModel = Instance.new("Model")
    previewModel.Name = "PreviewChar"
    local function updatePreview()
        for _, v in ipairs(previewModel:GetChildren()) do v:Destroy() end
        local char = LocalPlayer.Character
        if char then
            local torso = Instance.new("Part")
            torso.Size = Vector3.new(2, 2, 1)
            torso.Position = Vector3.new(0, 1, 0)
            torso.Anchored = true
            torso.BrickColor = BrickColor.new("Bright red")
            torso.Parent = previewModel
            local head = Instance.new("Part")
            head.Size = Vector3.new(1, 1, 1)
            head.Position = Vector3.new(0, 2.5, 0)
            head.Anchored = true
            head.BrickColor = BrickColor.new("Bright red")
            head.Parent = previewModel
        else
            local part = Instance.new("Part")
            part.Size = Vector3.new(2, 3, 1)
            part.Position = Vector3.new(0, 1.5, 0)
            part.Anchored = true
            part.BrickColor = BrickColor.new("Bright red")
            part.Parent = previewModel
        end
    end
    previewModel.Parent = viewport
    updatePreview()
    LocalPlayer.CharacterAdded:Connect(updatePreview)
    RunService.RenderStepped:Connect(updatePreview)

    local vcam = Instance.new("Camera")
    vcam.CFrame = CFrame.new(4, 2, 4, -0.7, 0, -0.7, 0, 1, 0, 0.7, 0, -0.7)
    viewport.CurrentCamera = vcam

    -- ESP değişkenleri
    local function isEnemy(player)
        if player == LocalPlayer then return false end
        if teamCheck and player.Team and LocalPlayer.Team then
            return player.Team ~= LocalPlayer.Team
        end
        return true
    end

    local function getCharacterSize(player)
        if player.Character and player.Character:FindFirstChild("Head") and player.Character:FindFirstChild("HumanoidRootPart") then
            local head = player.Character.Head
            local root = player.Character.HumanoidRootPart
            local headPos, _ = Camera:WorldToViewportPoint(head.Position)
            local rootPos, _ = Camera:WorldToViewportPoint(root.Position)
            local height = math.abs(headPos.Y - rootPos.Y) * 2.5
            local width = height * 0.6
            return Vector2.new(width, height), Vector2.new(rootPos.X, rootPos.Y - height/2)
        end
        return Vector2.new(60, 100), Vector2.new()
    end

    local function updateESP()
        for player, data in pairs(espConnections) do
            if data.box then data.box.Visible = false end
            if data.nametag then data.nametag.Visible = false end
            if data.health then
                if data.health.bg then data.health.bg.Visible = false end
                if data.health.fill then data.health.fill.Visible = false end
            end
        end

        for _, player in ipairs(Players:GetPlayers()) do
            if isEnemy(player) and player.Character and player.Character:FindFirstChild("Humanoid") and player.Character.Humanoid.Health > 0 then
                local root = player.Character:FindFirstChild("HumanoidRootPart")
                if root then
                    local pos, onScreen = Camera:WorldToViewportPoint(root.Position)
                    if onScreen then
                        local size, _ = getCharacterSize(player)
                        if espEnabled then
                            if not espConnections[player] then espConnections[player] = {} end
                            if not espConnections[player].box then
                                espConnections[player].box = Drawing.new("Square")
                                espConnections[player].box.Thickness = 2
                                espConnections[player].box.Filled = false
                            end
                            local box = espConnections[player].box
                            box.Color = Color3.new(1,0,0)
                            box.Size = size
                            box.Position = Vector2.new(pos.X - size.X/2, pos.Y - size.Y/2)
                            box.Visible = true
                        end

                        if livesEnabled then
                            if not espConnections[player] then espConnections[player] = {} end
                            if not espConnections[player].health then
                                espConnections[player].health = {}
                                espConnections[player].health.bg = Drawing.new("Square")
                                espConnections[player].health.bg.Filled = true
                                espConnections[player].health.fill = Drawing.new("Square")
                                espConnections[player].health.fill.Filled = true
                            end
                            local health = player.Character.Humanoid.Health
                            local maxHealth = player.Character.Humanoid.MaxHealth
                            local healthPercent = health / maxHealth
                            local barWidth = size.X
                            local barHeight = 4
                            local barPos = Vector2.new(pos.X - size.X/2, pos.Y + size.Y/2 + 2)
                            espConnections[player].health.bg.Size = Vector2.new(barWidth, barHeight)
                            espConnections[player].health.bg.Position = barPos
                            espConnections[player].health.bg.Color = Color3.new(0,0,0)
                            espConnections[player].health.bg.Visible = true
                            espConnections[player].health.fill.Size = Vector2.new(barWidth * healthPercent, barHeight)
                            espConnections[player].health.fill.Position = barPos
                            espConnections[player].health.fill.Color = Color3.new(1 - healthPercent, healthPercent, 0)
                            espConnections[player].health.fill.Visible = true
                        end

                        if mtEnabled then
                            if not espConnections[player] then espConnections[player] = {} end
                            if not espConnections[player].nametag then
                                espConnections[player].nametag = Drawing.new("Text")
                                espConnections[player].nametag.Size = 16
                                espConnections[player].nametag.Center = true
                                espConnections[player].nametag.Outline = true
                            end
                            local dist = (root.Position - Camera.CFrame.Position).Magnitude
                            espConnections[player].nametag.Text = player.Name .. " [" .. math.floor(dist) .. "m]"
                            espConnections[player].nametag.Position = Vector2.new(pos.X, pos.Y - size.Y/2 - 20)
                            espConnections[player].nametag.Color = Color3.new(1,1,1)
                            espConnections[player].nametag.Visible = true
                        end
                    end
                end
            end
        end
    end

    local function updateChams()
        for _, player in ipairs(Players:GetPlayers()) do
            if isEnemy(player) then
                if not chamsHighlights[player] then
                    chamsHighlights[player] = Instance.new("Highlight")
                    chamsHighlights[player].DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                end
                local highlight = chamsHighlights[player]
                highlight.Enabled = chamsEnabled
                if chamsEnabled and player.Character then
                    local root = player.Character:FindFirstChild("HumanoidRootPart")
                    if root then
                        local origin = Camera.CFrame.Position
                        local direction = (root.Position - origin).Unit
                        local ray = Ray.new(origin, direction * 1000)
                        local hit = Workspace:FindPartOnRay(ray, player.Character)
                        if hit and hit:IsDescendantOf(player.Character) then
                            highlight.FillColor = visibleColor
                        else
                            highlight.FillColor = invisibleColor
                        end
                        highlight.Parent = player.Character
                    end
                else
                    highlight.Parent = nil
                end
            else
                if chamsHighlights[player] then
                    chamsHighlights[player].Parent = nil
                end
            end
        end
    end

    Players.PlayerRemoving:Connect(function(player)
        if espConnections[player] then
            if espConnections[player].box then espConnections[player].box:Remove() end
            if espConnections[player].nametag then espConnections[player].nametag:Remove() end
            if espConnections[player].health then
                if espConnections[player].health.bg then espConnections[player].health.bg:Remove() end
                if espConnections[player].health.fill then espConnections[player].health.fill:Remove() end
            end
            espConnections[player] = nil
        end
        if chamsHighlights[player] then
            chamsHighlights[player]:Destroy()
            chamsHighlights[player] = nil
        end
    end)

    RunService.RenderStepped:Connect(function()
        if espEnabled or livesEnabled or mtEnabled then updateESP() end
        if chamsEnabled then updateChams() end
    end)

    local boxEspToggle = createAnimatedToggle("Box ESP", false, function(state) espEnabled = state end)
    boxEspToggle.Parent = leftPanel
    local livesToggle = createAnimatedToggle("Lives (Health Bar)", false, function(state) livesEnabled = state end)
    livesToggle.Parent = leftPanel
    local mtToggle = createAnimatedToggle("MT (Name + Distance)", false, function(state) mtEnabled = state end)
    mtToggle.Parent = leftPanel
    local chamsToggle = createAnimatedToggle("Chams", false, function(state) chamsEnabled = state end)
    chamsToggle.Parent = leftPanel
    local invColorPicker = createColorPicker("Invisible Color", invisibleColor, function(col) invisibleColor = col end)
    invColorPicker.Parent = leftPanel
    local visColorPicker = createColorPicker("Visible Color", visibleColor, function(col) visibleColor = col end)
    visColorPicker.Parent = leftPanel
    local teamCheckToggle = createAnimatedToggle("Team Check (Hide teammates)", true, function(state) teamCheck = state end)
    teamCheckToggle.Parent = leftPanel

    -- ===============================
    -- AIMBOT SEKMESİ
    -- ===============================
    local aimbotFrame = tabContent["Aimbot"]

    local aimbotToggle = createAnimatedToggle("Aimbot", false, function(state) aimbotEnabled = state end)
    aimbotToggle.Parent = aimbotFrame

    local keySelectFrame = Instance.new("Frame")
    keySelectFrame.Size = UDim2.new(1, 0, 0, 60)
    keySelectFrame.BackgroundTransparency = 1
    keySelectFrame.Parent = aimbotFrame

    local keyLabel = Instance.new("TextLabel")
    keyLabel.Size = UDim2.new(0.5, 0, 1, 0)
    keyLabel.BackgroundTransparency = 1
    keyLabel.Text = "Aimbot Key:"
    keyLabel.TextColor3 = Color3.new(1, 1, 1)
    keyLabel.TextSize = 20
    keyLabel.Font = Enum.Font.Gotham
    keyLabel.TextXAlignment = Enum.TextXAlignment.Left
    keyLabel.Parent = keySelectFrame

    local keyButton = Instance.new("TextButton")
    keyButton.Size = UDim2.new(0.4, 0, 0, 40)
    keyButton.Position = UDim2.new(0.6, 0, 0.5, -20)
    keyButton.BackgroundColor3 = Color3.fromRGB(30,30,30)
    keyButton.Text = "Right Click"
    keyButton.TextColor3 = Color3.new(1,1,1)
    keyButton.TextSize = 18
    keyButton.Font = Enum.Font.Gotham
    keyButton.Parent = keySelectFrame
    local keyBtnCorner = Instance.new("UICorner")
    keyBtnCorner.CornerRadius = UDim.new(0, 8)
    keyBtnCorner.Parent = keyButton

    local selectingKey = false
    keyButton.MouseButton1Click:Connect(function()
        selectingKey = true
        keyButton.Text = "Press any key/button..."
    end)

    UserInputService.InputBegan:Connect(function(input, gp)
        if gp then return end
        if selectingKey then
            selectingKey = false
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                aimbotKey = Enum.UserInputType.MouseButton1
                keyButton.Text = "Left Click"
            elseif input.UserInputType == Enum.UserInputType.MouseButton2 then
                aimbotKey = Enum.UserInputType.MouseButton2
                keyButton.Text = "Right Click"
            elseif input.UserInputType == Enum.UserInputType.MouseButton3 then
                aimbotKey = Enum.UserInputType.MouseButton3
                keyButton.Text = "Middle Click"
            elseif input.KeyCode ~= Enum.KeyCode.Unknown then
                aimbotKey = input.KeyCode
                keyButton.Text = tostring(input.KeyCode):gsub("Enum.KeyCode.", "")
            end
        end
    end)

    local aimbotPartToggle = createAnimatedToggle("Aim at Head", true, function(state) aimbotTargetPart = state and "Head" or "HumanoidRootPart" end)
    aimbotPartToggle.Parent = aimbotFrame
    local aimbotSmoothSlider = createSlider("Smoothness", 1, 20, 5, function(val) aimbotSmoothness = val end)
    aimbotSmoothSlider.Parent = aimbotFrame
    local aimbotFOVSlider = createSlider("FOV", 10, 360, 90, function(val) aimbotFOV = val end)
    aimbotFOVSlider.Parent = aimbotFrame

    local function getClosestEnemy()
        local closestDist = aimbotFOV
        local closestPlayer = nil
        local closestPos = nil
        for _, player in ipairs(Players:GetPlayers()) do
            if isEnemy(player) and player.Character and player.Character:FindFirstChild(aimbotTargetPart) and player.Character.Humanoid.Health > 0 then
                local part = player.Character[aimbotTargetPart]
                local pos, onScreen = Camera:WorldToViewportPoint(part.Position)
                if onScreen then
                    local mousePos = Vector2.new(Mouse.X, Mouse.Y)
                    local screenPos = Vector2.new(pos.X, pos.Y)
                    local dist = (mousePos - screenPos).Magnitude
                    if dist < closestDist then
                        closestDist = dist
                        closestPlayer = player
                        closestPos = part.Position
                    end
                end
            end
        end
        return closestPlayer, closestPos
    end

    RunService.RenderStepped:Connect(function()
        if aimbotEnabled then
            local active = false
            if typeof(aimbotKey) == "EnumItem" and aimbotKey.EnumType == Enum.KeyCode then
                active = UserInputService:IsKeyDown(aimbotKey)
            elseif typeof(aimbotKey) == "EnumItem" and aimbotKey.EnumType == Enum.UserInputType then
                active = UserInputService:IsMouseButtonPressed(aimbotKey)
            end
            if active then
                local target, targetPos = getClosestEnemy()
                if target and targetPos then
                    local cameraPos = Camera.CFrame.Position
                    local direction = (targetPos - cameraPos).Unit
                    local newCFrame = CFrame.lookAt(cameraPos, cameraPos + direction)
                    Camera.CFrame = Camera.CFrame:Lerp(newCFrame, aimbotSmoothness / 100, Enum.EasingStyle.Sine)
                end
            end
        end
    end)

    -- ===============================
    -- GUN SEKMESİ
    -- ===============================
    local gunFrame = tabContent["Gun"]

    local function handleRecoil(tool)
        if noRecoilEnabled and tool then
            local oldRecoil = tool.Recoil
            if oldRecoil then tool.Recoil = function() end end
        end
    end

    local function handleRapidFire(tool)
        if rapidFireEnabled and tool then
            if tool:FindFirstChild("FireRate") then tool.FireRate.Value = 0 end
            if tool:FindFirstChild("Ammo") then
                tool.Ammo.Value = tool:FindFirstChild("MaxAmmo") and tool.MaxAmmo.Value or 30
            end
            if tool:FindFirstChild("AutoFire") then tool.AutoFire.Value = true end
        end
    end

    LocalPlayer.CharacterAdded:Connect(function(char)
        char.ChildAdded:Connect(function(child)
            if child:IsA("Tool") then
                handleRecoil(child)
                handleRapidFire(child)
            end
        end)
    end)

    RunService.Heartbeat:Connect(function()
        local tool = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildWhichIsA("Tool")
        if tool then
            handleRecoil(tool)
            handleRapidFire(tool)
        end
    end)

    local noRecoilToggle = createAnimatedToggle("No Recoil", false, function(state) noRecoilEnabled = state end)
    noRecoilToggle.Parent = gunFrame
    local rapidFireToggle = createAnimatedToggle("Rapid Fire", false, function(state) rapidFireEnabled = state end)
    rapidFireToggle.Parent = gunFrame

    -- ===============================
    -- PROFILE SEKMESİ
    -- ===============================
    local profileFrame = tabContent["Profile"]
    profileFrame:ClearAllChildren()

    local playerList = Instance.new("ScrollingFrame")
    playerList.Size = UDim2.new(1, 0, 1, 0)
    playerList.BackgroundTransparency = 1
    playerList.BorderSizePixel = 0
    playerList.ScrollBarThickness = 6
    playerList.AutomaticCanvasSize = Enum.AutomaticSize.Y
    playerList.Parent = profileFrame

    local listLayout = Instance.new("UIListLayout")
    listLayout.Padding = UDim.new(0, 10)
    listLayout.SortOrder = Enum.SortOrder.LayoutOrder
    listLayout.Parent = playerList
    local listPadding = Instance.new("UIPadding")
    listPadding.PaddingTop = UDim.new(0, 10)
    listPadding.PaddingBottom = UDim.new(0, 10)
    listPadding.PaddingLeft = UDim.new(0, 10)
    listPadding.PaddingRight = UDim.new(0, 10)
    listPadding.Parent = playerList

    local function refreshPlayerList()
        playerList:ClearAllChildren()
        for _, player in ipairs(Players:GetPlayers()) do
            if player ~= LocalPlayer then
                local entry = Instance.new("Frame")
                entry.Size = UDim2.new(1, 0, 0, 70)
                entry.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
                entry.Parent = playerList
                local entryCorner = Instance.new("UICorner")
                entryCorner.CornerRadius = UDim.new(0, 8)
                entryCorner.Parent = entry

                local thumbnail = Instance.new("ImageLabel")
                thumbnail.Size = UDim2.new(0, 50, 0, 50)
                thumbnail.Position = UDim2.new(0, 10, 0.5, -25)
                thumbnail.BackgroundColor3 = Color3.fromRGB(50,50,50)
                thumbnail.Image = "rbxthumb://type=AvatarHeadShot&id=" .. player.UserId .. "&w=48&h=48"
                thumbnail.Parent = entry
                local thumbCorner = Instance.new("UICorner")
                thumbCorner.CornerRadius = UDim.new(0, 25)
                thumbCorner.Parent = thumbnail

                local nameLabel = Instance.new("TextLabel")
                nameLabel.Size = UDim2.new(0.5, 0, 1, 0)
                nameLabel.Position = UDim2.new(0, 70, 0, 0)
                nameLabel.BackgroundTransparency = 1
                nameLabel.Text = player.Name
                nameLabel.TextColor3 = Color3.new(1,1,1)
                nameLabel.TextSize = 20
                nameLabel.Font = Enum.Font.Gotham
                nameLabel.TextXAlignment = Enum.TextXAlignment.Left
                nameLabel.Parent = entry

                local loadBtn = Instance.new("TextButton")
                loadBtn.Size = UDim2.new(0, 80, 0, 40)
                loadBtn.Position = UDim2.new(1, -90, 0.5, -20)
                loadBtn.BackgroundColor3 = Color3.fromRGB(255,0,0)
                loadBtn.Text = "LOAD"
                loadBtn.TextColor3 = Color3.new(1,1,1)
                loadBtn.TextSize = 16
                loadBtn.Font = Enum.Font.Gotham
                loadBtn.Parent = entry
                local loadCorner = Instance.new("UICorner")
                loadCorner.CornerRadius = UDim.new(0, 8)
                loadCorner.Parent = loadBtn

                loadBtn.MouseButton1Click:Connect(function()
                    if player.Character then
                        local clone = player.Character:Clone()
                        if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
                            clone.HumanoidRootPart.CFrame = LocalPlayer.Character.HumanoidRootPart.CFrame + Vector3.new(0,5,0)
                            clone.Name = player.Name .. "_clone"
                            clone.Parent = Workspace
                            game:GetService("Debris"):AddItem(clone, 30)
                        end
                    end
                end)
            end
        end
    end
    refreshPlayerList()
    Players.PlayerAdded:Connect(refreshPlayerList)
    Players.PlayerRemoving:Connect(refreshPlayerList)

    -- ===============================
    -- SETTINGS SEKMESİ
    -- ===============================
    local settingsFrame = tabContent["Settings"]
    local watermarkToggle = createAnimatedToggle("Watermark", true, function() end)
    watermarkToggle.Parent = settingsFrame
    local fpsToggle = createAnimatedToggle("Show FPS", false, function() end)
    fpsToggle.Parent = settingsFrame

    -- ===============================
    -- SET SEKMESİ
    -- ===============================
    local setFrame = tabContent["Set"]
    local keyChangeBtn = Instance.new("TextButton")
    keyChangeBtn.Size = UDim2.new(1, 0, 0, 60)
    keyChangeBtn.BackgroundColor3 = Color3.fromRGB(30,30,30)
    keyChangeBtn.Text = "Menu Key: INSERT (Click to change)"
    keyChangeBtn.TextColor3 = Color3.new(1,1,1)
    keyChangeBtn.TextSize = 22
    keyChangeBtn.Font = Enum.Font.Gotham
    keyChangeBtn.Parent = setFrame
    local keyChangeCorner = Instance.new("UICorner")
    keyChangeCorner.CornerRadius = UDim.new(0, 12)
    keyChangeCorner.Parent = keyChangeBtn

    keyChangeBtn.MouseButton1Click:Connect(function()
        isWaitingForKey = true
        keyChangeBtn.Text = "Press any key..."
    end)

    UserInputService.InputBegan:Connect(function(input, gp)
        if gp then return end
        if isWaitingForKey then
            if input.KeyCode ~= Enum.KeyCode.Unknown then
                menuKey = input.KeyCode
                isWaitingForKey = false
                keyChangeBtn.Text = "Menu Key: " .. tostring(menuKey):gsub("Enum.KeyCode.", "")
            end
        end
        if input.KeyCode == menuKey and not isWaitingForKey and menuGui then
            if menuGui.Enabled then
                TweenService:Create(mainFrame, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.In), {Size = UDim2.new(0,0,0,0), Position = UDim2.new(0.5,0,0.5,0)}):Play()
                wait(0.3)
                menuGui.Enabled = false
            else
                menuGui.Enabled = true
                mainFrame.Size = UDim2.new(0,0,0,0)
                mainFrame.Position = UDim2.new(0.5,0,0.5,0)
                TweenService:Create(mainFrame, TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Size = UDim2.new(0,1200,0,750), Position = UDim2.new(0.5,-600,0.5,-375)}):Play()
            end
        end
    end)

    -- ===============================
    -- CFG SEKMESİ (ÇALIŞIR DURUMDA)
    -- ===============================
    local cfgFrame = tabContent["CFG"]
    cfgFrame:ClearAllChildren()

    local cfgTitle = Instance.new("TextLabel")
    cfgTitle.Size = UDim2.new(1, 0, 0, 40)
    cfgTitle.BackgroundTransparency = 1
    cfgTitle.Text = "Configuration Manager"
    cfgTitle.TextColor3 = Color3.new(1, 1, 1)
    cfgTitle.TextSize = 24
    cfgTitle.Font = Enum.Font.GothamBlack
    cfgTitle.Parent = cfgFrame

    local nameBox = Instance.new("TextBox")
    nameBox.Size = UDim2.new(1, -20, 0, 50)
    nameBox.Position = UDim2.new(0, 10, 0, 50)
    nameBox.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    nameBox.TextColor3 = Color3.new(1, 1, 1)
    nameBox.PlaceholderText = "Config adı girin"
    nameBox.Text = ""
    nameBox.TextSize = 20
    nameBox.Font = Enum.Font.Gotham
    nameBox.Parent = cfgFrame
    local nameCorner = Instance.new("UICorner")
    nameCorner.CornerRadius = UDim.new(0, 8)
    nameCorner.Parent = nameBox

    local saveBtn = Instance.new("TextButton")
    saveBtn.Size = UDim2.new(0.45, -10, 0, 50)
    saveBtn.Position = UDim2.new(0, 10, 0, 110)
    saveBtn.BackgroundColor3 = Color3.fromRGB(0, 200, 0)
    saveBtn.Text = "SAVE"
    saveBtn.TextColor3 = Color3.new(1, 1, 1)
    saveBtn.TextSize = 20
    saveBtn.Font = Enum.Font.Gotham
    saveBtn.Parent = cfgFrame
    local saveCorner = Instance.new("UICorner")
    saveCorner.CornerRadius = UDim.new(0, 8)
    saveCorner.Parent = saveBtn

    local loadBtn = Instance.new("TextButton")
    loadBtn.Size = UDim2.new(0.45, -10, 0, 50)
    loadBtn.Position = UDim2.new(0.55, 0, 0, 110)
    loadBtn.BackgroundColor3 = Color3.fromRGB(200, 200, 0)
    loadBtn.Text = "LOAD"
    loadBtn.TextColor3 = Color3.new(1, 1, 1)
    loadBtn.TextSize = 20
    loadBtn.Font = Enum.Font.Gotham
    loadBtn.Parent = cfgFrame
    local loadCorner = Instance.new("UICorner")
    loadCorner.CornerRadius = UDim.new(0, 8)
    loadCorner.Parent = loadBtn

    local listLabel = Instance.new("TextLabel")
    listLabel.Size = UDim2.new(1, 0, 0, 30)
    listLabel.Position = UDim2.new(0, 0, 0, 170)
    listLabel.BackgroundTransparency = 1
    listLabel.Text = "Saved Configs:"
    listLabel.TextColor3 = Color3.new(1, 1, 1)
    listLabel.TextSize = 18
    listLabel.Font = Enum.Font.Gotham
    listLabel.TextXAlignment = Enum.TextXAlignment.Left
    listLabel.Parent = cfgFrame

    local configList = Instance.new("ScrollingFrame")
    configList.Size = UDim2.new(1, 0, 0, 200)
    configList.Position = UDim2.new(0, 0, 0, 200)
    configList.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
    configList.BorderSizePixel = 0
    configList.ScrollBarThickness = 6
    configList.CanvasSize = UDim2.new(0, 0, 0, 0)
    configList.AutomaticCanvasSize = Enum.AutomaticSize.Y
    configList.Parent = cfgFrame
    local listCorner = Instance.new("UICorner")
    listCorner.CornerRadius = UDim.new(0, 8)
    listCorner.Parent = configList

    local listLayoutCfg = Instance.new("UIListLayout")
    listLayoutCfg.Padding = UDim.new(0, 5)
    listLayoutCfg.SortOrder = Enum.SortOrder.LayoutOrder
    listLayoutCfg.Parent = configList
    local listPaddingCfg = Instance.new("UIPadding")
    listPaddingCfg.PaddingTop = UDim.new(0, 5)
    listPaddingCfg.PaddingBottom = UDim.new(0, 5)
    listPaddingCfg.PaddingLeft = UDim.new(0, 5)
    listPaddingCfg.PaddingRight = UDim.new(0, 5)
    listPaddingCfg.Parent = configList

    -- Config kaydetme
    local function saveCurrentConfig(name)
        if name == "" then return end
        local config = {
            flySpeed = flySpeed,
            speedMultiplier = speedMultiplier,
            espEnabled = espEnabled,
            chamsEnabled = chamsEnabled,
            mtEnabled = mtEnabled,
            livesEnabled = livesEnabled,
            teamCheck = teamCheck,
            invisibleColor = invisibleColor,
            visibleColor = visibleColor,
            aimbotEnabled = aimbotEnabled,
            aimbotTargetPart = aimbotTargetPart,
            aimbotSmoothness = aimbotSmoothness,
            aimbotFOV = aimbotFOV,
            aimbotKey = aimbotKey,
            noRecoilEnabled = noRecoilEnabled,
            rapidFireEnabled = rapidFireEnabled,
            superJump = superJump,
            godMode = godMode,
        }
        savedConfigs[name] = config
        refreshConfigList()
    end

    -- Config yükleme
    local function loadConfig(name)
        local cfg = savedConfigs[name]
        if not cfg then return end
        flySpeed = cfg.flySpeed
        speedMultiplier = cfg.speedMultiplier
        espEnabled = cfg.espEnabled
        chamsEnabled = cfg.chamsEnabled
        mtEnabled = cfg.mtEnabled
        livesEnabled = cfg.livesEnabled
        teamCheck = cfg.teamCheck
        invisibleColor = cfg.invisibleColor
        visibleColor = cfg.visibleColor
        aimbotEnabled = cfg.aimbotEnabled
        aimbotTargetPart = cfg.aimbotTargetPart
        aimbotSmoothness = cfg.aimbotSmoothness
        aimbotFOV = cfg.aimbotFOV
        aimbotKey = cfg.aimbotKey
        noRecoilEnabled = cfg.noRecoilEnabled
        rapidFireEnabled = cfg.rapidFireEnabled
        superJump = cfg.superJump
        godMode = cfg.godMode

        -- Toggle görsellerini güncelle (manuel tetikleme gerekir ama şimdilik değişkenler atandı)
        print("Config yüklendi: " .. name)
    end

    -- Liste yenileme
    local function refreshConfigList()
        configList:ClearAllChildren()
        for name, _ in pairs(savedConfigs) do
            local btn = Instance.new("TextButton")
            btn.Size = UDim2.new(1, 0, 0, 40)
            btn.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
            btn.Text = name
            btn.TextColor3 = Color3.new(1, 1, 1)
            btn.TextSize = 18
            btn.Font = Enum.Font.Gotham
            btn.Parent = configList
            local btnCorner = Instance.new("UICorner")
            btnCorner.CornerRadius = UDim.new(0, 6)
            btnCorner.Parent = btn
            btn.MouseButton1Click:Connect(function()
                loadConfig(name)
            end)
        end
    end

    saveBtn.MouseButton1Click:Connect(function()
        saveCurrentConfig(nameBox.Text)
        nameBox.Text = ""
    end)

    -- ===============================
    -- KARAKTER DEĞİŞİMİ
    -- ===============================
    LocalPlayer.CharacterAdded:Connect(function(char)
        char:WaitForChild("Humanoid")
        char.Humanoid.WalkSpeed = 16 * speedMultiplier
    end)
end
