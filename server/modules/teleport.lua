local L0_1, L1_1, L2_1, L3_1
L0_1 = {}
L1_1 = RegisterNetEvent
L2_1 = "lunar_unijob:teleport"
function L3_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2
  L1_2 = source
  L2_2 = Framework
  L2_2 = L2_2.getPlayerFromId
  L3_2 = L1_2
  L2_2 = L2_2(L3_2)
  if not L2_2 then
    return
  end
  L3_2 = GetJobs
  L3_2 = L3_2()
  L5_2 = L2_2
  L4_2 = L2_2.getJob
  L4_2 = L4_2(L5_2)
  L3_2 = L3_2[L4_2]
  L3_2 = L3_2.teleports
  L3_2 = L3_2[A0_2]
  L4_2 = L0_1
  L4_2 = L4_2[L1_2]
  if not L4_2 then
    L4_2 = Utils
    L4_2 = L4_2.distanceCheck
    L5_2 = L1_2
    L6_2 = L3_2.from
    L6_2 = L6_2.coords
    L7_2 = 10.0
    L4_2 = L4_2(L5_2, L6_2, L7_2)
    if L4_2 then
      goto lbl_30
    end
  end
  do return end
  ::lbl_30::
  L4_2 = L0_1
  L4_2[L1_2] = true
  L4_2 = L3_2.routingBucket
  if L4_2 then
    L4_2 = SetPlayerRoutingBucket
    L5_2 = L1_2
    L6_2 = L3_2.routingBucket
    L4_2(L5_2, L6_2)
  end
end
L1_1(L2_1, L3_1)
L1_1 = RegisterNetEvent
L2_1 = "lunar_unijob:exitTeleport"
function L3_1()
  local L0_2, L1_2, L2_2, L3_2
  L0_2 = source
  L1_2 = L0_1
  L1_2 = L1_2[L0_2]
  if L1_2 then
    L1_2 = L0_1
    L1_2[L0_2] = nil
    L1_2 = SetPlayerRoutingBucket
    L2_2 = L0_2
    L3_2 = 0
    L1_2(L2_2, L3_2)
  end
end
L1_1(L2_1, L3_1)
