function widget:GetInfo()
	return {
		name		= "Top Bar",
		desc		= "Shows Resources, wind speed, commander counter, and various options.",
		author	= "Floris",
		date		= "Feb, 2017",
		license	= "GNU GPL, v2 or later",
		layer		= 0,
		enabled   = true, --enabled by default
		handler   = false, --can use widgetHandler:x()
	}
end

local height = 38
local borderPadding = 5
local showConversionSlider = true
local bladeSpeedMultiplier = 0.25

local armcomDefID = UnitDefNames.armcom.id
local corcomDefID = UnitDefNames.corcom.id

local bgcorner							= ":n:"..LUAUI_DIRNAME.."Images/bgcorner.png"
local barbg									= ":n:"..LUAUI_DIRNAME.."Images/resbar.dds"
local barGlowCenterTexture	= LUAUI_DIRNAME.."Images/barglow-center.dds"
local barGlowEdgeTexture		= LUAUI_DIRNAME.."Images/barglow-edge.dds"
local bladesTexture					= ":c:"..LUAUI_DIRNAME.."Images/blades.png"
local poleTexture						= LUAUI_DIRNAME.."Images/pole.png"
local comTexture						= LUAUI_DIRNAME.."Images/comIcon.png"

local vsx, vsy = gl.GetViewSizes()
local widgetScale = (0.60 + (vsx*vsy / 5000000))
local xPos = vsx*0.28
local currentWind = 0

local glTranslate				= gl.Translate
local glColor						= gl.Color
local glPushMatrix			= gl.PushMatrix
local glPopMatrix				= gl.PopMatrix
local glTexture					= gl.Texture
local glRect						= gl.Rect
local glTexRect					= gl.TexRect
local glText						= gl.Text
local glGetTextWidth		= gl.GetTextWidth
local glRotate					= gl.Rotate
local glCreateList			= gl.CreateList
local glCallList				= gl.CallList
local glDeleteList			= gl.DeleteList

local spGetSpectatingState = Spring.GetSpectatingState
local spGetTeamResources = Spring.GetTeamResources
local spGetMyTeamID = Spring.GetMyTeamID
local sformat = string.format
local spGetMouseState = Spring.GetMouseState

local spec = spGetSpectatingState()
local myAllyTeamID = Spring.GetMyAllyTeamID()
local myTeamID = Spring.GetMyTeamID()
local myPlayerID = Spring.GetMyPlayerID()
local isReplay = Spring.IsReplay()

local spWind		  			= Spring.GetWind
local minWind		  			= Game.windMin * 1.5 -- BA added extra wind income via gadget unit_windgenerators with an additional 50%
local maxWind		  			= Game.windMax * 1.5 -- BA added extra wind income via gadget unit_windgenerators with an additional 50%
local windRotation			= 0

local lastFrame = -1
local gameFrame = 0
local topbarArea = {}
local barContentArea = {}
local resbarArea = {'metal', 'energy'}
local shareIndicatorArea = {'metal', 'energy'}
local dlistResbar = {}
local energyconvArea = {}
local windArea = {}
local comsArea = {}
local rejoinArea = {}
local buttonsArea = {}

local allyComs				= 0
local enemyComs				= 0 -- if we are counting ourselves because we are a spec
local enemyComCount			= 0 -- if we are receiving a count from the gadget part (needs modoption on)
local prevEnemyComCount		= 0
local receiveCount			= (tostring(Spring.GetModOptions().mo_enemycomcount) == "1") or false

--------------------------------------------------------------------------------
-- Rejoin
--------------------------------------------------------------------------------
local serverFrameRate_G = 30 --//constant: assume server run at x1.0 gamespeed. 
local serverFrameNum1_G = nil --//variable: get the latest server's gameFrame from GameProgress() and do work with it.  
local oneSecondElapsed_G = 0 --//variable: a timer for 1 second, used in Update(). Update UI every 1 second.
local myLastFrameNum_G = 0 --//variable: used to calculate local game-frame rate.
local showRejoinUI = false --//variable:indicate whether UI is shown or hidden.
local averageLocalSpeed_G = {sumOfSpeed= 0, sumCounter= 0} --//variable: store the local-gameFrame speeds so that an average can be calculated. 
local defaultAverage_G = 30 --//constant: Initial/Default average is set at 30gfps (x1.0 gameSpeed)
local simpleMovingAverageLocalSpeed_G = {storage={},index = 1, runningAverage=defaultAverage_G} --//variable: for calculating rolling average. Initial/Default average is set at 30gfps (x1.0 gameSpeed)

--Variable for fixing GameProgress delay at rejoin------------------------------
local myTimestamp_G = 0 --//variable: store my own timestamp at GameStart
local serverFrameNum2_G = nil --//variable: the expected server-frame of current running game
local submittedTimestamp_G = {} --//variable: store all timestamp at GameStart submitted by original players (assuming we are rejoining)
local functionContainer_G = function(x) end --//variable object: store a function 
local gameProgressActive_G = false --//variable: signal whether GameProgress has been updated.

local serverFrameNum1_G = 0
local serverFrameNum2_G = 0
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------


function widget:ViewResize(n_vsx,n_vsy)
	vsx, vsy = gl.GetViewSizes()
	widgetScale = (0.60 + (vsx*vsy / 5000000))
	xPos = vsx*0.28
	init()
end

local function DrawRectRound(px,py,sx,sy,cs)
	gl.TexCoord(0.8,0.8)
	gl.Vertex(px+cs, py, 0)
	gl.Vertex(sx-cs, py, 0)
	gl.Vertex(sx-cs, sy, 0)
	gl.Vertex(px+cs, sy, 0)
	
	gl.Vertex(px, py+cs, 0)
	gl.Vertex(px+cs, py+cs, 0)
	gl.Vertex(px+cs, sy-cs, 0)
	gl.Vertex(px, sy-cs, 0)
	
	gl.Vertex(sx, py+cs, 0)
	gl.Vertex(sx-cs, py+cs, 0)
	gl.Vertex(sx-cs, sy-cs, 0)
	gl.Vertex(sx, sy-cs, 0)
	
	local offset = 0.05		-- texture offset, because else gaps could show
	local o = offset
	
	-- top left
	if py <= 0 or px <= 0 then o = 0.5 else o = offset end
	gl.TexCoord(o,o)
	gl.Vertex(px, py, 0)
	gl.TexCoord(o,1-o)
	gl.Vertex(px+cs, py, 0)
	gl.TexCoord(1-o,1-o)
	gl.Vertex(px+cs, py+cs, 0)
	gl.TexCoord(1-o,o)
	gl.Vertex(px, py+cs, 0)
	-- top right
	if py <= 0 or sx >= vsx then o = 0.5 else o = offset end
	gl.TexCoord(o,o)
	gl.Vertex(sx, py, 0)
	gl.TexCoord(o,1-o)
	gl.Vertex(sx-cs, py, 0)
	gl.TexCoord(1-o,1-o)
	gl.Vertex(sx-cs, py+cs, 0)
	gl.TexCoord(1-o,o)
	gl.Vertex(sx, py+cs, 0)
	-- bottom left
	if sy >= vsy or px <= 0 then o = 0.5 else o = offset end
	gl.TexCoord(o,o)
	gl.Vertex(px, sy, 0)
	gl.TexCoord(o,1-o)
	gl.Vertex(px+cs, sy, 0)
	gl.TexCoord(1-o,1-o)
	gl.Vertex(px+cs, sy-cs, 0)
	gl.TexCoord(1-o,o)
	gl.Vertex(px, sy-cs, 0)
	-- bottom right
	if sy >= vsy or sx >= vsx then o = 0.5 else o = offset end
	gl.TexCoord(o,o)
	gl.Vertex(sx, sy, 0)
	gl.TexCoord(o,1-o)
	gl.Vertex(sx-cs, sy, 0)
	gl.TexCoord(1-o,1-o)
	gl.Vertex(sx-cs, sy-cs, 0)
	gl.TexCoord(1-o,o)
	gl.Vertex(sx, sy-cs, 0)
end

function RectRound(px,py,sx,sy,cs)
	local px,py,sx,sy,cs = math.floor(px),math.floor(py),math.ceil(sx),math.ceil(sy),math.floor(cs)
	
	gl.Texture(bgcorner)
	gl.BeginEnd(GL.QUADS, DrawRectRound, px,py,sx,sy,cs)
	gl.Texture(false)
end


local function short(n,f)
	if (f == nil) then
		f = 0
	end
	if (n > 9999999) then
		return sformat("%."..f.."fm",n/1000000)
	elseif (n > 9999) then
		return sformat("%."..f.."fk",n/1000)
	else
		return sformat("%."..f.."f",n)
	end
end

local function updateRejoin()
	local area = rejoinArea
	local catchup = gameFrame / serverFrameNum1_G
	
	dlistRejoin = glCreateList( function()
	
		-- background
		glColor(0,0,0,0.7)
		RectRound(area[1], area[2], area[3], area[4], 5.5*widgetScale)
		local bgpadding = 3*widgetScale
		glColor(1,1,1,0.03)
		RectRound(area[1]+bgpadding, area[2]+bgpadding, area[3]-bgpadding, area[4], 5*widgetScale)
		
		if (WG['guishader_api'] ~= nil) then
			WG['guishader_api'].InsertRect(area[1], area[2], area[3], area[4], 'topbar_rejoin')
		end
		
		local barHeight = (height*widgetScale/10)
		local barHeighPadding = 6*widgetScale --((height/2) * widgetScale) - (barHeight/2)
		local barLeftPadding = 6 * widgetScale
		local barRightPadding = 6 * widgetScale
		local barArea = {area[1]+barLeftPadding, area[2]+barHeighPadding, area[3]-barRightPadding, area[2]+barHeight+barHeighPadding}
		local barWidth = barArea[3] - barArea[1]
		
		glColor(0.0,0.5,0,0.33)
		glTexture(barbg)
		glTexRect(barArea[1], barArea[2], barArea[3], barArea[4])

		-- Bar value
		glColor(0, 1, 0, 1)
		glTexture(barbg)
		glTexRect(barArea[1], barArea[2], barArea[1]+(catchup * barWidth), barArea[4])
		
		-- Bar value glow
		local glowSize = barHeight * 4
		glColor(0, 1, 0, 0.07)
		glTexture(barGlowCenterTexture)
		glTexRect(barArea[1], barArea[2] - glowSize, barArea[1]+(catchup * barWidth), barArea[4] + glowSize)
		glTexture(barGlowEdgeTexture)
		glTexRect(barArea[1]-(glowSize*2), barArea[2] - glowSize, barArea[1], barArea[4] + glowSize)
		glTexRect((barArea[1]+(catchup * barWidth))+(glowSize*2), barArea[2] - glowSize, barArea[1]+(catchup * barWidth), barArea[4] + glowSize)
		
		-- Text
		local fontsize = 12*widgetScale
		glText('\255\225\255\225Catching up', area[1]+((area[3]-area[1])/2), area[2]+barHeight*2+fontsize, fontsize, 'cor')
		
	end)
end

local function updateButtons()
	local area = buttonsArea
	
	dlistButtons = glCreateList( function()
	
		-- background
		glColor(0,0,0,0.7)
		RectRound(area[1], area[2], area[3], area[4], 5.5*widgetScale)
		local bgpadding = 3*widgetScale
		glColor(1,1,1,0.03)
		RectRound(area[1]+bgpadding, area[2]+bgpadding, area[3]-bgpadding, area[4], 5*widgetScale)
		
		if (WG['guishader_api'] ~= nil) then
			WG['guishader_api'].InsertRect(area[1], area[2], area[3], area[4], 'topbar_buttons')
		end
		
		
		local fontsize = 11.2*widgetScale
		if buttonsArea['buttons'] == nil then
			buttonsArea['buttons'] = {}
			
			local offset = 0
			local width = glGetTextWidth('   Commands  ') * fontsize
			buttonsArea['buttons']['commands'] = {area[1]+offset, area[2], area[1]+offset+width, area[4]}
			
			offset = offset+width
			width = glGetTextWidth('  Keybinds  ') * fontsize
			buttonsArea['buttons']['keybinds'] = {area[1]+offset, area[2], area[1]+offset+width, area[4]}
			
			offset = offset+width
			width = glGetTextWidth('  Changelog  ') * fontsize
			buttonsArea['buttons']['changelog'] = {area[1]+offset, area[2], area[1]+offset+width, area[4]}
			
			offset = offset+width
			width = glGetTextWidth('  Options  ') * fontsize
			buttonsArea['buttons']['options'] = {area[1]+offset, area[2], area[1]+offset+width, area[4]}
			
			offset = offset+width
			width = glGetTextWidth('  Quit  ') * fontsize
			buttonsArea['buttons']['quit'] = {area[1]+offset, area[2], area[3], area[4]}
		end
		
		local x,y = spGetMouseState()
		if buttonsArea['buttons'] ~= nil then
			buttonsAreaHovered = nil
			for button, pos in pairs(buttonsArea['buttons']) do
				if IsOnRect(x, y, pos[1], pos[2], pos[3], pos[4]) then
					buttonsAreaHovered = button
				end
			end
			if buttonsAreaHovered ~= nil then
				glColor(1,1,1,0.22)
				local margin = height*widgetScale / 11
				RectRound(buttonsArea['buttons'][buttonsAreaHovered][1]+margin, buttonsArea['buttons'][buttonsAreaHovered][2]+margin, buttonsArea['buttons'][buttonsAreaHovered][3]-margin, buttonsArea['buttons'][buttonsAreaHovered][4], 3.5*widgetScale)
			end
		end
		
		glText('\255\210\210\210   Commands    Keybinds    Changelog    Options    Quit  ', area[1], area[2]+((area[4]-area[2])/2)-(fontsize/5), fontsize, 'o')
		
	end)
end

local function updateComs()
	local area = comsArea
	
	dlistComs = glCreateList( function()
	
		-- background
		glColor(0,0,0,0.7)
		RectRound(area[1], area[2], area[3], area[4], 5.5*widgetScale)
		local bgpadding = 3*widgetScale
		glColor(1,1,1,0.03)
		RectRound(area[1]+bgpadding, area[2]+bgpadding, area[3]-bgpadding, area[4], 5*widgetScale)
		
		if (WG['guishader_api'] ~= nil) then
			WG['guishader_api'].InsertRect(area[1], area[2], area[3], area[4], 'topbar_coms')
		end
		
		-- Commander icon
		local sizeHalf = (height/2.75)*widgetScale
		if allyComs == 1 and (gameFrame % 12 < 6) then
			glColor(1,0.6,0,0.6)
		else
			glColor(1,1,1,0.3)
		end
		glTexture(comTexture)
		glTexRect(area[1]+((area[3]-area[1])/2)-sizeHalf, area[2]+((area[4]-area[2])/2)-sizeHalf, area[1]+((area[3]-area[1])/2)+sizeHalf, area[2]+((area[4]-area[2])/2)+sizeHalf)
		glTexture(false)
		
		-- Text
		if gameFrame > 0 then
			local fontsize = (height/2.85)*widgetScale
			local usedEnemyComs = enemyComs
			if not spec and receiveCount then
				usedEnemyComs = enemyComCount
			end
			glText('\255\255\000\000'..enemyComs, area[3]-(2.5*widgetScale), area[2]+(4.5*widgetScale), fontsize, 'or')
			
			fontSize = (height/2.15)*widgetScale
			glText("\255\000\255\000"..allyComs, area[1]+((area[3]-area[1])/2), area[2]+((area[4]-area[2])/2)-(fontSize/5), fontSize, 'oc') -- Wind speed text
		end
	end)
end

local function updateWind(currentWind)
	local area = windArea
		
	dlistWind = glCreateList( function()
		
		-- background
		glColor(0,0,0,0.7)
		RectRound(area[1], area[2], area[3], area[4], 5.5*widgetScale)
		local bgpadding = 3*widgetScale
		glColor(1,1,1,0.03)
		RectRound(area[1]+bgpadding, area[2]+bgpadding, area[3]-bgpadding, area[4], 5*widgetScale)
		
		if (WG['guishader_api'] ~= nil) then
			WG['guishader_api'].InsertRect(area[1], area[2], area[3], area[4], 'topbar_wind')
		end
		
		local xPos =  area[1] 
		local yPos =  area[2] + ((area[4] - area[2])/3.5)
		local oorx = 10*widgetScale
		local oory = 13*widgetScale
		
		glPushMatrix()
			glTranslate(xPos, yPos, 0)
			glTranslate(12*widgetScale, (height-(36*widgetScale))/2, 0) -- Spacing of icon
			glPushMatrix() -- Blades
				glTranslate(0, 9*widgetScale, 0)
				
				glTranslate(oorx, oory, 0)
				glRotate(windRotation, 0, 0, 1)
				glTranslate(-oorx, -oory, 0)
				
				glColor(1,1,1,0.3)
				glTexture(bladesTexture)
				glTexRect(0, 0, 27*widgetScale, 28*widgetScale)
				glTexture(false)
			glPopMatrix()
			
			local poleWidth = 6 * widgetScale
			local poleHeight = 14 * widgetScale
			x,y = 9*widgetScale, 2*widgetScale -- Pole
			glTexture(poleTexture)
			glTexRect(x, y, (7*widgetScale)+x, y+(18*widgetScale))
			glTexture(false)
		glPopMatrix()
		
		-- min and max wind
		local fontsize = (height/3.5)*widgetScale
		glText("\255\133\133\133"..minWind, area[3]-(2.5*widgetScale), area[4]-(4.5*widgetScale)-(fontsize/2), fontsize, 'or')
		glText("\255\133\133\133"..maxWind, area[3]-(2.5*widgetScale), area[2]+(4.5*widgetScale), fontsize, 'or')
		
		-- current wind
		if gameFrame > 0 then
			fontSize = (height/2.66)*widgetScale
			glText("\255\255\255\255"..currentWind, area[1]+((area[3]-area[1])/2), area[2]+((area[4]-area[2])/2)-(fontSize/5), fontSize, 'oc') -- Wind speed text
		end
	end)
end


local function updateResbar(res)
	local r = {spGetTeamResources(spGetMyTeamID(),res)} -- 1 = cur 2 = cap 3 = pull 4 = income 5 = expense 6 = share
	
	local area = resbarArea[res]
	
	if dlistResbar[res] ~= nil then
		glDeleteList(dlistResbar[res])
	end
	dlistResbar[res] = glCreateList( function()
		
		local barHeight = (height*widgetScale/10)
		local barHeighPadding = 6*widgetScale --((height/2) * widgetScale) - (barHeight/2)
		local barLeftPadding = 3 * widgetScale
		local barRightPadding = 6 * widgetScale
		local barArea = {area[1]+(height*widgetScale)+barLeftPadding, area[2]+barHeighPadding, area[3]-barRightPadding, area[2]+barHeight+barHeighPadding}
		local barWidth = barArea[3] - barArea[1]
		local shareSliderHeightAdd = barHeight / 4
		local shareSliderWidth = barHeight + shareSliderHeightAdd + shareSliderHeightAdd
		
		resbarArea[res].bar = barArea
		
		-- background
		glColor(0,0,0,0.7)
		RectRound(area[1], area[2], area[3], area[4], 5.5*widgetScale)
		local bgpadding = 3*widgetScale
		glColor(1,1,1,0.03)
		RectRound(area[1]+bgpadding, area[2]+bgpadding, area[3]-bgpadding, area[4], 5*widgetScale)
		
		if (WG['guishader_api'] ~= nil) then
			WG['guishader_api'].InsertRect(area[1], area[2], area[3], area[4], 'topbar_'..res)
		end
		
		-- Icon
		glColor(1,1,1,1)
		local iconPadding = 3*widgetScale
		if res == 'metal' then
			glTexture(LUAUI_DIRNAME.."Images/metal.png")
		else
			glTexture(LUAUI_DIRNAME.."Images/energy.png")
		end
		glTexRect(area[1]+iconPadding, area[2]+iconPadding, area[1]+(height*widgetScale)-iconPadding, area[4]-iconPadding)
		glTexture(false)
		
		-- Bar background
		if res == 'metal' then
			glColor(0.5,0.5,0.5,0.33)
		else
			glColor(0.5,0.5,0,0.33)
		end
		glTexture(barbg)
		glTexRect(barArea[1], barArea[2], barArea[3], barArea[4])

		-- Bar value
		if res == 'metal' then
			glColor(1, 1, 1, 1)
		else
			glColor(1, 1, 0, 1)
		end
		glTexture(barbg)
		glTexRect(barArea[1], barArea[2], barArea[1]+((r[1]/r[2]) * barWidth), barArea[4])
		
		
		-- Bar value glow
		local glowSize = barHeight * 4
		if res == 'metal' then
			glColor(1, 1, 1, 0.07)
		else
			glColor(1, 1, 0, 0.07)
		end
		glTexture(barGlowCenterTexture)
		glTexRect(barArea[1], barArea[2] - glowSize, barArea[1]+((r[1]/r[2]) * barWidth), barArea[4] + glowSize)
		glTexture(barGlowEdgeTexture)
		glTexRect(barArea[1]-(glowSize*2), barArea[2] - glowSize, barArea[1], barArea[4] + glowSize)
		glTexRect((barArea[1]+((r[1]/r[2]) * barWidth))+(glowSize*2), barArea[2] - glowSize, barArea[1]+((r[1]/r[2]) * barWidth), barArea[4] + glowSize)
		
		-- Share slider
		shareIndicatorArea[res] = {barArea[1]+(r[6] * barWidth)-(shareSliderWidth/2), barArea[2]-shareSliderHeightAdd, barArea[1]+(r[6] * barWidth)+(shareSliderWidth/2), barArea[4]+shareSliderHeightAdd}
		glTexture(barbg)
		glColor(0.8, 0, 0, 1)
		glTexRect(shareIndicatorArea[res][1], shareIndicatorArea[res][2], shareIndicatorArea[res][3], shareIndicatorArea[res][4])
		
		-- Metalmaker Conversion slider
		if showConversionSlider and res == 'energy' then 
			local convValue = Spring.GetTeamRulesParam(spGetMyTeamID(), 'mmLevel')
			conversionIndicatorArea = {barArea[1]+(convValue * barWidth)-(shareSliderWidth/2), barArea[2]-shareSliderHeightAdd, barArea[1]+(convValue * barWidth)+(shareSliderWidth/2), barArea[4]+shareSliderHeightAdd}
			glTexture(barbg)
			glColor(0.85, 0.85, 0.55, 1)
			glTexRect(conversionIndicatorArea[1], conversionIndicatorArea[2], conversionIndicatorArea[3], conversionIndicatorArea[4])
		end
		glTexture(false)
		
		-- Text: current
		glColor(1, 1, 1, 1)
		glText(short(r[1]), barArea[1]+barWidth/2, barArea[2]+barHeight*2, (height/2.75)*widgetScale, 'ocd')
		
		-- Text: storage
		glText("\255\133\133\133"..short(r[2]), barArea[3], barArea[2]+barHeight*2, (height/3.2)*widgetScale, 'ord')
		
		-- Text: pull
		glText("\255\200\100\100"..short(r[3]), barArea[1]+(50*widgetScale), barArea[2]+barHeight*2, (height/3.2)*widgetScale, 'od')
		
		-- Text: income
		glText("\255\100\200\100"..short(r[4]), barArea[1], barArea[2]+barHeight*2, (height/3.2)*widgetScale, 'od')
		
	end)
end

function init()
	
	if dlistBackground then
		glDeleteList(dlistBackground)
	end
	
	topbarArea = {xPos, vsy-(borderPadding*widgetScale)-(height*widgetScale), vsx, vsy}
	barContentArea = {xPos+(borderPadding*widgetScale), vsy-(height*widgetScale), vsx, vsy}
	
	local filledWidth = 0
	local totalWidth = barContentArea[3] - barContentArea[1]
	local areaSeparator = (borderPadding*widgetScale)
	
	dlistBackground = glCreateList( function()
		
		--glColor(0, 0, 0, 0.66)
		--RectRound(topbarArea[1], topbarArea[2], topbarArea[3], topbarArea[4], 6*widgetScale)
		--
		--glColor(1,1,1,0.025)
		--RectRound(barContentArea[1], barContentArea[2], barContentArea[3], barContentArea[4]+(10*widgetScale), 5*widgetScale)
		
		--if (WG['guishader_api'] ~= nil) then
		--	WG['guishader_api'].InsertRect(topbarArea[1]+((borderPadding*widgetScale)/2), topbarArea[2], topbarArea[3], topbarArea[4], 'topbar')
		--end
	end)
	
	-- metal
	local width = (totalWidth/4)
	resbarArea['metal'] = {barContentArea[1]+filledWidth, barContentArea[2], barContentArea[1]+filledWidth+width, barContentArea[4]}
	filledWidth = filledWidth + width + areaSeparator
	updateResbar('metal')
	
	--energy
	resbarArea['energy'] = {barContentArea[1]+filledWidth, barContentArea[2], barContentArea[1]+filledWidth+width, barContentArea[4]}
	filledWidth = filledWidth + width + areaSeparator
	updateResbar('energy')
	
	-- wind
	width = ((height*1.18)*widgetScale)
	windArea = {barContentArea[1]+filledWidth, barContentArea[2], barContentArea[1]+filledWidth+width, barContentArea[4]}
	filledWidth = filledWidth + width + areaSeparator
	
	-- coms
	comsArea = {barContentArea[1]+filledWidth, barContentArea[2], barContentArea[1]+filledWidth+width, barContentArea[4]}
	filledWidth = filledWidth + width + areaSeparator
	
	-- rejoin
	width = (totalWidth/4) / 3.3
	rejoinArea = {barContentArea[1]+filledWidth, barContentArea[2], barContentArea[1]+filledWidth+width, barContentArea[4]}
	filledWidth = filledWidth + width + areaSeparator
	
	-- buttons
	width = (totalWidth/4)
	buttonsArea = {barContentArea[3]-width, barContentArea[2], barContentArea[3], barContentArea[4]}
	filledWidth = filledWidth + width + areaSeparator
	
	WG['topbar'] = {}
	WG['topbar'].GetPosition = function()
		return {topbarArea[1], topbarArea[2], topbarArea[3], topbarArea[4], widgetScale}
	end
end

function widget:GameStart()
	checkStatus()
	countComs()
	
	-- code for rejoin
	local currentTime = os.date("!*t") --ie: clock on "gui_epicmenu.lua" (widget by CarRepairer), UTC & format: http://lua-users.org/wiki/OsLibraryTutorial
	local systemSecond = currentTime.hour*3600 + currentTime.min*60 + currentTime.sec
	local myTimestamp = systemSecond
	local timestampMsg = "rejnProg " .. systemSecond --currentTime --create a timestamp message
	Spring.SendLuaUIMsg(timestampMsg) --this message will remain in server's cache as a LUA message which rejoiner can intercept. Thus allowing the game to leave a clue at game start for latecomer.  The latecomer will compare the previous timestamp with present and deduce the catch-up time.
	myTimestamp_G = myTimestamp
end

function checkStatus()
	myAllyTeamID = Spring.GetMyAllyTeamID()
	myTeamID = Spring.GetMyTeamID()
	myPlayerID = Spring.GetMyPlayerID()
end

function widget:GameFrame(n)
	gameFrame = n
	functionContainer_G(n) --function that are able to remove itself. Reference: gui_take_reminder.lua (widget by EvilZerggin, modified by jK)
end

function widget:Update(dt)
	if (gameFrame ~= lastFrame) then
		lastFrame = gameFrame
		
		-- metal
		updateResbar('metal')
		
		-- energy
		updateResbar('energy')
		
		-- wind
    _, _, _, currentWind = spWind()
    currentWind = currentWind * 1.5 -- BA added extra wind income via gadget unit_windgenerators with an additional 50%
		updateWind(sformat('%.1f', currentWind))
		if minWind == maxWind then
      windRotation = windRotation + 1
    else
      windRotation = windRotation + (currentWind * bladeSpeedMultiplier)
    end
	end
    
 	-- coms
	if spec and myTeamID ~= spGetMyTeamID() then  -- check if the team that we are spectating changed
		checkStatus()
		countComs()
	end
	if not spec and receiveCount then	-- check if we have received a TeamRulesParam from the gadget part
		enemyComCount = Spring.GetTeamRulesParam(myTeamID, "enemyComCount")
		if enemyComCount ~= prevEnemyComCount then
			countChanged = true
			prevEnemyComCount = enemyComCount
		end
	end
	updateComs()
	
	-- rejoin
	if (gameFrame ~= lastFrame) then
		if showRejoinUI then
			oneSecondElapsed_G = oneSecondElapsed_G + dt
			if oneSecondElapsed_G >= 1 then --wait for 1 second period
				-----var localize-----
				local serverFrameNum1 = serverFrameNum1_G
				local serverFrameNum2 = serverFrameNum2_G
				local oneSecondElapsed = oneSecondElapsed_G
				local myLastFrameNum = myLastFrameNum_G
				local serverFrameRate = serverFrameRate_G
				local myGameFrame = gameFrame		
				local simpleMovingAverageLocalSpeed = simpleMovingAverageLocalSpeed_G
				-----localize
				
				local serverFrameNum = serverFrameNum1 or serverFrameNum2 --use FrameNum from GameProgress if available, else use FrameNum derived from LUA_msg.
				serverFrameNum = serverFrameNum + serverFrameRate*oneSecondElapsed -- estimate Server's frame number after each widget:Update() while waiting for GameProgress() to refresh with actual value.
				local frameDistanceToFinish = serverFrameNum-myGameFrame

				local myGameFrameRate = (myGameFrame - myLastFrameNum) / oneSecondElapsed
				--Method1: simple average
				--[[
				averageLocalSpeed_G.sumOfSpeed = averageLocalSpeed_G.sumOfSpeed + myGameFrameRate -- try to calculate the average of local gameFrame speed.
				averageLocalSpeed_G.sumCounter = averageLocalSpeed_G.sumCounter + 1
				myGameFrameRate = averageLocalSpeed_G.sumOfSpeed/averageLocalSpeed_G.sumCounter -- using the average to calculate the estimate for time of completion.
				--]]
				--Method2: simple moving average
				myGameFrameRate = SimpleMovingAverage(myGameFrameRate, simpleMovingAverageLocalSpeed) -- get our average frameRate
				
				local timeToComplete = frameDistanceToFinish/myGameFrameRate -- estimate the time to completion.
				local timeToComplete_string = "?/?"
				
				local minute, second = math.modf(timeToComplete/60) --second divide by 60sec-per-minute, then saperate result from its remainder
				second = 60*second --multiply remainder with 60sec-per-minute to get second back.
				timeToComplete_string = string.format ("Time Remaining: %d:%02d" , minute, second)
				
				oneSecondElapsed = 0
				myLastFrameNum = myGameFrame
				
				if serverFrameNum1 then serverFrameNum1 = serverFrameNum --update serverFrameNum1 if value from GameProgress() is used,
				else serverFrameNum2 = serverFrameNum end --update serverFrameNum2 if value from LuaRecvMsg() is used.
				-----return
				serverFrameNum1_G = serverFrameNum1
				serverFrameNum2_G = serverFrameNum2
				oneSecondElapsed_G = oneSecondElapsed
				myLastFrameNum_G = myLastFrameNum
				simpleMovingAverageLocalSpeed_G = simpleMovingAverageLocalSpeed
			end
			updateRejoin()
		end
	end
	
	-- buttons
	updateButtons()
end


function widget:DrawScreen()
	if dlistBackground then
		glCallList(dlistBackground)
	end
	if dlistResbar['metal'] then
		glCallList(dlistResbar['metal'])
	end
	if dlistResbar['energy'] then
		glCallList(dlistResbar['energy'])
	end
	if dlistWind then
		glCallList(dlistWind)
	end
	if dlistComs then
		glCallList(dlistComs)
	end
	if dlistRejoin and showRejoinUI then
		glCallList(dlistRejoin)
	end
	if dlistButtons then
		glCallList(dlistButtons)
	end
end


function IsOnRect(x, y, BLcornerX, BLcornerY,TRcornerX,TRcornerY)
	
	-- check if the mouse is in a rectangle
	return x >= BLcornerX and x <= TRcornerX
	                      and y >= BLcornerY
	                      and y <= TRcornerY
end

function widget:MouseMove(x, y)
	if draggingShareIndicator ~= nil and not spec then
		local shareValue =	(x - resbarArea[draggingShareIndicator]['bar'][1]) / (resbarArea[draggingShareIndicator]['bar'][3] - resbarArea[draggingShareIndicator]['bar'][1])
		if shareValue < 0 then shareValue = 0 end
		if shareValue > 1 then shareValue = 1 end
		Spring.SetShareLevel(draggingShareIndicator, shareValue)
	end
	if showConversionSlider and draggingConversionIndicator and not spec then
		local convValue = (x - resbarArea['energy']['bar'][1]) / (resbarArea['energy']['bar'][3] - resbarArea['energy']['bar'][1]) * 100
		if convValue < 12 then convValue = 12 end
		if convValue > 88 then convValue = 88 end
		Spring.SendLuaRulesMsg(sformat(string.char(137)..'%i', convValue))
	end
end

local function hideWindows()
	if (WG['options'] ~= nil) then
		WG['options'].toggle(false)
	end
	if (WG['changelog'] ~= nil) then
		WG['changelog'].toggle(false)
	end
	if (WG['keybinds'] ~= nil) then
		WG['keybinds'].toggle(false)
	end
	if (WG['commands'] ~= nil) then
		WG['commands'].toggle(false)
	end
end
local function applyButtonAction(button)
	if button == 'quit' then
		hideWindows()
		Spring.SendCommands("QuitMenu")
	elseif button == 'options' then
		hideWindows()
		if (WG['options'] ~= nil) then
			WG['options'].toggle()
		end
	elseif button == 'changelog' then
		hideWindows()
		if (WG['changelog'] ~= nil) then
			WG['changelog'].toggle()
		end
	elseif button == 'keybinds' then
		hideWindows()
		if (WG['keybinds'] ~= nil) then
			WG['keybinds'].toggle()
		end
	elseif button == 'commands' then
		hideWindows()
		if (WG['commands'] ~= nil) then
			WG['commands'].toggle()
		end
	end
end

function widget:MousePress(x, y, button)
	if button == 1 then
		if not spec then
			if IsOnRect(x, y, shareIndicatorArea['metal'][1], shareIndicatorArea['metal'][2], shareIndicatorArea['metal'][3], shareIndicatorArea['metal'][4]) then
				draggingShareIndicator = 'metal'
				return true
			end
			if IsOnRect(x, y, shareIndicatorArea['energy'][1], shareIndicatorArea['energy'][2], shareIndicatorArea['energy'][3], shareIndicatorArea['energy'][4]) then
				draggingShareIndicator = 'energy'
				return true
			end
			if showConversionSlider and IsOnRect(x, y, conversionIndicatorArea[1], conversionIndicatorArea[2], conversionIndicatorArea[3], conversionIndicatorArea[4]) then
				draggingConversionIndicator = true
				return true
			end
		end
	end
	if button == 1 then
		if buttonsArea['buttons'] ~= nil then
			for button, pos in pairs(buttonsArea['buttons']) do
				if IsOnRect(x, y, pos[1], pos[2], pos[3], pos[4]) then
					applyButtonAction(button)
					return true
				end
			end
		end
	end
end

function widget:MouseRelease(x, y, button)
	draggingShareIndicator = nil
	draggingConversionIndicator = nil
	
	if button == 1 then
		if buttonsArea['buttons'] ~= nil then	-- reapply again because else the other widgets disable when there is a click outside of their window
			for button, pos in pairs(buttonsArea['buttons']) do
				if IsOnRect(x, y, pos[1], pos[2], pos[3], pos[4]) then
					applyButtonAction(button)
				end
			end
		end
	end
end

function widget:PlayerChanged()
	spec = spGetSpectatingState()
	checkStatus()
	countComs()
end


function isCom(unitID,unitDefID)
	if not unitDefID and unitID then
		unitDefID =  Spring.GetUnitDefID(unitID)
	end
	if not unitDefID or not UnitDefs[unitDefID] or not UnitDefs[unitDefID].customParams then
		return false
	end
	return UnitDefs[unitDefID].customParams.iscommander ~= nil
end

function countComs()
	-- recount my own ally team coms
	allyComs = 0
	local myAllyTeamList = Spring.GetTeamList(myAllyTeamID)
	for _,teamID in ipairs(myAllyTeamList) do
		allyComs = allyComs + Spring.GetTeamUnitDefCount(teamID, armcomDefID) + Spring.GetTeamUnitDefCount(teamID, corcomDefID)
	end
	countChanged = true
	
	if spec then
		-- recount enemy ally team coms
		enemyComs = 0
		local allyTeamList = Spring.GetAllyTeamList()
		for _,allyTeamID in ipairs(allyTeamList) do
			if allyTeamID ~= myAllyTeamID then
				local teamList = Spring.GetTeamList(allyTeamID)
				for _,teamID in ipairs(teamList) do
					enemyComs = enemyComs + Spring.GetTeamUnitDefCount(teamID, armcomDefID) + Spring.GetTeamUnitDefCount(teamID, corcomDefID)
				end
			end
		end
	end
	
end

function widget:UnitCreated(unitID, unitDefID, unitTeam)
	if not isCom(unitID,unitDefID) then
		return
	end
	--record com created
	local _,_,_,_,_,allyTeamID = Spring.GetTeamInfo(unitTeam)
	if allyTeamID == myAllyTeamID then
		allyComs = allyComs + 1
	elseif spec then
		enemyComs = enemyComs + 1
	end
	countChanged = true
end

function widget:UnitDestroyed(unitID, unitDefID, unitTeam)
	if not isCom(unitID,unitDefID) then
		return
	end
	--record com died
	local _,_,_,_,_,allyTeamID = Spring.GetTeamInfo(unitTeam)
	if allyTeamID == myAllyTeamID then
		allyComs = allyComs - 1
	elseif spec then
		enemyComs = enemyComs - 1
	end
	countChanged = true
end



-- used for rejoin progress functionality
local function ActivateGUI_n_TTS (frameDistanceToFinish, ui_active, altThreshold)
	if frameDistanceToFinish >= (altThreshold or 120) then
		if not ui_active then
			ui_active = true
		end
	elseif frameDistanceToFinish < (altThreshold or 120) then
		if ui_active then
			ui_active = false
		end
	end
	return ui_active
end

-- used for rejoin progress functionality
function widget:GameProgress(serverFrameNum) --this function run 3rd. It read the official serverFrameNumber
	local ui_active = showRejoinUI

	local serverFrameNum1 = serverFrameNum
	local frameDistanceToFinish = serverFrameNum1-Spring.GetGameFrame()
	ui_active = ActivateGUI_n_TTS (frameDistanceToFinish, ui_active)
	
	serverFrameNum1_G = serverFrameNum1
	showRejoinUI = ui_active
	gameProgressActive_G = true
end

-- used for rejoin progress functionality
function widget:RecvLuaMsg(bigMsg, playerID) --this function run 2nd. It read the LUA timestamp
	
	if gameProgressActive_G or isReplay then --skip LUA message if gameProgress is already active OR game is a replay
		return false 
	end

	local myMsg = (playerID == myPlayerID)
	if (myMsg or spec) then
		if bigMsg:sub(1,9) == "rejnProg " then --check for identifier
			-----var localize-----
			local ui_active = showRejoinUI
			local submittedTimestamp = submittedTimestamp_G
			local myTimestamp = myTimestamp_G
			-----localize
			
			local timeMsg = bigMsg:sub(10) --saperate time-message from the identifier
			local systemSecond = tonumber(timeMsg)
			--Spring.Echo(systemSecond ..  " B")
			submittedTimestamp[#submittedTimestamp +1] = systemSecond --store all submitted timestamp from each players
			local sumSecond= 0
			for i=1, #submittedTimestamp,1 do
				sumSecond = sumSecond + submittedTimestamp[i]
			end
			--Spring.Echo(sumSecond ..  " C")
			local avgSecond = sumSecond/#submittedTimestamp
			--Spring.Echo(avgSecond ..  " D")
			local secondDiff = myTimestamp - avgSecond
			--Spring.Echo(secondDiff ..  " E")
			local frameDiff = secondDiff*30
			
			local serverFrameNum2 = frameDiff --this value represent the estimate difference in frame when everyone was submitting their timestamp at game start. Therefore the difference in frame will represent how much frame current player are ahead of us.
			ui_active = ActivateGUI_n_TTS (frameDiff, ui_active, 1800)
			
			-----return
			showRejoinUI = ui_active
			serverFrameNum2_G = serverFrameNum2
			submittedTimestamp_G = submittedTimestamp
		end
	end
end


-- used for rejoin progress functionality
local function RemoveLUARecvMsg(n)
	if n > 150 then
		isReplay = nil
		widgetHandler:RemoveCallIn("RecvLuaMsg") --remove unused method for increase efficiency after frame> timestampLimit (150frame or 5 second).
		functionContainer_G = function(x) end --replace this function with an empty function/method
	end 
end

-- used for rejoin progress functionality
function SimpleMovingAverage(myGameFrameRate, simpleMovingAverageLocalSpeed)
	--//remember current frameRate, and advance table index by 1
	local index = (simpleMovingAverageLocalSpeed.index) --retrieve current index.
	simpleMovingAverageLocalSpeed.storage[index] = myGameFrameRate --remember current frameRate at current index.
	simpleMovingAverageLocalSpeed.index = simpleMovingAverageLocalSpeed.index +1 --advance index by 1.
	--//wrap table index around. Create a circle
	local poolingSize = 10 --//number of sample. note: simpleMovingAverage() is executed every second, so the value represent an average spanning 10 second.
	if (simpleMovingAverageLocalSpeed.index == (poolingSize + 2)) then --when table out-of-bound:
		simpleMovingAverageLocalSpeed.index = 1 --wrap the table index around (create a circle of 150 + 1 (ie: poolingSize plus 1 space) entry).
	end
	--//update averages
	index = (simpleMovingAverageLocalSpeed.index) --retrieve an index advanced by 1.
	local oldAverage = (simpleMovingAverageLocalSpeed.storage[index] or defaultAverage_G) --retrieve old average or use initial/default average as old average.
	simpleMovingAverageLocalSpeed.runningAverage = simpleMovingAverageLocalSpeed.runningAverage + myGameFrameRate/poolingSize - oldAverage/poolingSize --calculate average: add new value, remove old value. Ref: http://en.wikipedia.org/wiki/Moving_average#Simple_moving_average
	local avgGameFrameRate = simpleMovingAverageLocalSpeed.runningAverage -- replace myGameFrameRate with its average value.

	return avgGameFrameRate, simpleMovingAverageLocalSpeed
end


function widget:GameProgress(serverFrameNum) --this function run 3rd. It read the official serverFrameNumber
	local ui_active = showRejoinUI

	local serverFrameNum1 = serverFrameNum
	local frameDistanceToFinish = serverFrameNum1-gameFrame
	ui_active = ActivateGUI_n_TTS (frameDistanceToFinish, ui_active)
	
	serverFrameNum1_G = serverFrameNum1
	showRejoinUI = ui_active
	gameProgressActive_G = true
end


function widget:Initialize()
	Spring.SendCommands("resbar 0")
	if Spring.GetGameFrame() > 0 then
		countComs()
	end
	init()
	
	-- used for rejoin progress functionality
	functionContainer_G = RemoveLUARecvMsg
	isReplay = Spring.IsReplay()
end

function widget:Shutdown()
	Spring.SendCommands("resbar 1")
	if dlistBackground ~= nil then
		glDeleteList(dlistBackground)
		glDeleteList(dlistResbar['metal'])
		glDeleteList(dlistResbar['energy'])
		glDeleteList(dlistWind)
		glDeleteList(dlistComs)
		glDeleteList(dlistButtons)
		glDeleteList(dlistRejoin)
	end
	if WG['guishader_api'] ~= nil then
		WG['guishader_api'].RemoveRect('topbar')
		WG['guishader_api'].RemoveRect('topbar_energy')
		WG['guishader_api'].RemoveRect('topbar_metal')
		WG['guishader_api'].RemoveRect('topbar_wind')
		WG['guishader_api'].RemoveRect('topbar_coms')
		WG['guishader_api'].RemoveRect('topbar_buttons')
		WG['guishader_api'].RemoveRect('topbar_rejoin')
	end
end