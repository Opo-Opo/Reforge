--[[
Reforge - finds the Artifact, Relic and Empyrean armor a character owns and checks what each piece's next upgrade needs.

Install: put this folder in Windower/addons/reforge/ then  //lua load reforge
Commands work as //reforge, //frg or //forge; the help below uses //frg.
Usage:
  //frg scan [job]     every upgradeable piece you own and whether its next step is ready
  //frg check <name>   full list for pieces whose name contains <name>: what you have, where it is, what's missing
  //frg need [job]     shopping list of everything missing across all those next steps
Add inv to any of these (//frg scan inv, //frg need GEO inv) to look only at pieces in your inventory.
Materials still count from every bag, so they show where to move them from.
  //frg check inv      everything needed for every piece in your inventory: move pieces there to see what they need
Add slips to include armor stored on storage slips (//frg scan slips); those need a Porter Moogle first.
  //frg gather         (or //frg mats) in your Mog House: move what the pieces in your inventory are short of
                      out of the Mog Safes, Storage and Mog Locker into inventory
Covers old level 75 Artifact and Relic sets and old level 99 Empyrean sets, through to +3.
Trades only take items from inventory, so Reforge also says what to move there.
Upgrade recipes live in upgrades.lua.

Trading (see trader.lua): Coelestrox for Artifact +1 -> +2 and +2 -> +3, Monisette for old sets -> iL109 and iL109 -> +1,
Aurix for Relic +1 -> +2 and +2 -> +3, Ruspix for Empyrean +1 -> +2 and +2 -> +3.
  //frg start          upgrade, one at a time, every piece in inventory whose materials you have
  //frg stop           stop; //frg start carries on later
  //frg status         what each NPC was given, and what is ready to go next
  //frg debug [on|off] dry run: write trade packets to data/dryrun.log instead of sending them
Put the pieces in inventory, stand by the NPC and //frg start. Materials in your Satchel, Sack or Case
are moved into inventory for you, just before that piece is traded. There is no queue: each time
(at start, after a day change, after a collection) Reforge asks the NPC what they hold, collects or waits,
and when they hold nothing trades the next ready piece from your inventory. So an upgraded piece whose next
step is at the same NPC carries straight on, pieces added mid-run are picked up, and a crash, a reload or
anything done by hand is noticed the next time it asks.
]]

_addon.name = 'Reforge'
_addon.author = 'Opo-Opo'
_addon.version = '0.3.1'
_addon.commands = {'reforge', 'frg', 'forge'}

local res = require('resources')
local packets = require('packets')
local slips = require('slips')
local upgrades = require('upgrades')
local trader = require('trader')

local KINDS = {'artifact', 'relic', 'empyrean'}
local KIND_ORDER = {artifact = 1, relic = 2, empyrean = 3}
local SKIP_BAGS = {[3] = true, [17] = true} -- temporary items, recycle bin

local WHITE, RED, GREEN = 207, 167, 158

local function say(text, color)
    windower.add_to_chat(color or WHITE, text)
end

local slot_order = {}
for i, slot in ipairs(upgrades.slot_order) do slot_order[slot] = i end

-- first word of a set's long name -> {job, kind}
local set_of = {}
for job, words in pairs(upgrades.jobs) do
    for i, word in ipairs(words) do
        set_of[word] = {job = job, kind = KINDS[i]}
    end
end

-- full name of an old set piece, lowercase and without +1/+2 -> {job, kind, slot}
local old_of = {}
for job, sets in pairs(upgrades.old_sets) do
    for kind, names in pairs(sets) do
        for i, name in ipairs(names) do
            old_of[name:lower()] = {job = job, kind = kind, slot = upgrades.slot_order[i]}
        end
    end
end
for job, names in pairs(upgrades.old_empyrean) do
    for i, name in ipairs(names) do
        old_of[name:lower()] = {job = job, kind = 'empyrean', slot = upgrades.slot_order[i]}
    end
end
for alias, name in pairs(upgrades.old_aliases) do
    old_of[alias] = old_of[name:lower()]
end

-- lowercase short or full name -> item id, built on first use
local ids_by_name = nil
local function item_id(name)
    if not ids_by_name then
        ids_by_name = {}
        for id, item in pairs(res.items) do
            for _, key in ipairs({item.en, item.enl}) do
                key = key:lower()
                if not ids_by_name[key] then ids_by_name[key] = id end
            end
        end
    end
    return ids_by_name[name:lower()]
end

-- res.items[id].slots is a set of slot indices; armor pieces have exactly one
local function slot_name(slots)
    if type(slots) ~= 'table' then return nil end
    local found = nil
    for index in pairs(slots) do
        if found or not upgrades.slots[index] then return nil end
        found = upgrades.slots[index]
    end
    return found
end

-- Armor without a +N is labelled NQ, so "Bagua Pants NQ -> +1" can't be misread
local function piece_label(item)
    return item.en:find(' %+%d$') and item.en or (item.en .. ' NQ')
end

-- Old set pieces are found by full name; reforged pieces by the first word of the name
local function classify(id)
    local item = res.items[id]
    if not item or item.category ~= 'Armor' then return nil end
    local long = (item.enl or item.en or ''):lower()
    local tier = tonumber(long:match(' %+(%d)$')) or 0

    local old = old_of[(long:gsub(' %+%d$', ''))]
    if old then
        return {id = id, name = piece_label(item), job = old.job, kind = old.kind, slot = old.slot, tier = tier, old = true}
    end

    if (item.item_level or 0) < 109 then return nil end
    local slot = slot_name(item.slots)
    local set = slot and set_of[long:match('^(%S+)')]
    if not set then return nil end
    return {id = id, name = piece_label(item), job = set.job, kind = set.kind, slot = slot, tier = tier}
end

-- Returns the owned pieces, sorted, and holdings: id -> {total, inventory, bags = {bag name -> count}}
local function read_bags()
    local pieces, holdings = {}, {}
    for bag_id = 0, 17 do
        local bag = res.bags[bag_id]
        local items = bag and not SKIP_BAGS[bag_id] and windower.ffxi.get_items(bag_id)
        if items and items.enabled ~= false then
            for index, item in pairs(items) do
                if type(index) == 'number' and type(item) == 'table' and item.id and item.id > 0 then
                    local h = holdings[item.id]
                    if not h then
                        h = {total = 0, inventory = 0, bags = {}}
                        holdings[item.id] = h
                    end
                    h.total = h.total + item.count
                    h.bags[bag.en] = (h.bags[bag.en] or 0) + item.count
                    if bag_id == 0 then h.inventory = h.inventory + item.count end

                    local piece = classify(item.id)
                    if piece then
                        piece.bag = bag.en
                        pieces[#pieces + 1] = piece
                    end
                end
            end
        end
    end
    return pieces, holdings
end

local function sort_pieces(pieces)
    table.sort(pieces, function(a, b)
        if a.job ~= b.job then return a.job < b.job end
        if a.kind ~= b.kind then return KIND_ORDER[a.kind] < KIND_ORDER[b.kind] end
        if a.slot ~= b.slot then return slot_order[a.slot] < slot_order[b.slot] end
        if (a.old or false) ~= (b.old or false) then return a.old == true end
        return a.tier < b.tier
    end)
end

local function tales(chapter, count)
    return {"Rem's Tale Ch." .. chapter, count}
end

-- The next upgrade for a piece: {target, npc, zone, trades = {{label, items}}, notes, incomplete}
-- Each item is {name, count} or {name, count, id = n} for the piece itself.
-- Returns nil and a reason when there is no step to show.
local function next_step(p)
    local slot, job = p.slot, p.job
    local piece = {p.name, 1, id = p.id}

    -- Old level 75 sets -> iL109
    if p.old and p.kind == 'artifact' then
        local a = upgrades.artifact109
        if not a.tales[p.tier] then return nil, 'this tier is not in upgrades.lua' end
        return {
            target = 'iL109', npc = a.npc, zone = a.zone,
            trades = {{items = {piece, tales(a.chapter[slot], a.tales[p.tier]), {a.job_item[job], 1}, {a.slot_item[slot], 1}}}},
            notes = {a.note},
        }
    elseif p.old and p.kind == 'empyrean' then
        local e = upgrades.empyrean109
        if not e.tales[p.tier] then return nil, 'only the +1 or +2 can be reforged, not the NQ' end
        return {
            target = 'iL109', npc = e.npc, zone = e.zone,
            trades = {{items = {piece, tales(e.chapter[slot], e.tales[p.tier]), {e.job_item[job], 1}, {e.slot_item[slot], 1}}}},
            notes = {},
        }
    elseif p.old then
        local r = upgrades.relic109
        local count = r.currency_count[p.tier]
        if not count then return nil, 'this tier is not in upgrades.lua' end
        local items = {piece, tales(r.chapter[slot], r.tales)}
        if count > 0 then items[#items + 1] = {r.currency[job], count} end
        items[#items + 1] = {r.job_item[job], 1}
        items[#items + 1] = {r.slot_item[slot], 1}
        return {target = 'iL109', npc = r.npc, zone = r.zone, trades = {{items = items}}, notes = {r.note}}
    end

    if p.tier >= 3 then
        if p.kind == 'empyrean' then return nil, 'fully upgraded' end
        return nil, '+4 is done at the Limbus furnaces, which Reforge leaves out (no day wait)'
    end

    if p.kind == 'empyrean' and p.tier < 2 then
        if p.tier == 0 then
            local e = upgrades.empyrean1
            return {
                target = '+1', npc = e.npc, zone = e.zone,
                trades = {{items = {piece, tales(e.chapter[slot], e.tales), {'Etched Memory', e.memories[slot]}, {e.slot_item[slot], 1}}}},
                notes = {e.note},
            }
        end
        local e = upgrades.empyrean2
        local items = {piece}
        for _, item in ipairs(e.items) do items[#items + 1] = item end
        return {
            target = '+2', npc = e.npc, zone = e.zone,
            trades = {{items = items}},
            currencies = {{e.currency[1], e.currency[2]}},
            notes = {e.note},
        }
    end

    -- iL109 -> +1
    if p.tier == 0 then
        local u = upgrades[p.kind .. '1']
        return {
            target = '+1', npc = u.npc, zone = u.zone,
            trades = {{items = {piece, tales(u.chapter[slot], u.tales), {u.job_item[job], 1}, {u.slot_item[slot], 1}}}},
            notes = {},
        }
    end

    -- +1 -> +2
    if p.tier == 1 then
        local job_item = {upgrades.plus2_job_item[job], 1}
        if p.kind == 'artifact' then
            local a = upgrades.artifact2
            return {
                target = '+2', npc = a.npc, zone = a.zone,
                trades = {{items = {piece, {'P. ' .. job .. ' Card', a.cards[slot]}, job_item, {a.slot_item[slot], 1}}}},
                currencies = {{'Escha Beads', a.beads}},
                notes = {a.note},
            }
        end
        local r = upgrades.relic2
        return {
            target = '+2', npc = r.npc, zone = r.zone,
            trades = {{items = {piece, {upgrades.relic3.shard[slot] .. ': ' .. job, r.shards}, job_item, {r.slot_item[slot], 1}}}},
            notes = {r.note},
        }
    end

    -- +2 -> +3
    if p.kind == 'artifact' then
        local a = upgrades.artifact3
        return {
            target = '+3', npc = a.npc, zone = a.zone,
            trades = {
                {label = 'Day 1', items = {piece, {'P. ' .. job .. ' Card', a.cards[slot]}, {a.scale[job], 1}}},
                {label = 'Day 2', items = a.day2[slot]},
            },
            currencies = {{'Escha Beads', a.beads.day1 + a.beads.day2}},
            notes = {
                string.format('Beads are paid %d on day 1 and %d on day 2.', a.beads.day1, a.beads.day2),
                'Stopping partway loses everything already traded.',
            },
        }
    elseif p.kind == 'relic' then
        local r = upgrades.relic3
        return {
            target = '+3', npc = r.npc, zone = r.zone,
            trades = {{items = {
                piece,
                {r.shard[slot] .. ': ' .. job, r.count},
                {r.void[slot] .. ': ' .. job, r.count},
                {r.material[slot], r.count},
            }}},
            notes = {r.note},
        }
    else
        local e = upgrades.empyrean3
        local items = {piece}
        for _, item in ipairs(e.items) do items[#items + 1] = item end
        return {
            target = '+3', npc = e.npc, zone = e.zone,
            trades = {{items = items}},
            currencies = {{e.currency[1], e.currency[2]}},
            notes = {},
        }
    end
end

-- Reforged pieces (not old sets) by job, kind, slot and tier, built on first use
local reforged = nil
local STEP_TIER = {iL109 = 0, ['+1'] = 1, ['+2'] = 2, ['+3'] = 3}
local function upgraded(p, step)
    if not reforged then
        reforged = {}
        for id, item in pairs(res.items) do
            if item.category == 'Armor' then
                local r = classify(id)
                if r and not r.old then
                    local key = r.job .. '|' .. r.kind .. '|' .. r.slot .. '|' .. r.tier
                    reforged[key] = reforged[key] or id
                end
            end
        end
    end
    local id = reforged[p.job .. '|' .. p.kind .. '|' .. p.slot .. '|' .. STEP_TIER[step.target]]
    return id and classify(id)
end

-- The steps the same NPC does one after another, from p's next step: {{piece, step}, ...}, or nil and a reason.
-- In the later steps the piece is made by the step before, so its item is marked made.
local function steps_here(p)
    local step, reason = next_step(p)
    if not step then return nil, reason end
    local stages = {{piece = p, step = step}}
    while true do
        local last = stages[#stages]
        local np = upgraded(last.piece, last.step)
        local ns = np and next_step(np)
        if not ns or ns.npc ~= step.npc then break end
        for _, trade in ipairs(ns.trades) do
            for _, req in ipairs(trade.items) do
                if req.id then req.made = true end
            end
        end
        stages[#stages + 1] = {piece = np, step = ns}
    end
    return stages
end

-- Read from the game's currency pages: 'Escha Beads' and 'Gallimaufry' -> amount (Currencies 2),
-- and stored Rem's Tales, chapter -> count (Currencies 1). Fields are nil when a page didn't arrive.
local balances = {}
local waiting = {} -- functions to run once the pages arrive
local missing_pages = {} -- incoming packet id -> page name, for pages not arrived yet

local function run_waiting()
    local run = waiting
    waiting, missing_pages = {}, {}
    for _, f in ipairs(run) do f() end
end

-- Asks the game for both currency pages (as opening those menus does), then runs fn
local function with_balances(fn)
    waiting[#waiting + 1] = fn
    if #waiting > 1 then return end
    balances = {}
    missing_pages = {[0x113] = "Currencies 1 (stored Rem's Tales)", [0x118] = 'Currencies 2 (beads, Gallimaufry)'}
    packets.inject(packets.new('outgoing', 0x10F, {}))
    packets.inject(packets.new('outgoing', 0x115, {}))
    coroutine.schedule(function()
        if #waiting == 0 then return end
        for _, page in pairs(missing_pages) do
            say("Reforge: couldn't read " .. page .. '; not checked this time.', RED)
        end
        run_waiting()
    end, 3)
end

local function currencies_arrived(id, data)
    if not missing_pages[id] then return end
    local p = packets.parse('incoming', data)
    if id == 0x118 then
        balances['Escha Beads'] = p['Escha Beads']
        balances['Gallimaufry'] = p['Gallimaufry']
    else
        balances.tales = {}
        for chapter = 1, 10 do balances.tales[chapter] = p['Rems Tale Chapter ' .. chapter] end
    end
    missing_pages[id] = nil
    if next(missing_pages) == nil then run_waiting() end
end

-- Armor stored on storage slips: slip name -> list of item ids
local function slip_contents()
    local found = {}
    for slip_id, ids in pairs(slips.get_player_items()) do
        local list = {}
        for _, id in ipairs(ids) do list[#list + 1] = id end
        if #list > 0 then found[res.items[slip_id].en] = list end
    end
    return found
end

-- read_bags, plus Rem's Tales stored with the NPC (counted as owned, but not in inventory),
-- plus armor on storage slips when with_slips is set
local function read_all(with_slips)
    local pieces, holdings = read_bags()
    if with_slips then
        for slip, ids in pairs(slip_contents()) do
            for _, id in ipairs(ids) do
                local h = holdings[id] or {total = 0, inventory = 0, bags = {}}
                holdings[id] = h
                h.total = h.total + 1
                h.bags[slip] = 1
                local piece = classify(id)
                if piece then
                    piece.bag = slip
                    pieces[#pieces + 1] = piece
                end
            end
        end
    end
    sort_pieces(pieces)
    for chapter, count in pairs(balances.tales or {}) do
        local id = item_id("Rem's Tale Ch." .. chapter)
        if id and count > 0 then
            local h = holdings[id] or {total = 0, inventory = 0, bags = {}}
            holdings[id] = h
            h.total = h.total + count
            h.bags['Stored'] = count
        end
    end
    return pieces, holdings
end

-- {have, missing} for a currency, or nil when it can't be checked
local function currency_holding(name, amount)
    local have = balances[name]
    if not have then return nil end
    return {have = have, missing = math.max(amount - have, 0)}
end

-- Bags whose materials Reforge can't move in at trade time: the Mog House ones (//frg gather) and slips
local MOG_HOUSE = {}
for _, bag in ipairs({1, 9, 2, 4}) do MOG_HOUSE[res.bags[bag].en] = true end
local function slip(name) return name:find('^Storage Slip') ~= nil end

-- used: id -> count already taken by earlier steps of the same piece (optional)
-- move is what you have to move in yourself: the piece itself from anywhere, materials only from the Mog House
-- (mog) or slips (slip); materials in carried bags or stored with Monisette come in when the piece is traded.
local function holding(req, holdings, used)
    local id = req.id or item_id(req[1])
    local h = id and holdings[id]
    local need = req[2]
    local taken = used and id and used[id] or 0
    local have = math.max((h and h.total or 0) - taken, 0)
    -- earlier steps take from inventory first, then the carried bags, then the Mog House, then slips
    local inventory = h and h.inventory or 0
    local carried, mog, slips = 0, 0, 0
    for name, count in pairs(h and h.bags or {}) do
        if MOG_HOUSE[name] then
            mog = mog + count
        elseif slip(name) then
            slips = slips + count
        elseif name ~= res.bags[0].en then
            carried = carried + count
        end
    end
    local left = taken
    local function after_taken(pool)
        local take = math.min(left, pool)
        left = left - take
        return pool - take
    end
    inventory, carried, mog = after_taken(inventory), after_taken(carried), after_taken(mog)
    local move = math.max(math.min(need, have) - inventory, 0)
    if not req.id then
        move = math.max(move - carried, 0)
        mog = math.min(move, mog)
        slips = move - mog
    end
    return {
        id = id,
        need = need,
        have = have,
        missing = math.max(need - have, 0),
        taken = taken,
        move = move,
        mog = mog,
        slip = slips,
        bags = h and h.bags or {},
    }
end

local function where(bags)
    local parts = {}
    for name, count in pairs(bags) do parts[#parts + 1] = name .. ' ' .. count end
    table.sort(parts)
    return table.concat(parts, ', ')
end

local function summary(stages, holdings)
    local missing, move, used, cost, incomplete = 0, 0, {}, {}, false
    for _, stage in ipairs(stages) do
        local step = stage.step
        for _, trade in ipairs(step.trades) do
            for _, req in ipairs(trade.items) do
                if not req.made then
                    local h = holding(req, holdings, used)
                    if h.missing > 0 then
                        missing = missing + 1
                    elseif h.move > 0 then
                        move = move + 1
                    end
                    if h.id then used[h.id] = (used[h.id] or 0) + req[2] end
                end
            end
        end
        for _, c in ipairs(step.currencies or {}) do cost[c[1]] = (cost[c[1]] or 0) + c[2] end
        incomplete = incomplete or step.incomplete
    end
    for name, amount in pairs(cost) do
        local h = currency_holding(name, amount)
        if h and h.missing > 0 then missing = missing + 1 end
    end
    local step = {incomplete = incomplete}
    local gap = step.incomplete and ' (recipe incomplete)' or ''
    if missing > 0 then
        return string.format('missing %d item%s%s', missing, missing == 1 and '' or 's', gap), RED
    elseif move > 0 then
        return string.format('have everything, move %d to inventory%s', move, gap), WHITE
    end
    return 'ready' .. gap, step.incomplete and WHITE or GREEN
end

local INVENTORY = res.bags[0].en

-- job: only that job's pieces. inv: only pieces in inventory (materials still count from every bag)
local function matches(piece, job, inv)
    return (not job or piece.job == job) and (not inv or piece.bag == INVENTORY)
end

local function where_text(job, inv)
    return (job and (' for ' .. job) or '') .. (inv and ' in your inventory' or '')
end

local KIND_NAME = {artifact = 'Artifact', relic = 'Relic', empyrean = 'Empyrean'}
local TARGET_ORDER = {iL109 = 1, ['+1'] = 2, ['+2'] = 3, ['+3'] = 4}

-- Pieces grouped under job, set type and NPC headings, so each line only needs the piece
local function scan(job, inv, with_slips)
    local pieces, holdings = read_all(with_slips)
    local groups = {} -- {job, kind, npc, zone, target (the earliest step), lines}
    for _, p in ipairs(pieces) do
        local stages = matches(p, job, inv) and steps_here(p)
        local step = stages and stages[1].step
        if step then
            local key = p.job .. '|' .. p.kind .. '|' .. step.npc
            local g = groups[key]
            if not g then
                g = {job = p.job, kind = p.kind, npc = step.npc, zone = step.zone, target = step.target, lines = {}}
                groups[key] = g
                groups[#groups + 1] = g
            elseif TARGET_ORDER[step.target] < TARGET_ORDER[g.target] then
                g.target = step.target -- a group goes where its earliest step would
            end
            local text, color = summary(stages, holdings)
            local targets = {}
            for i, stage in ipairs(stages) do targets[i] = stage.step.target end
            g.lines[#g.lines + 1] = {string.format('   %s -> %s: %s', p.name, table.concat(targets, ' -> '), text), color}
        end
    end
    if #groups == 0 then
        return say('Reforge: no upgradeable pieces found' .. where_text(job, inv) .. '.')
    end

    -- pieces are already sorted by job, type and slot; groups keep that and go in upgrade order
    table.sort(groups, function(a, b)
        if a.job ~= b.job then return a.job < b.job end
        if a.kind ~= b.kind then return KIND_ORDER[a.kind] < KIND_ORDER[b.kind] end
        return TARGET_ORDER[a.target] < TARGET_ORDER[b.target]
    end)
    local last_job, last_kind
    for _, g in ipairs(groups) do
        if g.job ~= last_job then
            say('== ' .. g.job .. ' ==')
            last_job, last_kind = g.job, nil
        end
        if g.kind ~= last_kind then
            say(' ' .. KIND_NAME[g.kind])
            last_kind = g.kind
        end
        say(string.format('  %s, %s:', g.npc, g.zone))
        for _, line in ipairs(g.lines) do say(line[1], line[2]) end
    end
    say('Reforge: //frg check <name> for details, //frg need for a shopping list.')
end

-- With inv and no name, every piece in inventory: put a piece there to see what its upgrade needs
local function check(text, inv, with_slips)
    if text == '' and not inv then
        say('Reforge: //frg check <part of an item name>, or //frg check inv for every piece in inventory')
        return
    end
    local pieces, holdings = read_all(with_slips)
    local found = 0
    for _, p in ipairs(pieces) do
        local long = (res.items[p.id].enl or ''):lower()
        if matches(p, nil, inv) and (p.name:lower():find(text, 1, true) or long:find(text, 1, true)) then
            found = found + 1
            local stages, reason = steps_here(p)
            if not stages then
                say(string.format('%s (%s): %s.', p.name, p.bag, reason))
            else
                local first = stages[1].step
                local targets = {}
                for i, stage in ipairs(stages) do targets[i] = stage.step.target end
                say(string.format('%s (%s) -> %s at %s, %s', p.name, p.bag, table.concat(targets, ' -> '), first.npc, first.zone))
                local used = {} -- what earlier steps take, so a shared material is only counted once
                for _, stage in ipairs(stages) do
                    local step = stage.step
                    if #stages > 1 then say(string.format('  -> %s:', step.target)) end
                    for _, trade in ipairs(step.trades) do
                        if trade.label then say('  ' .. trade.label .. ':') end
                        for _, req in ipairs(trade.items) do
                            local h = holding(req, holdings, used)
                            if h.id and not req.made then used[h.id] = (used[h.id] or 0) + req[2] end
                            local line = string.format('    %s: %d/%d', req[1], h.have, req[2]) -- have/need
                            if h.taken > 0 then
                                line = line .. string.format(' (%s; %d used by the step before)', where(h.bags), h.taken)
                            elseif h.have > 0 then
                                line = line .. ' (' .. where(h.bags) .. ')'
                            end
                            if req.made then
                                line = string.format('    %s: from the step before', req[1])
                            elseif req.id then
                                -- the piece itself: there is only ever one, so just say where it is
                                local bags = {}
                                for name in pairs(h.bags) do bags[#bags + 1] = name end
                                line = string.format('    %s: in %s', req[1], table.concat(bags, ', '))
                            end
                            local on_slip = false
                            for name in pairs(h.bags) do on_slip = on_slip or slip(name) end
                            if req.made then
                                say(line)
                            elseif req.id and h.move > 0 and on_slip then
                                say(line .. ' - retrieve it from a Porter Moogle')
                            elseif req.id and h.move > 0 then
                                say(line .. ' - move to inventory')
                            elseif not h.id then
                                say(line .. ' - item name not found in resources', RED)
                            elseif h.missing > 0 then
                                say(line .. string.format(' - get %d', h.missing), RED)
                            elseif h.move > 0 then
                                local todo = {}
                                if h.mog > 0 then todo[#todo + 1] = string.format('%d to //frg gather in your Mog House', h.mog) end
                                if h.slip > 0 then todo[#todo + 1] = string.format('retrieve %d from a Porter Moogle', h.slip) end
                                say(line .. ' - ' .. table.concat(todo, ', then '))
                            else
                                say(line .. ' - ok', GREEN)
                            end
                        end
                    end
                    for _, c in ipairs(step.currencies or {}) do
                        local h = currency_holding(c[1], c[2])
                        if not h then
                            say(string.format('  %s: ?/%d (not checked)', c[1], c[2]))
                        elseif h.missing > 0 then
                            say(string.format('  %s: %d/%d - get %d', c[1], h.have, c[2], h.missing), RED)
                        else
                            say(string.format('  %s: %d/%d - ok', c[1], h.have, c[2]), GREEN)
                        end
                    end
                    for _, note in ipairs(step.notes) do say('  ' .. note) end
                end
            end
        end
    end
    if found == 0 then
        say('Reforge: you don\'t own an Artifact, Relic or Empyrean piece matching "' .. text .. '"'
            .. where_text(nil, inv) .. '.')
    end
end

local function need(job, inv, with_slips)
    local pieces, holdings = read_all(with_slips)
    local totals, order, currencies, incomplete = {}, {}, {}, {}
    for _, p in ipairs(pieces) do
        for _, stage in ipairs(matches(p, job, inv) and steps_here(p) or {}) do
            local step = stage.step
            for _, trade in ipairs(step.trades) do
                for _, req in ipairs(trade.items) do
                    if not req.id then -- the piece itself is already owned, or made by the step before
                        if not totals[req[1]] then
                            totals[req[1]] = 0
                            order[#order + 1] = req[1]
                        end
                        totals[req[1]] = totals[req[1]] + req[2]
                    end
                end
            end
            for _, c in ipairs(step.currencies or {}) do
                if not currencies[c[1]] then
                    currencies[#currencies + 1] = c[1]
                    currencies[c[1]] = {}
                end
                table.insert(currencies[c[1]], c[2]) -- one cost per upgrade
            end
            if step.incomplete then incomplete[#incomplete + 1] = p.name end
        end
    end

    table.sort(order)
    local any = false
    for _, name in ipairs(order) do
        local h = holding({name, totals[name]}, holdings)
        if h.missing > 0 then
            say(string.format('%s: %d/%d - get %d', name, h.have, totals[name], h.missing), RED)
            any = true
        end
    end
    if not any then say('Reforge: you have every item for each piece\'s steps at its next NPC' .. where_text(job, inv) .. '.') end
    -- currencies are paid per upgrade, so say how many upgrades they cover, cheapest first
    for _, currency in ipairs(currencies) do
        local costs = currencies[currency]
        table.sort(costs)
        local total = 0
        for _, cost in ipairs(costs) do total = total + cost end
        local each = costs[1] == costs[#costs] and string.format('%d each', costs[1])
            or string.format('%d to %d each', costs[1], costs[#costs])
        local h = currency_holding(currency, total)
        if not h then
            say(string.format('%s: %d upgrade%s need it (%s, not checked)', currency, #costs, #costs == 1 and '' or 's', each))
        else
            local enough, left = 0, h.have
            for _, cost in ipairs(costs) do
                if cost > left then break end
                enough, left = enough + 1, left - cost
            end
            if enough == #costs then
                say(string.format('%s: have %d, enough for all %d upgrade%s (%s)', currency, h.have, #costs,
                    #costs == 1 and '' or 's', each), GREEN)
            else
                say(string.format('%s: have %d, enough for %d of %d upgrades (%s); %d more for all', currency, h.have,
                    enough, #costs, each, h.missing), enough == 0 and RED or WHITE)
            end
        end
    end
    if #incomplete > 0 then
        say('Recipes not in upgrades.lua yet: ' .. table.concat(incomplete, ', '))
    end
end

-- Bags only open in the Mog House, which //frg gather takes from
local MOG_BAGS = {1, 9, 2, 4} -- Mog Safe, Mog Safe 2, Storage, Mog Locker
local MOG_NAME = {[1] = 'Mog Safe', [9] = 'Mog Safe 2', [2] = 'Storage', [4] = 'Mog Locker'}
local GATHER_DELAY = 1 -- seconds between moving stacks
local gathering = false

-- //frg gather: in the Mog House, moves into inventory what the pieces in inventory are short of for every step
-- their next NPC can do, counting inventory, the bags you carry and stored Rem's Tales as already there.
local function gather()
    local info = windower.ffxi.get_info()
    if not (info and info.mog_house) then
        return say('Reforge: //frg gather only works in your Mog House, where the Mog Safes, Storage and Locker are.')
    end
    if gathering then return say('Reforge: already gathering.') end
    local pieces, holdings = read_all(false)

    -- what the inventory pieces need, all steps at their next NPC
    local need, order, names = {}, {}, {}
    for _, p in ipairs(pieces) do
        if p.bag == res.bags[0].en then
            for _, stage in ipairs(steps_here(p) or {}) do
                for _, trade in ipairs(stage.step.trades) do
                    for _, req in ipairs(trade.items) do
                        local id = not req.id and item_id(req[1])
                        if id then
                            if not need[id] then order[#order + 1] = id end
                            need[id] = (need[id] or 0) + req[2]
                            names[id] = req[1]
                        end
                    end
                end
            end
        end
    end
    if #order == 0 then
        return say('Reforge: no piece in your inventory has a next step; put the pieces to upgrade in inventory first.')
    end

    -- what is short once inventory, carried bags and stored tales count, taken from the Mog House bags
    local mog_names = {}
    for _, bag in ipairs(MOG_BAGS) do mog_names[res.bags[bag].en] = true end
    local stacks = {}
    for _, bag in ipairs(MOG_BAGS) do
        local items = windower.ffxi.get_items(bag)
        if items and items.enabled ~= false then
            for index = 1, items.max or 80 do
                local st = items[index]
                if type(st) == 'table' and st.id and st.id > 0 and st.status == 0 then
                    stacks[#stacks + 1] = {bag = bag, index = index, id = st.id, count = st.count}
                end
            end
        end
    end
    local moves, missing = {}, {}
    for _, id in ipairs(order) do
        local h = holdings[id]
        local carried = h and h.total or 0
        for name, count in pairs(h and h.bags or {}) do
            if mog_names[name] then carried = carried - count end
        end
        local lack = need[id] - carried
        for _, st in ipairs(stacks) do
            if lack > 0 and st.id == id then
                local take = math.min(lack, st.count)
                moves[#moves + 1] = {bag = st.bag, index = st.index, id = id, count = take}
                lack = lack - take
            end
        end
        if lack > 0 then missing[#missing + 1] = string.format('%s x%d', names[id], lack) end
    end

    local inv = windower.ffxi.get_items(0)
    local free = 0
    for index = 1, inv.max or 80 do
        local st = inv[index]
        if type(st) ~= 'table' or not st.id or st.id == 0 then free = free + 1 end
    end
    local left_out = 0
    while #moves > free do
        table.remove(moves)
        left_out = left_out + 1
    end

    local parts = {}
    for _, m in ipairs(moves) do
        parts[#parts + 1] = string.format('%s x%d (%s)', names[m.id], m.count, MOG_NAME[m.bag])
    end
    if #moves == 0 and left_out == 0 then
        say('Reforge: nothing to gather; nothing the inventory pieces need is in the Mog Safes, Storage or Locker.')
    elseif #moves > 0 then
        say('Reforge: moving to inventory: ' .. table.concat(parts, ', ') .. '.', GREEN)
    end
    if left_out > 0 then
        say(string.format('Reforge: no room for %d more stack%s; free some inventory space and //frg gather again.',
            left_out, left_out == 1 and '' or 's'), RED)
    end
    if #missing > 0 then say('Reforge: not in any bag: ' .. table.concat(missing, ', ') .. '.', RED) end

    gathering = #moves > 0
    local function step(i)
        local m = moves[i]
        if not m then
            gathering = false
            return
        end
        windower.ffxi.get_item(m.bag, m.index, m.count)
        coroutine.schedule(function() step(i + 1) end, GATHER_DELAY)
    end
    step(1)
end

windower.register_event('addon command', function(cmd, ...)
    cmd = cmd and cmd:lower() or 'help'
    local args = {...}

    -- 'inv' anywhere limits scan, check and need to pieces in inventory; 'slips' adds armor on storage slips
    local inv, with_slips = false, false
    for i = #args, 1, -1 do
        local word = args[i]:lower()
        if word == 'inv' or word == 'slips' then
            inv = inv or word == 'inv'
            with_slips = with_slips or word == 'slips'
            table.remove(args, i)
        end
    end

    if cmd == 'scan' or cmd == 'need' then
        local job = args[1] and args[1]:upper() or nil
        if job and not upgrades.jobs[job] then
            say('Reforge: unknown job "' .. args[1] .. '"')
        elseif cmd == 'scan' then
            with_balances(function() scan(job, inv, with_slips) end)
        else
            with_balances(function() need(job, inv, with_slips) end)
        end
    elseif cmd == 'check' then
        local text = table.concat(args, ' '):lower()
        if text == '' and not inv then
            check(text, inv) -- just the usage line; no need to ask for currencies
        else
            with_balances(function() check(text, inv, with_slips) end)
        end
    elseif cmd == 'status' or cmd == 'queue' then
        trader.status()
    elseif cmd == 'start' then
        -- stored Rem's Tales first, so pieces Monisette's storage can cover count as ready
        with_balances(function() trader.start(balances.tales) end)
    elseif cmd == 'debug' then
        local mode = args[1] and args[1]:lower()
        trader.set_dry_run(mode == 'on' or (mode ~= 'off' and not trader.dry_run()))
    elseif cmd == 'stop' then
        trader.stop()
    elseif cmd == 'gather' or cmd == 'mats' then
        with_balances(gather) -- stored Rem's Tales count as already there
    else
        say('Reforge: //frg scan [job] [inv|slips] | check <name> [inv|slips] | need [job] [inv|slips]')
        say('Reforge: //frg start | stop | status | debug | gather (or mats, in your Mog House)')
    end
end)

trader.setup({
    say = say,
    item_id = item_id,
    classify = classify,
    next_step = next_step,
    read_holdings = function() local _, holdings = read_bags() return holdings end,
    RED = RED,
    GREEN = GREEN,
})

windower.register_event('incoming chunk', function(id, original)
    if id == 0x113 or id == 0x118 then currencies_arrived(id, original) end
    return trader.incoming(id, original)
end)

windower.register_event('day change', trader.day_change)

windower.register_event('load', function()
    trader.reset()
end)

windower.register_event('login', function()
    trader.reset()
end)
