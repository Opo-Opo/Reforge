--[[
Trader - runs upgrades that wait for a game day, at the NPCs whose menus have been logged:
  Coelestrox (Reisenjima): Artifact +1 -> +2. Trade, wait a day, collect.
                          Artifact +2 -> +3. Day-1 trade, wait a day, day-2 trade, wait a day, collect.
  Monisette (Port Jeuno): old sets -> iL109, and iL109 -> +1. Trade, wait a day, collect.
  Aurix ("???", Ru'Lude Gardens): Relic +1 -> +2 and +2 -> +3. Trade, wait a day, collect.
  Ruspix (Leafallia): Empyrean +1 -> +2 and +2 -> +3. Trade (Gallimaufry taken automatically), wait a day, collect.
Each NPC works on one piece at a time. Reforge acts at whichever NPC you are standing by.

There is no queue. Each time Reforge has to decide (on //frg start, after a day change, after a collection)
it asks the NPC what they hold, and:
  - something unfinished: waits for the day change
  - something finished: collects it
  - Coelestrox ready for the day-2 trade: does it
  - nothing: trades the first piece in your inventory whose next step is at this NPC and whose materials
    (both days', at Coelestrox) are all there; with none left it says so and stops.
So a collected piece whose next step is at the same NPC carries straight on, a piece added to your inventory
mid-run is picked up, and a crash, reload or anything done by hand can't leave Reforge out of step.

Safety:
  - //frg debug turns on dry run (off by default): packets are written to data/dryrun.log instead of being sent.
  - //frg stop stops it; nothing more happens until the next //frg start.
  - Trades only use inventory, and the NPC must be in range. Just before a trade, whatever it is short of is
    moved into inventory from the bags open everywhere (Satchel, Sack, Case), only for that trade
    and only when the bags cover all of it and there is room. Pieces themselves are never moved: putting a piece in
    inventory is how you say you want it upgraded.
  - Reforge answers a trade or collect menu only when it names a piece of equipment (Ruspix's trade menu names
    the piece traded, and his collect menu names nothing) and, at Coelestrox, shows the normal bead fee and instant
    cost. Which piece doesn't matter (male and female versions differ). Any other menu must be one listed below.
    Anything else is logged to data/menus.log, Reforge says something unexpected happened, and stops.
    It sends nothing more, so the NPC's question is left to you.

Coelestrox's menus, from packet logs of real upgrades (addons/upgradelog/logs, 2026-10-27):
  27  talked to while he holds none of your pieces ("Look at list, please."). Params: 15, ..., bead balance.
      It ended with option 0.
  28  after a trade. Params: result item, ?, bead fee, instant cost, ?, ?, bead balance, ?. Option 1 waits a day.
  29  talked to while he holds a piece that isn't finished. Two kinds:
        not ready: param 1 is the instant cost after day 1 (10000), and 0 after day 2. Option 0 comes back later.
        ready for the day-2 trade: param 1 is the +3 it will become. He only lists the day-2 items
        (no choices); the game ends that dialogue with option 2.
      Param 6 looked like the slot in three logs (body 1, feet 4).
  30  talked to after the day change. Param 1 is the finished item. Option 0 takes it.
  32  items missing. Reforge leaves this one to you.
  +1 -> +2 (2026-10-30, Terra's Atrophy Boots +1): menu 28 as above, params Atro. Boots +2, 1, 10 beads, instant 500,
  1, 0, bead balance. Option 1 waits a day. A trade with a wrong item got no reply. Talked to while he works on it:
  menu 29, params 500 (the instant cost), 1, 1, 0, 1, 0, bead balance, 4; ended with option 0. After the day
  change: menu 30, param 1 Atro. Boots +2, the rest 0; option 0 took it.

Monisette's menus (2026-10-28, Bagua Tunic, Mitaines and Pants -> +1):
  385 talked to while she has none of your pieces: her plans and Rem's Tale withdrawal list. Bytes 17-26 of
      the params are your stored tales per chapter. A withdrawal is option chapter + 256 x count (Terra took
      Ch.7, 8 and 9 x8 as 2055, 2056, 2057, each its own conversation), so option 0 asks for nothing and leaves.
      Reforge withdraws the tales the next piece is short of this way, one chapter per conversation.
  388 after a trade. Params: result item, slot item, tale, the piece traded. No fee, no choice. Ended with 0.
  387 talked to while she is working on it ("still reconditioning"). Ended with 0.
  393 talked to after the day change. Param 1 is the finished item. Option 0 takes it.
  386 the same for an Empyrean piece (Locke's Chass. Tricorne, 2026-10-28); option 0 assumed to take it too.

Aurix's menus (2026-10-28, Bagua Mitaines +1 -> +2). He is a "???", so he is found by id, not name.
  3007 talked to when he has nothing finished: "do ya wanna see the list?". Param 1 is 0 when he holds nothing
       of yours and 1 when he is working on a piece ("not ready yet"); the rest changed between talks.
       Option 0 is "Never mind" (and Escape).
  3005 after a trade. Param 1 is the result item. No choice. Ended with 0.
  3006 talked to after the day change. Param 1 is the finished item. Option 0 takes it.
  A trade he doesn't want gets no reply at all, so Reforge's reply timeout stops it.

Ruspix's menus (2026-10-29, Locke's Chass. Tricorne +1 -> +2). None of them names the result.
  71 talked to when he has nothing finished: "Care to browse my special list?". Param 1 is your Gallimaufry.
     It is the same whether he is working on a piece or holds nothing (byte 31 flips between 2 and 6 in all his
     menus, for something else), so Reforge just trades the next piece. Option 0 is "Leaving for now" (and Escape).
  74 after a trade. Param 1 is the piece traded (not the result). No choice; the muffins are taken. Ended with 0.
  76 after a trade while he is working on a piece (2026-11-13, Terra's Bhikku Hose +1 traded a few seconds after
     the Cyclas +1): turned down, the items stay with you. Param 1 was 15. Ended with 0.
  75 talked to after the day change: "The equipment you ordered is ready!". Param 1 was 281, not an item.
     Option 0 takes it; Reforge then checks the result arrived. It is also his reply to a trade while a piece is
     finished (2026-11-13, param 1 was 3): the trade is ignored, the traded items stay, and option 0 takes the piece.
  Empyrean +2 -> +3 (Ra'Kaz. Starstone + 70000 Gallimaufry) is assumed to use the same menus; turned on at the
  user's request before one was logged.
  Relic +2 -> +3 uses the same menus, it is assumed (turned on at the user's request before one was logged).
  2 shards and 2 voids are from the wiki; the 2 of the slot material is unconfirmed.
]]

local packets = require('packets')
local files = require('files')
local res = require('resources')
local upgrades = require('upgrades')

local A = upgrades.artifact3

local NPCS = {
    Coelestrox = {zone_id = A.zone_id, zone = A.zone},
    Monisette = {zone_id = 246, zone = 'Port Jeuno'},
    Aurix = {zone_id = 243, zone = "Ru'Lude Gardens", id = 17772865}, -- one of many "???"s
    Ruspix = {zone_id = 281, zone = 'Leafallia', id = 17928266},
}
local NPC_ORDER = {'Coelestrox', 'Monisette', 'Aurix', 'Ruspix'}
local NPC_KEY = {['??? (Aurix)'] = 'Aurix'} -- upgrades.lua's name -> the name used here

-- Coelestrox
local MENU_IDLE, MENU_TRADE, MENU_NOT_READY, MENU_COLLECT = 27, 28, 29, 30
local OPTION_WAIT, OPTION_LATER, OPTION_COLLECT, OPTION_IDLE = 1, 0, 0, 0
local OPTION_LEAVE = 2 -- how the game ends menu 29 when it only lists the day-2 items
-- Bead fee for each trade, and what the instant option costs (checked against menu 28, never picked).
-- 'trade' is the +1 -> +2; 'day1' and 'day2' the +2 -> +3.
local BEADS = {day1 = A.beads.day1, day2 = A.beads.day2, trade = upgrades.artifact2.beads}
local INSTANT = {day1 = A.instant.day1, day2 = A.instant.day2, trade = upgrades.artifact2.instant}
-- Monisette
local M_IDLE, M_TRADE, M_BUSY = 385, 388, 387
local M_COLLECT = {[393] = true, [386] = true} -- 393 for Relic (Bagua), 386 for Empyrean (Chasseur's)
local M_OPTION = 0 -- every Monisette conversation Reforge answers ends with 0
-- Aurix
local A_ASK, A_TRADE, A_COLLECT = 3007, 3005, 3006
local A_OPTION = 0 -- "Never mind", and how his trade and collect conversations end
-- Ruspix
local R_ASK, R_TRADE, R_COLLECT, R_BUSY = 71, 74, 75, 76
local R_OPTION = 0 -- "Leaving for now", and how his trade and collect conversations end

-- Menu 29's 6th param looked like the slot (body 1, feet 4). Unconfirmed; only used to name a piece.
local PROBE_SLOT = {[0] = 'head', [1] = 'body', [2] = 'hands', [3] = 'legs', [4] = 'feet'}
local TIER = {iL109 = 0, ['+1'] = 1, ['+2'] = 2, ['+3'] = 3}

local TRADE_RANGE = 6 -- yalms
local REPLY_TIMEOUT = 10 -- seconds to wait for the NPC's menu
local ANSWER_DELAY = 1 -- seconds before answering a menu
local RETRY_DELAY = 60 -- seconds before asking again when the NPC isn't ready after the day change
local GAME_MINUTE = 2.4 -- earth seconds
local MOVE_DELAY = 1 -- seconds between moving stacks into inventory
local FETCH_BAGS = {5, 6, 7} -- Satchel, Sack, Case (wardrobes only hold equipment)

local M = {}

local ctx -- say, item_id, classify, next_step, read_holdings and colors, from reforge.lua
local dry_run = false -- debug: log packets instead of sending them
local running = false -- set by //frg start; cleared by //frg stop, by anything unexpected, or when nothing is left
local pending = nil -- packet sent, waiting for the NPC's menu
local new_day = false -- the day has changed since the NPC last said "not ready"
local finished = 0 -- pieces collected since the last //frg start
-- What Reforge traded to each NPC, only so messages can name it; the NPC is what Reforge goes by
local traded_to = {}
-- Rem's Tales stored with Monisette, chapter -> count: from //frg start, then from each menu 385
local stored = {}
local last_withdrawal = nil -- {chapter, before}: to stop if a withdrawal didn't arrive
-- The last menu Reforge answered, so a second copy of it (Aurix sometimes sends two) is blocked too
local answered = nil
local DUPLICATE_WINDOW = 2 -- seconds

local function say(text, color) ctx.say(text, color) end

local function hex(data)
    return (data:gsub('.', function(c) return string.format('%02X ', c:byte()) end))
end

-- Armor without a +N is labelled NQ, so "Bagua Pants NQ -> +1" can't be misread
local function item_name(id)
    local item = id and res.items[id]
    if not item then return 'item ' .. tostring(id) end
    if item.category == 'Armor' and not item.en:find(' %+%d$') then return item.en .. ' NQ' end
    return item.en
end

local function piece_name(e)
    if e.piece then return item_name(e.piece) end
    return e.slot and ('your ' .. e.slot .. ' piece') or 'your piece'
end

-- An NPC's trade or collect menu is answered with decision only when it names a piece of equipment; otherwise
-- nil and why. Which piece doesn't matter (the user's call, 2026-10-30): male and female versions differ, and
-- what comes back is checked when it arrives. Equipment only, as low item numbers (1 is Chocobo Bedding) could
-- be a flag. for_id: the piece the NPC says was traded, when the menu names one.
local function if_equipment(npc, id, decision, for_id)
    local item = id and res.items[id]
    if item and (item.category == 'Armor' or item.category == 'Weapon') then return decision end
    return nil, string.format('%s names %s%s, which is not a piece of equipment.', npc, item_name(id),
        for_id and (' for ' .. item_name(for_id)) or '')
end

local function result_name(e)
    if e.result then return item_name(e.result) end
    return 'the upgraded piece'
end

-- Reforged pieces (not old sets) by job, kind, slot and tier, built on first use. Some sets (Maxixi) have
-- two items of each, for different races; races picks the one that matches the piece being upgraded.
local by_tier = nil
local function find_piece(job, kind, slot, tier, races)
    if not by_tier then
        by_tier = {}
        for id, item in pairs(res.items) do
            if item.category == 'Armor' then
                local p = ctx.classify(id)
                if p and not p.old then
                    local key = p.job .. '|' .. p.kind .. '|' .. p.slot .. '|' .. p.tier
                    by_tier[key] = by_tier[key] or {}
                    table.insert(by_tier[key], id)
                end
            end
        end
        for _, ids in pairs(by_tier) do table.sort(ids) end
    end
    local ids = by_tier[job .. '|' .. kind .. '|' .. slot .. '|' .. tier]
    if not ids then return nil end
    for _, id in ipairs(ids) do
        if res.items[id].races == races then return id end
    end
    return ids[1]
end

-- Menu Parameters is 32 bytes: eight little-endian uint32 values. n is 1-based.
local function param(params, n)
    local b1, b2, b3, b4 = params:byte(n * 4 - 3, n * 4)
    if not b4 then return nil end
    return b1 + b2 * 0x100 + b3 * 0x10000 + b4 * 0x1000000
end

-- Earth time of the next Vana'diel midnight, and minutes until it
local function next_day_at()
    local info = windower.ffxi.get_info()
    return os.time() + math.ceil((1440 - info.time) * GAME_MINUTE)
end

local function minutes_to_day()
    return math.max(math.ceil((next_day_at() - os.time()) / 60), 0)
end

-- Menus Reforge didn't answer, so new ones can be added from real data
local function log_menu(npc, menu, params)
    local f = files.new('data/menus.log')
    if not f:exists() then f:create() end
    f:append(os.date('[%Y-%m-%d %H:%M:%S] ') .. string.format('%s menu %d params %s\n', npc, menu, hex(params)))
end

local function log_dry(text)
    local f = files.new('data/dryrun.log')
    if not f:exists() then f:create() end
    f:append(os.date('[%Y-%m-%d %H:%M:%S] ') .. text .. '\n')
end

---------------------------------------------------------------- checks

-- The NPC if they can be traded with now, else nil and why not
local function npc_check(npc)
    local n = NPCS[npc]
    local info = windower.ffxi.get_info()
    if not info or info.zone ~= n.zone_id then return nil, 'you are not in ' .. n.zone .. '.' end
    local player = windower.ffxi.get_player()
    if not player or player.status ~= 0 then return nil, 'you must be idle (not fighting, resting or in a menu).' end
    local mob = n.id and windower.ffxi.get_mob_by_id(n.id) or windower.ffxi.get_mob_by_name(npc)
    if not mob or not mob.valid_target then return nil, npc .. ' is not in view.' end
    local distance = math.sqrt(mob.distance)
    if distance > TRADE_RANGE then
        return nil, string.format('%s is %.1f yalms away; get within %d.', npc, distance, TRADE_RANGE)
    end
    return mob
end

-- The NPC you are standing by, and their mob
local function nearby()
    for _, npc in ipairs(NPC_ORDER) do
        local mob = npc_check(npc)
        if mob then return npc, mob end
    end
end

-- The trades a piece's next step takes: 'day1' and 'day2' for Artifact +2 -> +3 at Coelestrox,
-- otherwise the one 'trade'
local TRADE_NO = {trade = 1, day1 = 1, day2 = 2}
local function stages(e)
    if e.npc == 'Coelestrox' and e.target == '+3' then return {'day1', 'day2'} end
    return {'trade'}
end

-- {id, name, count} for each item a trade needs, from the piece's next step. e is {npc, piece}.
local function trade_items(e, stage)
    local list = {}
    local step = ctx.next_step(ctx.classify(e.piece))
    for _, item in ipairs(step.trades[TRADE_NO[stage]].items) do
        list[#list + 1] = {id = item.id, name = item[1], count = item[2]}
    end
    for _, item in ipairs(list) do
        item.id = item.id or ctx.item_id(item.name)
        item.name = item.id and item_name(item.id) or item.name
    end
    return list
end

-- Usable inventory counts by item id (not equipped or bazaared), and the inventory itself
local function inventory_counts()
    local inv = windower.ffxi.get_items(0)
    local counts = {}
    for index = 1, inv.max or 80 do
        local s = inv[index]
        if type(s) == 'table' and s.id and s.id > 0 and s.status == 0 then
            counts[s.id] = (counts[s.id] or 0) + s.count
        end
    end
    return counts, inv
end

-- Inventory slots to trade: {{index, count}}, or nil and a list of what is short.
-- Equipped or bazaared items don't count.
local function allocate(list)
    local inv = windower.ffxi.get_items(0)
    local slots, short, used = {}, {}, {}
    for _, item in ipairs(list) do
        local left = item.count
        if item.id then
            for index = 1, inv.max or 80 do
                local s = inv[index]
                if left > 0 and type(s) == 'table' and s.id == item.id and s.status == 0 and not used[index] then
                    local take = math.min(left, s.count)
                    slots[#slots + 1] = {index = index, count = take}
                    used[index] = true
                    left = left - take
                end
            end
        end
        if left > 0 then
            short[#short + 1] = string.format('%s x%d', item.name, left) .. (item.id and '' or ' (unknown item)')
        end
    end
    if #short > 0 then return nil, short end
    if #slots > 8 then return nil, {'the items are split over more than 8 stacks; combine them first'} end
    return slots
end

-- Unequipped stacks in the bags Reforge may take from: {{bag, index, id, count}}
local function bag_stacks()
    local stacks = {}
    for _, bag in ipairs(FETCH_BAGS) do
        local items = windower.ffxi.get_items(bag)
        if items and items.enabled ~= false then
            for index = 1, items.max or 80 do
                local s = items[index]
                if type(s) == 'table' and s.id and s.id > 0 and s.status == 0 then
                    stacks[#stacks + 1] = {bag = bag, index = index, id = s.id, count = s.count}
                end
            end
        end
    end
    return stacks
end

local function free_slots(inv)
    local free = 0
    for index = 1, inv.max or 80 do
        local s = inv[index]
        if type(s) ~= 'table' or not s.id or s.id == 0 then free = free + 1 end
    end
    return free
end

-- Moves that cover need (id -> count) beyond what inventory has left after claimed, or nil if the bags can't.
-- Armor is never moved.
local function plan_moves(need, counts, claimed, stacks)
    local moves = {}
    for id, n in pairs(need) do
        local lack = n - ((counts[id] or 0) - (claimed[id] or 0))
        local item = res.items[id]
        if lack > 0 and item and item.category == 'Armor' then return nil end
        for _, s in ipairs(stacks) do
            if lack > 0 and s.id == id and s.count > 0 then
                local take = math.min(lack, s.count)
                moves[#moves + 1] = {stack = s, count = take}
                lack = lack - take
            end
        end
        if lack > 0 then return nil end
    end
    return moves
end

-- Rem's Tale chapter of an item id, or nil
local tale_chapters = nil
local function tale_chapter(id)
    if not tale_chapters then
        tale_chapters = {}
        for chapter = 1, 10 do
            local tale = ctx.item_id("Rem's Tale Ch." .. chapter)
            if tale then tale_chapters[tale] = chapter end
        end
    end
    return tale_chapters[id]
end

-- Whether need (id -> count) is covered by inventory, the bags and (at Monisette) stored tales.
-- Returns from_bags, withdraw (chapter -> count) when it is, or nil.
local function cover(need, counts, stacks, npc)
    local from_bags, withdraw = false, {}
    for id, n in pairs(need) do
        local lack = n - (counts[id] or 0)
        local item = res.items[id]
        if lack > 0 and not (item and item.category == 'Armor') then
            for _, st in ipairs(stacks) do
                if st.id == id and lack > 0 then
                    lack = lack - math.min(lack, st.count)
                    from_bags = true
                end
            end
        end
        if lack > 0 then
            local chapter = tale_chapter(id)
            if npc ~= 'Monisette' or not chapter or (stored[chapter] or 0) < lack then return nil end
            withdraw[chapter] = lack
        end
    end
    return from_bags, withdraw
end

-- Every piece in inventory that Reforge could upgrade, in inventory order:
-- {npc, piece, result, job, slot, short = {...} (empty when ready), equipped, from_bags}
-- A piece whose shortfall the bags (or at Monisette, stored tales) cover is ready too: from_bags, withdraw
-- (chapter -> count). Tales are withdrawn before the trade; bag materials are moved in when it is traded.
local function candidates()
    local counts, inv = inventory_counts()
    local stacks = bag_stacks()
    local list = {}
    for index = 1, inv.max or 80 do
        local s = inv[index]
        local p = type(s) == 'table' and s.id and s.id > 0 and ctx.classify(s.id)
        local step = p and ctx.next_step(p)
        local npc = step and (NPC_KEY[step.npc] or step.npc)
        if npc and NPCS[npc] then
            local e = {npc = npc, piece = p.id, job = p.job, slot = p.slot, target = step.target, short = {}}
            e.result = find_piece(p.job, p.kind, p.slot, TIER[step.target], res.items[p.id].races)
            -- every trade up front: for a +3 at Coelestrox, stopping between the days loses the day-1 trade
            local need = {}
            for _, stage in ipairs(stages(e)) do
                for _, item in ipairs(trade_items(e, stage)) do
                    if item.id then
                        need[item.id] = (need[item.id] or 0) + item.count
                    else
                        e.short[#e.short + 1] = item.name .. ' (unknown item)'
                        e.blocked = true
                    end
                end
            end
            for id, n in pairs(need) do
                if (counts[id] or 0) < n then
                    e.short[#e.short + 1] = string.format('%s x%d', item_name(id), n - (counts[id] or 0))
                    e.tales = e.tales or item_name(id):find("^Rem's Tale") ~= nil
                end
            end
            e.need, e.equipped = need, s.status ~= 0
            if not e.result then
                e.short[#e.short + 1] = 'no ' .. step.target .. ' found in resources'
                e.blocked = true
            end
            if #e.short > 0 and not e.blocked then
                local from_bags, withdraw = cover(need, counts, stacks, npc)
                if from_bags ~= nil then
                    e.short, e.tales, e.from_bags = {}, nil, from_bags
                    if next(withdraw) then e.withdraw = withdraw end
                end
            end
            list[#list + 1] = e
        end
    end
    return list
end

local function ready_to_go(e)
    return #e.short == 0 and not e.equipped
end

local function why_not(e)
    if e.equipped then return 'it is equipped' end
    return 'short of ' .. table.concat(e.short, ', ')
        .. (e.tales and ' (stored tales can be withdrawn from Monisette)' or '')
end

---------------------------------------------------------------- moving materials into inventory

-- Moves the planned stacks into inventory one at a time, then calls done(true)
local function move_all(moves, done)
    local parts, seen = {}, {}
    for _, m in ipairs(moves) do
        local key = m.stack.id .. '|' .. m.stack.bag
        if not seen[key] then
            seen[key] = {name = item_name(m.stack.id), bag = res.bags[m.stack.bag].en, count = 0}
            parts[#parts + 1] = seen[key]
        end
        seen[key].count = seen[key].count + m.count
    end
    for i, p in ipairs(parts) do parts[i] = string.format('%s x%d (%s)', p.name, p.count, p.bag) end
    if dry_run then
        say('Reforge [dry run]: would move to inventory: ' .. table.concat(parts, ', ') .. '.')
        return done(false)
    end
    say('Reforge: moving to inventory: ' .. table.concat(parts, ', ') .. '.')
    local function step(i)
        if not running then return end
        local m = moves[i]
        if not m then return coroutine.schedule(function() done(true) end, 2) end
        windower.ffxi.get_item(m.stack.bag, m.stack.index, m.count)
        coroutine.schedule(function() step(i + 1) end, MOVE_DELAY)
    end
    step(1)
end

-- Moves into inventory what one trade (list) is short of, just before it is traded, so nothing sits in
-- inventory for later steps. Only if the bags cover all of it and there is room. Calls done(moved).
local function fetch(list, done)
    local counts, inv = inventory_counts()
    local need = {}
    for _, item in ipairs(list) do
        if item.id then need[item.id] = (need[item.id] or 0) + item.count end
    end
    local moves = plan_moves(need, counts, {}, bag_stacks())
    if not moves or #moves == 0 then return done(false) end
    if #moves > free_slots(inv) then
        say(string.format('Reforge: no room to move %d stacks into inventory; free some space.', #moves), ctx.RED)
        return done(false)
    end
    move_all(moves, done)
end

---------------------------------------------------------------- packets

local function trade_packet(mob, slots)
    local fields = {['Target'] = mob.id, ['Target Index'] = mob.index, ['Number of Items'] = #slots}
    for i, s in ipairs(slots) do
        fields['Item Index ' .. i] = s.index
        fields['Item Count ' .. i] = s.count
    end
    return packets.new('outgoing', 0x036, fields)
end

local function talk_packet(mob)
    return packets.new('outgoing', 0x01A, {
        ['Target'] = mob.id, ['Target Index'] = mob.index, ['Category'] = 0, ['Param'] = 0,
    })
end

local function menu_packet(t, menu, option)
    return packets.new('outgoing', 0x05B, {
        ['Target'] = t.npc_id, ['Target Index'] = t.npc_index, ['Option Index'] = option, ['_unknown1'] = 0,
        ['Automated Message'] = false, ['_unknown2'] = 0, ['Zone'] = NPCS[t.npc].zone_id, ['Menu ID'] = menu,
    })
end

local function dry_send(p, what)
    log_dry(what .. ': ' .. hex(packets.build(p)))
    say('Reforge [dry run]: would send ' .. what .. '. Packet written to data/dryrun.log.')
end

-- Sends p and waits for the NPC's menu
local function send_expecting(p, t)
    pending = t
    coroutine.schedule(function()
        if pending == t then
            pending, running = nil, false
            say('Reforge: no menu from ' .. t.npc .. '. Stopped; check the NPC by hand.', ctx.RED)
        end
    end, REPLY_TIMEOUT)
    packets.inject(p)
end

---------------------------------------------------------------- steps

-- stage: 'day1' or 'day2' for a +3 at Coelestrox, otherwise 'trade' (see stages)
local function trade(e, stage, mob, fetched)
    local list = trade_items(e, stage)
    local slots, short = allocate(list)
    if not slots and not fetched then
        -- try the bags first, then look again
        return fetch(list, function() if running then trade(e, stage, mob, true) end end)
    end
    if not slots then
        running = false
        return say('Reforge: not in inventory: ' .. table.concat(short, ', ') .. '. Stopped.', ctx.RED)
    end
    local p = trade_packet(mob, slots)
    local what = ({trade = 'trade', day1 = 'day-1 trade', day2 = 'day-2 trade'})[stage]
    if dry_run then
        dry_send(p, what .. ' to ' .. e.npc .. ' for ' .. piece_name(e))
        say('Reforge [dry run]: would then accept if ' .. e.npc .. "'s menu names a piece of equipment"
            .. (e.npc == 'Coelestrox' and ' for the normal bead fee' or '') .. ' (' .. result_name(e) .. ' expected).')
        running = false -- nothing was traded, so there is nothing to wait for
        return
    end
    say(string.format('Reforge: %s for %s.', what, piece_name(e)))
    send_expecting(p, {kind = 'trade', npc = e.npc, entry = e, stage = stage, npc_id = mob.id, npc_index = mob.index})
end

-- Asks the NPC what they hold; what happens next depends on the answer.
-- Talking costs nothing, so this is sent even in debug.
local function ask(npc, mob)
    send_expecting(talk_packet(mob), {kind = 'ask', npc = npc, npc_id = mob.id, npc_index = mob.index})
end

-- Asks the NPC you are standing by what they hold, then acts on it
function M.go()
    if not running or pending then return end
    local npc, mob = nearby()
    if npc then return ask(npc, mob) end
    say("Reforge: stand by Coelestrox (Reisenjima), Monisette (Port Jeuno), Aurix (Ru'Lude Gardens) or Ruspix (Leafallia) and //frg start.")
    running = false
end

-- The NPC is working on a piece that isn't ready
local function holds_unfinished(npc, what)
    local known = traded_to[npc]
    local name = known and piece_name(known) or what
    if new_day then
        -- the day has changed by our clock, but not theirs yet
        say(string.format('Reforge: %s says %s is not ready yet. Asking again in a minute.', npc, name))
        coroutine.schedule(function() M.go() end, RETRY_DELAY)
    else
        say(string.format('Reforge: %s has %s; next step after the day change, in about %d min.',
            npc, name, minutes_to_day()), ctx.GREEN)
    end
end

-- The NPC holds nothing of yours: trade the next piece for them, or finish.
-- unsure: the NPC's menu can't say whether they hold a piece (Ruspix), so what Reforge last traded them is kept;
-- a trade they turn down says they do.
local function next_piece(npc, mob, unsure)
    local known = traded_to[npc]
    if not unsure then traded_to[npc] = nil end
    for _, e in ipairs(candidates()) do
        if e.npc == npc and ready_to_go(e) then return trade(e, stages(e)[1], mob) end
    end
    if unsure and known then return holds_unfinished(npc, 'your piece') end
    running = false
    if finished > 0 then return say('Reforge: all done, nothing left to upgrade here. Stopped.', ctx.GREEN) end
    say('Reforge: nothing to upgrade here: no piece in inventory with all its materials for ' .. npc
        .. (unsure and '.' or (', and ' .. npc .. ' has nothing of yours.')))
end

-- What //frg start shows: what can be done here, and what can't and why
-- tales: chapter -> count stored with Monisette, read from the currency page (may be nil)
function M.start(tales)
    running, finished, new_day, last_withdrawal = true, 0, false, nil
    if tales then stored = tales end
    local here = nearby()
    local list = candidates()
    -- pieces for another NPC: just say where they are done, whatever their materials
    for _, e in ipairs(list) do
        if e.npc ~= here then
            say(string.format('Reforge: %s -> %s is done at %s, %s.', piece_name(e), result_name(e), e.npc, NPCS[e.npc].zone))
        end
    end
    for _, e in ipairs(list) do
        if e.npc == here and not ready_to_go(e) then
            say(string.format('Reforge: %s skipped, %s.', item_name(e.piece), why_not(e)), ctx.RED)
        end
    end
    local shown = false
    for _, e in ipairs(list) do
        local line = string.format('    %s -> %s at %s', piece_name(e), result_name(e), e.npc)
            .. (e.withdraw and " (Rem's Tales taken from Monisette's storage first)" or '')
            .. (e.from_bags and ' (materials moved in from your bags when it is traded)' or '')
        if e.npc ~= here or not ready_to_go(e) then
            -- listed above
        else
            if not shown then
                say('Reforge: ready to upgrade' .. (dry_run and ' (debug dry run: nothing is sent)' or '') .. ':', ctx.GREEN)
                shown = true
            end
            say(line)
        end
    end
    if shown then
        say('    One at a time; pieces you add to inventory are picked up too. //frg stop to stop.')
    end
    M.go()
end

---------------------------------------------------------------- what the NPC said

-- The NPC handed over a finished piece; carry on with whatever is next
local function collected(npc, result)
    traded_to[npc] = nil
    finished = finished + 1
    new_day = false
    coroutine.schedule(function()
        local h = result and ctx.read_holdings()[result]
        if not result then
            say('Reforge: collected your piece from ' .. npc .. '.', ctx.GREEN)
        elseif h and h.inventory > 0 then
            say('Reforge: got ' .. item_name(result) .. '!', ctx.GREEN)
        else
            say('Reforge: ' .. item_name(result) .. ' is not in your inventory yet; check it arrived.', ctx.RED)
        end
        M.go()
    end, 3)
end

local function traded(e, result, text)
    traded_to[e.npc] = {npc = e.npc, piece = e.piece, result = result, slot = e.slot}
    new_day = false
    say(string.format('Reforge: %s Next step after the day change, in about %d min.', text, minutes_to_day()), ctx.GREEN)
end

-- Coelestrox: picks the answer to his menu, or nil and why it won't answer
local function decide_coelestrox(t, menu, params)
    local e = t.entry
    local result = param(params, 1)
    if t.kind == 'trade' then
        if menu ~= MENU_TRADE then
            return nil, string.format('Coelestrox replied with menu %d, not %d%s.', menu, MENU_TRADE,
                menu == 32 and ' (items missing; nothing should have been taken)' or '')
        end
        local fee, instant = param(params, 3), param(params, 4)
        local beads = BEADS[t.stage]
        if fee ~= beads or instant ~= INSTANT[t.stage] then
            return nil, string.format('the menu asks %s beads (instant %s); expected %d (instant %d).',
                tostring(fee), tostring(instant), beads, INSTANT[t.stage])
        end
        local what = ({day1 = 'Day 1', day2 = 'Day 2', trade = piece_name(e)})[t.stage]
        return if_equipment('Coelestrox', result, {option = OPTION_WAIT, after = function()
            traded(e, result, string.format('%s traded, %d beads paid (%d left).', what, beads, (param(params, 7) or 0) - beads))
        end})
    end

    -- asking what he holds
    local p = result and ctx.classify(result)
    local is_plus3 = p and p.kind == 'artifact' and not p.old and p.tier == 3
    if menu == MENU_IDLE then
        return {option = OPTION_IDLE, after = function() next_piece('Coelestrox', t.mob) end}
    elseif menu == MENU_NOT_READY and is_plus3 then
        -- the day-1 trade is done and the day has changed: he names the piece and wants the day-2 items
        return {option = OPTION_LEAVE, after = function()
            local e = {
                npc = 'Coelestrox', piece = find_piece(p.job, p.kind, p.slot, 2, res.items[result].races),
                result = result, job = p.job, slot = p.slot, target = '+3',
            }
            say(string.format('Reforge: Coelestrox has %s, ready for the day-2 trade.', piece_name(e)), ctx.GREEN)
            coroutine.schedule(function() trade(e, 'day2', t.mob) end, 2)
        end}
    elseif menu == MENU_NOT_READY then
        -- 1st param is the instant cost, which tells the step
        local instant = param(params, 1)
        if instant == INSTANT.trade then
            -- a +1 -> +2: 500, 1, 1, 0, 1, 0, beads, 4 when logged (feet); the 6th param isn't the slot here
            if not (param(params, 4) == 0 and param(params, 5) == 1 and param(params, 6) == 0) then
                return nil, 'Coelestrox has a +2 on the way, but its menu numbers are not ones Reforge knows.'
            end
            return {option = OPTION_LATER, after = function()
                holds_unfinished('Coelestrox', 'your piece (+2, collection next)')
            end}
        end
        local slot = PROBE_SLOT[param(params, 6)]
        local next_step = instant == A.instant.day1 and 'day-2 trade' or instant == 0 and 'collection' or nil
        if not (next_step and slot) then
            return nil, 'Coelestrox has a piece that is not ready, but its menu numbers are not ones Reforge knows.'
        end
        return {option = OPTION_LATER, after = function()
            holds_unfinished('Coelestrox', string.format('your %s piece (%s next)', slot, next_step))
        end}
    elseif menu == MENU_COLLECT then
        return if_equipment('Coelestrox', result, {option = OPTION_COLLECT, after = function() collected('Coelestrox', result) end})
    end
    return nil, string.format('Coelestrox showed menu %d, which Reforge does not know.',
        menu)
end

-- Monisette: picks the answer to her menu, or nil and why it won't answer
local function decide_monisette(t, menu, params)
    local e = t.entry
    local result = param(params, 1)
    if t.kind == 'trade' then
        if menu ~= M_TRADE then
            return nil, string.format('Monisette replied with menu %d offering %s for %s; expected menu %d.',
                menu, item_name(result), item_name(param(params, 4)), M_TRADE)
        end
        return if_equipment('Monisette', result, {option = M_OPTION, after = function()
            traded(e, result, 'Traded ' .. piece_name(e) .. ' to Monisette.')
        end}, param(params, 4))
    end

    -- asking what she holds
    if menu == M_IDLE then
        for chapter = 1, 10 do stored[chapter] = params:byte(16 + chapter) end
        -- the piece next_piece would trade: if it needs stored tales, withdraw one chapter and ask again
        for _, e in ipairs(candidates()) do
            if e.npc == 'Monisette' and ready_to_go(e) then
                local chapter = e.withdraw and next(e.withdraw)
                if not chapter or dry_run then break end
                local count = e.withdraw[chapter]
                local tale = ctx.item_id("Rem's Tale Ch." .. chapter)
                local have = inventory_counts()[tale] or 0
                if last_withdrawal and last_withdrawal.chapter == chapter and have <= last_withdrawal.before then
                    return nil, string.format("Rem's Tale Ch.%d didn't arrive after asking Monisette for it.", chapter)
                end
                last_withdrawal = {chapter = chapter, before = have}
                return {option = chapter + 256 * count, after = function()
                    say(string.format("Reforge: taking Rem's Tale Ch.%d x%d from Monisette for %s.",
                        chapter, count, piece_name(e)))
                    coroutine.schedule(function() M.go() end, 3)
                end}
            end
        end
        last_withdrawal = nil
        -- option 0 withdraws nothing and leaves
        return {option = M_OPTION, after = function() next_piece('Monisette', t.mob) end}
    elseif menu == M_BUSY then
        -- she is working on a piece, but this menu doesn't say which; her collect menu will
        return {option = M_OPTION, after = function() holds_unfinished('Monisette', 'your piece') end}
    elseif M_COLLECT[menu] then
        return if_equipment('Monisette', result, {option = M_OPTION, after = function() collected('Monisette', result) end})
    end
    return nil, string.format('Monisette showed menu %d, which Reforge does not know.',
        menu)
end

-- Aurix: picks the answer to his menu, or nil and why it won't answer
local function decide_aurix(t, menu, params)
    local e = t.entry
    local result = param(params, 1)
    if t.kind == 'trade' then
        if menu ~= A_TRADE then
            return nil, string.format('Aurix replied with menu %d offering %s; expected menu %d.',
                menu, item_name(result), A_TRADE)
        end
        return if_equipment('Aurix', result, {option = A_OPTION, after = function()
            traded(e, result, 'Traded ' .. piece_name(e) .. ' to Aurix.')
        end})
    end

    -- asking what he holds
    if menu == A_ASK and result == 0 then
        return {option = A_OPTION, after = function() next_piece('Aurix', t.mob) end}
    elseif menu == A_ASK and result == 1 then
        return {option = A_OPTION, after = function() holds_unfinished('Aurix', 'your piece') end}
    elseif menu == A_COLLECT then
        return if_equipment('Aurix', result, {option = A_OPTION, after = function() collected('Aurix', result) end})
    end
    return nil, string.format('Aurix showed menu %d (%s), which Reforge does not know.',
        menu, tostring(result))
end

-- Ruspix: picks the answer to his menu, or nil and why it won't answer. His menus never name the result.
local function decide_ruspix(t, menu, params)
    local e = t.entry
    if menu == R_COLLECT then
        -- also his reply to a trade when a piece is finished: the trade is ignored and the piece handed over,
        -- so the next talk shows menu 71 and the ignored piece is traded then
        local known = traded_to.Ruspix
        return {option = R_OPTION, after = function() collected('Ruspix', known and known.result) end}
    end
    if t.kind == 'trade' then
        if menu == R_BUSY then
            -- he turned the trade down: he is working on a piece, and the traded items stay with you
            return {option = R_OPTION, after = function() holds_unfinished('Ruspix', 'your piece') end}
        elseif menu ~= R_TRADE then
            return nil, string.format('Ruspix replied with menu %d naming %s; expected menu %d.',
                menu, item_name(param(params, 1)), R_TRADE)
        end
        -- his menu names the piece traded, not the result
        return if_equipment('Ruspix', param(params, 1), {option = R_OPTION, after = function()
            traded(e, e.result, 'Traded ' .. piece_name(e) .. ' to Ruspix.')
        end})
    end

    -- asking what he holds: menu 71 looks the same whether he is working on a piece or not
    if menu == R_ASK then
        return {option = R_OPTION, after = function() next_piece('Ruspix', t.mob, true) end}
    end
    return nil, string.format('Ruspix showed menu %d, which Reforge does not know.', menu)
end

local DECIDE = {Coelestrox = decide_coelestrox, Monisette = decide_monisette, Aurix = decide_aurix, Ruspix = decide_ruspix}

function M.incoming(id, data)
    if id ~= 0x034 then return end
    local p = packets.parse('incoming', data)
    if answered and os.time() - answered.at <= DUPLICATE_WINDOW and p['NPC'] == answered.npc
            and p['Menu ID'] == answered.menu and p['Menu Parameters'] == answered.params then
        return true -- the same menu again: already answered
    end
    if not pending then return end
    if p['NPC'] ~= pending.npc_id then return end
    local t = pending
    pending = nil
    t.mob = {id = t.npc_id, index = t.npc_index}

    local params = p['Menu Parameters'] or ''
    local decide = DECIDE[t.npc]
    local answer, why = decide(t, p['Menu ID'], params)
    if not answer then
        -- not one Reforge knows: log it, say so and stop, sending nothing more
        log_menu(t.npc, p['Menu ID'], params)
        running = false
        say('Reforge: something unexpected happened: ' .. why .. ' Logged to data/menus.log. Reforge has stopped.', ctx.RED)
        return
    end
    coroutine.schedule(function()
        packets.inject(menu_packet(t, p['Menu ID'], answer.option))
        answer.after()
    end, ANSWER_DELAY)
    answered = {npc = p['NPC'], menu = p['Menu ID'], params = params, at = os.time()}
    return true -- blocked, so the dialog never opens on screen
end

-- A new day: whatever the NPC holds may have moved on, so ask them again
function M.day_change()
    coroutine.schedule(function()
        if not running then return end
        new_day = true
        say('Reforge: new day.', ctx.GREEN)
        M.go()
    end, 3) -- let the server reach the new day too
end

---------------------------------------------------------------- commands

-- What each NPC was last given, and what is ready to go next
function M.status()
    say('Reforge: ' .. (running and 'running' or 'stopped') .. (dry_run and ' (debug dry run)' or '') .. '.')
    for _, npc in ipairs(NPC_ORDER) do
        local known = traded_to[npc]
        if known then
            say(string.format('  %s has %s -> %s.', npc, piece_name(known), result_name(known)))
        end
    end
    local any = false
    for _, e in ipairs(candidates()) do
        if ready_to_go(e) then
            if not any then say('  Ready to go next:') end
            any = true
            say(string.format('    %s -> %s at %s', piece_name(e), result_name(e), e.npc))
        end
    end
    if not any then say('  No piece in inventory has all its materials.') end
end

function M.reset()
    running, pending, new_day, finished, traded_to, answered = false, nil, false, 0, {}, nil
    stored, last_withdrawal = {}, nil -- another character's tales don't count
end

function M.dry_run()
    return dry_run
end

function M.set_dry_run(on)
    dry_run = on
    if on then
        say('Reforge: debug on. Trades are not sent; their packets go to data/dryrun.log.')
    else
        say('Reforge: debug off. Trades are sent as normal.')
    end
end

function M.stop()
    pending, running = nil, false
    say('Reforge: stopped. //frg start to carry on.')
end

function M.setup(context)
    ctx = context
end

return M
