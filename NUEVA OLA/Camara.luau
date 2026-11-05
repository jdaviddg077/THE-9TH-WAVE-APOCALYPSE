--AGAIN DO NOT MESS WITH ANYTHING UNLESS YOU KNOW WHAT YOU'RE DOING
-- wat3r_l3g3nds
repeat wait() until game:GetService("Players").LocalPlayer.Character ~= nil
local runService = game:GetService("RunService")
local input = game:GetService("UserInputService")
local players = game:GetService("Players")

CanToggleMouse = {allowed = true; activationkey = Enum.KeyCode.F;} 
CanViewBody = false 		
Sensitivity = 0.6		
Smoothness = 0.05		
FieldOfView = 90		

local cam = game.Workspace.CurrentCamera
local player = players.LocalPlayer
local m = player:GetMouse()
m.Icon = "http://www.roblox.com/asset/?id=569021388" -- replaces mouse icon
local character = player.Character or player.CharacterAdded:wait()
local humanoidpart = character.HumanoidRootPart

local head = character:WaitForChild("Head")
local CamPos,TargetCamPos = cam.CoordinateFrame.p,cam.CoordinateFrame.p 
local AngleX,TargetAngleX = 0,0
local AngleY,TargetAngleY = 0,0

local running = true
local freemouse = false

---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- 

---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- 

input.InputChanged:connect(function(inputObject)
	
	if inputObject.UserInputType == Enum.UserInputType.MouseMovement then
		local delta = Vector2.new(inputObject.Delta.x/Sensitivity,inputObject.Delta.y/Sensitivity) * Smoothness

		local X = TargetAngleX - delta.y 
		TargetAngleX = (X >= 80 and 80) or (X <= -80 and -80) or X 
		TargetAngleY = (TargetAngleY - delta.x) %360 
	end	
	
end)

input.InputBegan:connect(function(inputObject)
	
	if inputObject.UserInputType == Enum.UserInputType.Keyboard then
		if inputObject.KeyCode == CanToggleMouse.activationkey then
			if CanToggleMouse.allowed and freemouse == false then
				freemouse = true
			else
				freemouse = false
			end
		end
	end
	
end)

---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- 
-- Guardamos la conexión para limpiarla si el jugador muere
local cameraConnection

cameraConnection = runService.RenderStepped:Connect(function()
	if running then
		-- 1. Verificación segura de updatechar
		if typeof(updatechar) == "function" then
			updatechar()
		end

		-- 2. Interpolación de posición y ángulo X
		CamPos = CamPos + (TargetCamPos - CamPos) * 0.28
		AngleX = AngleX + (TargetAngleX - AngleX) * 0.35

		-- 3. Manejo de ángulo Y sin división por cero (evita que dist sea 0)
		local dist = TargetAngleY - AngleY
		if math.abs(dist) > 0.001 then
			if math.abs(dist) > 180 then
				dist = dist - (dist / math.abs(dist)) * 360
			end
		else
			dist = 0
		end

		AngleY = (AngleY + dist * 0.35) % 360
		cam.CameraType = Enum.CameraType.Scriptable

		-- 4. Verificación de existencia de Head y HumanoidRootPart antes de mover la cámara
		if head and humanoidpart then
			cam.CFrame = CFrame.new(head.Position)
				* CFrame.Angles(0, math.rad(AngleY), 0)
				* CFrame.Angles(math.rad(AngleX), 0, 0)
				* CFrame.new(0, 0.5, 0) -- offset

			humanoidpart.CFrame = CFrame.new(humanoidpart.Position) * CFrame.Angles(0, math.rad(AngleY), 0)
		end
	else
		game:GetService("UserInputService").MouseBehavior = Enum.MouseBehavior.Default
	end
end)

	if (cam.Focus.p-cam.CoordinateFrame.p).magnitude < 1 then
		running = false
	else
		running = true
		if freemouse == true then
			game:GetService("UserInputService").MouseBehavior = Enum.MouseBehavior.Default
		else
			game:GetService("UserInputService").MouseBehavior = Enum.MouseBehavior.LockCenter
		end
	end
	
	if not CanToggleMouse.allowed then
		freemouse = false
	end
	
	cam.FieldOfView = FieldOfView
end)



---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- 