local L0_1, L1_1, L2_1, L3_1, L4_1, L5_1, L6_1
L0_1 = nil
L1_1 = {}
L2_1 = {}
L3_1 = lib
L3_1 = L3_1.callback
L3_1 = L3_1.register
L4_1 = "lunar_unijob:getCollectables"
function L5_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2
  L1_2 = L2_1
  L1_2 = L1_2[A0_2]
  if L1_2 then
    return
  end
  L1_2 = L2_1
  L1_2[A0_2] = true
  L1_2 = {}
  L2_2 = pairs
  L3_2 = L1_1
  L2_2, L3_2, L4_2, L5_2 = L2_2(L3_2)
  for L6_2, L7_2 in L2_2, L3_2, L4_2, L5_2 do
    L8_2 = #L1_2
    L8_2 = L8_2 + 1
    L9_2 = {}
    L10_2 = L7_2.spawned
    L9_2.spawned = L10_2
    L10_2 = L7_2.job
    L10_2 = L10_2.name
    L9_2.jobName = L10_2
    L10_2 = L7_2.index
    L9_2.index = L10_2
    L10_2 = L7_2.locationIndex
    L9_2.locationIndex = L10_2
    L1_2[L8_2] = L9_2
  end
  return L1_2
end
L3_1(L4_1, L5_1)
function L3_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2
  L2_2 = 1
  L3_2 = #A1_2
  L4_2 = 1
  for L5_2 = L2_2, L3_2, L4_2 do
    L6_2 = A1_2[L5_2]
    L8_2 = A0_2
    L7_2 = A0_2.canCarryItem
    L9_2 = L6_2.name
    L10_2 = type
    L11_2 = L6_2.count
    L10_2 = L10_2(L11_2)
    if "table" == L10_2 then
      L10_2 = L6_2.count
      L10_2 = L10_2.max
      if L10_2 then
        goto lbl_18
      end
    end
    L10_2 = L6_2.count
    ::lbl_18::
    L7_2 = L7_2(L8_2, L9_2, L10_2)
    if not L7_2 then
      L7_2 = false
      return L7_2
    end
  end
  L2_2 = true
  return L2_2
end
L4_1 = lib
L4_1 = L4_1.callback
L4_1 = L4_1.register
L5_1 = "lunar_unijob:harvestCollectable"
function L6_1(A0_2, A1_2, A2_2)
  local L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2
  L3_2 = L1_1
  L3_2 = L3_2[A1_2]
  L4_2 = Framework
  L4_2 = L4_2.getPlayerFromId
  L5_2 = A0_2
  L4_2 = L4_2(L5_2)
  L5_2 = L3_2.spawned
  L5_2 = L5_2[A2_2]
  if L3_2 and L5_2 and L4_2 then
    L7_2 = A1_2
    L6_2 = A1_2.find
    L9_2 = L4_2
    L8_2 = L4_2.getJob
    L8_2, L9_2 = L8_2(L9_2)
    L6_2 = L6_2(L7_2, L8_2, L9_2)
    if L6_2 then
      L6_2 = L5_2.xy
      L7_2 = GetEntityCoords
      L8_2 = GetPlayerPed
      L9_2 = A0_2
      L8_2, L9_2 = L8_2(L9_2)
      L7_2 = L7_2(L8_2, L9_2)
      L7_2 = L7_2.xy
      L6_2 = L6_2 - L7_2
      L6_2 = #L6_2
      if not (L6_2 > 10.0) then
        L6_2 = L3_1
        L7_2 = L4_2
        L8_2 = L3_2.data
        L8_2 = L8_2.items
        L6_2 = L6_2(L7_2, L8_2)
        if L6_2 then
          goto lbl_41
        end
      end
    end
  end
  do return end
  ::lbl_41::
  L6_2 = SetTimeout
  L7_2 = L3_2.data
  L7_2 = L7_2.duration
  function L8_2()
    local L0_3, L1_3, L2_3, L3_3, L4_3, L5_3, L6_3, L7_3, L8_3, L9_3
    L1_3 = A1_2
    L0_3 = L1_1
    L0_3 = L0_3[L1_3]
    L0_3 = L0_3.spawned
    L1_3 = A2_2
    L0_3 = L0_3[L1_3]
    if L0_3 then
      L0_3 = L3_1
      L1_3 = L4_2
      L2_3 = L3_2.data
      L2_3 = L2_3.items
      L0_3 = L0_3(L1_3, L2_3)
      if L0_3 then
        goto lbl_17
      end
    end
    do return end
    ::lbl_17::
    L1_3 = A1_2
    L0_3 = L1_1
    L0_3 = L0_3[L1_3]
    L0_3 = L0_3.spawned
    L1_3 = A2_2
    L0_3[L1_3] = nil
    L0_3 = 1
    L1_3 = L3_2.data
    L1_3 = L1_3.items
    L1_3 = #L1_3
    L2_3 = 1
    for L3_3 = L0_3, L1_3, L2_3 do
      L4_3 = L3_2.data
      L4_3 = L4_3.items
      L4_3 = L4_3[L3_3]
      L5_3 = type
      L6_3 = L4_3.count
      L5_3 = L5_3(L6_3)
      if "number" == L5_3 then
        L5_3 = L4_3.count
        if L5_3 then
          goto lbl_47
        end
      end
      L5_3 = math
      L5_3 = L5_3.random
      L6_3 = L4_3.count
      L6_3 = L6_3.min
      L7_3 = L4_3.count
      L7_3 = L7_3.max
      L5_3 = L5_3(L6_3, L7_3)
      ::lbl_47::
      L6_3 = L4_2
      L7_3 = L6_3
      L6_3 = L6_3.addItem
      L8_3 = L4_3.name
      L9_3 = L5_3
      L6_3(L7_3, L8_3, L9_3)
    end
    L0_3 = TriggerClientEvent
    L1_3 = "lunar_unijob:removeCollectable"
    L2_3 = -1
    L3_3 = A1_2
    L4_3 = A2_2
    L0_3(L1_3, L2_3, L3_3, L4_3)
  end
  L6_2(L7_2, L8_2)
  L6_2 = true
  return L6_2
end
L4_1(L5_1, L6_1)
function L4_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2
  L1_2 = {}
  L2_2 = pairs
  L3_2 = L1_1
  L2_2, L3_2, L4_2, L5_2 = L2_2(L3_2)
  for L6_2, L7_2 in L2_2, L3_2, L4_2, L5_2 do
    L9_2 = L6_2
    L8_2 = L6_2.find
    L10_2 = A0_2.name
    L8_2 = L8_2(L9_2, L10_2)
    if L8_2 then
      L8_2 = ClearInterval
      L9_2 = L7_2.interval
      L8_2(L9_2)
      L8_2 = L1_1
      L8_2[L6_2] = nil
      L8_2 = #L1_2
      L8_2 = L8_2 + 1
      L1_2[L8_2] = L6_2
    end
  end
  L2_2 = #L1_2
  if L2_2 > 0 then
    L2_2 = TriggerClientEvent
    L3_2 = "lunar_unijob:clearAdvancedCollecting"
    L4_2 = -1
    L5_2 = L1_2
    L2_2(L3_2, L4_2, L5_2)
  end
  L2_2 = A0_2.advancedCollecting
  if not L2_2 then
    return
  end
  L2_2 = ipairs
  L3_2 = A0_2.advancedCollecting
  L2_2, L3_2, L4_2, L5_2 = L2_2(L3_2)
  for L6_2, L7_2 in L2_2, L3_2, L4_2, L5_2 do
    L8_2 = ipairs
    L9_2 = L7_2.locations
    L8_2, L9_2, L10_2, L11_2 = L8_2(L9_2)
    for L12_2, L13_2 in L8_2, L9_2, L10_2, L11_2 do
      L14_2 = "%s_%s_%s"
      L15_2 = L14_2
      L14_2 = L14_2.format
      L16_2 = A0_2.name
      L17_2 = L6_2
      L18_2 = L12_2
      L14_2 = L14_2(L15_2, L16_2, L17_2, L18_2)
      L15_2 = L1_1
      L16_2 = {}
      L17_2 = {}
      L16_2.spawned = L17_2
      L16_2.data = L7_2
      L16_2.index = L6_2
      L16_2.locationIndex = L12_2
      L16_2.job = A0_2
      L15_2[L14_2] = L16_2
      L15_2 = L1_1
      L15_2 = L15_2[L14_2]
      L16_2 = SetInterval
      function L17_2()
        local L0_3, L1_3, L2_3, L3_3, L4_3, L5_3, L6_3, L7_3, L8_3, L9_3, L10_3, L11_3, L12_3, L13_3
        L1_3 = L14_2
        L0_3 = L1_1
        L0_3 = L0_3[L1_3]
        L0_3 = L0_3.spawned
        L1_3 = L13_2.maxSpawned
        if L1_3 then
          L1_3 = Utils
          L1_3 = L1_3.getTableSize
          L2_3 = L0_3
          L1_3 = L1_3(L2_3)
          L2_3 = L13_2.maxSpawned
          if L1_3 == L2_3 then
            goto lbl_18
          end
        end
        L1_3 = L13_2.coords
        ::lbl_18::
        if not L1_3 then
          return
        end
        L1_3 = nil
        L2_3 = false
        L3_3 = 0
        L4_3 = 20
        while not L2_3 and L3_3 < L4_3 do
          L3_3 = L3_3 + 1
          L5_3 = L13_2.radius
          L6_3 = vector3
          L7_3 = L13_2.coords
          L7_3 = L7_3.x
          L8_3 = math
          L8_3 = L8_3.random
          L8_3 = L8_3()
          L9_3 = L5_3 * 2
          L8_3 = L8_3 * L9_3
          L8_3 = L8_3 - L5_3
          L7_3 = L7_3 + L8_3
          L8_3 = L13_2.coords
          L8_3 = L8_3.y
          L9_3 = math
          L9_3 = L9_3.random
          L9_3 = L9_3()
          L10_3 = L5_3 * 2
          L9_3 = L9_3 * L10_3
          L9_3 = L9_3 - L5_3
          L8_3 = L8_3 + L9_3
          L9_3 = L13_2.coords
          L9_3 = L9_3.z
          L6_3 = L6_3(L7_3, L8_3, L9_3)
          L1_3 = L6_3
          L2_3 = true
          L6_3 = pairs
          L7_3 = L0_3
          L6_3, L7_3, L8_3, L9_3 = L6_3(L7_3)
          for L10_3, L11_3 in L6_3, L7_3, L8_3, L9_3 do
            L12_3 = L1_3.xy
            L13_3 = L11_3.xy
            L12_3 = L12_3 - L13_3
            L12_3 = #L12_3
            if L12_3 < 1.0 then
              L2_3 = false
              break
            end
          end
        end
        if not L2_3 then
          return
        end
        L5_3 = #L0_3
        L5_3 = L5_3 + 1
        L6_3 = TriggerClientEvent
        L7_3 = "lunar_unijob:spawnCollectable"
        L8_3 = -1
        L9_3 = A0_2.name
        L10_3 = L6_2
        L11_3 = L12_2
        L12_3 = L1_3
        L13_3 = L5_3
        L6_3(L7_3, L8_3, L9_3, L10_3, L11_3, L12_3, L13_3)
        L0_3[L5_3] = L1_3
      end
      L18_2 = L13_2.interval
      L16_2 = L16_2(L17_2, L18_2)
      L15_2.interval = L16_2
    end
  end
end
function L5_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2
  L0_1 = A0_2
  L1_2 = pairs
  L2_2 = L0_1
  L1_2, L2_2, L3_2, L4_2 = L1_2(L2_2)
  for L5_2, L6_2 in L1_2, L2_2, L3_2, L4_2 do
    L7_2 = L4_1
    L8_2 = L6_2
    L7_2(L8_2)
  end
end
L6_1 = {}
L6_1.init = L5_1
L6_1.update = L4_1
AdvancedCollecting = L6_1
