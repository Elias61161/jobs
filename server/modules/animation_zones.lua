local L0_1, L1_1, L2_1, L3_1, L4_1
L0_1 = nil
L1_1 = {}
L2_1 = lib
L2_1 = L2_1.callback
L2_1 = L2_1.register
L3_1 = "lunar_unijob:startAnimation"
function L4_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2
  L2_2 = Framework
  L2_2 = L2_2.getPlayerFromId
  L3_2 = A0_2
  L2_2 = L2_2(L3_2)
  if not L2_2 then
    L3_2 = false
    return L3_2
  end
  L3_2 = L1_1
  L3_2 = L3_2[A1_2]
  if L3_2 then
    L4_2 = L3_2.occupant
    if not L4_2 then
      L4_2 = L3_2.zone
      L4_2 = L4_2.global
      if L4_2 then
        goto lbl_28
      end
      L5_2 = L2_2
      L4_2 = L2_2.getJob
      L4_2 = L4_2(L5_2)
      L5_2 = L3_2.job
      L5_2 = L5_2.name
      if L4_2 == L5_2 then
        goto lbl_28
      end
    end
  end
  L4_2 = false
  do return L4_2 end
  ::lbl_28::
  L3_2.occupant = A0_2
  L4_2 = true
  return L4_2
end
L2_1(L3_1, L4_1)
L2_1 = RegisterNetEvent
L3_1 = "lunar_unijob:stopAnimation"
function L4_1(A0_2)
  local L1_2, L2_2
  L1_2 = source
  L2_2 = L1_1
  L2_2 = L2_2[A0_2]
  L2_2 = L2_2.occupant
  if L2_2 == L1_2 then
    L2_2 = L1_1
    L2_2 = L2_2[A0_2]
    L2_2.occupant = nil
  end
end
L2_1(L3_1, L4_1)
function L2_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2
  L1_2 = A0_2.animationZones
  if not L1_2 then
    return
  end
  L1_2 = ipairs
  L2_2 = A0_2.animationZones
  L1_2, L2_2, L3_2, L4_2 = L1_2(L2_2)
  for L5_2, L6_2 in L1_2, L2_2, L3_2, L4_2 do
    L7_2 = ipairs
    L8_2 = L6_2.locations
    L7_2, L8_2, L9_2, L10_2 = L7_2(L8_2)
    for L11_2 in L7_2, L8_2, L9_2, L10_2 do
      L12_2 = "%s_%s_%s"
      L13_2 = L12_2
      L12_2 = L12_2.format
      L14_2 = A0_2.name
      L15_2 = L5_2
      L16_2 = L11_2
      L12_2 = L12_2(L13_2, L14_2, L15_2, L16_2)
      L13_2 = L1_1
      L14_2 = {}
      L14_2.job = A0_2
      L14_2.zone = L6_2
      L13_2[L12_2] = L14_2
    end
  end
end
function L3_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2
  L0_1 = A0_2
  L1_2 = pairs
  L2_2 = L0_1
  L1_2, L2_2, L3_2, L4_2 = L1_2(L2_2)
  for L5_2, L6_2 in L1_2, L2_2, L3_2, L4_2 do
    L7_2 = L2_1
    L8_2 = L6_2
    L7_2(L8_2)
  end
end
L4_1 = {}
L4_1.init = L3_1
L4_1.update = L2_1
AnimationZones = L4_1
