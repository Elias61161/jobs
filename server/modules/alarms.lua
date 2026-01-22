local L0_1, L1_1, L2_1, L3_1, L4_1
L0_1 = nil
L1_1 = {}
L2_1 = lib
L2_1 = L2_1.callback
L2_1 = L2_1.register
L3_1 = "lunar_unijob:triggerAlarm"
function L4_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2
  L2_2 = Framework
  L2_2 = L2_2.getPlayerFromId
  L3_2 = A0_2
  L2_2 = L2_2(L3_2)
  L4_2 = A1_2.job
  L3_2 = L0_1
  L3_2 = L3_2[L4_2]
  L4_2 = L3_2
  if L4_2 then
    L4_2 = L4_2.alarms
  end
  L5_2 = A1_2.index
  L4_2 = L4_2[L5_2]
  if L2_2 and L4_2 then
    L6_2 = A1_2.job
    L5_2 = L1_1
    L5_2 = L5_2[L6_2]
    L6_2 = A1_2.index
    L5_2 = L5_2[L6_2]
    if not L5_2 then
      goto lbl_26
    end
  end
  do return end
  ::lbl_26::
  L6_2 = L2_2
  L5_2 = L2_2.getJob
  L5_2 = L5_2(L6_2)
  L6_2 = A1_2.job
  if L5_2 ~= L6_2 then
    L5_2 = L4_2.global
    if not L5_2 then
      goto lbl_80
    end
  end
  L6_2 = A1_2.job
  L5_2 = L1_1
  L5_2 = L5_2[L6_2]
  L6_2 = A1_2.index
  L5_2[L6_2] = true
  L5_2 = SetTimeout
  L6_2 = L4_2.cooldown
  function L7_2()
    local L0_3, L1_3
    L1_3 = A1_2.job
    L0_3 = L1_1
    L0_3 = L0_3[L1_3]
    L1_3 = A1_2.index
    L0_3[L1_3] = nil
  end
  L5_2(L6_2, L7_2)
  L5_2 = Dispatch
  L5_2 = L5_2.call
  L6_2 = L4_2.locations
  L7_2 = A1_2.locationIndex
  L6_2 = L6_2[L7_2]
  L6_2 = L6_2.xyz
  L7_2 = {}
  L8_2 = Config
  L8_2 = L8_2.alarmCode
  L7_2.Code = L8_2
  L8_2 = locale
  L9_2 = "dispatch_alarm"
  L8_2 = L8_2(L9_2)
  L7_2.Title = L8_2
  L8_2 = locale
  L9_2 = "dispatch_alarm_desc"
  L10_2 = L3_2.label
  L8_2 = L8_2(L9_2, L10_2)
  L7_2.Message = L8_2
  L5_2(L6_2, L7_2)
  L5_2 = Webhooks
  L5_2 = L5_2.settings
  L5_2 = L5_2.alarms
  if L5_2 then
    L5_2 = Logs
    L5_2 = L5_2.send
    L6_2 = A0_2
    L7_2 = L3_2.name
    L8_2 = "Triggered the alarm inside %s."
    L9_2 = L8_2
    L8_2 = L8_2.format
    L10_2 = L3_2.label
    L8_2, L9_2, L10_2 = L8_2(L9_2, L10_2)
    L5_2(L6_2, L7_2, L8_2, L9_2, L10_2)
  end
  L5_2 = true
  do return L5_2 end
  ::lbl_80::
  L5_2 = false
  return L5_2
end
L2_1(L3_1, L4_1)
function L2_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2
  L0_1 = A0_2
  L1_2 = pairs
  L2_2 = L0_1
  L1_2, L2_2, L3_2, L4_2 = L1_2(L2_2)
  for L5_2, L6_2 in L1_2, L2_2, L3_2, L4_2 do
    L8_2 = L6_2.name
    L7_2 = L1_1
    L9_2 = {}
    L7_2[L8_2] = L9_2
  end
end
function L3_1(A0_2)
  local L1_2, L2_2, L3_2
  L2_2 = A0_2.name
  L1_2 = L1_1
  L3_2 = {}
  L1_2[L2_2] = L3_2
end
L4_1 = {}
L4_1.init = L2_1
L4_1.update = L3_1
Alarms = L4_1
