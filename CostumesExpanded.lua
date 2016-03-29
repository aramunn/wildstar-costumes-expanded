require "Apollo"
require "Window"
require "CostumesLib"

local CostumesExpanded = {}
local costumes

local function getDefaultSettings()
  return {
    nBackground = 1,
    arWindowAnchorOffsets = { -446, -308, 446, 308 },
  }
end

local tSettings = getDefaultSettings()
local lastScrollPos = 0
local selectedSlot = -1

local arBackgrounds = {
  "00ffffff",
  "ff000000",
  "ff333333",
  "ff666666",
  "ff999999",
  "ffcccccc",
  "ffffffff",
  
  "ff1d3c42",
  "ff674f68",
  "ff8d835a",
  "ff973739",
}

local knWeaponModelId = 70573
local ktClassToWeaponCamera = {
  [GameLib.CodeEnumClass.Warrior]       = "Weapon_Sword2H",
  [GameLib.CodeEnumClass.Spellslinger]  = "Weapon_Pistols1H",
  [GameLib.CodeEnumClass.Stalker]       = "Weapon_Claws",
  [GameLib.CodeEnumClass.Esper]         = "Weapon_Psyblade",
  [GameLib.CodeEnumClass.Engineer]      = "Weapon_Launcher",
  [GameLib.CodeEnumClass.Medic]         = "Weapon_Resonator",
}
local ktItemSlotToCamera = {
  [GameLib.CodeEnumItemSlots.Chest]     = "Armor_Chest",
  [GameLib.CodeEnumItemSlots.Legs]      = "Armor_Pants",
  [GameLib.CodeEnumItemSlots.Head]      = "Armor_Head",
  [GameLib.CodeEnumItemSlots.Shoulder]  = "Armor_Shoulders",
  [GameLib.CodeEnumItemSlots.Feet]      = "Armor_Boots",
  [GameLib.CodeEnumItemSlots.Hands]     = "Armor_Gloves",
}
local ktManneqinIds = {
  [Unit.CodeEnumGender.Male] = 47305,
  [Unit.CodeEnumGender.Female] = 56135,
}

function CostumesExpanded:OnShowLargeWindow() --modified version of HelperUpdatePageItems
  self:OnCloseLargeWindow()
  self.largeCostumeListWindow = Apollo.LoadForm(self.xmlDoc, "LargeCostumeListWindow", nil, self)
  self.wndLargeCostumeList = self.largeCostumeListWindow:FindChild("LargeCostumeList")
  for nItemIdx = 1, #costumes.arDisplayedItems do
    local wndItemPreview = Apollo.LoadForm(costumes.xmlDoc, "CostumeListItem", self.wndLargeCostumeList, costumes)
    local wndMannequin = wndItemPreview:FindChild("CostumeWindow")

    if costumes.arDisplayedItems[nItemIdx] then
      wndMannequin:SetData(costumes.arDisplayedItems[nItemIdx])
      wndItemPreview:SetData(costumes.arDisplayedItems[nItemIdx])
      
      local wndCostumeBtn = wndItemPreview:FindChild("CostumeListItemBtn")
      wndCostumeBtn:SetData(costumes.arDisplayedItems[nItemIdx])
      wndCostumeBtn:SetCheck(costumes.itemSelected and costumes.itemSelected:GetItemId() == costumes.arDisplayedItems[nItemIdx]:GetItemId())
      
      wndMannequin:SetTooltipForm(nil)
      wndMannequin:SetTooltipDoc(nil)
      
      wndItemPreview:Show(true)
      
      local tItemCostumeInfo = costumes.arDisplayedItems[nItemIdx]:GetCostumeUnlockInfo()
      
      local bCanUse = tItemCostumeInfo and tItemCostumeInfo.bCanUseInCostume
      local wndUnusableIcon = wndItemPreview:FindChild("UnusableIcon")

      wndUnusableIcon:Show(not bCanUse)
      wndCostumeBtn:Enable(bCanUse)
      wndItemPreview:FindChild("DeprecatedIcon"):Show(costumes.arDisplayedItems[nItemIdx]:IsDeprecated())

      if costumes.eSelectedSlot == GameLib.CodeEnumItemSlots.Weapon then
        wndMannequin:SetCamera(ktClassToWeaponCamera[GameLib.GetPlayerUnit():GetClassId()])
        wndMannequin:SetCostumeToCreatureId(knWeaponModelId)
      else
        wndMannequin:SetCamera(ktItemSlotToCamera[costumes.eSelectedSlot])
        wndMannequin:SetCostumeToCreatureId(ktManneqinIds[costumes.unitPlayer:GetGender()])
      end

      wndMannequin:SetItem(costumes.arDisplayedItems[nItemIdx])
      wndMannequin:SetSheathed(false)
    else
      wndItemPreview:Show(false)
    end
  end
  self:ChangeBackground()
  self:ChangeWindowAnchors()
  self.wndLargeCostumeList:SetVScrollPos(lastScrollPos)
  selectedSlot = costumes.eSelectedSlot
end

function CostumesExpanded:OnLargeCostumeListWindowSizeChanged()
  self.wndLargeCostumeList:ArrangeChildrenTiles(Window.CodeEnumArrangeOrigin.LeftOrTop)
end

function CostumesExpanded:OnLargeCostumeListWindowClosed()
  self:OnCloseLargeWindow(true)
end

function CostumesExpanded:OnCycleBackground()
  if tSettings.nBackground == #arBackgrounds then
    tSettings.nBackground = 1
  else
    tSettings.nBackground = tSettings.nBackground + 1
  end
  self:ChangeBackground()
end

function CostumesExpanded:OnResetToDefaults()
  tSettings = getDefaultSettings()
  self:ChangeBackground()
  self:ChangeWindowAnchors()
end

function CostumesExpanded:ChangeBackground()
  self.wndLargeCostumeList:DestroyAllPixies()
  self.wndLargeCostumeList:AddPixie({
    strSprite = "WhiteFill", cr = arBackgrounds[tSettings.nBackground],
    loc = { fPoints = {0,0,1,1}, nOffsets = {0,0,0,0} },
  })
end

function CostumesExpanded:ChangeWindowAnchors()
  self.largeCostumeListWindow:SetAnchorOffsets(unpack(tSettings.arWindowAnchorOffsets))
  self.wndLargeCostumeList:ArrangeChildrenTiles(Window.CodeEnumArrangeOrigin.LeftOrTop)
end

function CostumesExpanded:OnCloseLargeWindow(bUpdateCostumes)
  if (self.largeCostumeListWindow and self.largeCostumeListWindow:IsValid()) then
    local nLeft, nTop, nRight, nBottom = self.largeCostumeListWindow:GetAnchorOffsets()
    tSettings.arWindowAnchorOffsets = { nLeft, nTop, nRight, nBottom }
    lastScrollPos = self.wndLargeCostumeList:GetVScrollPos()
    self.largeCostumeListWindow:Destroy()
    if (bUpdateCostumes) then costumes:HelperUpdatePageItems(1) end
    return true
  end
  return false
end

function CostumesExpanded:OnSave(eLevel)
  if eLevel ~= GameLib.CodeEnumAddonSaveLevel.Account then return nil end
  return tSettings
end

function CostumesExpanded:OnRestore(eLevel, tSave)
  for name, data in pairs(tSave) do
    if tSettings[name] ~= nil then tSettings[name] = data end
  end
end

function CostumesExpanded:new(o)
  o = o or {}
  setmetatable(o, self)
  self.__index = self
  return o
end

function CostumesExpanded:Init()
  Apollo.RegisterAddon(self)
end

function CostumesExpanded:OnLoad()
  self.xmlDoc = XmlDoc.CreateFromFile("CostumesExpanded.xml")
  self.xmlDoc:RegisterCallback("OnDocumentReady", self)
end

function CostumesExpanded:OnDocumentReady()
  if not self.xmlDoc then
    return
  end
  costumes = Apollo.GetAddon("Costumes")
  if not costumes then
    Print("CostumesExpanded didn't load because it couldn't find Carbine's default Costumes addon.")
    return
  end
  local strCloseExpanded = "OnCloseCostumesExpandedWindow"
  costumes[strCloseExpanded] = function () self:OnCloseLargeWindow() end
  local origOnInit = costumes.OnInit
  costumes.OnInit = function (...)
    origOnInit(...)
    self:AddButtonToWindow(costumes)
    costumes.wndMain:AddEventHandler("WindowClosed", strCloseExpanded)
  end
  local origOnRemoveWardrobeItem = costumes.OnRemoveWardrobeItem
  costumes.OnRemoveWardrobeItem = function (ref, wndHandler, wndControl, ...)
    self.bLargeCostumeListWindowWasOpen = self:OnCloseLargeWindow()
    origOnRemoveWardrobeItem(ref, wndHandler, wndControl, ...)
  end
  local origOnForgetResult = costumes.OnForgetResult
  costumes.OnForgetResult = function (ref, itemRemoved, eResult, ...)
    origOnForgetResult(ref, itemRemoved, eResult, ...)
    if eResult == CostumesLib.CostumeUnlockResult.ForgetItemSuccess then
      if (self.bLargeCostumeListWindowWasOpen) then self:OnShowLargeWindow() end
    end
  end
  local origOnCloseCancel = costumes.OnCloseCancel
  costumes.OnCloseCancel = function (...)
    origOnCloseCancel(...)
    if (self.bLargeCostumeListWindowWasOpen) then self:OnShowLargeWindow() end
  end
  local origHelperUpdatePageItems = costumes.HelperUpdatePageItems
  costumes.HelperUpdatePageItems = function (...)
    self.bLargeCostumeListWindowWasOpen = self:OnCloseLargeWindow()
    origHelperUpdatePageItems(...)
    if selectedSlot ~= costumes.eSelectedSlot then lastScrollPos = 0 end
    if (self.bLargeCostumeListWindowWasOpen) then self:OnShowLargeWindow() end
  end
end

function CostumesExpanded:AddButtonToWindow(addon)
  local wndContentContainer = addon.wndMain:FindChild("Center:ContentContainer")
  local wndPageDown = wndContentContainer:FindChild("PageDown")
  local nLeft, nTop, nRight, nBottom = wndPageDown:GetAnchorOffsets()
  wndPageDown:SetAnchorOffsets(nLeft+13, nTop, nRight+13, nBottom)
  local wndHookBtn = Apollo.LoadForm(self.xmlDoc, "CostumesExpandedHook", wndContentContainer, self)
  wndHookBtn:SetAnchorOffsets(150, 524, 197, 569)
end

local CostumesInstance = CostumesExpanded:new()
CostumesInstance:Init()
