local L0_1, L1_1, L2_1, L3_1, L4_1, L5_1, L6_1, L7_1
L0_1 = nil
L1_1 = {}
L2_1 = {}
L3_1 = RegisterNetEvent
L4_1 = "lunar_unijob:stopCollecting"
function L5_1()
  local L0_2, L1_2, L2_2, L3_2, L4_2
  L0_2 = source
  L1_2 = L2_1
  L1_2 = L1_2[L0_2]
  if L1_2 then
    L2_2 = L1_2.clear
    L2_2()
    L2_2 = SetTimeout
    L3_2 = 1000
    function L4_2()
      local L0_3, L1_3
      L1_3 = L0_2
      L0_3 = L2_1
      L0_3 = L0_3[L1_3]
      L1_3 = L1_2
      if L0_3 ~= L1_3 then
        return
      end
      L1_3 = L0_2
      L0_3 = L2_1
      L0_3[L1_3] = nil
    end
    L2_2(L3_2, L4_2)
  end
end
L3_1(L4_1, L5_1)
function L3_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2
  L2_2 = TriggerClientEvent
  L3_2 = "lunar_unijob:stopCollecting"
  L4_2 = A0_2
  L5_2 = A1_2
  L2_2(L3_2, L4_2, L5_2)
  L2_2 = L2_1
  L2_2 = L2_2[A0_2]
  if L2_2 then
    L3_2 = L2_2.clear
    L3_2()
    L3_2 = SetTimeout
    L4_2 = 1000
    function L5_2()
      local L0_3, L1_3
      L1_3 = A0_2
      L0_3 = L2_1
      L0_3 = L0_3[L1_3]
      L1_3 = L2_2
      if L0_3 ~= L1_3 then
        return
      end
      L1_3 = A0_2
      L0_3 = L2_1
      L0_3[L1_3] = nil
    end
    L3_2(L4_2, L5_2)
  end
end
function L4_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2
  L2_2 = true
  L3_2 = A1_2 or L3_2
  if not A1_2 then
    L3_2 = 0
  end
  L4_2 = CreateThread
  function L5_2()
    local L0_3, L1_3
    while true do
      L0_3 = Wait
      L1_3 = L3_2
      L0_3(L1_3)
      L0_3 = L2_2
      if L0_3 then
        L0_3 = A0_2
        L0_3()
      else
        break
      end
    end
  end
  L4_2(L5_2)
  L4_2 = {}
  function L5_2()
    local L0_3, L1_3
    L0_3 = false
    L2_2 = L0_3
  end
  L4_2.clear = L5_2
  return L4_2
end
L5_1 = lib
L5_1 = L5_1.callback
L5_1 = L5_1.register
L6_1 = "lunar_unijob:startCollecting"
function L7_1(A0_2, A1_2, A2_2)
  local L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2
  L3_2 = Framework
  L3_2 = L3_2.getPlayerFromId
  L4_2 = A0_2
  L3_2 = L3_2(L4_2)
  if not L3_2 then
    return
  end
  L5_2 = L3_2
  L4_2 = L3_2.getJob
  L4_2 = L4_2(L5_2)
  L5_2 = L0_1
  L4_2 = L5_2[L4_2]
  if not L4_2 then
    return
  end
  L5_2 = L4_2.collecting
  L5_2 = L5_2[A1_2]
  L6_2 = L5_2
  if L6_2 then
    L6_2 = L6_2.locations
  end
  if L6_2 then
    L6_2 = L6_2[A2_2]
  end
  if L5_2 and L6_2 then
    L7_2 = Utils
    L7_2 = L7_2.distanceCheck
    L8_2 = A0_2
    L9_2 = L6_2
    L10_2 = L5_2.radius
    if not L10_2 then
      L10_2 = Config
      L10_2 = L10_2.defaultRadius
      L10_2 = L10_2 * 1.25
    end
    L7_2 = L7_2(L8_2, L9_2, L10_2)
    if L7_2 then
      L7_2 = L2_1
      L7_2 = L7_2[A0_2]
      if not L7_2 then
        goto lbl_47
      end
    end
  end
  do return end
  ::lbl_47::
  L7_2 = L5_2.requiredItem
  if L7_2 then
    L8_2 = L3_2
    L7_2 = L3_2.hasItem
    L9_2 = L5_2.requiredItem
    L7_2 = L7_2(L8_2, L9_2)
    if not L7_2 then
      L7_2 = false
      L8_2 = locale
      L9_2 = "missing_item"
      L10_2 = Utils
      L10_2 = L10_2.getItemLabel
      L11_2 = L5_2.requiredItem
      L10_2, L11_2 = L10_2(L11_2)
      L8_2, L9_2, L10_2, L11_2 = L8_2(L9_2, L10_2, L11_2)
      return L7_2, L8_2, L9_2, L10_2, L11_2
    end
  end
  L7_2 = L5_2.max
  if L7_2 then
    L8_2 = L4_2.name
    L7_2 = L1_1
    L7_2 = L7_2[L8_2]
    if not L7_2 then
      L8_2 = L4_2.name
      L7_2 = L1_1
      L9_2 = {}
      L7_2[L8_2] = L9_2
    end
    L8_2 = L4_2.name
    L7_2 = L1_1
    L7_2 = L7_2[L8_2]
    L7_2 = L7_2[A1_2]
    if not L7_2 then
      L8_2 = L4_2.name
      L7_2 = L1_1
      L7_2 = L7_2[L8_2]
      L8_2 = {}
      L7_2[A1_2] = L8_2
    end
    L8_2 = L4_2.name
    L7_2 = L1_1
    L7_2 = L7_2[L8_2]
    L7_2 = L7_2[A1_2]
    L7_2 = L7_2[A2_2]
    if not L7_2 then
      L8_2 = L4_2.name
      L7_2 = L1_1
      L7_2 = L7_2[L8_2]
      L7_2 = L7_2[A1_2]
      L8_2 = L5_2.max
      L7_2[A2_2] = L8_2
    end
    L8_2 = L4_2.name
    L7_2 = L1_1
    L7_2 = L7_2[L8_2]
    L7_2 = L7_2[A1_2]
    L7_2 = L7_2[A2_2]
    if 0 == L7_2 then
      L7_2 = false
      L8_2 = locale
      L9_2 = "collecting_depleted"
      L8_2, L9_2, L10_2, L11_2 = L8_2(L9_2)
      return L7_2, L8_2, L9_2, L10_2, L11_2
    end
  end
  L7_2 = L2_1
  L7_2 = L7_2[A0_2]
  if L7_2 then
    return
  end
  L7_2 = L2_1
  L8_2 = L4_1
  function L9_2()
    local L0_3, L1_3, L2_3, L3_3, L4_3, L5_3, L6_3, L7_3, L8_3, L9_3, L10_3, L11_3, L12_3, L13_3
    L0_3 = Utils
    L0_3 = L0_3.distanceCheck
    L1_3 = A0_2
    L2_3 = L6_2
    L3_3 = L5_2.radius
    if not L3_3 then
      L3_3 = Config
      L3_3 = L3_3.defaultRadius
    end
    L3_3 = L3_3 * 1.25
    L0_3 = L0_3(L1_3, L2_3, L3_3)
    if not L0_3 then
      L0_3 = L3_1
      L1_3 = A0_2
      L2_3 = locale
      L3_3 = "too_far"
      L2_3, L3_3, L4_3, L5_3, L6_3, L7_3, L8_3, L9_3, L10_3, L11_3, L12_3, L13_3 = L2_3(L3_3)
      L0_3(L1_3, L2_3, L3_3, L4_3, L5_3, L6_3, L7_3, L8_3, L9_3, L10_3, L11_3, L12_3, L13_3)
      return
    end
    L0_3 = L5_2.max
    if L0_3 then
      L1_3 = L4_2.name
      L0_3 = L1_1
      L0_3 = L0_3[L1_3]
      L1_3 = A1_2
      L0_3 = L0_3[L1_3]
      L1_3 = A2_2
      L0_3 = L0_3[L1_3]
      if 0 == L0_3 then
        L0_3 = L3_1
        L1_3 = A0_2
        L2_3 = locale
        L3_3 = "collecting_depleted"
        L2_3, L3_3, L4_3, L5_3, L6_3, L7_3, L8_3, L9_3, L10_3, L11_3, L12_3, L13_3 = L2_3(L3_3)
        L0_3(L1_3, L2_3, L3_3, L4_3, L5_3, L6_3, L7_3, L8_3, L9_3, L10_3, L11_3, L12_3, L13_3)
        L0_3 = L5_2.recover
        if L0_3 then
          L0_3 = SetTimeout
          L1_3 = L5_2.recover
          function L2_3()
            local L0_4, L1_4, L2_4
            L1_4 = L4_2.name
            L0_4 = L1_1
            L0_4 = L0_4[L1_4]
            L1_4 = A1_2
            L0_4 = L0_4[L1_4]
            L1_4 = A2_2
            L2_4 = L5_2.max
            L0_4[L1_4] = L2_4
          end
          L0_3(L1_3, L2_3)
        end
        return
      end
      L1_3 = L4_2.name
      L0_3 = L1_1
      L0_3 = L0_3[L1_3]
      L1_3 = A1_2
      L0_3 = L0_3[L1_3]
      L1_3 = A2_2
      L2_3 = L0_3[L1_3]
      L2_3 = L2_3 - 1
      L0_3[L1_3] = L2_3
    end
    L0_3 = {}
    L1_3 = ipairs
    L2_3 = L5_2.items
    L1_3, L2_3, L3_3, L4_3 = L1_3(L2_3)
    for L5_3, L6_3 in L1_3, L2_3, L3_3, L4_3 do
      L7_3 = type
      L8_3 = L6_3.count
      L7_3 = L7_3(L8_3)
      if "number" == L7_3 then
        L7_3 = L6_3.count
        if L7_3 then
          goto lbl_79
        end
      end
      L7_3 = math
      L7_3 = L7_3.random
      L8_3 = L6_3.count
      L8_3 = L8_3.min
      L9_3 = L6_3.count
      L9_3 = L9_3.max
      L7_3 = L7_3(L8_3, L9_3)
      ::lbl_79::
      L8_3 = L3_2
      L9_3 = L8_3
      L8_3 = L8_3.canCarryItem
      L10_3 = L6_3.name
      L11_3 = L7_3
      L8_3 = L8_3(L9_3, L10_3, L11_3)
      if not L8_3 then
        L8_3 = L3_1
        L9_3 = A0_2
        L8_3(L9_3)
        return
      end
      L8_3 = table
      L8_3 = L8_3.insert
      L9_3 = L0_3
      L10_3 = {}
      L11_3 = L6_3.name
      L10_3.name = L11_3
      L10_3.count = L7_3
      L8_3(L9_3, L10_3)
    end
    L1_3 = ipairs
    L2_3 = L0_3
    L1_3, L2_3, L3_3, L4_3 = L1_3(L2_3)
    for L5_3, L6_3 in L1_3, L2_3, L3_3, L4_3 do
      L7_3 = L3_2
      L8_3 = L7_3
      L7_3 = L7_3.addItem
      L9_3 = L6_3.name
      L10_3 = L6_3.count
      L7_3(L8_3, L9_3, L10_3)
    end
    L1_3 = Webhooks
    L1_3 = L1_3.settings
    L1_3 = L1_3.collecting
    if L1_3 then
      L1_3 = {}
      L2_3 = ipairs
      L3_3 = L0_3
      L2_3, L3_3, L4_3, L5_3 = L2_3(L3_3)
      for L6_3, L7_3 in L2_3, L3_3, L4_3, L5_3 do
        L8_3 = table
        L8_3 = L8_3.insert
        L9_3 = L1_3
        L10_3 = "%sx %s"
        L11_3 = L10_3
        L10_3 = L10_3.format
        L12_3 = L7_3.count
        L13_3 = L7_3.name
        L10_3, L11_3, L12_3, L13_3 = L10_3(L11_3, L12_3, L13_3)
        L8_3(L9_3, L10_3, L11_3, L12_3, L13_3)
      end
      L2_3 = Logs
      L2_3 = L2_3.send
      L3_3 = A0_2
      L4_3 = L4_2.name
      L5_3 = "Collected %s."
      L6_3 = L5_3
      L5_3 = L5_3.format
      L7_3 = table
      L7_3 = L7_3.concat
      L8_3 = L1_3
      L9_3 = ", "
      L7_3, L8_3, L9_3, L10_3, L11_3, L12_3, L13_3 = L7_3(L8_3, L9_3)
      L5_3, L6_3, L7_3, L8_3, L9_3, L10_3, L11_3, L12_3, L13_3 = L5_3(L6_3, L7_3, L8_3, L9_3, L10_3, L11_3, L12_3, L13_3)
      L2_3(L3_3, L4_3, L5_3, L6_3, L7_3, L8_3, L9_3, L10_3, L11_3, L12_3, L13_3)
    end
  end
  L10_2 = L5_2.duration
  L10_2 = L10_2 + 100
  L8_2 = L8_2(L9_2, L10_2)
  L7_2[A0_2] = L8_2
  L7_2 = true
  return L7_2
end
L5_1(L6_1, L7_1)
L5_1 = {}
function L6_1(A0_2)
  local L1_2
  L0_1 = A0_2
end
L5_1.init = L6_1
Collecting = L5_1
