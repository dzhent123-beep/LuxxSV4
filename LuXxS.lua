--[[ luxxs v5.0 | NurHub | MM2 | FULL REWRITE ]]
-- Key system (cycling) | Legit farm | Skin changer | Profile avatar | Shade palette
-- Auto-Win | Spin | Teleport to player | Arrow tab nav | Color isolation fix
local TweenService=game:GetService("TweenService")
local UIS=game:GetService("UserInputService")
local Players=game:GetService("Players")
local RunService=game:GetService("RunService")
local Lighting=game:GetService("Lighting")
local HttpService=game:GetService("HttpService")
local VU=game:GetService("VirtualUser")
local LP=Players.LocalPlayer

local FOLDER="luxxs"
local hasFS=type(writefile)=="function" and type(readfile)=="function" and type(isfile)=="function"
local function ensureFolder() if type(makefolder)=="function" and type(isfolder)=="function" and not isfolder(FOLDER) then pcall(makefolder,FOLDER) end end

--========================================================
-- KEY SYSTEM (days + cycling)
--========================================================
local KEYS={
    {name="LUXXS",  days=5,  secs=5*86400},
    {name="DRHUB",  days=10, secs=10*86400},
    {name="NURHUB", days=3,  secs=3*86400},
}
local KEY_TABLE={}
for _,k in ipairs(KEYS) do KEY_TABLE[k.name]=k end

local function loadKeyState()
    if not hasFS then return {} end
    ensureFolder()
    local p=FOLDER.."/keys.json"
    if isfile(p) then
        local ok,data=pcall(function() return HttpService:JSONDecode(readfile(p)) end)
        if ok and type(data)=="table" then return data end
    end
    return {}
end
local function saveKeyState(st)
    if not hasFS then return end
    ensureFolder()
    pcall(function() writefile(FOLDER.."/keys.json",HttpService:JSONEncode(st)) end)
end
local keyState=loadKeyState()

local function checkKeyCycle()
    local now=os.time(); local anyActive=false; local anyExists=false
    for _,cfg in ipairs(KEYS) do
        local e=keyState[cfg.name]
        if e then
            anyExists=true
            if now < (e.activated+cfg.secs) then anyActive=true end
        end
    end
    if anyExists and not anyActive then
        keyState={}; saveKeyState(keyState); return true
    end
    return false
end
checkKeyCycle()

local function activateKey(name)
    local cfg=KEY_TABLE[name]; if not cfg then return false,"Unknown key" end
    local now=os.time(); local e=keyState[name]
    if e and now<(e.activated+cfg.secs) then
        local rem=(e.activated+cfg.secs)-now
        return false,string.format("Already active (%dd %dh left)",math.floor(rem/86400),math.floor((rem%86400)/3600))
    end
    keyState[name]={activated=now}; saveKeyState(keyState)
    return true,cfg.days.." days activated"
end
local function keyInfoLine(name)
    local cfg=KEY_TABLE[name]; if not cfg then return name..": —" end
    local e=keyState[name]
    if not e then return name..": NOT ACTIVATED ("..cfg.days.."d)" end
    local now=os.time(); local expires=e.activated+cfg.secs
    if now>=expires then return name..": EXPIRED" end
    local rem=expires-now
    return string.format("%s: %dd %dh left",name,math.floor(rem/86400),math.floor((rem%86400)/3600))
end
local function isValidKey(txt)
    local t=txt:gsub("^%s+",""):gsub("%s+$",""):upper()
    return KEY_TABLE[t] and t or nil
end

--========================================================
-- THEME
--========================================================
local ACCENTS={Lime=Color3.fromRGB(196,255,61),Coral=Color3.fromRGB(255,104,84),Ice=Color3.fromRGB(110,214,255),Violet=Color3.fromRGB(158,110,255),Gold=Color3.fromRGB(255,196,70),Rose=Color3.fromRGB(255,96,160)}
local ACCENT_NAMES={"Lime","Coral","Ice","Violet","Gold","Rose"}
local ACC_NAME="Lime"
if hasFS then pcall(function() local p=FOLDER.."/accent.txt"; if isfile(p) then local n=readfile(p); if ACCENTS[n] then ACC_NAME=n end end end) end
local ACC=ACCENTS[ACC_NAME]
local C={bg=Color3.fromRGB(11,11,14),panel=Color3.fromRGB(16,16,20),row=Color3.fromRGB(24,24,30),line=Color3.fromRGB(40,40,48),off=Color3.fromRGB(58,58,68),text=Color3.fromRGB(232,232,226),dim=Color3.fromRGB(122,122,136)}
local WHITE=Color3.fromRGB(255,255,255)
local AIM_RED=Color3.fromRGB(255,64,64)
local BODY_GRAY=Color3.fromRGB(196,196,206)
local F_HEAD,F_BODY,F_MONO,F_SEC=Enum.Font.Michroma,Enum.Font.SourceSansSemibold,Enum.Font.RobotoMono,Enum.Font.Oswald
local themed={}
local function T(o,p,fn) themed[#themed+1]={o,p,fn}; o[p]=fn and fn(ACC) or ACC end
local function setAccent(c) ACC=c; for _,t in ipairs(themed) do pcall(function() t[1][t[2]]=t[3] and t[3](ACC) or ACC end) end end
local function tween(o,ti,p,s,d) local tw=TweenService:Create(o,TweenInfo.new(ti,s or Enum.EasingStyle.Quint,d or Enum.EasingDirection.Out),p); tw:Play(); return tw end
local function corner(o,r) local c=Instance.new("UICorner"); c.CornerRadius=UDim.new(0,r); c.Parent=o; return c end
local function stroke(o,col,th,tr) local s=Instance.new("UIStroke"); s.Color=col; s.Thickness=th or 1; s.Transparency=tr or 0; s.ApplyStrokeMode=Enum.ApplyStrokeMode.Border; s.Parent=o; return s end
local function gradient(f,rot,seq) local g=Instance.new("UIGradient"); g.Rotation=rot or 0; if seq then g.Color=seq end; g.Parent=f; return g end

local connections={} local function track(c) connections[#connections+1]=c; return c end
local Flags,Setters,Defaults={},{},{} local function register(k,d,s) Flags[k]=d; Defaults[k]=d; Setters[k]=s end

--========================================================
-- GUI ROOT
--========================================================
local gui=Instance.new("ScreenGui"); gui.Name="luxxs"; gui.ResetOnSpawn=false; gui.ZIndexBehavior=Enum.ZIndexBehavior.Sibling; gui.IgnoreGuiInset=true
local okP,parent=pcall(function() return (gethui and gethui()) or game:GetService("CoreGui") end)
if not okP or not parent then parent=LP:WaitForChild("PlayerGui") end
for _,n in ipairs({"luxxs","luxxsKey","luxxsFPS"}) do local f=parent:FindFirstChild(n); if f then f:Destroy() end end
gui.Parent=parent

--========================================================
-- KEY SCREEN
--========================================================
do
    local sg=Instance.new("ScreenGui"); sg.Name="luxxsKey"; sg.ResetOnSpawn=false; sg.IgnoreGuiInset=true; sg.DisplayOrder=999; sg.Parent=parent
    local root=Instance.new("CanvasGroup"); root.Size=UDim2.new(1,0,1,0); root.BackgroundColor3=WHITE; root.BorderSizePixel=0; root.Parent=sg
    gradient(root,90,ColorSequence.new(Color3.fromRGB(22,22,28),Color3.fromRGB(8,8,10)))
    local word="LUXXS"; local LW=62; local total=LW*#word
    local holder=Instance.new("Frame"); holder.AnchorPoint=Vector2.new(0.5,0.5); holder.Position=UDim2.new(0.5,0,0.36,0); holder.Size=UDim2.new(0,total,0,84); holder.BackgroundTransparency=1; holder.ClipsDescendants=true; holder.Parent=root
    local letters={}
    for i=1,#word do
        local l=Instance.new("TextLabel"); l.BackgroundTransparency=1; l.Size=UDim2.new(0,LW,0,84); l.Position=UDim2.new(0,(i-1)*LW,0,98); l.Font=F_HEAD; l.TextSize=52; l.Text=word:sub(i,i); l.TextColor3=C.text; l.Parent=holder; letters[i]=l
    end
    local ul=Instance.new("Frame"); ul.AnchorPoint=Vector2.new(0.5,0); ul.Position=UDim2.new(0.5,0,0.36,52); ul.Size=UDim2.new(0,0,0,2); ul.BorderSizePixel=0; ul.Parent=root; T(ul,"BackgroundColor3")
    local sub=Instance.new("TextLabel"); sub.BackgroundTransparency=1; sub.AnchorPoint=Vector2.new(0.5,0); sub.Position=UDim2.new(0.5,0,0.36,68); sub.Size=UDim2.new(0,320,0,18); sub.Font=F_MONO; sub.TextSize=12; sub.TextColor3=C.dim; sub.Text="ENTER ACCESS KEY"; sub.TextTransparency=1; sub.Parent=root
    local kp=Instance.new("Frame"); kp.AnchorPoint=Vector2.new(0.5,0.5); kp.Position=UDim2.new(0.5,0,0.58,0); kp.Size=UDim2.new(0,340,0,44); kp.BackgroundColor3=C.row; kp.BorderSizePixel=0; kp.Visible=false; kp.Parent=root; stroke(kp,C.line,1,0)
    local ki=Instance.new("TextBox"); ki.BackgroundTransparency=1; ki.Position=UDim2.new(0,14,0,0); ki.Size=UDim2.new(1,-112,1,0); ki.Font=F_MONO; ki.TextSize=14; ki.TextColor3=C.text; ki.PlaceholderText="KEY (LUXXS / DRHUB / NURHUB)"; ki.PlaceholderColor3=C.dim; ki.Text=""; ki.TextXAlignment=Enum.TextXAlignment.Left; ki.ClearTextOnFocus=false; ki.Parent=kp
    local kb=Instance.new("TextButton"); kb.AnchorPoint=Vector2.new(1,0.5); kb.Position=UDim2.new(1,-6,0.5,0); kb.Size=UDim2.new(0,92,0,32); kb.BorderSizePixel=0; kb.Text="ENTER"; kb.Font=F_MONO; kb.TextSize=13; kb.TextColor3=C.bg; kb.AutoButtonColor=false; kb.Parent=kp; T(kb,"BackgroundColor3")
    local st=Instance.new("TextLabel"); st.BackgroundTransparency=1; st.AnchorPoint=Vector2.new(0.5,0); st.Position=UDim2.new(0.5,0,0.58,36); st.Size=UDim2.new(0,340,0,18); st.Font=F_MONO; st.TextSize=12; st.TextColor3=C.dim; st.Text=""; st.Parent=root
    -- INFO panel listing keys
    local info=Instance.new("TextLabel"); info.BackgroundTransparency=1; info.AnchorPoint=Vector2.new(0.5,0); info.Position=UDim2.new(0.5,0,0.68,0); info.Size=UDim2.new(0,400,0,60); info.Font=F_MONO; info.TextSize=11; info.TextColor3=C.dim; info.Text=""; info.Parent=root

    task.spawn(function()
        task.wait(0.2)
        for i,l in ipairs(letters) do tween(l,0.7,{Position=UDim2.new(0,(i-1)*LW,0,0)}); task.wait(0.09) end
        task.wait(0.3); tween(ul,0.6,{Size=UDim2.new(0,total,0,2)})
        task.wait(0.3); tween(sub,0.4,{TextTransparency=0})
        kp.Visible=true; kp.Size=UDim2.new(0,0,0,44); tween(kp,0.5,{Size=UDim2.new(0,340,0,44)})
        pcall(function() ki:CaptureFocus() end)
        local function refreshInfo()
            local lines={}
            for _,cfg in ipairs(KEYS) do lines[#lines+1]=keyInfoLine(cfg.name) end
            info.Text=table.concat(lines,"\n")
        end
        refreshInfo()
        sg:GetPropertyChangedSignal("Parent"):Wait()
    end)

    local done=false
    local function tryKey()
        if done then return end
        local keyName=isValidKey(ki.Text)
        if not keyName then
            st.Text="INVALID KEY"; st.TextColor3=Color3.fromRGB(255,84,84)
            local op=kp.Position
            for _,dx in ipairs({-10,10,-6,6,0}) do tween(kp,0.05,{Position=UDim2.new(op.X.Scale,op.X.Offset+dx,op.Y.Scale,op.Y.Offset)}); task.wait(0.055) end
            ki.Text=""; task.wait(0.6); st.Text=""; return
        end
        local ok,msg=activateKey(keyName)
        if ok then
            done=true; st.Text="ACCESS GRANTED // "..msg; T(st,"TextColor3"); ki.TextEditable=false
            for _,l in ipairs(letters) do T(l,"TextColor3") end
            task.wait(0.8); tween(root,0.6,{GroupTransparency=1}); task.wait(0.65); sg:Destroy()
        else
            st.Text=msg; st.TextColor3=Color3.fromRGB(255,160,70)
            task.wait(1.2); st.Text=""
            -- if all ended -> cycle and tell
            if checkKeyCycle() then st.Text="ALL KEYS CYCLED — re-enter any key"; task.wait(1.5); st.Text="" end
        end
    end
    kb.MouseButton1Click:Connect(tryKey)
    ki.FocusLost:Connect(function(enter) if enter then tryKey() end end)
    repeat task.wait(0.1) until done
end

--========================================================
-- notify + draggable
--========================================================
local function notify(text)
    local f=Instance.new("Frame"); f.AnchorPoint=Vector2.new(1,1); f.Size=UDim2.new(0,260,0,34); f.Position=UDim2.new(1,280,1,-20); f.BackgroundColor3=C.panel; f.BorderSizePixel=0; f.ZIndex=20; f.Parent=gui; stroke(f,C.line,1,0)
    local bar=Instance.new("Frame"); bar.Size=UDim2.new(0,3,1,0); bar.BorderSizePixel=0; bar.BackgroundColor3=ACC; bar.ZIndex=21; bar.Parent=f
    local l=Instance.new("TextLabel"); l.BackgroundTransparency=1; l.Size=UDim2.new(1,-20,1,0); l.Position=UDim2.new(0,14,0,0); l.Font=F_MONO; l.TextSize=12; l.TextColor3=C.text; l.TextXAlignment=Enum.TextXAlignment.Left; l.Text=text; l.ZIndex=21; l.Parent=f
    tween(f,0.4,{Position=UDim2.new(1,-20,1,-20)})
    task.delay(2.6,function() tween(f,0.3,{Position=UDim2.new(1,280,1,-20)},Enum.EasingStyle.Quint,Enum.EasingDirection.In); task.delay(0.35,function() f:Destroy() end) end)
end
local function makeDraggable(handle,target,onClick)
    local dragging,startPos,startInput,moved=false,nil,nil,false
    handle.InputBegan:Connect(function(input)
        if input.UserInputType==Enum.UserInputType.MouseButton1 or input.UserInputType==Enum.UserInputType.Touch then
            dragging=true; moved=false; startInput=input.Position; startPos=target.Position
            input.Changed:Connect(function() if input.UserInputState==Enum.UserInputState.End then dragging=false; if not moved and onClick then onClick() end end end)
        end
    end)
    track(UIS.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType==Enum.UserInputType.MouseMovement or input.UserInputType==Enum.UserInputType.Touch) then
            local delta=input.Position-startInput
            if delta.Magnitude>5 then moved=true end
            if moved then tween(target,0.08,{Position=UDim2.new(startPos.X.Scale,startPos.X.Offset+delta.X,startPos.Y.Scale,startPos.Y.Offset+delta.Y)},Enum.EasingStyle.Linear) end
        end
    end))
end

--========================================================
-- COSMETICS
--========================================================
local Cos={}
local function destroyCos(n) if Cos[n] then for _,o in ipairs(Cos[n].objs) do pcall(function() o:Destroy() end) end Cos[n]=nil end end
local function newPart(sz,p) local pt=Instance.new("Part"); pt.Size=sz; pt.CanCollide=false; pt.CanQuery=false; pt.CanTouch=false; pt.Massless=true; pt.Anchored=false; pt.Parent=p; return pt end

local function buildWings()
    destroyCos("wings")
    local char=LP.Character; local torso=char and (char:FindFirstChild("UpperTorso") or char:FindFirstChild("Torso")); if not torso then return end
    local model=Instance.new("Model"); model.Name="luxxsWings"; local feathers={}
    for _,side in ipairs({-1,1}) do for i=1,6 do
        local len=4.2-i*0.35
        local p=newPart(Vector3.new(len,0.5,0.08),model); p.Material=Enum.Material.Neon
        local w=Instance.new("Weld"); w.Part0=torso; w.Part1=p; w.Parent=p
        feathers[#feathers+1]={part=p,weld=w,side=side,i=i,len=len}
    end end
    model.Parent=char; Cos.wings={objs={model},model=model,feathers=feathers}
end
local function buildHat()
    destroyCos("hat")
    local char=LP.Character; local head=char and char:FindFirstChild("Head"); if not head then return end
    local model=Instance.new("Model"); model.Name="luxxsHat"; local slices={}
    for i=1,10 do
        local r=2.0*(1-(i-1)/10)+0.1
        local p=newPart(Vector3.new(0.2,r*2,r*2),model); p.Shape=Enum.PartType.Cylinder; p.Material=Enum.Material.SmoothPlastic
        local w=Instance.new("Weld"); w.Part0=head; w.Part1=p; w.C0=CFrame.new(0,0.55+(i-1)*0.19,0)*CFrame.Angles(0,0,math.pi/2); w.Parent=p; slices[i]=p
    end
    model.Parent=char; Cos.hat={objs={model},model=model,slices=slices}
end
local function buildTrail()
    destroyCos("trail")
    local char=LP.Character; local hrp=char and char:FindFirstChild("HumanoidRootPart"); if not hrp then return end
    local a0=Instance.new("Attachment"); a0.Name="luxxsA0"; a0.Parent=hrp
    local a1=Instance.new("Attachment"); a1.Name="luxxsA1"; a1.Parent=hrp
    local tr=Instance.new("Trail"); tr.Attachment0=a0; tr.Attachment1=a1; tr.LightEmission=1; tr.FaceCamera=true
    tr.Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,0.1),NumberSequenceKeypoint.new(1,1)}); tr.Parent=hrp
    Cos.trail={objs={a0,a1,tr},a0=a0,a1=a1,trail=tr}
end

-- Spin
local Spin={Enabled=false,Speed=200,Conn=nil}
local function startSpin()
    if Spin.Conn then Spin.Conn:Disconnect(); Spin.Conn=nil end
    Spin.Conn=RunService.Heartbeat:Connect(function(dt)
        if not Spin.Enabled then return end
        local char=LP.Character; local hrp=char and char:FindFirstChild("HumanoidRootPart"); if not hrp then return end
        hrp.CFrame=hrp.CFrame*CFrame.Angles(0,math.rad(Spin.Speed)*dt,0)
    end)
end
local function stopSpin() if Spin.Conn then Spin.Conn:Disconnect(); Spin.Conn=nil end end

track(RunService.Heartbeat:Connect(function()
    local t=os.clock()
    local w=Cos.wings
    if w and w.model.Parent then
        local flap=math.sin(t*(Flags["Visuals/Wing Speed"] or 3))*0.2
        for _,f in ipairs(w.feathers) do
            local a=math.rad(10+f.i*12)+flap*(0.5+f.i*0.12)
            local theta=(f.side==1) and a or (math.pi-a)
            f.weld.C0=CFrame.new(f.side*0.5,0.45,0.6)*CFrame.Angles(0,f.side*-0.35,0)*CFrame.Angles(0,0,theta)*CFrame.new(f.len/2,0,0)
            f.part.Color=PALETTE_FN and PALETTE_FN(Flags["Visuals/Wing Color"],t,f.i*0.05) or Color3.new(1,1,1)
        end
    end
    local h=Cos.hat
    if h and h.model.Parent then for i,s in ipairs(h.slices) do s.Color=PALETTE_FN and PALETTE_FN(Flags["Visuals/Hat Color"],t,i*0.07) or Color3.new(1,1,1) end end
    local tr=Cos.trail
    if tr and tr.trail.Parent then
        local width=(Flags["Visuals/Trail Width"] or 4)*0.4
        tr.a0.Position=Vector3.new(0,width/2,0); tr.a1.Position=Vector3.new(0,-width/2,0)
        tr.trail.Lifetime=math.max(0.1,(Flags["Visuals/Trail Length"] or 10)/10)
        if SEQ_FN then tr.trail.Color=SEQ_FN(Flags["Visuals/Trail Color"],t) end
    end
end))

track(LP.CharacterAdded:Connect(function(c)
    c:WaitForChild("HumanoidRootPart",10); task.wait(0.3)
    if Flags["Visuals/Wings"] then buildWings() end
    if Flags["Visuals/Chinese Hat"] then buildHat() end
    if Flags["Visuals/Trail"] then buildTrail() end
    if Spin.Enabled then startSpin() end
end))

--========================================================
-- SHADERS
--========================================================
local Shader={}
local PRESETS={
    ["Cinematic"]={b=0.02,c=0.25,s=-0.1,tint=Color3.fromRGB(255,238,220),bloom=0.5,bsize=28,bth=1,rays=0.08,dens=0.3,haze=1.2,acol=Color3.fromRGB(190,190,205)},
    ["Neon Night"]={b=-0.03,c=0.3,s=0.5,tint=Color3.fromRGB(215,190,255),bloom=1.3,bsize=42,bth=0.75,rays=0,dens=0.35,haze=1.5,acol=Color3.fromRGB(110,70,200)},
    ["Sunset"]={b=0.03,c=0.15,s=0.3,tint=Color3.fromRGB(255,205,160),bloom=0.6,bsize=30,bth=0.9,rays=0.25,dens=0.3,haze=1.8,acol=Color3.fromRGB(255,170,120)},
    ["Vivid"]={b=0.02,c=0.2,s=0.7,tint=Color3.fromRGB(255,255,255),bloom=0.4,bsize=24,bth=1,rays=0.1,dens=0.2,haze=0.5,acol=Color3.fromRGB(200,215,235)},
    ["Noir"]={b=-0.02,c=0.4,s=-1,tint=Color3.fromRGB(235,235,245),bloom=0.3,bsize=20,bth=1,rays=0,dens=0.35,haze=2.2,acol=Color3.fromRGB(160,160,170)},
    ["Dream"]={b=0.05,c=-0.05,s=0.3,tint=Color3.fromRGB(255,210,255),bloom=1,bsize=50,bth=0.7,rays=0.15,dens=0.4,haze=1,acol=Color3.fromRGB(255,190,240)},
}
local PRESET_NAMES={"Off","Cinematic","Neon Night","Sunset","Vivid","Noir","Dream"}
local NEUTRAL={b=0,c=0,s=0,tint=Color3.fromRGB(255,255,255),bloom=0,bsize=24,bth=1,rays=0}
local function ensureShader()
    if Shader.cc then return end
    local function mk(c) local i=Instance.new(c); i.Name="luxxs_"..c; i.Parent=Lighting; return i end
    Shader.cc=mk("ColorCorrectionEffect"); Shader.bloom=mk("BloomEffect"); Shader.rays=mk("SunRaysEffect")
    local atm=Lighting:FindFirstChildOfClass("Atmosphere")
    if atm then Shader.atm=atm; Shader.atmOrig={Density=atm.Density,Haze=atm.Haze,Color=atm.Color}
    else Shader.atm=mk("Atmosphere"); Shader.atm.Density=0; Shader.atmCreated=true end
end
local function disableShader(full)
    if not Shader.cc then return end
    Shader.cc.Enabled=false; Shader.bloom.Enabled=false; Shader.rays.Enabled=false
    if Shader.atmOrig then pcall(function() tween(Shader.atm,0.5,Shader.atmOrig) end) elseif Shader.atm then pcall(function() Shader.atm.Density=0 end) end
    if full then for _,k in ipairs({"cc","bloom","rays"}) do pcall(function() Shader[k]:Destroy() end) end; if Shader.atmCreated then pcall(function() Shader.atm:Destroy() end) end; Shader={} end
end
local function refreshShader(time)
    time=time or 0.9
    local preset=PRESETS[Flags["Shaders/Preset"] or "Off"]
    local ob=(Flags["Shaders/Brightness"] or 0)/100; local oc=(Flags["Shaders/Contrast"] or 0)/100
    local os_=(Flags["Shaders/Saturation"] or 0)/100; local obl=(Flags["Shaders/Bloom"] or 0)/50
    if not preset and ob==0 and oc==0 and os_==0 and obl==0 then disableShader(false); return end
    ensureShader(); local p=preset or NEUTRAL
    Shader.cc.Enabled=true; Shader.bloom.Enabled=true; Shader.rays.Enabled=true
    tween(Shader.cc,time,{Brightness=p.b+ob,Contrast=p.c+oc,Saturation=p.s+os_,TintColor=p.tint})
    tween(Shader.bloom,time,{Intensity=p.bloom+obl,Size=p.bsize,Threshold=p.bth})
    tween(Shader.rays,time,{Intensity=p.rays})
    if preset then tween(Shader.atm,time,{Density=preset.dens,Haze=preset.haze,Color=preset.acol})
    elseif Shader.atmOrig then tween(Shader.atm,time,Shader.atmOrig) else tween(Shader.atm,time,{Density=0}) end
end

--========================================================
-- COLOR PALETTE (with shades) — color picker isolation
--========================================================
local BASE_COLORS={
    Lime=Color3.fromRGB(196,255,61),
    Coral=Color3.fromRGB(255,104,84),
    Ice=Color3.fromRGB(110,214,255),
    Violet=Color3.fromRGB(158,110,255),
    Gold=Color3.fromRGB(255,196,70),
    Rose=Color3.fromRGB(255,96,160),
    Red=Color3.fromRGB(255,60,60),
    Green=Color3.fromRGB(70,230,110),
    Blue=Color3.fromRGB(70,110,255),
    Pink=Color3.fromRGB(255,110,200),
    White=Color3.fromRGB(255,255,255),
    Rainbow="Rainbow",
}
local SHADES={
    {name="Dark",   mul=0.55},
    {name="Normal", mul=1.0},
    {name="Light",  mul=1.35},
    {name="Neon",   mul=1.7},
    {name="Pastel", mul=1.2, sat=0.5},
}
local COLOR_NAMES={"Rainbow","Lime","Coral","Ice","Violet","Gold","Red","Green","Blue","Pink","White"}
local WING_COLORS={"White","Gold","Rainbow","Ice","Violet","Pink","Coral"}
local SHADE_NAMES={}
for _,s in ipairs(SHADES) do SHADE_NAMES[#SHADE_NAMES+1]=s.name end

local function shadeColor(name,shadeName,t,off)
    if name=="Rainbow" then return Color3.fromHSV((((t or 0)*0.2)+(off or 0))%1,0.85,1) end
    local base=BASE_COLORS[name] or ACC
    for _,s in ipairs(SHADES) do
        if s.name==shadeName then
            local h,sat,v=Color3.toHSV(base)
            if s.sat then sat=s.sat end
            return Color3.fromHSV(h,sat,math.clamp(v*s.mul,0,1))
        end
    end
    return base
end
local function shadeSequence(name,shadeName,t)
    if name=="Rainbow" then
        local kp={} for k=0,6 do kp[#kp+1]=ColorSequenceKeypoint.new(k/6,shadeColor(name,shadeName,t,-k/6*0.8)) end
        return ColorSequence.new(kp)
    end
    return ColorSequence.new(shadeColor(name,shadeName,t,0))
end
PALETTE_FN=function(name,t,off) return shadeColor(name,Flags["Settings/Shade"] or "Normal",t,off) end
SEQ_FN=function(name,t) return shadeSequence(name,Flags["Settings/Shade"] or "Normal",t) end

--========================================================
-- MAIN WINDOW (with arrow navigation)
--========================================================
local W,H=960,500
local main=Instance.new("CanvasGroup")
main.AnchorPoint=Vector2.new(0.5,0.5); main.Position=UDim2.new(0.5,0,0.5,0); main.Size=UDim2.new(0,W,0,H)
main.BackgroundColor3=C.bg; main.BorderSizePixel=0; main.GroupTransparency=1; main.Visible=false; main.Parent=gui
stroke(main,C.line,1,0)
local scale=Instance.new("UIScale"); scale.Scale=0.9; scale.Parent=main

-- top bar
local top=Instance.new("Frame"); top.Size=UDim2.new(1,0,0,44); top.BackgroundColor3=C.panel; top.BorderSizePixel=0; top.Parent=main
local topLine=Instance.new("Frame"); topLine.Position=UDim2.new(0,0,1,-1); topLine.Size=UDim2.new(1,0,0,1); topLine.BackgroundColor3=C.line; topLine.BorderSizePixel=0; topLine.Parent=top
local title=Instance.new("TextLabel"); title.BackgroundTransparency=1; title.Position=UDim2.new(0,18,0,0); title.Size=UDim2.new(0,120,1,0); title.Font=F_HEAD; title.TextSize=15; title.TextXAlignment=Enum.TextXAlignment.Left; title.TextColor3=C.text; title.Text="LUXXS"; title.Parent=top
local sub=Instance.new("TextLabel"); sub.BackgroundTransparency=1; sub.Position=UDim2.new(0,110,0,2); sub.Size=UDim2.new(0,200,1,0); sub.Font=F_MONO; sub.TextSize=11; sub.TextXAlignment=Enum.TextXAlignment.Left; sub.TextColor3=C.dim; sub.Text="by NurHub // v5"; sub.Parent=top
local ver=Instance.new("TextLabel"); ver.BackgroundTransparency=1; ver.AnchorPoint=Vector2.new(1,0); ver.Position=UDim2.new(1,-52,0,0); ver.Size=UDim2.new(0,220,1,0); ver.Font=F_MONO; ver.TextSize=11; ver.TextXAlignment=Enum.TextXAlignment.Right; ver.TextColor3=C.dim; ver.Text="MM2 // MM2"; ver.Parent=top
local closeBtn=Instance.new("TextButton"); closeBtn.AnchorPoint=Vector2.new(1,0.5); closeBtn.Position=UDim2.new(1,-10,0.5,0); closeBtn.Size=UDim2.new(0,28,0,28); closeBtn.BackgroundColor3=C.row; closeBtn.BorderSizePixel=0; closeBtn.Text="X"; closeBtn.Font=F_MONO; closeBtn.TextSize=13; closeBtn.TextColor3=C.dim; closeBtn.AutoButtonColor=false; closeBtn.Parent=top

-- side
local side=Instance.new("Frame"); side.Position=UDim2.new(0,0,0,44); side.Size=UDim2.new(0,150,0,H-44-24); side.BackgroundColor3=C.panel; side.BorderSizePixel=0; side.Parent=main
local sideLine=Instance.new("Frame"); sideLine.Position=UDim2.new(1,-1,0,0); sideLine.Size=UDim2.new(0,1,1,0); sideLine.BackgroundColor3=C.line; sideLine.BorderSizePixel=0; sideLine.Parent=side
local sideList=Instance.new("Frame"); sideList.BackgroundTransparency=1; sideList.Position=UDim2.new(0,0,0,12); sideList.Size=UDim2.new(1,-1,1,-12); sideList.Parent=side
local indicator=Instance.new("Frame"); indicator.Size=UDim2.new(0,2,0,22); indicator.Position=UDim2.new(0,0,0,18); indicator.BorderSizePixel=0; indicator.ZIndex=3; indicator.Parent=side; T(indicator,"BackgroundColor3")

-- footer
local foot=Instance.new("Frame"); foot.Position=UDim2.new(0,0,1,-24); foot.Size=UDim2.new(1,0,0,24); foot.BackgroundColor3=C.panel; foot.BorderSizePixel=0; foot.Parent=main
local footLine=Instance.new("Frame"); footLine.Size=UDim2.new(1,0,0,1); footLine.BackgroundColor3=C.line; footLine.BorderSizePixel=0; footLine.Parent=foot
local footL=Instance.new("TextLabel"); footL.BackgroundTransparency=1; footL.Position=UDim2.new(0,14,0,0); footL.Size=UDim2.new(0.5,0,1,0); footL.Font=F_MONO; footL.TextSize=10; footL.TextXAlignment=Enum.TextXAlignment.Left; footL.TextColor3=C.dim; footL.Text="RIGHTSHIFT = TOGGLE"; footL.Parent=foot
local footR=Instance.new("TextLabel"); footR.BackgroundTransparency=1; footR.AnchorPoint=Vector2.new(1,0); footR.Position=UDim2.new(1,-14,0,0); footR.Size=UDim2.new(0.5,0,1,0); footR.Font=F_MONO; footR.TextSize=10; footR.TextXAlignment=Enum.TextXAlignment.Right; footR.TextColor3=C.dim; footR.Text="ROLE  INNOCENT"; footR.Parent=foot

local pages=Instance.new("Frame"); pages.BackgroundTransparency=1; pages.Position=UDim2.new(0,150,0,54); pages.Size=UDim2.new(0,W-150-260,0,H-24-54-10); pages.ClipsDescendants=true; pages.Parent=main

-- arrow nav (bottom of side)
local navBar=Instance.new("Frame"); navBar.Position=UDim2.new(0,0,1,-70); navBar.Size=UDim2.new(1,0,0,46); navBar.BackgroundTransparency=1; navBar.Parent=side
local prevBtn=Instance.new("TextButton"); prevBtn.Position=UDim2.new(0,10,0,10); prevBtn.Size=UDim2.new(0,60,0,28); prevBtn.BackgroundColor3=C.row; prevBtn.BorderSizePixel=0; prevBtn.Text="◀ PREV"; prevBtn.Font=F_MONO; prevBtn.TextSize=11; prevBtn.TextColor3=C.text; prevBtn.AutoButtonColor=false; prevBtn.Parent=navBar
local nextBtn=Instance.new("TextButton"); nextBtn.AnchorPoint=Vector2.new(1,0); nextBtn.Position=UDim2.new(1,-10,0,10); nextBtn.Size=UDim2.new(0,60,0,28); nextBtn.BackgroundColor3=C.row; nextBtn.BorderSizePixel=0; nextBtn.Text="NEXT ▶"; nextBtn.Font=F_MONO; nextBtn.TextSize=11; nextBtn.TextColor3=C.text; nextBtn.AutoButtonColor=false; nextBtn.Parent=navBar

local tabs,currentTab,switching={},nil,false
local function restyleTabs()
    for _,t in ipairs(tabs) do
        local on=(t==currentTab)
        t.nm.TextColor3=on and C.text or C.dim
        t.num.TextColor3=on and ACC or C.dim
        t.button.BackgroundTransparency=on and 0.55 or 1
    end
end
local function selectTab(tab)
    if currentTab==tab or switching then return end
    switching=true; local old=currentTab; currentTab=tab
    tween(indicator,0.3,{Position=UDim2.new(0,0,0,18+tab.index*38)})
    restyleTabs()
    if old then tween(old.page,0.15,{GroupTransparency=1}); task.delay(0.15,function() old.page.Visible=false end) end
    task.delay(old and 0.12 or 0,function()
        tab.page.GroupTransparency=1; tab.page.Visible=true
        tween(tab.page,0.25,{GroupTransparency=0})
        task.delay(0.25,function() switching=false end)
    end)
end
prevBtn.MouseButton1Click:Connect(function() local i=currentTab and currentTab.index or 0; local n=(i-1)%#tabs; selectTab(tabs[n+1]) end)
nextBtn.MouseButton1Click:Connect(function() local i=currentTab and currentTab.index or 0; local n=(i+1)%#tabs; selectTab(tabs[n+1]) end)

--========================================================
-- TAB BUILDER
--========================================================
local function hairline(parent,y) local f=Instance.new("Frame"); f.Position=UDim2.new(0,0,1,y or -1); f.Size=UDim2.new(1,0,0,1); f.BackgroundColor3=C.line; f.BorderSizePixel=0; f.Parent=parent; return f end

local function createTab(name)
    local index=#tabs
    local button=Instance.new("TextButton"); button.Size=UDim2.new(1,0,0,34); button.Position=UDim2.new(0,0,0,index*38+6); button.BackgroundColor3=C.row; button.BackgroundTransparency=1; button.BorderSizePixel=0; button.Text=""; button.AutoButtonColor=false; button.Parent=sideList
    local num=Instance.new("TextLabel"); num.BackgroundTransparency=1; num.Position=UDim2.new(0,16,0,0); num.Size=UDim2.new(0,24,1,0); num.Font=F_MONO; num.TextSize=11; num.TextXAlignment=Enum.TextXAlignment.Left; num.TextColor3=C.dim; num.Text="0"..(index+1); num.Parent=button
    local nm=Instance.new("TextLabel"); nm.BackgroundTransparency=1; nm.Position=UDim2.new(0,46,0,0); nm.Size=UDim2.new(1,-50,1,0); nm.Font=F_SEC; nm.TextSize=16; nm.TextXAlignment=Enum.TextXAlignment.Left; nm.TextColor3=C.dim; nm.Text=string.upper(name); nm.Parent=button
    local page=Instance.new("CanvasGroup"); page.Size=UDim2.new(1,0,1,0); page.BackgroundTransparency=1; page.Visible=false; page.GroupTransparency=1; page.Parent=pages
    local scroll=Instance.new("ScrollingFrame"); scroll.Size=UDim2.new(1,0,1,0); scroll.BackgroundTransparency=1; scroll.BorderSizePixel=0; scroll.ScrollBarThickness=2; scroll.CanvasSize=UDim2.new(0,0,0,0); scroll.AutomaticCanvasSize=Enum.AutomaticSize.Y; scroll.Parent=page
    T(scroll,"ScrollBarImageColor3")
    local layout=Instance.new("UIListLayout"); layout.Padding=UDim.new(0,2); layout.SortOrder=Enum.SortOrder.LayoutOrder; layout.Parent=scroll
    local pad=Instance.new("UIPadding"); pad.PaddingRight=UDim.new(0,8); pad.PaddingTop=UDim.new(0,2); pad.PaddingBottom=UDim.new(0,10); pad.Parent=scroll
    local tab={button=button,page=page,scroll=scroll,index=index,name=name,num=num,nm=nm}; table.insert(tabs,tab)
    button.MouseButton1Click:Connect(function() selectTab(tab) end)
    button.MouseEnter:Connect(function() if currentTab~=tab then tween(nm,0.15,{TextColor3=C.text}) end end)
    button.MouseLeave:Connect(function() if currentTab~=tab then tween(nm,0.15,{TextColor3=C.dim}) end end)

    function tab:Label(text)
        local f=Instance.new("Frame"); f.Size=UDim2.new(1,0,0,30); f.BackgroundTransparency=1; f.Parent=scroll
        local l=Instance.new("TextLabel"); l.BackgroundTransparency=1; l.Position=UDim2.new(0,0,0,6); l.Size=UDim2.new(1,0,0,18); l.Font=F_SEC; l.TextSize=13; l.TextXAlignment=Enum.TextXAlignment.Left; l.TextColor3=C.dim; l.Text=string.upper(text); l.Parent=f
        hairline(f,-3)
        local ac=Instance.new("Frame"); ac.Position=UDim2.new(0,0,1,-3); ac.Size=UDim2.new(0,28,0,1); ac.BorderSizePixel=0; ac.Parent=f; T(ac,"BackgroundColor3")
    end
    function tab:Label2(text,font,size,color)
        local l=Instance.new("TextLabel"); l.Size=UDim2.new(1,0,0,18); l.BackgroundTransparency=1; l.Font=font or F_MONO; l.TextSize=size or 11; l.TextColor3=color or C.dim; l.TextXAlignment=Enum.TextXAlignment.Left; l.Text=text; l.Parent=scroll
        return l
    end
    function tab:Toggle(text,default,callback)
        local key=name.."/"..text; local state=default or false
        local row=Instance.new("TextButton"); row.Size=UDim2.new(1,0,0,34); row.BackgroundColor3=C.row; row.BackgroundTransparency=1; row.BorderSizePixel=0; row.AutoButtonColor=false; row.Text=""; row.Parent=scroll
        hairline(row)
        local lbl=Instance.new("TextLabel"); lbl.BackgroundTransparency=1; lbl.Position=UDim2.new(0,10,0,0); lbl.Size=UDim2.new(1,-60,1,0); lbl.Font=F_BODY; lbl.TextSize=16; lbl.TextColor3=C.text; lbl.TextXAlignment=Enum.TextXAlignment.Left; lbl.Text=text; lbl.Parent=row
        local box=Instance.new("Frame"); box.AnchorPoint=Vector2.new(1,0.5); box.Position=UDim2.new(1,-10,0.5,0); box.Size=UDim2.new(0,16,0,16); box.BackgroundColor3=C.bg; box.BorderSizePixel=0; box.Parent=row
        local bs=stroke(box,C.off,1,0)
        local inner=Instance.new("Frame"); inner.AnchorPoint=Vector2.new(0.5,0.5); inner.Position=UDim2.new(0.5,0,0.5,0); inner.Size=UDim2.new(0,state and 8 or 0,0,state and 8 or 0); inner.BorderSizePixel=0; inner.Parent=box; T(inner,"BackgroundColor3")
        local function paint() bs.Color=state and ACC or C.off; tween(inner,0.15,{Size=UDim2.new(0,state and 8 or 0,0,state and 8 or 0)}) end
        register(key,state,function(v) state=v and true or false; Flags[key]=state; paint(); if callback then task.spawn(callback,state) end end)
        row.MouseButton1Click:Connect(function() Setters[key](not state) end)
        row.MouseEnter:Connect(function() tween(row,0.12,{BackgroundTransparency=0.5}) end)
        row.MouseLeave:Connect(function() tween(row,0.12,{BackgroundTransparency=1}) end)
    end
    function tab:Button(text,callback)
        local wrap=Instance.new("Frame"); wrap.Size=UDim2.new(1,0,0,38); wrap.BackgroundTransparency=1; wrap.Parent=scroll
        local b=Instance.new("TextButton"); b.Position=UDim2.new(0,10,0,4); b.Size=UDim2.new(1,-20,0,30); b.BackgroundColor3=C.bg; b.BackgroundTransparency=1; b.BorderSizePixel=0; b.AutoButtonColor=false; b.Font=F_MONO; b.TextSize=12; b.Text=string.upper(text); b.Parent=wrap
        T(b,"TextColor3"); local bs=stroke(b,ACC,1,0.4); T(bs,"Color")
        b.MouseEnter:Connect(function() b.BackgroundColor3=ACC; tween(b,0.12,{BackgroundTransparency=0}); b.TextColor3=C.bg end)
        b.MouseLeave:Connect(function() tween(b,0.12,{BackgroundTransparency=1}); b.TextColor3=ACC end)
        b.MouseButton1Click:Connect(function() if callback then task.spawn(callback) end end)
    end
    function tab:Input(text,default,callback)
        local row=Instance.new("Frame"); row.Size=UDim2.new(1,0,0,38); row.BackgroundTransparency=1; row.Parent=scroll
        hairline(row)
        local lbl=Instance.new("TextLabel"); lbl.BackgroundTransparency=1; lbl.Position=UDim2.new(0,10,0,0); lbl.Size=UDim2.new(0.5,-10,1,0); lbl.Font=F_BODY; lbl.TextSize=16; lbl.TextColor3=C.text; lbl.TextXAlignment=Enum.TextXAlignment.Left; lbl.Text=text; lbl.Parent=row
        local boxF=Instance.new("Frame"); boxF.AnchorPoint=Vector2.new(1,0.5); boxF.Position=UDim2.new(1,-10,0.5,0); boxF.Size=UDim2.new(0.5,-10,0,26); boxF.BackgroundColor3=C.bg; boxF.BorderSizePixel=0; boxF.Parent=row
        local bs=stroke(boxF,ACC,1,0.4); T(bs,"Color")
        local tb=Instance.new("TextBox"); tb.BackgroundTransparency=1; tb.Size=UDim2.new(1,-12,1,0); tb.Position=UDim2.new(0,6,0,0); tb.Font=F_MONO; tb.TextSize=13; tb.TextColor3=C.text; tb.PlaceholderColor3=C.dim; tb.PlaceholderText="value"; tb.Text=tostring(default or ""); tb.ClearTextOnFocus=false; tb.TextXAlignment=Enum.TextXAlignment.Center; tb.Parent=boxF
        tb.FocusLost:Connect(function(enter) if callback then task.spawn(callback,tb.Text,tb) end end)
        return tb
    end
    function tab:Slider(text,min,max,default,callback)
        local key=name.."/"..text; local value=default or min
        local row=Instance.new("Frame"); row.Size=UDim2.new(1,0,0,46); row.BackgroundTransparency=1; row.Parent=scroll
        hairline(row)
        local lbl=Instance.new("TextLabel"); lbl.BackgroundTransparency=1; lbl.Position=UDim2.new(0,10,0,4); lbl.Size=UDim2.new(0.6,0,0,20); lbl.Font=F_BODY; lbl.TextSize=16; lbl.TextColor3=C.text; lbl.TextXAlignment=Enum.TextXAlignment.Left; lbl.Text=text; lbl.Parent=row
        local val=Instance.new("TextLabel"); val.BackgroundTransparency=1; val.AnchorPoint=Vector2.new(1,0); val.Position=UDim2.new(1,-10,0,4); val.Size=UDim2.new(0,100,0,20); val.Font=F_MONO; val.TextSize=13; val.TextXAlignment=Enum.TextXAlignment.Right; val.Text=tostring(value); val.Parent=row; T(val,"TextColor3")
        local bar=Instance.new("Frame"); bar.Position=UDim2.new(0,10,0,34); bar.Size=UDim2.new(1,-20,0,2); bar.BackgroundColor3=C.off; bar.BorderSizePixel=0; bar.Parent=row
        local fill=Instance.new("Frame"); fill.Size=UDim2.new((value-min)/(max-min),0,1,0); fill.BorderSizePixel=0; fill.Parent=bar; T(fill,"BackgroundColor3")
        local knob=Instance.new("Frame"); knob.AnchorPoint=Vector2.new(0.5,0.5); knob.Position=UDim2.new((value-min)/(max-min),0,0.5,0); knob.Size=UDim2.new(0,6,0,14); knob.BackgroundColor3=C.text; knob.BorderSizePixel=0; knob.ZIndex=3; knob.Parent=bar
        register(key,value,function(v)
            v=math.clamp(math.floor((tonumber(v) or min)+0.5),min,max); value=v; Flags[key]=v
            val.Text=tostring(v); local r=(v-min)/(max-min)
            tween(fill,0.08,{Size=UDim2.new(r,0,1,0)},Enum.EasingStyle.Linear); tween(knob,0.08,{Position=UDim2.new(r,0,0.5,0)},Enum.EasingStyle.Linear)
            if callback then task.spawn(callback,v) end
        end)
        local hit=Instance.new("TextButton"); hit.BackgroundTransparency=1; hit.Text=""; hit.Position=UDim2.new(0,0,0,22); hit.Size=UDim2.new(1,0,0,24); hit.Parent=row
        local sliding=false
        local function update(x) local rel=math.clamp((x-bar.AbsolutePosition.X)/math.max(bar.AbsoluteSize.X,1),0,1); Setters[key](min+(max-min)*rel) end
        hit.InputBegan:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then sliding=true; scroll.ScrollingEnabled=false; update(i.Position.X) end end)
        track(UIS.InputEnded:Connect(function(i) if sliding and (i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch) then sliding=false; scroll.ScrollingEnabled=true end end))
        track(UIS.InputChanged:Connect(function(i) if sliding and (i.UserInputType==Enum.UserInputType.MouseMovement or i.UserInputType==Enum.UserInputType.Touch) then update(i.Position.X) end end))
    end
    function tab:Choice(text,options,default,callback)
        local key=name.."/"..text; local idx=table.find(options,default) or 1
        local row=Instance.new("TextButton"); row.Size=UDim2.new(1,0,0,34); row.BackgroundColor3=C.row; row.BackgroundTransparency=1; row.BorderSizePixel=0; row.AutoButtonColor=false; row.Text=""; row.Parent=scroll
        hairline(row)
        local lbl=Instance.new("TextLabel"); lbl.BackgroundTransparency=1; lbl.Position=UDim2.new(0,10,0,0); lbl.Size=UDim2.new(0.5,-10,1,0); lbl.Font=F_BODY; lbl.TextSize=16; lbl.TextColor3=C.text; lbl.TextXAlignment=Enum.TextXAlignment.Left; lbl.Text=text; lbl.Parent=row
        local val=Instance.new("TextLabel"); val.BackgroundTransparency=1; val.AnchorPoint=Vector2.new(1,0); val.Position=UDim2.new(1,-10,0,0); val.Size=UDim2.new(0.5,-10,1,0); val.Font=F_MONO; val.TextSize=13; val.TextXAlignment=Enum.TextXAlignment.Right; val.Text="< "..options[idx].." >"; val.Parent=row; T(val,"TextColor3")
        register(key,options[idx],function(v)
            local i=table.find(options,v); if not i then return end
            idx=i; Flags[key]=options[i]; val.Text="< "..options[i].." >"
            if callback then task.spawn(callback,options[i]) end
        end)
        row.MouseButton1Click:Connect(function() Setters[key](options[idx%#options+1]) end)
        row.MouseButton2Click:Connect(function() Setters[key](options[(idx-2)%#options+1]) end)
        row.MouseEnter:Connect(function() tween(row,0.12,{BackgroundTransparency=0.5}) end)
        row.MouseLeave:Connect(function() tween(row,0.12,{BackgroundTransparency=1}) end)
    end
    return tab
end

--========================================================
-- ROLE / ESP (unchanged core)
--========================================================
local ROLE_COLORS={Murderer=Color3.fromRGB(255,60,60),Sheriff=Color3.fromRGB(70,130,255),Innocent=Color3.fromRGB(70,230,110)}
local ROLE_NAMES={"Murderer","Sheriff","Innocent"}
local function scanName(name)
    local n=string.lower(name)
    if n=="knife" or n:find("knife") or n:find("murderknife") then return "Murderer" end
    if n=="gun" or n=="revolver" or n=="sheriff gun" or n:find("revolver") or (n:find("gun") and not n:find("shotgun") and not n:find("stun")) then return "Sheriff" end
    return nil
end
local function getRole(plr)
    local char=plr.Character; if not char then return "Innocent" end
    if plr.Team then
        local tl=string.lower(plr.Team.Name)
        if tl=="murderer" then return "Murderer" end
        if tl=="sheriff" then return "Sheriff" end
        if tl=="innocent" then return "Innocent" end
    end
    for _,src in ipairs({plr,char}) do
        for _,attr in ipairs({"Role","MM2Role","MurderRole","PlayerRole","Team"}) do
            local v=src:GetAttribute(attr)
            if v~=nil then local rl=string.lower(tostring(v))
                if rl=="murderer" or rl=="murder" then return "Murderer" end
                if rl=="sheriff" then return "Sheriff" end
                if rl=="innocent" then return "Innocent" end
            end
        end
    end
    for _,obj in ipairs(char:GetChildren()) do if obj:IsA("Tool") then local r=scanName(obj.Name); if r then return r end end end
    local bp=plr:FindFirstChildOfClass("Backpack")
    if bp then for _,obj in ipairs(bp:GetChildren()) do if obj:IsA("Tool") then local rr=scanName(obj.Name); if rr then return rr end end end end
    return "Innocent"
end
local roleCache={}
local function getRoleCached(plr)
    local c=roleCache[plr]; local now=os.clock()
    if c and now-c.t<0.3 then return c.r end
    local r=getRole(plr); roleCache[plr]={r=r,t=now}; return r
end
Players.PlayerRemoving:Connect(function(p) roleCache[p]=nil end)

-- ESP
local ESPFolder=Instance.new("Folder"); ESPFolder.Name="luxxsESP"; ESPFolder.Parent=gui
local espData={}
local function setLine(f,p1,p2,thick)
    local dx,dy=p2.X-p1.X,p2.Y-p1.Y
    f.Position=UDim2.new(0,(p1.X+p2.X)*0.5,0,(p1.Y+p2.Y)*0.5)
    f.Size=UDim2.new(0,math.sqrt(dx*dx+dy*dy),0,thick)
    f.Rotation=math.deg(math.atan2(dy,dx))
end
local BONES={{"Head","UpperTorso"},{"UpperTorso","LowerTorso"},{"UpperTorso","LeftUpperArm"},{"LeftUpperArm","LeftLowerArm"},{"LeftLowerArm","LeftHand"},{"UpperTorso","RightUpperArm"},{"RightUpperArm","RightLowerArm"},{"RightLowerArm","RightHand"},{"LowerTorso","LeftUpperLeg"},{"LeftUpperLeg","LeftLowerLeg"},{"LeftLowerLeg","LeftFoot"},{"LowerTorso","RightUpperLeg"},{"RightUpperLeg","RightLowerLeg"},{"RightLowerLeg","RightFoot"}}

local function createESP(plr)
    if espData[plr] or plr==LP then return end
    local d={}
    d.box=Instance.new("Frame"); d.box.BackgroundTransparency=1; d.box.BorderSizePixel=0; d.box.ZIndex=2; d.box.Parent=ESPFolder; d.boxStroke=stroke(d.box,ACC,1.2,0)
    local function mkLabel(size,font)
        local l=Instance.new("TextLabel"); l.BackgroundTransparency=1; l.Font=font or F_MONO; l.TextSize=size; l.TextColor3=WHITE; l.TextStrokeTransparency=0.4; l.TextStrokeColor3=Color3.new(0,0,0); l.Size=UDim2.new(0,260,0,size+2); l.TextXAlignment=Enum.TextXAlignment.Center; l.ZIndex=4; l.Parent=ESPFolder; return l
    end
    d.role=mkLabel(13,F_SEC); d.name=mkLabel(12); d.dist=mkLabel(11)
    d.tracer=Instance.new("Frame"); d.tracer.AnchorPoint=Vector2.new(0.5,0.5); d.tracer.BorderSizePixel=0; d.tracer.ZIndex=2; d.tracer.Parent=ESPFolder
    d.hpBg=Instance.new("Frame"); d.hpBg.BackgroundColor3=Color3.fromRGB(14,14,16); d.hpBg.BorderSizePixel=0; d.hpBg.ZIndex=3; d.hpBg.Parent=ESPFolder
    d.hpFill=Instance.new("Frame"); d.hpFill.AnchorPoint=Vector2.new(0,1); d.hpFill.BackgroundColor3=Color3.fromRGB(70,230,110); d.hpFill.BorderSizePixel=0; d.hpFill.Size=UDim2.new(1,0,1,0); d.hpFill.Position=UDim2.new(0,0,1,0); d.hpFill.ZIndex=4; d.hpFill.Parent=d.hpBg
    d.skeleton={}
    for i=1,#BONES do local f=Instance.new("Frame"); f.AnchorPoint=Vector2.new(0.5,0.5); f.BorderSizePixel=0; f.BackgroundColor3=WHITE; f.Visible=false; f.ZIndex=3; f.Parent=ESPFolder; d.skeleton[i]=f end
    d.highlight=Instance.new("Highlight"); d.highlight.FillTransparency=1; d.highlight.OutlineTransparency=1; d.highlight.DepthMode=Enum.HighlightDepthMode.AlwaysOnTop; d.highlight.Parent=ESPFolder
    espData[plr]=d
end
local function removeESP(plr)
    local d=espData[plr]; if not d then return end
    for k,v in pairs(d) do
        if typeof(v)=="Instance" then pcall(function() v:Destroy() end)
        elseif type(v)=="table" then for _,o in pairs(v) do pcall(function() o:Destroy() end) end end
    end
    espData[plr]=nil
end
for _,plr in ipairs(Players:GetPlayers()) do if plr~=LP then createESP(plr) end end
Players.PlayerAdded:Connect(function(plr) task.wait(0.2); createESP(plr) end)
Players.PlayerRemoving:Connect(function(plr) removeESP(plr) end)

local function espAnyOn() return Flags["Visuals/ESP Box"] or Flags["Visuals/Role"] or Flags["Visuals/Name"] or Flags["Visuals/Health"] or Flags["Visuals/Distance"] or Flags["Visuals/Tracers"] or Flags["Visuals/Skeleton"] or Flags["Visuals/Chams"] or Flags["Visuals/Glow"] end

track(RunService.RenderStepped:Connect(function()
    local cam=workspace.CurrentCamera; if not cam then return end
    local vp=cam.ViewportSize; local t=os.clock()
    local anyOn=espAnyOn()
    for plr,d in pairs(espData) do
        local char=plr.Character; local hum=char and char:FindFirstChildOfClass("Humanoid"); local hrp=char and char:FindFirstChild("HumanoidRootPart")
        local visible=false; local minX,minY,maxX,maxY=math.huge,math.huge,-math.huge,-math.huge
        if char and hum and hum.Health>0 and anyOn then
            for _,p in ipairs(char:GetChildren()) do
                if p:IsA("BasePart") then
                    local sp,onS=cam:WorldToViewportPoint(p.Position)
                    if onS and sp.Z>0 then visible=true; minX=math.min(minX,sp.X-10); maxX=math.max(maxX,sp.X+10); minY=math.min(minY,sp.Y-10); maxY=math.max(maxY,sp.Y+10) end
                end
            end
        end
        if visible then
            local role=getRoleCached(plr); local rcol=ROLE_COLORS[role] or WHITE
            local ecol=Flags["Visuals/Color by Role"] and rcol or shadeColor(Flags["Visuals/ESP Color"],Flags["Settings/Shade"],t,0)
            local w,h=maxX-minX,maxY-minY; local cx=(minX+maxX)*0.5
            d.box.Visible=Flags["Visuals/ESP Box"]; d.box.Position=UDim2.new(0,minX,0,minY); d.box.Size=UDim2.new(0,w,0,h); d.boxStroke.Color=ecol
            d.role.Visible=Flags["Visuals/Role"]; d.role.Text=string.upper(role); d.role.TextColor3=rcol; d.role.Position=UDim2.new(0,cx-130,0,minY-48)
            d.name.Visible=Flags["Visuals/Name"]; d.name.Text=plr.Name; d.name.TextColor3=ecol; d.name.Position=UDim2.new(0,cx-130,0,minY-32)
            local dist=(hrp.Position-cam.CFrame.Position).Magnitude
            d.dist.Visible=Flags["Visuals/Distance"]; d.dist.Text="["..math.floor(dist).."m]"; d.dist.Position=UDim2.new(0,cx-130,0,minY+h+2)
            d.hpBg.Visible=Flags["Visuals/Health"]; d.hpBg.Position=UDim2.new(0,minX-6,0,minY); d.hpBg.Size=UDim2.new(0,3,0,h); d.hpFill.Size=UDim2.new(1,0,math.clamp(hum.Health/hum.MaxHealth,0,1),0)
            d.tracer.Visible=Flags["Visuals/Tracers"]
            if d.tracer.Visible then d.tracer.BackgroundColor3=ecol; setLine(d.tracer,Vector2.new(vp.X*0.5,vp.Y),Vector2.new(cx,minY+h),1) end
            local skelOn=Flags["Visuals/Skeleton"]
            for i,bone in ipairs(BONES) do
                local ln=d.skeleton[i]
                if skelOn then
                    local p1=char:FindFirstChild(bone[1]); local p2=char:FindFirstChild(bone[2])
                    if p1 and p2 then
                        local s1,o1=cam:WorldToViewportPoint(p1.Position); local s2,o2=cam:WorldToViewportPoint(p2.Position)
                        if o1 and o2 and s1.Z>0 and s2.Z>0 then ln.Visible=true; ln.BackgroundColor3=ecol; setLine(ln,Vector2.new(s1.X,s1.Y),Vector2.new(s2.X,s2.Y),1.5)
                        else ln.Visible=false end
                    else ln.Visible=false end
                else ln.Visible=false end
            end
            local chams,glow=Flags["Visuals/Chams"],Flags["Visuals/Glow"]
            if chams or glow then
                d.highlight.Adornee=char; d.highlight.FillColor=ecol; d.highlight.OutlineColor=ecol
                d.highlight.FillTransparency=chams and 0.5 or 1; d.highlight.OutlineTransparency=glow and 0.3 or 1
            else d.highlight.FillTransparency=1; d.highlight.OutlineTransparency=1; d.highlight.Adornee=nil end
        else
            d.box.Visible=false; d.role.Visible=false; d.name.Visible=false; d.dist.Visible=false; d.hpBg.Visible=false; d.tracer.Visible=false
            for _,ln in ipairs(d.skeleton) do ln.Visible=false end
            d.highlight.Adornee=nil
        end
    end
end))

--========================================================
-- AUTO WIN + TELEPORT TO PLAYER
--========================================================
local AutoWin={Enabled=false,Mode="Auto",Cooldown=0,Conn=nil,Last=0}
local function getMurderer()
    for _,plr in ipairs(Players:GetPlayers()) do
        if plr~=LP and getRoleCached(plr)=="Murderer" then return plr end
    end
    return nil
end
local function getAllTargets(myRole)
    local out={}
    for _,plr in ipairs(Players:GetPlayers()) do
        if plr~=LP and getRoleCached(plr)~="Innocent" then
            -- if murderer, target innocents + sheriff; if sheriff, target murderer
            if myRole=="Murderer" and getRoleCached(plr)~="Murderer" then out[#out+1]=plr end
            if myRole=="Sheriff" and getRoleCached(plr)=="Murderer" then out[#out+1]=plr end
        end
    end
    return out
end
local function teleportToPlayer(plr)
    local char=LP.Character; local hrp=char and char:FindFirstChild("HumanoidRootPart")
    local tchar=plr.Character; local thrp=tchar and tchar:FindFirstChild("HumanoidRootPart")
    if not hrp or not thrp then return end
    hrp.CFrame=thrp.CFrame*CFrame.new(0,0,2)
    hrp.AssemblyLinearVelocity=Vector3.zero
end
local function useCurrentTool()
    local char=LP.Character; if not char then return end
    local tool=char:FindFirstChildOfClass("Tool")
    if not tool then return end
    pcall(function() tool:Activate() end)
    pcall(function()
        local hum=char:FindFirstChildOfClass("Humanoid")
        if hum then
            local target=char:FindFirstChild("Head")
            if target then
                local mouse=LP:GetMouse()
                if mouse then mouse.Target=target end
            end
        end
    end)
    if not tool.Enabled then pcall(function() tool.Enabled=true end) end
end
local function autoWinTick(dt)
    if not AutoWin.Enabled then return end
    if os.clock()-AutoWin.Last<0.25 then return end
    AutoWin.Last=os.clock()
    local myRole=getRoleCached(LP)
    if myRole=="Sheriff" then
        local murd=getMurderer()
        if murd and murd.Character then
            teleportToPlayer(murd)
            task.wait(0.05)
            -- aim & fire
            local hrp=LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
            local thrp=murd.Character:FindFirstChild("HumanoidRootPart")
            if hrp and thrp then
                local dir=(thrp.Position-hrp.Position)
                if dir.Magnitude>0.01 then hrp.CFrame=CFrame.lookAt(hrp.Position,hrp.Position+dir.Unit) end
            end
            useCurrentTool()
        end
    elseif myRole=="Murderer" then
        local targets=getAllTargets(myRole)
        for _,t in ipairs(targets) do
            if t.Character and t.Character:FindFirstChild("HumanoidRootPart") then
                local hum=t.Character:FindFirstChildOfClass("Humanoid")
                if hum and hum.Health>0 then
                    teleportToPlayer(t)
                    task.wait(0.04)
                    local hrp=LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
                    local thrp=t.Character:FindFirstChild("HumanoidRootPart")
                    if hrp and thrp then
                        local dir=(thrp.Position-hrp.Position)
                        if dir.Magnitude>0.01 then hrp.CFrame=CFrame.lookAt(hrp.Position,hrp.Position+dir.Unit) end
                    end
                    useCurrentTool()
                    task.wait(0.1)
                end
            end
        end
    end
end
track(RunService.Heartbeat:Connect(autoWinTick))

--========================================================
-- COIN FARM (legit + teleport)
--========================================================
local Farm={Enabled=false,Mode="Legit",Speed=32,TeleportDelay=0.35,ReturnOnFinish=false,ReturnPos=nil,LoopThread=nil,Collected=0,Status="idle",LastTP=0}
local antiAfkConn=nil
local function setAntiAFK(on)
    if antiAfkConn then antiAfkConn:Disconnect(); antiAfkConn=nil end
    if not on then return end
    antiAfkConn=LP.Idled:Connect(function() VU:CaptureController(); VU:ClickButton2(Vector2.new()) end)
end
local coinSet,coinConns={}, {}
local function isCoin(o) return o:IsA("BasePart") and (o.Name=="Coin" or o.Name:find("Coin") or o.Name:find("coin")) end
local function startCoinCache()
    for _,c in ipairs(coinConns) do c:Disconnect() end
    coinConns={}; coinSet={}
    for _,o in ipairs(workspace:GetDescendants()) do if isCoin(o) then coinSet[o]=true end end
    coinConns[1]=workspace.DescendantAdded:Connect(function(o) if isCoin(o) then coinSet[o]=true end end)
    coinConns[2]=workspace.DescendantRemoving:Connect(function(o)
        if coinSet[o] then
            coinSet[o]=nil
            local hrp=LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
            if Farm.Enabled and hrp and (hrp.Position-o.Position).Magnitude<16 then Farm.Collected+=1 end
        end
    end)
end
local function nearestCoin(pos,skip)
    local best,bd,now=nil,math.huge,os.clock()
    for p in pairs(coinSet) do
        if p.Parent and not (skip[p] and skip[p]>now) then
            local d=(p.Position-pos).Magnitude
            if d<bd then best,bd=p,d end
        end
    end
    return best,bd
end

-- fly (used in some modes)
local farmFlyVel,farmFlyGyro,farmFlyConn=nil,nil,nil
local function disableFarmFly()
    if farmFlyConn then farmFlyConn:Disconnect(); farmFlyConn=nil end
    if farmFlyVel then farmFlyVel:Destroy(); farmFlyVel=nil end
    if farmFlyGyro then farmFlyGyro:Destroy(); farmFlyGyro=nil end
    local hum=LP.Character and LP.Character:FindFirstChildOfClass("Humanoid")
    if hum then hum.PlatformStand=false end
end
local function enableFarmFly()
    disableFarmFly()
    local char=LP.Character; local hrp=char and char:FindFirstChild("HumanoidRootPart"); local hum=char and char:FindFirstChildOfClass("Humanoid")
    if not hrp or not hum then return end
    farmFlyVel=Instance.new("BodyVelocity"); farmFlyVel.MaxForce=Vector3.new(9e9,9e9,9e9); farmFlyVel.Velocity=Vector3.zero; farmFlyVel.Parent=hrp
    farmFlyGyro=Instance.new("BodyGyro"); farmFlyGyro.MaxTorque=Vector3.new(9e9,9e9,9e9); farmFlyGyro.P=2000; farmFlyGyro.CFrame=hrp.CFrame; farmFlyGyro.Parent=hrp
    hum.PlatformStand=true
    farmFlyConn=RunService.RenderStepped:Connect(function()
        if not Farm.Enabled or not hrp.Parent then return end
        local coin=nearestCoin(hrp.Position,{})
        if coin then
            local dir=(coin.Position-hrp.Position)
            if dir.Magnitude>0.1 then farmFlyVel.Velocity=dir.Unit*Farm.Speed*2 end
        end
    end)
end

local function startFarm()
    if Farm.LoopThread then return end
    local hrp0=LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
    if Farm.ReturnOnFinish and hrp0 then Farm.ReturnPos=hrp0.CFrame end
    Farm.LoopThread=task.spawn(function()
        startCoinCache()
        local skip={}
        while Farm.Enabled do
            local dt=RunService.Heartbeat:Wait()
            local char=LP.Character
            local hrp=char and char:FindFirstChild("HumanoidRootPart")
            local hum=char and char:FindFirstChildOfClass("Humanoid")
            if hrp and hum then
                local coin=getNearestCoinLegit and nil or nil
                local c,dist=nearestCoin(hrp.Position,skip)
                if c then
                    Farm.Status="to coin"
                    local target=c.Position
                    if Farm.Mode=="Teleport" then
                        if os.clock()-Farm.LastTP>=Farm.TeleportDelay then
                            Farm.LastTP=os.clock()
                            -- teleport slightly above to look less like a snap
                            hrp.CFrame=CFrame.new(target+Vector3.new(math.random(-1,1),2.5,math.random(-1,1)))
                            hrp.AssemblyLinearVelocity=Vector3.zero
                        end
                    elseif Farm.Mode=="Legit" then
                        -- walk using MoveTo with humane pacing
                        if (hrp.Position-target).Magnitude>3.5 then
                            hum:MoveTo(target)
                        else
                            hum:MoveTo(hrp.Position)
                            skip[c]=os.clock()+0.6
                        end
                    elseif Farm.Mode=="Smooth" then
                        local dir=target-hrp.Position
                        local step=Farm.Speed*dt
                        if dir.Magnitude<=step then
                            hrp.CFrame=CFrame.new(target)
                            hrp.AssemblyLinearVelocity=Vector3.zero
                        else
                            hrp.CFrame=CFrame.new(hrp.Position+dir.Unit*step)
                        end
                    end
                    if Farm.Mode~="Legit" and (hrp.Position-target).Magnitude<3 then skip[c]=os.clock()+0.4 end
                else
                    Farm.Status="no coins"; task.wait(0.25)
                end
            end
            task.wait(0.05+math.random()*0.08)
        end
        if Farm.ReturnOnFinish and Farm.ReturnPos then
            local hrp=LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
            if hrp then hrp.CFrame=Farm.ReturnPos end
        end
        Farm.Status="idle"
    end)
end
local function stopFarm()
    Farm.Enabled=false
    if Farm.LoopThread then pcall(function() task.cancel(Farm.LoopThread) end); Farm.LoopThread=nil end
    for _,c in ipairs(coinConns) do c:Disconnect() end
    coinConns={}
    disableFarmFly()
end

--========================================================
-- MOVEMENT (Fly, Noclip)
--========================================================
local Move={Fly=false,Speed=60,Noclip=false}
local mvConn,mvVel,mvGyro,mvControls=nil,nil,nil,nil
local upHeld,downHeld=false,false
local function getMoveVector()
    if mvControls then
        local ok,v=pcall(function() return mvControls:GetMoveVector() end)
        if ok and typeof(v)=="Vector3" then return v end
    end
    local hum=LP.Character and LP.Character:FindFirstChildOfClass("Humanoid")
    local cam=workspace.CurrentCamera
    if hum and cam then return cam.CFrame:VectorToObjectSpace(hum.MoveDirection) end
    return Vector3.zero
end
local function disableFlyMove()
    if mvConn then mvConn:Disconnect(); mvConn=nil end
    if mvVel then pcall(function() mvVel:Destroy() end); mvVel=nil end
    if mvGyro then pcall(function() mvGyro:Destroy() end); mvGyro=nil end
    local hum=LP.Character and LP.Character:FindFirstChildOfClass("Humanoid")
    if hum then hum.PlatformStand=false; pcall(function() hum:ChangeState(Enum.HumanoidStateType.GettingUp) end) end
end
local function enableFlyMove()
    disableFlyMove()
    local char=LP.Character; local hrp=char and char:FindFirstChild("HumanoidRootPart"); local hum=char and char:FindFirstChildOfClass("Humanoid")
    if not hrp or not hum then return end
    if not mvControls then pcall(function()
        local pm=LP:FindFirstChild("PlayerScripts") and LP.PlayerScripts:FindFirstChild("PlayerModule")
        if pm then mvControls=require(pm):GetControls() end
    end) end
    mvVel=Instance.new("BodyVelocity"); mvVel.MaxForce=Vector3.new(9e9,9e9,9e9); mvVel.Velocity=Vector3.zero; mvVel.Parent=hrp
    mvGyro=Instance.new("BodyGyro"); mvGyro.MaxTorque=Vector3.new(9e9,9e9,9e9); mvGyro.P=9e4; mvGyro.D=800; mvGyro.CFrame=hrp.CFrame; mvGyro.Parent=hrp
    hum.PlatformStand=true
    mvConn=RunService.RenderStepped:Connect(function()
        if not hrp.Parent then return end
        local cam=workspace.CurrentCamera; if not cam then return end
        local mv=getMoveVector()
        local dir=cam.CFrame:VectorToWorldSpace(Vector3.new(mv.X,0,mv.Z))
        if UIS:IsKeyDown(Enum.KeyCode.W) and mv.Magnitude==0 then dir+=cam.CFrame.LookVector end
        if UIS:IsKeyDown(Enum.KeyCode.Space) or UIS:IsKeyDown(Enum.KeyCode.E) or upHeld then dir+=Vector3.new(0,1,0) end
        if UIS:IsKeyDown(Enum.KeyCode.LeftShift) or UIS:IsKeyDown(Enum.KeyCode.Q) or downHeld then dir-=Vector3.new(0,1,0) end
        if dir.Magnitude>1 then dir=dir.Unit end
        mvVel.Velocity=dir*Move.Speed
        local look=cam.CFrame.LookVector
        if Vector3.new(look.X,0,look.Z).Magnitude>0.01 then mvGyro.CFrame=CFrame.lookAt(hrp.Position,hrp.Position+Vector3.new(look.X,0,look.Z)) end
    end)
end
local ncConn,ncTouched=nil,{}
local function setNoclipMove(on)
    if ncConn then ncConn:Disconnect(); ncConn=nil end
    if on then
        ncConn=RunService.Stepped:Connect(function()
            local char=LP.Character; if not char then return end
            for _,p in ipairs(char:GetDescendants()) do if p:IsA("BasePart") and p.CanCollide then ncTouched[p]=true; p.CanCollide=false end end
        end)
    else
        for p in pairs(ncTouched) do if p.Parent then pcall(function() p.CanCollide=true end) end end
        ncTouched={}
    end
end

--========================================================
-- FPS (unlock + counter)
--========================================================
local FPS={Enabled=false,Target=10000,Current=0}
local originalFpsCap=nil
local function applyFpsCap(cap) if type(setfpscap)=="function" then pcall(setfpscap,cap) end FPS.Current=cap end
local function enableFps()
    if type(getfpscap)=="function" then local ok,cur=pcall(getfpscap); if ok then originalFpsCap=cur end end
    applyFpsCap(FPS.Target); notify("FPS unlocked to "..FPS.Target)
end
local function disableFps()
    if originalFpsCap then applyFpsCap(originalFpsCap) else applyFpsCap(60) end
    notify("FPS restored")
end
local fpsGui=Instance.new("ScreenGui"); fpsGui.Name="luxxsFPS"; fpsGui.ResetOnSpawn=false; fpsGui.IgnoreGuiInset=true; fpsGui.DisplayOrder=100; fpsGui.Parent=parent
local fpsFrame=Instance.new("Frame"); fpsFrame.AnchorPoint=Vector2.new(1,0); fpsFrame.Position=UDim2.new(1,-12,0,12); fpsFrame.Size=UDim2.new(0,84,0,24); fpsFrame.BackgroundColor3=C.bg; fpsFrame.BackgroundTransparency=0.1; fpsFrame.BorderSizePixel=0; fpsFrame.Visible=true; fpsFrame.ZIndex=5; fpsFrame.Parent=fpsGui
stroke(fpsFrame,C.line,1,0)
local fpsBar=Instance.new("Frame"); fpsBar.Size=UDim2.new(0,2,1,0); fpsBar.BorderSizePixel=0; fpsBar.ZIndex=6; fpsBar.Parent=fpsFrame; T(fpsBar,"BackgroundColor3")
local fpsNum=Instance.new("TextLabel"); fpsNum.BackgroundTransparency=1; fpsNum.Position=UDim2.new(0,10,0,0); fpsNum.Size=UDim2.new(1,-12,1,0); fpsNum.Font=F_MONO; fpsNum.TextSize=12; fpsNum.TextColor3=C.text; fpsNum.TextXAlignment=Enum.TextXAlignment.Left; fpsNum.Text="0 FPS"; fpsNum.ZIndex=6; fpsNum.Parent=fpsFrame
local FpsCounter={Avg=0,Max=0,Frames=0,Last=tick()}
task.spawn(function()
    while fpsGui.Parent do
        RunService.RenderStepped:Wait()
        FpsCounter.Frames+=1
        local elapsed=tick()-FpsCounter.Last
        if elapsed>=0.25 then
            local fps=math.floor(FpsCounter.Frames/elapsed+0.5)
            FpsCounter.Frames=0; FpsCounter.Last=tick()
            FpsCounter.Avg=FpsCounter.Avg==0 and fps or (FpsCounter.Avg*0.9+fps*0.1)
            if fps>FpsCounter.Max then FpsCounter.Max=fps end
            fpsNum.Text=tostring(fps).." FPS"
            fpsNum.TextColor3=fps>=60 and C.text or (fps>=30 and Color3.fromRGB(255,190,70) or Color3.fromRGB(255,84,84))
        end
    end
end)
makeDraggable(fpsFrame,fpsFrame)

--========================================================
-- SKIN CHANGER (visual only)
--========================================================
local MM2_SKINS={
    "Laser","Amerilaser","Icepiercer","Gemstone","Chroma Laser","Chroma Seer","Chroma Lightbringer","Chroma Darkbringer",
    "Elderwood Revolver","Elderwood Scythe","Elderwood Blade","Batwing","Pixel","Corrupt","Hallowscythe","Hallows Edge",
    "Candleflame","Green Luger","Red Luger","Ghostblade","Vampire's Edge","Ice Dragon","Fire Bat","Snow Dagger",
    "Snowflake","Sweet Tooth","Virtual","BattleAxe","BattleAxe II","Phaser","Nebula","Ocean","Spider","Bioblade",
    "Fang","Handsaw","Prince of Persia","Nightblade","Logchopper","Gingerblade","Peppermint","Icebeam","Snowball",
    "Plasma Beam","Blizzard","Saw","Prismatic","Heartblade","Cotton Candy","Candy","Splash","Chroma Fang",
    "Bat","Cookieblade","Pumpking","Luger","Prince of Persia","Ripper","Snowman","Gingerbread","Minty",
    "Reaver","BattleAxe III","Alien","Tides","Waves","Bloom","Sunrise","Eternal","Elderwood Scythe II",
    "Traveler's Gun","Prismatic","Clockwork","Gemstone","Makeshift","Laser","Phaser"
}
local Skin={Enabled=false,Selected="Laser",Color=Color3.fromRGB(255,215,0),Accent=Color3.fromRGB(180,140,255),Conn=nil,Model=nil}
local function destroySkinModel()
    if Skin.Model then pcall(function() Skin.Model:Destroy() end); Skin.Model=nil end
    if Skin.Conn then Skin.Conn:Disconnect(); Skin.Conn=nil end
end
local function buildSkinModel()
    destroySkinModel()
    local char=LP.Character; local hrp=char and char:FindFirstChild("HumanoidRootPart"); if not hrp then return end
    local model=Instance.new("Model"); model.Name="luxxsSkin"
    -- create a floating weapon replica above shoulder
    local handle=Instance.new("Part"); handle.Size=Vector3.new(0.4,0.4,3); handle.Material=Enum.Material.Neon; handle.CanCollide=false; handle.Massless=true; handle.Anchored=false
    handle.Color=Skin.Color
    local weld=Instance.new("Weld"); weld.Part0=hrp; weld.Part1=handle; weld.C0=CFrame.new(1.6,0.4,-0.4)*CFrame.Angles(math.rad(90),0,0); weld.Parent=handle
    handle.Parent=model
    local blade=Instance.new("Part"); blade.Size=Vector3.new(0.1,0.9,1.6); blade.Material=Enum.Material.Neon; blade.CanCollide=false; blade.Massless=true; blade.Anchored=false
    blade.Color=Skin.Accent
    local weld2=Instance.new("Weld"); weld2.Part0=hrp; weld2.Part1=blade; weld2.C0=CFrame.new(1.6,0.4,-2)*CFrame.Angles(math.rad(90),0,0); weld2.Parent=blade
    blade.Parent=model
    -- label
    local bb=Instance.new("BillboardGui"); bb.Size=UDim2.new(0,160,0,24); bb.StudsOffset=Vector3.new(0,2,0); bb.AlwaysOnTop=true; bb.Adornee=handle; bb.Parent=model
    local lbl=Instance.new("TextLabel"); lbl.BackgroundTransparency=1; lbl.Size=UDim2.new(1,0,1,0); lbl.Font=F_MONO; lbl.TextSize=13; lbl.TextStrokeTransparency=0.4; lbl.TextStrokeColor3=Color3.new(0,0,0); lbl.Text=Skin.Selected; lbl.TextColor3=Skin.Color; lbl.Parent=bb
    model.Parent=char
    Skin.Model=model
    Skin.Conn=RunService.Heartbeat:Connect(function()
        local t=os.clock()
        local h,s,v=Color3.toHSV(Skin.Color)
        handle.Color=Color3.fromHSV((h+t*0.05)%1,s,v)
    end)
end

--========================================================
-- TABS
--========================================================
local visTab=createTab("Visuals")
visTab:Label("ESP")
visTab:Toggle("ESP Box",false)
visTab:Toggle("Role",false)
visTab:Toggle("Color by Role",false)
visTab:Toggle("Name",false)
visTab:Toggle("Health",false)
visTab:Toggle("Distance",false)
visTab:Toggle("Tracers",false)
visTab:Toggle("Skeleton",false)
visTab:Toggle("Chams",false)
visTab:Toggle("Glow",false)
visTab:Choice("ESP Color",COLOR_NAMES,"Lime")
visTab:Choice("Shade",SHADE_NAMES,"Normal")
visTab:Label("Cosmetics")
visTab:Toggle("Wings",false,function(s) if s then buildWings() else destroyCos("wings") end end)
visTab:Choice("Wing Color",WING_COLORS,"White")
visTab:Slider("Wing Speed",1,10,3)
visTab:Toggle("Chinese Hat",false,function(s) if s then buildHat() else destroyCos("hat") end end)
visTab:Choice("Hat Color",COLOR_NAMES,"Rainbow")
visTab:Choice("Hat Shade",SHADE_NAMES,"Normal")
visTab:Toggle("Trail",false,function(s) if s then buildTrail() else destroyCos("trail") end end)
visTab:Choice("Trail Color",COLOR_NAMES,"Rainbow")
visTab:Slider("Trail Length",1,30,10)
visTab:Slider("Trail Width",1,10,4)

local aimTab=createTab("Aimbot")
aimTab:Toggle("Enable",false)
aimTab:Toggle("Skip Innocents",true)
aimTab:Toggle("Weapon Only",true)
aimTab:Toggle("Wall Check",true)
aimTab:Choice("Body Part",{"Head","Chest","Stomach","Left Arm","Right Arm","Left Leg","Right Leg"},"Head")
aimTab:Slider("FOV",10,360,120)
aimTab:Slider("Smoothness",1,100,30)
aimTab:Toggle("Show FOV",false)

local moveTab=createTab("Move")
moveTab:Label("Fly")
moveTab:Toggle("Fly",false,function(s)
    Move.Fly=s
    if s then enableFlyMove() else disableFlyMove() end
    notify(s and "Fly ON" or "Fly OFF")
end)
moveTab:Slider("Fly Speed",10,500,80,function(v) Move.Speed=v end)
moveTab:Toggle("Noclip",false,function(s) Move.Noclip=s; setNoclipMove(s); notify(s and "Noclip ON" or "Noclip OFF") end)
moveTab:Label("Spin")
moveTab:Toggle("Spin",false,function(s) Spin.Enabled=s; if s then startSpin() else stopSpin() end; notify(s and "Spin ON" or "Spin OFF") end)
moveTab:Slider("Spin Speed",10,1000,200,function(v) Spin.Speed=v end)
moveTab:Label("Teleport to player")
local tpList={}
for _,p in ipairs(Players:GetPlayers()) do if p~=LP then tpList[#tpList+1]=p.Name end end
local tpChoice=moveTab:Choice("Target",#tpList>0 and tpList or {"—"},"—")
moveTab:Button("Teleport",function()
    local targetName=Flags["Move/Target"]
    local plr=Players:FindFirstChild(targetName)
    if plr then teleportToPlayer(plr); notify("Teleported to "..targetName)
    else notify("Player not found") end
end)
Players.PlayerAdded:Connect(function() end)

local awTab=createTab("Auto-Win")
awTab:Label("Auto-kill")
awTab:Toggle("Enable Auto-Win",false,function(s) AutoWin.Enabled=s; notify(s and "Auto-Win ON" or "Auto-Win OFF") end)
awTab:Toggle("Auto (Sheriff → Murderer, Murderer → all)",true)
awTab:Label2("When Sheriff: teleports to murderer and fires.",F_MONO,10,C.dim)
awTab:Label2("When Murderer: teleports to every player and kills.",F_MONO,10,C.dim)
awTab:Button("Teleport to Murderer",function()
    local m=getMurderer(); if m then teleportToPlayer(m); notify("Teleported to murderer") else notify("No murderer") end
end)

local farmTab=createTab("Farm")
farmTab:Label("Coin farm")
farmTab:Toggle("Enable Farm",false,function(state)
    Farm.Enabled=state
    if state then startFarm(); if Farm.Mode=="Fly" then enableFarmFly() end; notify("Farm ON ("..Farm.Mode..")")
    else stopFarm(); notify("Farm OFF") end
end)
farmTab:Choice("Mode",{"Legit","Smooth","Teleport","Fly"},"Legit",function(v)
    Farm.Mode=v
    if Farm.Enabled then disableFarmFly(); if v=="Fly" then enableFarmFly() end end
end)
farmTab:Slider("Speed",10,200,60,function(v) Farm.Speed=v end)
farmTab:Slider("Teleport Delay (x10ms)",1,50,35,function(v) Farm.TeleportDelay=v/100 end)
farmTab:Toggle("Anti-AFK",false,function(state) setAntiAFK(state) end)
farmTab:Toggle("Return to Start",false,function(state) Farm.ReturnOnFinish=state end)
farmTab:Button("Reset Counter",function() Farm.Collected=0; notify("Counter reset") end)
farmTab:Button("Show Status",function() notify("Collected: "..Farm.Collected.." | "..Farm.Status) end)

local skinTab=createTab("Skins")
skinTab:Label("MM2 Skin Changer (visual)")
skinTab:Toggle("Enable Skin",false,function(s)
    Skin.Enabled=s
    if s then buildSkinModel() else destroySkinModel() end
    notify(s and ("Skin: "..Skin.Selected) or "Skin OFF")
end)
skinTab:Choice("Skin",MM2_SKINS,"Laser",function(v) Skin.Selected=v; if Skin.Enabled then buildSkinModel() end end)
skinTab:Label("Colors")

local fpsTab=createTab("FPS")
fpsTab:Toggle("Enable Unlock",false,function(state) FPS.Enabled=state; if state then enableFps() else disableFps() end end)
fpsTab:Slider("Target FPS",60,10000,10000,function(v) FPS.Target=v; if FPS.Enabled then applyFpsCap(v) end end)
fpsTab:Button("60 FPS",function() Setters["FPS/Target FPS"](60) end)
fpsTab:Button("120 FPS",function() Setters["FPS/Target FPS"](120) end)
fpsTab:Button("240 FPS",function() Setters["FPS/Target FPS"](240) end)
fpsTab:Button("1000 FPS",function() Setters["FPS/Target FPS"](1000) end)
fpsTab:Input("Custom FPS","240",function(txt,tb)
    local n=tonumber(txt); if not n or n<1 then notify("Invalid") ; tb.Text=tostring(FPS.Target); return end
    n=math.floor(math.clamp(n,1,100000))
    FPS.Target=n
    if not FPS.Enabled then Setters["FPS/Enable Unlock"](true) else applyFpsCap(n); notify("FPS cap: "..n) end
    tb.Text=tostring(n)
end)
fpsTab:Toggle("Show Counter",true,function(state) fpsFrame.Visible=state end)
fpsTab:Button("Reset Stats",function() FpsCounter.Max=0; FpsCounter.Avg=0 end)

local shTab=createTab("Shaders")
shTab:Choice("Preset",PRESET_NAMES,"Off",function() refreshShader(0.9) end)
shTab:Slider("Brightness",-50,50,0,function() refreshShader(0.15) end)
shTab:Slider("Contrast",-50,50,0,function() refreshShader(0.15) end)
shTab:Slider("Saturation",-100,100,0,function() refreshShader(0.15) end)
shTab:Slider("Bloom",0,100,0,function() refreshShader(0.15) end)
shTab:Button("Reset Shaders",function()
    Setters["Shaders/Preset"]("Off"); Setters["Shaders/Brightness"](0); Setters["Shaders/Contrast"](0); Setters["Shaders/Saturation"](0); Setters["Shaders/Bloom"](0)
end)

-- PROFILE TAB (with avatar)
local profileTab=createTab("Profile")
profileTab:Label("Player")
-- avatar container
local profHolder=Instance.new("Frame"); profHolder.Size=UDim2.new(1,0,0,90); profHolder.BackgroundTransparency=1; profHolder.Parent=profileTab.scroll
local avatar=Instance.new("ImageLabel"); avatar.Position=UDim2.new(0,10,0,6); avatar.Size=UDim2.new(0,72,0,72); avatar.BackgroundColor3=C.bg; avatar.BorderSizePixel=0; avatar.Image=""; avatar.Parent=profHolder; corner(avatar,6); stroke(avatar,C.line,1,0)
local profUser=Instance.new("TextLabel"); profUser.BackgroundTransparency=1; profUser.Position=UDim2.new(0,92,0,10); profUser.Size=UDim2.new(1,-100,0,20); profUser.Font=F_MONO; profUser.TextSize=14; profUser.TextColor3=C.text; profUser.TextXAlignment=Enum.TextXAlignment.Left; profUser.Text=LP.Name; profUser.Parent=profHolder
local profRole=Instance.new("TextLabel"); profRole.BackgroundTransparency=1; profRole.Position=UDim2.new(0,92,0,32); profRole.Size=UDim2.new(1,-100,0,18); profRole.Font=F_MONO; profRole.TextSize=12; profRole.TextColor3=C.dim; profRole.TextXAlignment=Enum.TextXAlignment.Left; profRole.Text="ROLE      Innocent"; profRole.Parent=profHolder
local profSkin=Instance.new("TextLabel"); profSkin.BackgroundTransparency=1; profSkin.Position=UDim2.new(0,92,0,50); profSkin.Size=UDim2.new(1,-100,0,18); profSkin.Font=F_MONO; profSkin.TextSize=12; profSkin.TextColor3=C.dim; profSkin.TextXAlignment=Enum.TextXAlignment.Left; profSkin.Text="SKIN      —"; profSkin.Parent=profHolder
local profSession=profileTab:Label2("SESSION   00:00:00",F_MONO,12,C.dim)
local profCoins=profileTab:Label2("COINS     0",F_MONO,12,C.dim)
local profFps=profileTab:Label2("FPS       0 | avg 0 | max 0",F_MONO,12,C.dim)
local profKeys=profileTab:Label2("KEYS      —",F_MONO,11,C.dim)
profileTab:Button("Refresh Profile",function()
    local uid=LP.UserId
    local ok,url=pcall(function() return Players:GetUserThumbnailAsync(uid,Enum.ThumbnailType.HeadShot,Enum.ThumbnailSize.Size100x100) end)
    if ok and url then avatar.Image=url end
    profUser.Text=LP.Name
    profRole.Text="ROLE      "..getRole(LP)
    profSkin.Text="SKIN      "..(Skin.Enabled and Skin.Selected or "—")
    profCoins.Text="COINS     "..Farm.Collected
    local lines={}
    for _,cfg in ipairs(KEYS) do lines[#lines+1]=keyInfoLine(cfg.name) end
    profKeys.Text=table.concat(lines,"\n")
    notify("Profile refreshed")
end)
profileTab:Button("Reset All Stats",function() FpsCounter.Max=0; FpsCounter.Avg=0; Farm.Collected=0; notify("Stats reset") end)

-- INFO tab (keys details)
local infoTab=createTab("INFO")
infoTab:Label("Key Activation Status")
local infoKeys=infoTab:Label2("—",F_MONO,12,C.text)
local infoCycle=infoTab:Label2("Cycle: auto-resets when all keys expire",F_MONO,10,C.dim)
infoTab:Button("Refresh Keys",function()
    local lines={}
    for _,cfg in ipairs(KEYS) do
        local entry=keyState[cfg.name]
        local status
        if not entry then status="NOT ACTIVATED (duration "..cfg.days.."d)"
        else
            local now=os.time(); local exp=entry.activated+cfg.secs
            if now>=exp then status="EXPIRED"
            else
                local rem=exp-now
                status=string.format("%dd %dh %dm left",math.floor(rem/86400),math.floor((rem%86400)/3600),math.floor((rem%3600)/60))
            end
        end
        lines[#lines+1]=cfg.name.."  →  "..status
    end
    infoKeys.Text=table.concat(lines,"\n")
end)
infoTab:Button("Force Cycle Check",function()
    local cycled=checkKeyCycle()
    notify(cycled and "Keys cycled — re-enter any key" or "Cycle not needed")
end)

-- SETTINGS
local setTab=createTab("Settings")
local SLOTS={"1","2","3","4","5"}
local function cfgPath(s) return FOLDER.."/config_"..s..".json" end
local function isSettingsKey(k) return k:sub(1,9)=="Settings/" end
local function saveConfig(slot)
    if not hasFS then notify("FS unavailable") return end
    ensureFolder(); local data={}
    for k,v in pairs(Flags) do if not isSettingsKey(k) then data[k]=v end end
    local ok=pcall(function() writefile(cfgPath(slot),HttpService:JSONEncode(data)) end)
    notify(ok and ("Saved slot "..slot) or "Save error")
end
local function loadConfig(slot,silent)
    if not hasFS then if not silent then notify("FS unavailable") end return end
    local p=cfgPath(slot); if not isfile(p) then if not silent then notify("Slot empty") end return end
    local ok,data=pcall(function() return HttpService:JSONDecode(readfile(p)) end)
    if not ok or type(data)~="table" then notify("Read error") return end
    for k,v in pairs(data) do if Setters[k] and not isSettingsKey(k) then Setters[k](v) end end
    notify("Loaded slot "..slot)
end
local function resetAll()
    for k,d in pairs(Defaults) do if not isSettingsKey(k) and Setters[k] then Setters[k](d) end end
    notify("Settings reset")
end
local function unload()
    for _,c in ipairs(connections) do pcall(function() c:Disconnect() end) end
    destroyCos("wings"); destroyCos("hat"); destroyCos("trail")
    destroySkinModel()
    for plr in pairs(espData) do removeESP(plr) end
    pcall(disableFlyMove); pcall(setNoclipMove,false); stopFarm(); stopSpin()
    disableShader(true); disableFps(); gui:Destroy(); fpsGui:Destroy()
end
setTab:Label("Interface")
setTab:Choice("Accent",ACCENT_NAMES,ACC_NAME,function(n) setAccent(ACCENTS[n]); restyleTabs(); if hasFS then ensureFolder(); pcall(function() writefile(FOLDER.."/accent.txt",n) end) end end)
setTab:Choice("Global Shade",SHADE_NAMES,"Normal")
setTab:Label("Configs")
setTab:Choice("Config Slot",SLOTS,"1")
setTab:Button("Save Config",function() saveConfig(Flags["Settings/Config Slot"]) end)
setTab:Button("Load Config",function() loadConfig(Flags["Settings/Config Slot"]) end)
setTab:Button("Reset All",resetAll)
setTab:Label("Menu")
setTab:Button("Close Menu",function() closeMenu() end)
setTab:Button("Unload luxxs",unload)

--========================================================
-- Menu open/close (needed before buttons use it)
--========================================================
local isOpen,busy=false,false
local function fitScale() local cam=workspace.CurrentCamera; local vp=cam and cam.ViewportSize or Vector2.new(1280,720); return math.min(1,(vp.X-20)/W,(vp.Y-20)/H) end
function openMenu()
    if busy or isOpen then return end
    busy=true; isOpen=true; main.Visible=true
    local fit=fitScale(); scale.Scale=fit*0.94; main.GroupTransparency=1
    tween(scale,0.35,{Scale=fit}); tween(main,0.3,{GroupTransparency=0})
    task.delay(0.35,function() busy=false end)
end
function closeMenu()
    if busy or not isOpen then return end
    busy=true; isOpen=false
    tween(scale,0.25,{Scale=fitScale()*0.94},Enum.EasingStyle.Quint,Enum.EasingDirection.In); tween(main,0.25,{GroupTransparency=1},Enum.EasingStyle.Quint,Enum.EasingDirection.In)
    task.delay(0.26,function() main.Visible=false; busy=false end)
end
local function toggleMenu() if isOpen then closeMenu() else openMenu() end end

closeBtn.MouseButton1Click:Connect(closeMenu)
closeBtn.MouseEnter:Connect(function() tween(closeBtn,0.12,{BackgroundColor3=Color3.fromRGB(190,56,56)}); closeBtn.TextColor3=WHITE end)
closeBtn.MouseLeave:Connect(function() tween(closeBtn,0.12,{BackgroundColor3=C.row}); closeBtn.TextColor3=C.dim end)

-- floating icon
local icon=Instance.new("TextButton"); icon.Size=UDim2.new(0,50,0,50); icon.Position=UDim2.new(0,24,0.5,-25); icon.BackgroundColor3=C.bg; icon.BorderSizePixel=0; icon.AutoButtonColor=false; icon.Text="LX"; icon.Font=F_HEAD; icon.TextSize=14; icon.TextColor3=C.text; icon.ZIndex=5; icon.Parent=gui
local iconStroke=stroke(icon,ACC,1.5,0); T(iconStroke,"Color")
task.spawn(function() while gui.Parent do tween(iconStroke,1.3,{Transparency=0.65},Enum.EasingStyle.Sine,Enum.EasingDirection.InOut); task.wait(1.3); tween(iconStroke,1.3,{Transparency=0},Enum.EasingStyle.Sine,Enum.EasingDirection.InOut); task.wait(1.3) end end)
icon.MouseEnter:Connect(function() tween(icon,0.15,{TextColor3=ACC}) end)
icon.MouseLeave:Connect(function() tween(icon,0.15,{TextColor3=C.text}) end)
makeDraggable(icon,icon,toggleMenu)
makeDraggable(top,main)
track(UIS.InputBegan:Connect(function(input,processed) if not processed and input.KeyCode==Enum.KeyCode.RightShift then toggleMenu() end end))

--========================================================
-- Update footer / profile with key info
--========================================================
task.spawn(function()
    local startTick=tick()
    while gui.Parent do
        task.wait(1)
        local s=math.floor(tick()-startTick)
        local hh=math.floor(s/3600); local mm=math.floor((s%3600)/60); local ss=s%60
        local role=getRoleCached(LP)
        profSession.Text=string.format("SESSION   %02d:%02d:%02d",hh,mm,ss)
        profRole.Text="ROLE      "..role
        profCoins.Text="COINS     "..Farm.Collected
        profFps.Text="FPS       "..(FPS.Current or 0).." | avg "..math.floor(FpsCounter.Avg).." | max "..FpsCounter.Max
        local lines={}
        for _,cfg in ipairs(KEYS) do lines[#lines+1]=keyInfoLine(cfg.name) end
        profKeys.Text=table.concat(lines,"\n")
        footR.Text="ROLE  "..string.upper(role)
        footR.TextColor3=(role~="Innocent") and (ROLE_COLORS[role] or C.dim) or C.dim
        -- cycle keys if all expired
        checkKeyCycle()
    end
end)

-- autoload
if hasFS then
    pcall(function()
        local p=FOLDER.."/autoload.txt"
        if isfile(p) then local slot=readfile(p)
            if slot~="" and table.find(SLOTS,slot) then Setters["Settings/Config Slot"](slot); loadConfig(slot,true) end
        end
    end)
end

--========================================================
-- Preload profile avatar
--========================================================
task.spawn(function()
    local uid=LP.UserId
    local ok,url=pcall(function() return Players:GetUserThumbnailAsync(uid,Enum.ThumbnailType.HeadShot,Enum.ThumbnailSize.Size100x100) end)
    if ok and url then avatar.Image=url end
    infoKeys.Text=(function()
        local l={} for _,cfg in ipairs(KEYS) do l[#l+1]=cfg.name.."  →  "..keyInfoLine(cfg.name) end return table.concat(l,"\n")
    end)()
end)

notify("Key accepted // RightShift or LX icon")
