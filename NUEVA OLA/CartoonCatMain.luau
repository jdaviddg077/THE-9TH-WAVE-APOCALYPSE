--[[ 
	Script de IA: Jeff The Killer
	Original por: Brutez
	Optimizado y Refactorizado para Luau
--]]

local workspace = game:GetService("Workspace")
local players = game:GetService("Players")

local jeffModel = script.Parent

-- Esperar a que el modelo cargue correctamente sus partes críticas
repeat task.wait() until jeffModel 
	and jeffModel:FindFirstChild("Head") 
	and jeffModel:FindFirstChild("HumanoidRootPart")

local humanoid = jeffModel:WaitForChild("Humanoid")
local rootPart = jeffModel:WaitForChild("HumanoidRootPart")
local head = jeffModel:WaitForChild("Head")
local knife = jeffModel:FindFirstChild("Knife")

-- Configuración de parámetros
local NOTICE_DISTANCE = 400
local ATTACK_DISTANCE = 9
local JUMPSCARE_MUSIC_DIST = 50
local LAUGH_DIST = 25

-- Variables de Estado (Debounces)
local attackDebounce = false
local walkDebounce = false
local noticeDebounce = false
local musicDebounce = false
local laughDebounce = false

local chosenMusic = nil

-- Parámetros de Raycast reutilizables
local rayParams = RaycastParams.new()
rayParams.FilterType = Enum.RaycastFilterType.Exclude
rayParams.FilterDescendantsInstances = {jeffModel}

----------------------------------------------------------------
-- FUNCIONES AUXILIARES
----------------------------------------------------------------

local function castRay(origin, direction)
	return workspace:Raycast(origin, direction, rayParams)
end

-- Busca al objetivo vivo más cercano dentro del rango
local function findNearestTarget()
	local closestTarget = nil
	local currentMinDist = NOTICE_DISTANCE

	for _, model in ipairs(workspace:GetChildren()) do
		if model:IsA("Model") and model ~= jeffModel and model.Name ~= jeffModel.Name then
			local targetRoot = model:FindFirstChild("HumanoidRootPart")
			local targetHead = model:FindFirstChild("Head")
			local targetHum = model:FindFirstChildOfClass("Humanoid")

			if targetRoot and targetHead and targetHum and targetHum.Health > 0 then
				local dist = (targetRoot.Position - rootPart.Position).Magnitude
				if dist < currentMinDist then
					-- Comprobar si hay línea de visión clara hacia el objetivo
					local direction = (targetRoot.Position - rootPart.Position)
					local result = castRay(rootPart.Position, direction)

					if result and result.Instance and result.Instance:IsDescendantOf(model) then
						closestTarget = targetRoot
						currentMinDist = dist

						-- Ataque al estar a distancia cuerpo a cuerpo
						if dist < ATTACK_DISTANCE and not attackDebounce then
							task.spawn(function()
								attackDebounce = true

								local swingAnim = jeffModel:FindFirstChild("Swing")
								if swingAnim then
									local track = humanoid:LoadAnimation(swingAnim)
									track:Play()
									track:AdjustSpeed(1.5 + (math.random() * 0.1))
								end

								if knife and knife:FindFirstChild("Swing") then
									knife.Swing.Pitch = 1 + (math.random() * 0.04)
									knife.Swing:Play()
								end

								task.wait(0.3)

								-- Verificar si sigue al alcance tras la animación
								local postDist = (targetRoot.Position - rootPart.Position).Magnitude
								if postDist < 8 and targetHum.Health > 0 then
									targetHum:TakeDamage(5000)

									local hitIndex = math.random(1, 3)
									local hitSound = knife and knife:FindFirstChild("Hit" .. hitIndex)
									if hitSound then
										hitSound.Pitch = 1 + (math.random() * 0.04)
										hitSound:Play()
									end
								end

								task.wait(0.1)
								attackDebounce = false
							end)
						end
					end
				end
			end
		end
	end

	return closestTarget
end

----------------------------------------------------------------
-- PROPIEDADES INICIALES DE HUMANOID
----------------------------------------------------------------
humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
humanoid.HealthDisplayDistance = 0
humanoid.NameDisplayDistance = 0
humanoid.NameOcclusion = Enum.NameOcclusion.EnemyOcclusion
humanoid.AutoJumpEnabled = true
humanoid.AutoRotate = true
humanoid.MaxHealth = 1300
humanoid.Health = 1300
humanoid.JumpPower = 60
humanoid.MaxSlopeAngle = 89.9

----------------------------------------------------------------
-- BUCLE PRINCIPAL (AI LOOP)
----------------------------------------------------------------
while task.wait(0.1) do
	if humanoid.Health <= 0 then break end

	-- Asegurar que estados no deseados se desactiven
	if humanoid.Sit then humanoid.Sit = false end
	if humanoid.PlatformStand then humanoid.PlatformStand = false end

	-- 1. Verificación de obstáculos para saltar automáticamente
	local lookDirection = rootPart.CFrame.LookVector * (rootPart.Size.Z * 2.5)
	local obstacleResult = castRay(rootPart.Position, lookDirection)

	if obstacleResult and obstacleResult.Instance then
		local hitInst = obstacleResult.Instance
		local hitModel = hitInst:FindFirstAncestorOfClass("Model")
		local hitHum = hitModel and hitModel:FindFirstChildOfClass("Humanoid")

		-- Saltar solo si es una pared/bloque estático y no otro jugador o terreno líquido
		if not hitHum and not hitInst:IsA("TrussPart") and not hitInst:IsA("WedgePart") then
			humanoid.Jump = true
		end
	end

	-- 2. Reproducción de Sonido de Pasos
	local horizontalVelocity = Vector3.new(rootPart.Velocity.X, 0, rootPart.Velocity.Z).Magnitude
	if horizontalVelocity >= 5 and not walkDebounce then
		task.spawn(function()
			walkDebounce = true

			-- Verificar si está tocando el suelo
			local floorRay = castRay(rootPart.Position, Vector3.new(0, -4, 0))
			if floorRay then
				local stepSound = head:FindFirstChild("Jeff_Step")
				if stepSound then
					local cloneStep = stepSound:Clone()
					cloneStep.Parent = head
					cloneStep:Play()
					game:GetService("Debris"):AddItem(cloneStep, 1)
				end

				task.wait(humanoid.WalkSpeed > 17 and 0.2 or 0.5)
			end

			walkDebounce = false
		end)
	end

	-- 3. Búsqueda y Persecución de Objetivo
	local targetPart = findNearestTarget()
	local targetHum = targetPart and targetPart.Parent:FindFirstChildOfClass("Humanoid")

	if targetPart and targetHum and targetHum.Health > 0 then
		local distToTarget = (targetPart.Position - rootPart.Position).Magnitude

		-- Si el jugador salta, Jeff también salta
		if targetHum.Jump then
			humanoid.Jump = true
		end

		-- Sonido de susto inicial al detectar
		local sustoSound = head:FindFirstChild("Jeff_Susto2")
		if sustoSound and not noticeDebounce then
			sustoSound:Play()
			noticeDebounce = true
		end

		-- Ajustar velocidad de persecución
		if distToTarget > 5 then
			humanoid.WalkSpeed = 40.5
		else
			humanoid.WalkSpeed = 0.004
		end

		humanoid:MoveTo(targetPart.Position + (targetPart.Position - rootPart.Position).Unit * 2)

		-- Risa macabra cercana
		local laughSound = head:FindFirstChild("Jeff_Laugh")
		if laughSound then
			if distToTarget < LAUGH_DIST then
				if not laughSound.IsPlaying then
					laughSound.Volume = 1
					laughSound:Play()
				end
			elseif laughSound.IsPlaying and not laughDebounce then
				task.spawn(function()
					laughDebounce = true
					while laughSound.Volume > 0 do
						laughSound.Volume = math.max(0, laughSound.Volume - 0.1)
						task.wait(0.05)
					end
					laughSound:Stop()
					laughDebounce = false
				end)
			end
		end

		-- Música de Tensión / Persecución
		if distToTarget < JUMPSCARE_MUSIC_DIST then
			if not chosenMusic then
				local musicIndex = math.random(1, 2)
				chosenMusic = jeffModel:FindFirstChild("Jeff_Scene_Sound" .. musicIndex)
			end

			if chosenMusic and not chosenMusic.IsPlaying then
				chosenMusic.Volume = 0.5
				chosenMusic:Play()
			end
		elseif chosenMusic and chosenMusic.IsPlaying and not musicDebounce then
			task.spawn(function()
				musicDebounce = true
				while chosenMusic and chosenMusic.Volume > 0 do
					chosenMusic.Volume = math.max(0, chosenMusic.Volume - 0.01)
					task.wait(0.05)
				end
				if chosenMusic then
					chosenMusic:Stop()
				end
				chosenMusic = nil
				musicDebounce = false
			end)
		end

	else
		-- Resetear variables cuando no hay objetivo a la vista
		noticeDebounce = false

		-- Apagar Risa progresivamente
		local laughSound = head:FindFirstChild("Jeff_Laugh")
		if laughSound and laughSound.IsPlaying and not laughDebounce then
			task.spawn(function()
				laughDebounce = true
				while laughSound.Volume > 0 do
					laughSound.Volume = math.max(0, laughSound.Volume - 0.1)
					task.wait(0.05)
				end
				laughSound:Stop()
				laughDebounce = false
			end)
		end

		-- Apagar Música progresivamente
		if chosenMusic and chosenMusic.IsPlaying and not musicDebounce then
			task.spawn(function()
				musicDebounce = true
				while chosenMusic and chosenMusic.Volume > 0 do
					chosenMusic.Volume = math.max(0, chosenMusic.Volume - 0.01)
					task.wait(0.05)
				end
				if chosenMusic then
					chosenMusic:Stop()
				end
				chosenMusic = nil
				musicDebounce = false
			end)
		end

		-- Movimiento Aleatorio (Patrulla)
		humanoid.WalkSpeed = 12
		if math.random(1, 150) == 1 then
			local randomPos = Vector3.new(math.random(-500, 500), 0, math.random(-500, 500))
			humanoid:MoveTo(rootPart.Position + randomPos)
		end
	end
end