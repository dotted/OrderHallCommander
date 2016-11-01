local me, addon = ...
local _G=_G
local wipe=wipe
local format=format
local UNKNOWN=UNKNOWN
local AceGUI=LibStub("AceGUI-3.0")
local module=addon:NewSubModule("widgets") --#module
local C=addon:GetColorTable()
local function Constructor()
	local widget= AceGUI:Create("Label")
	widget.SetAtlas=function (atlasname)
		widget.image:SetAtlas(atlasname)
	end
	widget.OnRelease=function() widget.image:SetAtlas(nil) end
end
AceGUI:RegisterWidgetType("AtlasLabel", Constructor, 1)
--- Quick backdrop
--
local backdrop = {
	bgFile="Interface\\TutorialFrame\\TutorialFrameBackground",
	edgeFile="Interface\\Tooltips\\UI-Tooltip-Border",
	tile=true,
	tileSize=16,
	edgeSize=16,
	insets={bottom=7,left=7,right=7,top=7}
}
local function addBackdrop(f,color)
	f:SetBackdrop(backdrop)
	f:SetBackdropBorderColor(C[color or 'Yellow']())
end
local function createOHCMissionListWidget()
	local Type="OHCMissionList"
	local Version=1
	local m={} --#OHCMissionList
	function m:ScrollDown()
		local obj=self.scroll
		if (#self.missions >1 and obj.scrollbar and obj.scrollbar:IsShown()) then
			obj:SetScroll(80)
			obj.scrollbar.ScrollDownButton:Click()
		end
	end
	function m:OnAcquire()
		wipe(self.missions)
	end
	function m:Show()
		self.frame:Show()
	end
	function m:Hide()
		self.frame:Hide()
		self:Release()
	end
	function m:AddButton(text,action)
		local obj=self.scroll
		local b=AceGUI:Create("Label")
		b:SetFullWidth(true)
		b:SetText(text)
		b:SetColor(C.yellow.r,C.yellow.g,C.yellow.b)
		--b:SetCallback("OnClick",action)
		obj:AddChild(b)
	end
	function m:AddMissionButton(mission,party,perc,source)
		if not self.missions[mission.missionID] then
			local obj=self.scroll
			local b=AceGUI:Create("OHCMiniMissionButton")
			b:SetMission(mission,party,perc,source)
			b:SetScale(0.7)
			b:SetFullWidth(true)
			self.missions[mission.missionID]=b
			obj:AddChild(b)
			local extra=b.extra
			extra.Success:Hide()
			extra.Failure:Hide()
			extra.Spinner:Show()
			extra.Spinner.Anim:Play()
		end

	end
	function m:AddMissionResult(missionID,success)
		local mission=self.missions[missionID]
		if mission then
			local frame=mission.frame
			local extra=mission.extra
			extra.Spinner.Anim:Stop()
			extra.Spinner:Hide()
			if success then
				extra.Success:Show()
				extra.Failure:Hide()
				for i=1,#frame.Rewards do
					frame.Rewards[i].Icon:SetDesaturated(false)
					frame.Rewards[i].Quantity:Show()
				end
			else
				extra.Success:Hide()
				extra.Failure:Show()
				for i=1,#frame.Rewards do
					frame.Rewards[i].Icon:SetDesaturated(true)
					frame.Rewards[i].Quantity:Hide()
				end
			end
		end
	end
	function m:AddRow(data,...)
		local obj=self.scroll
		local l=AceGUI:Create("InteractiveLabel")
		l:SetFontObject(GameFontNormalSmall)
		l:SetText(data)
		l:SetColor(...)
		l:SetFullWidth(true)
		obj:AddChild(l)

	end
	function m:AddFollower(follower,xp,levelup)
		local followerID=follower.followerID
		local followerType=follower.followerTypeID
		if xp < 0 then
			return self:AddFollowerIcon(followerType,addon:GetFollowerTexture(follower),
								format("%s was destroyed",follower.fullname or L["A ship"]))
		end
		if follower.maxed and not levelup then
			return
--			return self:AddFollowerIcon(followerType,addon:GetFollowerTexture(follower),format("%s is already at maximum xp",follower.fullname))
		end
		local quality=G.GetFollowerQuality(followerID) or follower.quality
		local level=G.GetFollowerLevel(followerID) or follower.level
		if levelup then
			PlaySound("UI_Garrison_CommandTable_Follower_LevelUp");
		end
		return self:AddFollowerIcon(followerType,
			addon:GetFollowerTexture(follower),
			format("%s gained %d xp%s%s",
				follower.fullname,
				xp,
				levelup and " |cffffed1a*** Level Up ***|r ." or ".",
				format(" %d to go.",follower.levelXP-follower.xp))
		)
	end
	function m:AddFollowerIcon(followerType,icon,text)
		local l=self:AddIconText(icon,text)
	end
	function m:AddIconText(icon,text,qt)
		local obj=self.scroll
		local l=AceGUI:Create("Label")
		l:SetFontObject(GameFontNormalSmall)
		if (qt) then
			l:SetText(format("%s x %s",text,qt))
		else
			l:SetText(text)
		end
		l:SetImage(icon)
		l:SetImageSize(24,24)
		l:SetHeight(26)
		l:SetFullWidth(true)
		obj:AddChild(l)
		if (obj.scrollbar and obj.scrollbar:IsShown()) then
			obj:SetScroll(80)
			obj.scrollbar.ScrollDownButton:Click()
		end
		return l
	end
	function m:AddItem(itemID,qt)
		local obj=self.scroll
		local _,itemlink,itemquality,_,_,_,_,_,_,itemtexture=GetItemInfo(itemID)
		if not itemlink then
			self:AddIconText(itemtexture,itemID,qt)
		else
			self:AddIconText(itemtexture,itemlink,qt)
		end
	end
	---@function [parent=#OHCMissionList]
	local function Constructor()
		local widget=AceGUI:Create("OHCGUIContainer")
		widget:SetLayout("Fill")
		widget.missions={}
		local scroll = AceGUI:Create("ScrollFrame")
		scroll:SetLayout("List") -- probably?
		scroll:SetFullWidth(true)
		scroll:SetFullHeight(true)
		widget:AddChild(scroll)
		for k,v in pairs(m) do widget[k]=v end
		widget:Show()
		widget.scroll=scroll
		widget.type=Type
		return widget
	end
	AceGUI:RegisterWidgetType(Type,Constructor,Version)
end
local function createOHCGUIContainerWidget()
	local Type="OHCGUIContainer"
	local Version=1
	local m={} --#OHCGUIContainer
	function m:Close()
		self.frame.CloseButton:Click()
	end
	function m:OnAcquire()
		self.frame:EnableMouse(true)
		self:SetTitleColor(C.Yellow())
		self.frame:SetFrameStrata("HIGH")
		self.frame:SetFrameLevel(999)
	end
	function m:SetContentWidth(x)
		self.content:SetWidth(x)
	end
	---@function [parent=#OHCGUIContainer]
	local function Constructor()
		local frame=CreateFrame("Frame",Type..AceGUI:GetNextWidgetNum(Type),nil,"GarrisonUITemplate")
		for _,f in pairs({frame:GetRegions()}) do
			if (f:GetObjectType()=="Texture" and f:GetAtlas()=="Garr_WoodFrameCorner") then f:Hide() end
		end
		local widget={frame=frame,missions={}}
		widget.type=Type
		widget.SetTitle=function(self,...) self.frame.TitleText:SetText(...) end
		widget.SetTitleColor=function(self,...) self.frame.TitleText:SetTextColor(...) end
		for k,v in pairs(m) do widget[k]=v end
		frame:SetScript("OnHide",function(self) self.obj:Fire('OnClose') end)
		frame.obj=widget
		--Container Support
		local content = CreateFrame("Frame",nil,frame)
		widget.content = content
		--addBackdrop(content,'Green')
		content.obj = widget
		content:SetPoint("TOPLEFT",25,-25)
		content:SetPoint("BOTTOMRIGHT",-25,25)
		AceGUI:RegisterAsContainer(widget)
		return widget
	end
	AceGUI:RegisterWidgetType(Type,Constructor,Version)
end
local function GMCLayer()
	local Type="GMCLayer"
	local Version=1
	local function OnRelease(self)
		wipe(self.childs)
	end
	local m={} --#GMCLayer
	function m:OnAcquire()
		self.frame:SetParent(UIParent)
		self.frame:SetFrameStrata("HIGH")
		self.frame:SetHeight(50)
		self.frame:SetWidth(100)
		self.frame:Show()
		self.frame:SetPoint("LEFT")
	end
	function m:Show()
		return self.frame:Show()
	end
	function m:Hide()
		self.frame:Hide()
		self:Release()
	end
	function m:SetScript(...)
		return self.frame:SetScript(...)
	end
	function m:SetParent(...)
		return self.frame:SetParent(...)
	end
	function m:PushChild(child,index)
		self.childs[index]=child
		self.scroll:AddChild(child)
	end
	function m:RemoveChild(index)
		local child=self.childs[index]
		if (child) then
			self.childs[index]=nil
			child:Hide()
			self:DoLayout()
		end
	end
	function m:ClearChildren()
		wipe(self.childs)
		self:AddScroll()
	end
	function m:AddScroll()
		if (self.scroll) then
			self:ReleaseChildren()
			self.scroll=nil
		end
		self.scroll=AceGUI:Create("ScrollFrame")
		local scroll=self.scroll
		self:AddChild(scroll)
		scroll:SetLayout("List") -- probably?
		scroll:SetFullWidth(true)
		scroll:SetFullHeight(true)
		scroll:SetPoint("TOPLEFT",self.title,"BOTTOMLEFT",0,0)
		scroll:SetPoint("TOPRIGHT",self.title,"BOTTOMRIGHT",0,0)
		scroll:SetPoint("BOTTOM",self.content,"BOTTOM",0,0)
	end
	---@function [parent=#GMCLayer]
	local function Constructor()
		local frame=CreateFrame("Frame")
		local title=frame:CreateFontString(nil, "BACKGROUND", "GameFontNormalHugeBlack")
		title:SetJustifyH("CENTER")
		title:SetJustifyV("CENTER")
		title:SetPoint("TOPLEFT")
		title:SetPoint("TOPRIGHT")
		title:SetHeight(0)
		title:SetWidth(0)
		addBackdrop(frame)
		local widget={childs={}}
		widget.title=title
		widget.type=Type
		widget.SetTitle=function(self,...) self.title:SetText(...) end
		widget.SetTitleColor=function(self,...) self.title:SetTextColor(...) end
		widget.SetFormattedTitle=function(self,...) self.title:SetFormattedText(...) end
		widget.SetTitleWidth=function(self,...) self.title:SetWidth(...) end
		widget.SetTitleHeight=function(self,...) self.title:SetHeight(...) end
		widget.frame=frame
		frame.obj=widget
		for k,v in pairs(m) do widget[k]=v end
		frame:SetScript("OnHide",function(self) self.obj:Fire('OnClose') end)
		--Container Support
		local content = CreateFrame("Frame",nil,frame)
		widget.content = content
		content.obj = self
		content:SetPoint("TOPLEFT",title,"BOTTOMLEFT")
		content:SetPoint("BOTTOMRIGHT")
		AceGUI:RegisterAsContainer(widget)
		return widget
	end
	AceGUI:RegisterWidgetType(Type,Constructor,Version)
end

local function createOHCMiniMissionButtonWidget()
	local Type="OHCMiniMissionButton"
	local Version=1
	local unique=0
	local m={} --#OHCMiniMissionButton
	function m:OnAcquire()
		local frame=self.frame
		frame.info=nil
		frame:SetAlpha(1)
		frame:SetScale(1.0)
		frame:Enable()
		for i=1,#self.scripts do
			frame:SetScript(self.scripts[i],nil)
		end
		for i=1,#frame.Rewards do
			frame.Rewards[i].Icon:SetDesaturated(false)
		end
		wipe(self.scripts)
		return
	end
	function m:Show()
		return self.frame:Show()
	end
	function m:SetHeight(h)
		return self.frame:SetHeight(h)
	end
	function m:Hide()
		self.frame:SetHeight(1)
		self.frame:SetAlpha(0)
		return self.frame:Disable()
	end
	function m:SetScript(name,method)
		tinsert(self.scripts,name)
		return self.frame:SetScript(name,method)
	end
	function m:SetScale(s)
		return self.frame:SetScale(s)
	end
	function m:Blacklist(blacklisted)
		local mb=self.frame
		if blacklisted then
--@debug@
			print("Blacklisting",mb:GetName())
--@end-debug@
			mb.Overlay:Show()
			mb.Overlay.Overlay:SetAlpha(1)
			for i,v in pairs(mb.gcPANEL.Party) do
				v.PortraitFrame.Portrait:SetDesaturated(true)
				v.PortraitFrame.PortraitRingQuality:Hide()
				v.PortraitFrame.LevelBorder:Hide()
			end
			for i,v in pairs(mb.Rewards) do
				v.Icon:SetDesaturated(true)
				v.Quantity:Hide()
			end
			return true
		else
			mb.Overlay:Hide()
			mb.Overlay.Overlay:SetAlpha(0.4)
			for i,v in pairs(mb.gcPANEL.Party) do
				v.PortraitFrame.Portrait:SetDesaturated(false)
				v.PortraitFrame.PortraitRingQuality:Show()
				v.PortraitFrame.LevelBorder:Show()
			end
			for i,v in pairs(mb.Rewards) do
				v.Icon:SetDesaturated(false)
				v.Quantity:Show()
			end
			return false
		end
	end
	function m:SetMission(mission,party,perc,source)
		local frame=self.frame
		frame.info=mission
		frame:EnableMouse(true)
		frame.party=party
		frame.Title:SetText(mission.name)
		local rc,message =pcall(GarrisonMissionButton_SetRewards,frame,mission.rewards)
		if #frame.Rewards > 0 then
			local Reward=frame.Rewards[1]
			Reward:ClearAllPoints()
			Reward:SetPoint("RIGHT")
		end
		if not rc then frame.Title:SetText(message) end
		 
		
	end
	---@function [parent=#OHCMiniMissionButton]
	local function Constructor()
		unique=unique+1
		local frame=CreateFrame("Button",Type..unique,nil,"OHCMissionButton")
		--frame.Title:SetFontObject("QuestFont_Shadow_Small")
		--frame.Summary:SetFontObject("QuestFont_Shadow_Small")
		frame:SetScript("OnEnter",function(self) self.obj:Fire("OnEnter") end)
		frame:SetScript("OnLeave",function(self)self.obj:Fire("OnLeave") end)
		frame:RegisterForClicks("LeftButtonUp","RightButtonUp")
		frame:SetScript("OnClick",function(self,button) print(button) return button=="RightButton" and self.obj:Fire("OnRightClick",self,button) or  self.obj:Fire("OnClick",self,button) end)
		frame.LocBG:SetPoint("LEFT")
		frame.MissionType:SetPoint("TOPLEFT",5,-2)
		--[[
		frame.members={}
		for i=1,3 do
			local f=CreateFrame("Button",nil,frame,"GarrisonCommanderMissionPageFollowerTemplateSmall" )
			frame.members[i]=f
			f:SetPoint("BOTTOMRIGHT",-65 -65 *i,5)
			f:SetScale(0.8)
		end
		--]]
		local widget={extra={}}
		setmetatable(widget,{__index=frame})
		widget.frame=frame
		widget.scripts={}
		frame.obj=widget
		for k,v in pairs(m) do widget[k]=v end
		-- Spinning while
		local extra=widget.extra
		extra.Spinner=CreateFrame("Frame",nil,frame,"LoadingSpinnerTemplate")
		-- Failed text string
		extra.Failure=frame:CreateFontString()
		-- Success text string
		extra.Success=frame:CreateFontString()
		extra.Failure:SetFontObject("GameFontRedLarge")
		extra.Success:SetFontObject("GameFontGreenLarge")
		extra.Failure:SetText(FAILED)
		extra.Success:SetText(SUCCESS)
		extra.Failure:Hide()
		extra.Success:Hide()
		extra.Success:SetPoint("BOTTOMLEFT")
		extra.Failure:SetPoint("BOTTOMLEFT")
		extra.Spinner:SetPoint("CENTER")
		return AceGUI:RegisterAsWidget(widget)
	end
	AceGUI:RegisterWidgetType(Type,Constructor,Version)
	
end
local function createOHCMenu()
	local Type = "OHCMenu"
	local Version = 1
	local m={} --#OHCMenu 
	
	
	function m:Hide()
		self.frame:Hide()
	end
	
	function m:Show()
		self.frame:Show()
	end
	
	function m:OnAcquire()
		self.frame:SetParent(UIParent)
		self.frame:SetFrameStrata("FULLSCREEN_DIALOG")
		self:Show()
	end
	
	function m:OnRelease()
		print("OnRelease called")
	end
	
	function m:OnWidthSet(width)
		local content = self.content
		local contentwidth = width - 34
		if contentwidth < 0 then
			contentwidth = 0
		end
		content:SetWidth(contentwidth)
		content.width = contentwidth
	end
	
	
	function m:OnHeightSet(height)
		local content = self.content
		local contentheight = height - 57
		if contentheight < 0 then
			contentheight = 0
		end
		content:SetHeight(contentheight)
		content.height = contentheight
	end
	
	local function Constructor()
		local frame = CreateFrame("Frame",nil,UIParent)
		local self = {}
		self.type = "Window"
		
		for k,v in pairs(m) do
			self[k]=v
		end
		
		self.frame = frame
		frame.obj = self
		frame:SetWidth(700)
		frame:SetHeight(500)
		frame:SetPoint("CENTER",UIParent,"CENTER",0,0)
		frame:EnableMouse()
		frame:SetMovable(true)
		frame:SetResizable(true)
		frame:SetFrameStrata("FULLSCREEN_DIALOG")
		frame:SetScript("OnHide",function(self) self.obj:Fire('OnClose') end)		
		frame:SetMinResize(240,240)
		frame:SetToplevel(true)
		
		local background=frame:CreateTexture(nil,"BACKGROUND")
		background:SetAtlas("ClassHall-CombatAlly")
		background:SetAllPoints(frame)
	
		--Container Support
		local content = CreateFrame("Frame",nil,frame)
		self.content = content
		content.obj = self
		content:SetPoint("TOPLEFT",frame,"TOPLEFT",12,-32)
		content:SetPoint("BOTTOMRIGHT",frame,"BOTTOMRIGHT",-12,13)
		
		AceGUI:RegisterAsContainer(self)
		return self	
	end
	
	AceGUI:RegisterWidgetType(Type,Constructor,Version)
end

function module:OnInitialized()
	--GMCLayer()
	createOHCGUIContainerWidget()
	createOHCMissionListWidget()
	createOHCMiniMissionButtonWidget()
	createOHCMenu()

end
