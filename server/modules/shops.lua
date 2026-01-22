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
  L3_1 = L3_1.shops
  if L3_1 then
    L3_1 = exports
    L3_1 = L3_1.ox_inventory
    L4_1 = L3_1
    L3_1 = L3_1.registerHook
    L5_1 = "buyItem"
    function L6_1(A0_2)
      local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2
      L2_2 = A0_2.shopType
      L1_2 = L2_1
      L1_2 = L1_2[L2_2]
      if L1_2 then
        L2_2 = "Bought %sx %s for %sx %s."
        L3_2 = L2_2
        L2_2 = L2_2.format
        L4_2 = A0_2.count
        L5_2 = A0_2.itemName
        L6_2 = A0_2.totalPrice
        L7_2 = A0_2.currency
        if not L7_2 then
          L7_2 = "money"
        end
        L2_2 = L2_2(L3_2, L4_2, L5_2, L6_2, L7_2)
        L3_2 = Logs
        L3_2 = L3_2.send
        L4_2 = A0_2.source
        L5_2 = L1_2
        L6_2 = L2_2
        L3_2(L4_2, L5_2, L6_2)
      end
    end
    L3_1(L4_1, L5_1, L6_1)
  end
end
L3_1 = lib
L3_1 = L3_1.callback
L3_1 = L3_1.register
L4_1 = "lunar_unijob:buyItem"
function L5_1(A0_2, A1_2, A2_2, A3_2, A4_2)
  local L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2
  L5_2 = A0_2
  L6_2 = Framework
  L6_2 = L6_2.getPlayerFromId
  L7_2 = L5_2
  L6_2 = L6_2(L7_2)
  if not L6_2 then
    L7_2 = false
    return L7_2
  end
  L8_2 = L6_2
  L7_2 = L6_2.getJob
  L7_2 = L7_2(L8_2)
  L8_2 = L0_1
  L7_2 = L8_2[L7_2]
  if not L7_2 then
    L8_2 = false
    return L8_2
  end
  L8_2 = L7_2.shops
  L8_2 = L8_2[A1_2]
  if not L8_2 then
    L9_2 = false
    return L9_2
  end
  L9_2 = L8_2.locations
  L9_2 = L9_2[A2_2]
  L10_2 = L8_2.items
  L10_2 = L10_2[A3_2]
  if L9_2 and L10_2 then
    L11_2 = Utils
    L11_2 = L11_2.distanceCheck
    L12_2 = L5_2
    L13_2 = L9_2
    L14_2 = 5.0
    L11_2 = L11_2(L12_2, L13_2, L14_2)
    if L11_2 then
      L11_2 = L10_2.grade
      if not L11_2 then
        goto lbl_50
      end
      L12_2 = L6_2
      L11_2 = L6_2.getJobGrade
      L11_2 = L11_2(L12_2)
      L12_2 = L10_2.grade
      if not (L11_2 < L12_2) then
        goto lbl_50
      end
    end
  end
  L11_2 = false
  do return L11_2 end
  ::lbl_50::
  L11_2 = L10_2.price
  L11_2 = L11_2 * A4_2
  if L11_2 <= 0 then
    L12_2 = false
    return L12_2
  end
  L12_2 = L10_2.currency
  if not L12_2 then
    L12_2 = "money"
  end
  L14_2 = L6_2
  L13_2 = L6_2.getAccountMoney
  L15_2 = L12_2
  L13_2 = L13_2(L14_2, L15_2)
  if L11_2 > L13_2 then
    L13_2 = false
    L14_2 = locale
    L15_2 = "not_enough_money"
    L14_2, L15_2 = L14_2(L15_2)
    return L13_2, L14_2, L15_2
  end
  L13_2 = SetTimeout
  L14_2 = 3000
  function L15_2()
    local L0_3, L1_3, L2_3, L3_3
    L0_3 = L6_2
    L1_3 = L0_3
    L0_3 = L0_3.getAccountMoney
    L2_3 = L12_2
    L0_3 = L0_3(L1_3, L2_3)
    L1_3 = L11_2
    if L0_3 < L1_3 then
      return
    end
    L0_3 = L6_2
    L1_3 = L0_3
    L0_3 = L0_3.removeAccountMoney
    L2_3 = L12_2
    L3_3 = L11_2
    L0_3(L1_3, L2_3, L3_3)
    L0_3 = L6_2
    L1_3 = L0_3
    L0_3 = L0_3.addItem
    L2_3 = L10_2.name
    L3_3 = A4_2
    L0_3(L1_3, L2_3, L3_3)
  end
  L13_2(L14_2, L15_2)
  L13_2 = true
  return L13_2
end
L3_1(L4_1, L5_1)
function L3_1(A0_2, A1_2, A2_2)
  local L3_2, L4_2, L5_2, L6_2
  L3_2 = Editable
  L3_2 = L3_2.registerShop
  L4_2 = A0_2
  L5_2 = A1_2
  L6_2 = A2_2
  L3_2(L4_2, L5_2, L6_2)
  L3_2 = L2_1
  L4_2 = A0_2.name
  L3_2[A1_2] = L4_2
end
function L4_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2
  L1_2 = A0_2.shops
  if not L1_2 then
    return
  end
  L1_2 = ipairs
  L2_2 = A0_2.shops
  L1_2, L2_2, L3_2, L4_2 = L1_2(L2_2)
  for L5_2, L6_2 in L1_2, L2_2, L3_2, L4_2 do
    L7_2 = "%s_shop_%s"
    L8_2 = L7_2
    L7_2 = L7_2.format
    L9_2 = A0_2.name
    L10_2 = L5_2
    L7_2 = L7_2(L8_2, L9_2, L10_2)
    L8_2 = L3_1
    L9_2 = A0_2
    L10_2 = L7_2
    L11_2 = L6_2
    L8_2(L9_2, L10_2, L11_2)
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
Shops = L6_1
