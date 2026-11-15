local _, ns = ...
local LEM = ns.LibEditMode

local DEFAULT = {
    point = "CENTER", x = 0, y = -120,
    size = 40, showIcon = true,
    showText = true, textSize = 12, textR = 1, textG = 0.82, textB = 0, -- gold, like GameFontNormal
}
local FISHING_ICON = 136245 -- Trade_Fishing, shown in Edit Mode when no pole is equipped
local GetItemInfoInstant = C_Item and C_Item.GetItemInfoInstant or GetItemInfoInstant

local L = ({
    frFR = { text = "Canne à pêche équipée", size = "Taille de l'icône", showIcon = "Afficher l'icône", show = "Afficher le texte",
             textSize = "Taille du texte", color = "Couleur du texte", edit = "Texte", button = "Modifier", hint = "Laisser vide pour le texte par défaut." },
    deDE = { text = "Angelrute ausgerüstet", size = "Symbolgröße", showIcon = "Symbol anzeigen", show = "Text anzeigen",
             textSize = "Textgröße", color = "Textfarbe", edit = "Text", button = "Ändern", hint = "Leer lassen für den Standardtext." },
    esES = { text = "Caña de pescar equipada", size = "Tamaño del icono", showIcon = "Mostrar icono", show = "Mostrar texto",
             textSize = "Tamaño del texto", color = "Color del texto", edit = "Texto", button = "Cambiar", hint = "Dejar vacío para el texto predeterminado." },
    esMX = { text = "Caña de pescar equipada", size = "Tamaño del icono", showIcon = "Mostrar icono", show = "Mostrar texto",
             textSize = "Tamaño del texto", color = "Color del texto", edit = "Texto", button = "Cambiar", hint = "Dejar vacío para el texto predeterminado." },
    itIT = { text = "Canna da pesca equipaggiata", size = "Dimensione icona", showIcon = "Mostra icona", show = "Mostra testo",
             textSize = "Dimensione testo", color = "Colore testo", edit = "Testo", button = "Modifica", hint = "Lascia vuoto per il testo predefinito." },
    ptBR = { text = "Vara de pescar equipada", size = "Tamanho do ícone", showIcon = "Mostrar ícone", show = "Mostrar texto",
             textSize = "Tamanho do texto", color = "Cor do texto", edit = "Texto", button = "Alterar", hint = "Deixe vazio para o texto padrão." },
    ruRU = { text = "Удочка экипирована", size = "Размер значка", showIcon = "Показывать значок", show = "Показывать текст",
             textSize = "Размер текста", color = "Цвет текста", edit = "Текст", button = "Изменить", hint = "Оставьте пустым для текста по умолчанию." },
    koKR = { text = "낚싯대 장착됨", size = "아이콘 크기", showIcon = "아이콘 표시", show = "텍스트 표시",
             textSize = "텍스트 크기", color = "텍스트 색상", edit = "텍스트", button = "변경", hint = "비워 두면 기본 텍스트를 사용합니다." },
    zhCN = { text = "已装备鱼竿", size = "图标大小", showIcon = "显示图标", show = "显示文字",
             textSize = "文字大小", color = "文字颜色", edit = "文字", button = "修改", hint = "留空则使用默认文字。" },
    zhTW = { text = "已裝備魚竿", size = "圖示大小", showIcon = "顯示圖示", show = "顯示文字",
             textSize = "文字大小", color = "文字顏色", edit = "文字", button = "修改", hint = "留空則使用預設文字。" },
})[GetLocale()] or { text = "Fishing pole equipped", size = "Icon size", showIcon = "Show icon", show = "Show text",
                     textSize = "Text size", color = "Text color", edit = "Text", button = "Change", hint = "Leave empty for the default text." }

local db = DEFAULT -- replaced by the saved table at login

local f = CreateFrame("Frame", "FishPoleEquippedFrame", UIParent)
f:SetSize(DEFAULT.size, DEFAULT.size)
f:SetPoint(DEFAULT.point, DEFAULT.x, DEFAULT.y)
f:Hide()
f.tex = f:CreateTexture(nil, "ARTWORK")
f.tex:SetAllPoints()
f.text = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
f.text:SetPoint("TOP", f, "BOTTOM", 0, -2)
local FONT, _, FONT_FLAGS = f.text:GetFont()

local function PoleEquipped()
    local id = GetInventoryItemID("player", INVSLOT_MAINHAND)
    if not id then return false end
    local _, _, _, _, _, classID, subclassID = GetItemInfoInstant(id)
    return classID == Enum.ItemClass.Weapon and subclassID == Enum.ItemWeaponSubclass.Fishingpole
end

local function Update()
    local pole = PoleEquipped()
    f:SetSize(db.size, db.size)
    f.tex:SetShown(db.showIcon)
    f.tex:SetTexture(pole and GetInventoryItemTexture("player", INVSLOT_MAINHAND) or FISHING_ICON)
    f.text:SetShown(db.showText)
    f.text:SetFont(FONT, db.textSize, FONT_FLAGS)
    f.text:SetTextColor(db.textR, db.textG, db.textB)
    f.text:SetText(db.text or L.text)
    f:SetShown(pole or LEM:IsInEditMode())
end

LEM:AddFrame(f, function(_, _, point, x, y)
    db.point, db.x, db.y = point, x, y
end, DEFAULT, "FishPoleEquipped")
LEM:RegisterCallback("enter", Update)
LEM:RegisterCallback("exit", Update)

local function SetColor(r, g, b)
    db.textR, db.textG, db.textB = r, g, b
    Update()
end

local function PickColor()
    local pr, pg, pb = db.textR, db.textG, db.textB
    local function onChange() SetColor(ColorPickerFrame:GetColorRGB()) end
    local function onCancel() SetColor(pr, pg, pb) end
    if ColorPickerFrame.SetupColorPickerAndShow then
        ColorPickerFrame:SetupColorPickerAndShow({ r = pr, g = pg, b = pb, hasOpacity = false, swatchFunc = onChange, cancelFunc = onCancel })
    else
        ColorPickerFrame.hasOpacity = false
        ColorPickerFrame.func = onChange
        ColorPickerFrame.cancelFunc = onCancel
        ColorPickerFrame:SetColorRGB(pr, pg, pb)
        ColorPickerFrame:Hide()
        ColorPickerFrame:Show()
    end
end

-- the edit box field was renamed across client versions
local function EditBoxOf(popup) return popup.GetEditBox and popup:GetEditBox() or popup.editBox end

local function SaveText(box)
    local t = strtrim(box:GetText())
    db.text = t ~= "" and t or nil
    Update()
end

StaticPopupDialogs["FISH_POLE_EQUIPPED_TEXT"] = {
    text = L.edit .. "\n" .. L.hint,
    button1 = OKAY, button2 = CANCEL,
    hasEditBox = true, editBoxWidth = 260,
    OnShow = function(self) local box = EditBoxOf(self); box:SetText(db.text or L.text); box:HighlightText() end,
    OnAccept = function(self) SaveText(EditBoxOf(self)) end,
    EditBoxOnEnterPressed = function(box) SaveText(box); box:GetParent():Hide() end,
    EditBoxOnEscapePressed = function(box) box:GetParent():Hide() end,
    timeout = 0, whileDead = true, hideOnEscape = true,
}

-- Options > AddOns page; needs the saved table, so it runs at login
local function RegisterOptions()
    local category, layout = Settings.RegisterVerticalLayoutCategory("FishPoleEquipped")
    local settings = {} -- key -> setting, so a reset also refreshes the controls

    local function Checkbox(variable, key, name)
        local s = Settings.RegisterAddOnSetting(category, variable, key, db, Settings.VarType.Boolean, name, DEFAULT[key])
        s:SetValueChangedCallback(Update)
        settings[key] = s
        Settings.CreateCheckbox(category, s)
    end

    local function Slider(variable, key, name, min, max, step)
        local s = Settings.RegisterAddOnSetting(category, variable, key, db, Settings.VarType.Number, name, DEFAULT[key])
        s:SetValueChangedCallback(Update)
        settings[key] = s
        local options = Settings.CreateSliderOptions(min, max, step)
        options:SetLabelFormatter(MinimalSliderWithSteppersMixin.Label.Right)
        Settings.CreateSlider(category, s, options)
    end

    Checkbox("FISH_POLE_EQUIPPED_SHOW_ICON", "showIcon", L.showIcon)
    Slider("FISH_POLE_EQUIPPED_SIZE", "size", L.size, 16, 128, 2)
    Checkbox("FISH_POLE_EQUIPPED_TEXT", "showText", L.show)
    Slider("FISH_POLE_EQUIPPED_TEXT_SIZE", "textSize", L.textSize, 8, 32, 1)
    layout:AddInitializer(CreateSettingsButtonInitializer(L.color, L.button, PickColor, nil, true))
    layout:AddInitializer(CreateSettingsButtonInitializer(L.edit, L.button, function()
        StaticPopup_Show("FISH_POLE_EQUIPPED_TEXT")
    end, nil, true))
    layout:AddInitializer(CreateSettingsButtonInitializer(RESET_TO_DEFAULT or "Reset to default", RESET or "Reset", function()
        -- position is left alone: Edit Mode has its own "Reset Position"
        for k, s in pairs(settings) do s:SetValue(DEFAULT[k]) end
        db.textR, db.textG, db.textB, db.text = DEFAULT.textR, DEFAULT.textG, DEFAULT.textB, nil
        Update()
    end, nil, true))

    Settings.RegisterAddOnCategory(category)
end

f:RegisterEvent("PLAYER_LOGIN")
f:RegisterEvent("PLAYER_EQUIPMENT_CHANGED")
f:SetScript("OnEvent", function(_, event)
    if event == "PLAYER_LOGIN" then
        FishPoleEquippedDB = FishPoleEquippedDB or {}
        db = FishPoleEquippedDB
        for k, v in pairs(DEFAULT) do
            if db[k] == nil then db[k] = v end
        end
        f:ClearAllPoints()
        f:SetPoint(db.point, UIParent, db.point, db.x, db.y)
        RegisterOptions()
    end
    Update()
end)
