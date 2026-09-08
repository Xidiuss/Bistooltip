-- Whitemane:Frostmourne custom content extracted from fork data (2026-09-08)
-- BEFORE upstream refresh. Source for the Bistooltip_Whitemane_Frostmourne
-- plugin diff (spec W6). Custom IDs: 128858, 130023, 130031, 131004, 150005.
-- A) wowtbc bislists: slots containing custom IDs (self-describing lines):

Bistooltip_wowtbc_bislists["Druid"]["Balance"]["T7"][13] = { ["slot_name"] = "Weapon", ["enhs"] = { [1] = { ["type"] = "spell", ["id"] = 60714 } }, [1] = 130023, [2] = 40395, [3] = 40489, [4] = 40408, [5] = 39424, [6] = 39763}
Bistooltip_wowtbc_bislists["Druid"]["Balance"]["T8"][13] = { ["slot_name"] = "Weapon", ["enhs"] = { [1] = { ["type"] = "spell", ["id"] = 60714 }, [2] = { ["type"] = "item", ["id"] = 39998 } }, [1] = 130023, [2] = 45620, [3] = 45612, [4] = 46035, [5] = 45171, [6] = 45527}
Bistooltip_wowtbc_bislists["Druid"]["Feral dps"]["T8"][13] = { ["slot_name"] = "Weapon", ["enhs"] = { [1] = { ["type"] = "spell", ["id"] = 59621 }, [2] = { ["type"] = "item", ["id"] = 40002 }, [3] = { ["type"] = "none", ["id"] = 0 }, [4] = { ["type"] = "item", ["id"] = 40002 } }, [1] =128858 , [2] = 45613, [3] = 45533, [4] = 46033, [5] = 46067, [6] = 45498 }
Bistooltip_wowtbc_bislists["Hunter"]["Beast mastery"]["T7"][15] = { ["slot_name"] = "Ranged", ["enhs"] = { [1] = { ["type"] = "item", ["id"] = 41167 } }, [1] = 150005, [2] = 40385, [3] = 40265, [4] = 39419, [5] = 40346, [6] = 42485}
Bistooltip_wowtbc_bislists["Hunter"]["Marksmanship"]["T7"][15] = { ["slot_name"] = "Ranged", ["enhs"] = { [1] = { ["type"] = "item", ["id"] = 41167 } }, [1] = 150005, [2] = 40385, [3] = 39419, [4] = 40265, [5] = 40346, [6] = 42485}
Bistooltip_wowtbc_bislists["Hunter"]["Survival"]["T7"][15] = { ["slot_name"] = "Ranged", ["enhs"] = { [1] = { ["type"] = "item", ["id"] = 41167 } }, [1] = 150005, [2] = 40385, [3] = 40265, [4] = 39419, [5] = 40346, [6] = 39296}
Bistooltip_wowtbc_bislists["Mage"]["Arcane"]["T7"][13] = { ["slot_name"] = "Weapon", ["enhs"] = { [1] = { ["type"] = "spell", ["id"] = 60714 } }, [1] = 130023, [2] = 40396, [3] = 40489, [4] = 40408, [5] = 39424, [6] = 40336}
Bistooltip_wowtbc_bislists["Mage"]["Arcane"]["T8"][13] = { ["slot_name"] = "Weapon", ["enhs"] = { [1] = { ["type"] = "spell", ["id"] = 60714 }, [2] = { ["type"] = "item", ["id"] = 39998 } }, [1] = 130023, [2] = 45620, [3] = 45990, [4] = 45171, [5] = 45527, [6] = 45437}
Bistooltip_wowtbc_bislists["Mage"]["Fire"]["T7"][13] = { ["slot_name"] = "Weapon", ["enhs"] = { [1] = { ["type"] = "spell", ["id"] = 60714 } }, [1] = 130023, [2] = 40396, [3] = 40489, [4] = 40408, [5] = 39424, [6] = 40336}
Bistooltip_wowtbc_bislists["Mage"]["Fire"]["T8"][13] = { ["slot_name"] = "Weapon", ["enhs"] = { [1] = { ["type"] = "spell", ["id"] = 60714 }, [2] = { ["type"] = "item", ["id"] = 39998 } }, [1] = 130023, [2] = 45620, [3] = 45990, [4] = 45527, [5] = 45437, [6] = 45171}
Bistooltip_wowtbc_bislists["Mage"]["Fire FFB"]["T7"][13] = { ["slot_name"] = "Weapon", ["enhs"] = { [1] = { ["type"] = "spell", ["id"] = 60714 } }, [1] = 130023, [2] = 40396, [3] = 40489, [4] = 40408, [5] = 39424, [6] = 40336}
Bistooltip_wowtbc_bislists["Mage"]["Fire FFB"]["T8"][13] = { ["slot_name"] = "Weapon", ["enhs"] = { [1] = { ["type"] = "spell", ["id"] = 60714 }, [2] = { ["type"] = "item", ["id"] = 39998 } }, [1] = 130023, [2] = 45620, [3] = 45990, [4] = 45457, [5] = 45527, [6] = 45437}
Bistooltip_wowtbc_bislists["Mage"]["Frost"]["T7"][13] = { ["slot_name"] = "Weapon", ["enhs"] = { [1] = { ["type"] = "spell", ["id"] = 60714 } }, [1] = 130023, [2] = 40396, [3] = 40489, [4] = 40408, [5] = 39424, [6] = 40336}
Bistooltip_wowtbc_bislists["Mage"]["Frost"]["T8"][13] = { ["slot_name"] = "Weapon", ["enhs"] = { [1] = { ["type"] = "spell", ["id"] = 60714 }, [2] = { ["type"] = "item", ["id"] = 39998 } }, [1] = 130023, [2] = 45620, [3] = 45990, [4] = 45527, [5] = 45171, [6] = 45437}
Bistooltip_wowtbc_bislists["Paladin"]["Retribution"]["T7"][13] = { ["slot_name"] = "Weapon", ["enhs"] = { [1] = { ["type"] = "spell", ["id"] = 59621 } }, [1] = 130031, [2] = 40384, [3] = 39758, [4] = 39417, [5] = 40497, [6] = 40406}
Bistooltip_wowtbc_bislists["Paladin"]["Retribution"]["T8"][13] = { ["slot_name"] = "Weapon", ["enhs"] = { [1] = { ["type"] = "spell", ["id"] = 59621 }, [2] = { ["type"] = "item", ["id"] = 39996 }, [3] = { ["type"] = "none", ["id"] = 0 }, [4] = { ["type"] = "item", ["id"] = 39996 } }, [1] = 130031, [2] = 45516, [3] = 45533, [4] = 46067, [5] = 45868, [6] = 45521}
Bistooltip_wowtbc_bislists["Paladin"]["Retribution"]["T9"][13] = { ["slot_name"] = "Weapon", ["enhs"] = { [1] = { ["type"] = "spell", ["id"] = 59621 }, [2] = { ["type"] = "item", ["id"] = 40111 }, [3] = { ["type"] = "none", ["id"] = 0 }, [4] = { ["type"] = "item", ["id"] = 40111 } }, [1] = 130031, [2] = 47519, [3] = 47515, [4] = 45533, [5] = 47078, [6] = 47239 }
Bistooltip_wowtbc_bislists["Priest"]["Shadow"]["T7"][13] = { ["slot_name"] = "Weapon", ["enhs"] = { [1] = { ["type"] = "spell", ["id"] = 60714 } }, [1] = 130023, [2] = 40395, [3] = 40489, [4] = 40408, [5] = 39424, [6] = 39423}
Bistooltip_wowtbc_bislists["Priest"]["Shadow"]["T8"][13] = { ["slot_name"] = "Weapon", ["enhs"] = { [1] = { ["type"] = "spell", ["id"] = 60714 }, [2] = { ["type"] = "item", ["id"] = 40026 } }, [1] = 130023, [2] = 45620, [3] = 45612, [4] = 46035, [5] = 45171, [6] = 45527}
Bistooltip_wowtbc_bislists["Shaman"]["Enhancement"]["T8"][13] = { ["slot_name"] = "Weapon", ["enhs"] = { [1] = { ["type"] = "spell", ["id"] = 59621 }, [2] = { ["type"] = "item", ["id"] = 40017 } }, [1] = 131004,  [2] = 45132, [3] = 45449, [4] = 46097, [5] = 45463, [6] = 45489}
Bistooltip_wowtbc_bislists["Shaman"]["Enhancement"]["T9"][13] = { ["slot_name"] = "Weapon", ["enhs"] = { [1] = { ["type"] = "spell", ["id"] = 59621 } }, [1] = 131004, [2] = 47206, [3] = 46980, [4] = 46017, [5] = 45620, [6] = 47941 }
Bistooltip_wowtbc_bislists["Warrior"]["Arms"]["T7"][13] = { ["slot_name"] = "Weapon", ["enhs"] = { [1] = { ["type"] = "spell", ["id"] = 59621 } }, [1] = 130031, [2] = 40384, [3] = 40497, [4] = 40208, [5] = 39417, [6] = 39221}
Bistooltip_wowtbc_bislists["Warrior"]["Arms"]["T8"][13] = { ["slot_name"] = "Weapon", ["enhs"] = { [1] = { ["type"] = "spell", ["id"] = 59621 }, [2] = { ["type"] = "item", ["id"] = 39996 }, [3] = { ["type"] = "none", ["id"] = 0 }, [4] = { ["type"] = "item", ["id"] = 42702 } }, [1] = 130031, [2] = 45516, [3] = 45533, [4] = 45868, [5] = 45498, [6] = 46067}
Bistooltip_wowtbc_bislists["Warrior"]["Arms"]["T9"][13] = { ["slot_name"] = "Weapon", ["enhs"] = { [1] = { ["type"] = "spell", ["id"] = 59621 }, [2] = { ["type"] = "item", ["id"] = 40117 }, [3] = { ["type"] = "none", ["id"] = 0 }, [4] = { ["type"] = "item", ["id"] = 40117 } }, [1] = 130031, [2] = 47078, [3] = 47515, [4] = 47239, [5] = 47519, [6] = 45533 }
Bistooltip_wowtbc_bislists["Warrior"]["Fury"]["T7"][13] = { ["slot_name"] = "Weapon", ["enhs"] = { [1] = { ["type"] = "spell", ["id"] = 59621 } }, [1] = 130031, [2] = 40384, [3] = 40497, [4] = 39417, [5] = 39758, [6] = 40208}
Bistooltip_wowtbc_bislists["Warrior"]["Fury"]["T8"][13] = { ["slot_name"] = "Weapon", ["enhs"] = { [1] = { ["type"] = "spell", ["id"] = 59621 }, [2] = { ["type"] = "item", ["id"] = 39996 }, [3] = { ["type"] = "none", ["id"] = 0 }, [4] = { ["type"] = "item", ["id"] = 39996 } }, [1] = 130031, [2] = 45516, [3] = 45533, [4] = 46067, [5] = 45868, [6] = 45521}
Bistooltip_wowtbc_bislists["Warrior"]["Fury"]["T9"][13] = { ["slot_name"] = "Weapon", ["enhs"] = { [1] = { ["type"] = "spell", ["id"] = 59621 }, [2] = { ["type"] = "item", ["id"] = 40111 }, [3] = { ["type"] = "none", ["id"] = 0 }, [4] = { ["type"] = "item", ["id"] = 40111 } }, [1] = 130031, [2] = 47078, [3] = 47515, [4] = 47519, [5] = 45516, [6] = 46067}

-- B) Loot_Sources: fork-side custom entry 131004 (with block context):

1297-        ["Thorim"] = { 45038, 46017, 45468, 45467, 45469, 45466, 45463, 45638, 45639, 45640 },
1298-        ["Freya"] = { 45038, 46017, 45483, 45482, 45481, 45480, 45479, 45653, 45654, 45655 },
1299-        ["Mimirion"] = { 45038, 46017, 45493, 45492, 45491, 45490, 45489, 45641, 45642, 45643 },
1300-        ["General Vezax"] = { 45038, 46017, 45514, 45508, 45512, 45504, 45513, 45502, 45505, 45501, 45503, 45515, 45507, 45509, 45145, 45498, 45511 },
1301-        ["Yogg-Saron"] = { 45038, 46017, 45529, 45532, 45523, 45524, 45531, 45525, 45530, 45522, 45527, 45521, 45656, 45657, 45658 },
1302-        ["Trash Mobs"] = { 45541, 45549, 45547, 45548, 45543, 45544, 45542, 45540, 45539, 45538, 46138, 45605 },
1303:        ["Legendary"] = {46017, 131004},

-- C) EmblemData custom tables remain in the live file (not refreshed from
-- upstream; upstream has no EmblemData). Extraction to plugin = spec W6.
