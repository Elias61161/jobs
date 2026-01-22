local L0_1, L1_1, L2_1, L3_1, L4_1, L5_1, L6_1
L0_1 = nil
L1_1 = GetResourceState
L2_1 = "ox_inventory"
L1_1 = L1_1(L2_1)
L1_1 = "started" == L1_1
L2_1 = {}
if L1_1 then
  L3_1 = Webhooks
  L3_1 = L3_1.settings
  L3_1 = L3_1.stashes
  if L3_1 then
    L3_1 = exports
    L3_1 = L3_1.ox_inventory
    L4_1 = L3_1
    L3_1 = L3_1.registerHook
    L5_1 = "swapItems"
    function L6_1(A0_2)
      local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2
      L1_2 = Webhooks
      L1_2 = L1_2.settings
      L1_2 = L1_2.stashes
      if L1_2 then
        L1_2 = A0_2.fromInventory
        L2_2 = A0_2.toInventory
        if L1_2 ~= L2_2 then
          goto lbl_11
        end
      end
      do return end
      ::lbl_11::
      L1_2 = A0_2.fromType
      if "stash" == L1_2 then
        L1_2 = A0_2.fromInventory
        if L1_2 then
          goto lbl_18
        end
      end
      L1_2 = A0_2.toInventory
      ::lbl_18::
      L2_2 = type
      L3_2 = L1_2
      L2_2 = L2_2(L3_2)
      if "string" ~= L2_2 then
        return
      end
      L3_2 = L1_2
      L2_2 = L1_2.find
      L4_2 = ":"
      L2_2 = L2_2(L3_2, L4_2)
      if L2_2 then
        L4_2 = L1_2
        L3_2 = L1_2.sub
        L5_2 = 1
        L6_2 = L2_2 - 1
        L3_2 = L3_2(L4_2, L5_2, L6_2)
        L1_2 = L3_2
      end
      L3_2 = L2_1
      L3_2 = L3_2[L1_2]
      if L3_2 then
        L6_2 = L3_2
        L4_2 = L6_2.name
        L5_2 = L6_2.stash
        L6_2 = nil
        L7_2 = nil
        L8_2 = A0_2.fromType
        if "stash" == L8_2 then
          L8_2 = "%sx %s"
          L9_2 = L8_2
          L8_2 = L8_2.format
          L10_2 = A0_2.fromSlot
          L10_2 = L10_2.count
          L11_2 = Utils
          L11_2 = L11_2.getItemLabel
          L12_2 = A0_2.fromSlot
          L12_2 = L12_2.name
          L11_2, L12_2, L13_2, L14_2, L15_2, L16_2 = L11_2(L12_2)
          L8_2 = L8_2(L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2)
          L6_2 = L8_2
          L8_2 = type
          L9_2 = A0_2.toSlot
          L8_2 = L8_2(L9_2)
          if "table" == L8_2 then
            L8_2 = "%sx %s"
            L9_2 = L8_2
            L8_2 = L8_2.format
            L10_2 = A0_2.toSlot
            L10_2 = L10_2.count
            L11_2 = Utils
            L11_2 = L11_2.getItemLabel
            L12_2 = A0_2.toSlot
            L12_2 = L12_2.name
            L11_2, L12_2, L13_2, L14_2, L15_2, L16_2 = L11_2(L12_2)
            L8_2 = L8_2(L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2)
            L7_2 = L8_2
          end
        else
          L8_2 = "%sx %s"
          L9_2 = L8_2
          L8_2 = L8_2.format
          L10_2 = A0_2.fromSlot
          L10_2 = L10_2.count
          L11_2 = Utils
          L11_2 = L11_2.getItemLabel
          L12_2 = A0_2.fromSlot
          L12_2 = L12_2.name
          L11_2, L12_2, L13_2, L14_2, L15_2, L16_2 = L11_2(L12_2)
          L8_2 = L8_2(L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2)
          L7_2 = L8_2
          L8_2 = type
          L9_2 = A0_2.toSlot
          L8_2 = L8_2(L9_2)
          if "table" == L8_2 then
            L8_2 = "%sx %s"
            L9_2 = L8_2
            L8_2 = L8_2.format
            L10_2 = A0_2.toSlot
            L10_2 = L10_2.count
            L11_2 = Utils
            L11_2 = L11_2.getItemLabel
            L12_2 = A0_2.toSlot
            L12_2 = L12_2.name
            L11_2, L12_2, L13_2, L14_2, L15_2, L16_2 = L11_2(L12_2)
            L8_2 = L8_2(L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2)
            L6_2 = L8_2
          end
        end
        L8_2 = Logs
        L8_2 = L8_2.send
        L9_2 = A0_2.source
        L10_2 = L4_2
        L11_2 = [[
Stash: %s (%s)
Took: %s
Gave: %s]]
        L12_2 = L11_2
        L11_2 = L11_2.format
        L13_2 = L5_2.label
        L14_2 = L1_2
        L15_2 = L6_2 or L15_2
        if not L6_2 then
          L15_2 = "nothing"
        end
        L16_2 = L7_2 or L16_2
        if not L7_2 then
          L16_2 = "nothing"
        end
        L11_2, L12_2, L13_2, L14_2, L15_2, L16_2 = L11_2(L12_2, L13_2, L14_2, L15_2, L16_2)
        L8_2(L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2)
      end
    end
    L3_1(L4_1, L5_1, L6_1)
  end
end
function L3_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2
  L1_2 = A0_2.stashes
  if not L1_2 then
    return
  end
  L1_2 = ipairs
  L2_2 = A0_2.stashes
  L1_2, L2_2, L3_2, L4_2 = L1_2(L2_2)
  for L5_2, L6_2 in L1_2, L2_2, L3_2, L4_2 do
    L7_2 = ipairs
    L8_2 = L6_2.locations
    L7_2, L8_2, L9_2, L10_2 = L7_2(L8_2)
    for L11_2, L12_2 in L7_2, L8_2, L9_2, L10_2 do
      L13_2 = L6_2.name
      if not L13_2 then
        L13_2 = "%s_stash_%s_%s"
        L14_2 = L13_2
        L13_2 = L13_2.format
        L15_2 = A0_2.name
        L16_2 = L5_2
        L17_2 = L11_2
        L13_2 = L13_2(L14_2, L15_2, L16_2, L17_2)
      end
      L14_2 = Editable
      L14_2 = L14_2.registerStash
      L15_2 = A0_2
      L16_2 = L13_2
      L17_2 = L6_2
      L18_2 = L12_2
      L14_2(L15_2, L16_2, L17_2, L18_2)
      L14_2 = L2_1
      L15_2 = {}
      L16_2 = A0_2.name
      L15_2.name = L16_2
      L15_2.stash = L6_2
      L14_2[L13_2] = L15_2
    end
  end
end
function L4_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2
  L0_1 = A0_2
  L1_2 = pairs
  L2_2 = L0_1
  L1_2, L2_2, L3_2, L4_2 = L1_2(L2_2)
  for L5_2, L6_2 in L1_2, L2_2, L3_2, L4_2 do
    L7_2 = L3_1
    L8_2 = L6_2
    L7_2(L8_2)
  end
end
L5_1 = {}
L5_1.init = L4_1
L5_1.update = L3_1
Stashes = L5_1
