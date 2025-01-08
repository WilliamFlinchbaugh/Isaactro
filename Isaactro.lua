SMODS.Atlas {
    key = "IsaactroJokers", 
    path = "isaactro_jokers.png", 
    px = 71,
    py = 95
}

SMODS.Atlas {
    key = "IsaactroTags", 
    path = "isaactro_tags.png", 
    px = 34,
    py = 34
}

SMODS.current_mod.config_tab = function() --Config tab
    return {}
end

-- Helper functions
-- help from Accretion Disk Joker in ExtraCredit Mod: https://github.com/GuilloryCraft/ExtraCredit/blob/main/src/essay.lua
local function level_of_most_played()
    local _hand, _tally = nil, 0
    for k, v in ipairs(G.handlist) do
        -- if not in game yet, skip
        if not G.GAME.hands[v] then
            goto continue
        end
        -- count the most played hand
        if G.GAME.hands[v].visible and G.GAME.hands[v].played > _tally then
            _hand = v
            _tally = G.GAME.hands[v].played
        end
        ::continue::
    end
    if not _hand then
        return 1
    end
    local hand = localize(_hand, 'poker_hands')
    return G.GAME.hands[hand].level or 1
end


-- QUALITY 0 JOKERS (all common)

-- Missing No.
SMODS.Joker {
    key = "missingno",
    loc_txt = {
        name = 'Missing No.',
        text = {
            "When {C:attention}Boss Blind{} is defeated,",
            "{C:attention}destroy{} all other Jokers",
            "and replace them with",
            "{C:attention}random Jokers{}",
            "After triggered once, this Joker",
            "becomes {C:attention}Eternal{}",
            "{C:inactive}(Eternal Jokers cannot be sold or destroyed)"
        }
    },
    config = { extra = {} },
    pos = {
        x = 2,
        y = 37
    },
    cost = 3,
    rarity = 1,
    blueprint_compat = false,
    eternal_compat = true,
    unlocked = true,
    discovered = true,
    atlas = 'IsaactroJokers',

    loc_vars = function(self, info_queue, card)
        return {vars = {}}
    end,

    calculate = function(self, card, context)
        if context.end_of_round and not context.repetition and context.game_over == false and G.GAME.blind.boss and #G.jokers.cards > 1 then
            -- destroy all other jokers
            local num_destroyed = 0
            for _, other_joker in ipairs(G.jokers.cards) do
                if other_joker ~= card and not other_joker.ability.eternal then
                    num_destroyed = num_destroyed + 1
                    G.E_MANAGER:add_event(Event({trigger = 'before', blockable = true,
                        func = function()
                            G.jokers:remove_card(other_joker)
                            other_joker:remove()
                            other_joker = nil
                            return true
                        end
                    })) 
                end
            end

            -- set to eternal
            if not card.ability.eternal then
                -- create a copy of this card as eternal
                local new_card = copy_card(card, nil)
                play_sound('holo1', 1.2 + math.random()*0.1, 0.4)
                new_card:set_eternal(true)
                new_card:add_to_deck()
                G.jokers:emplace(new_card)

                -- remove the old card
                G.E_MANAGER:add_event(Event({
                    func = function()
                    play_sound('tarot1')
                    card.T.r = -0.2
                    card:juice_up(0.3, 0.4)
                    card.states.drag.is = true
                    card.children.center.pinch.x = true
                    G.E_MANAGER:add_event(Event({
                        trigger = 'immediate',
                        blockable = false,
                        func = function()
                        G.jokers:remove_card(card)
                        card:remove()
                        card = nil
                        return true;
                        end
                    }))
                    return true
                    end
                }))
            end

            -- add jokers up to the number of joker slots
            for i = 1, num_destroyed do
                G.E_MANAGER:add_event(Event({
                    trigger = 'after',
                    delay = 0.5,
                    blockable = true,
                    blocking = true,
                    func = function()
                        local joker = create_card('Joker', G.joker, nil, nil, nil, nil, nil, 'missingno')
                        joker:add_to_deck()
                        G.jokers:emplace(joker)
                        play_sound('holo1', 1.2 + math.random()*0.1, 0.4)
                        return true
                    end
                }))
            end

            return {
                message = "^$#%Corrupt!*@)&",
                colour = G.C.RED
            }
        end
    end
}

-- Box
SMODS.Joker { 
    key = "box",
    loc_txt = {
        name = 'Box',
        text = {
            "After {C:attention}#1#{} rounds, sell this card",
            "to gain {C:attention}1 random Planet Card",
            "and {C:attention}1 random Tarot Card",
            "{C:inactive}(Currently {C:attention}#2#{C:inactive}/#1#)"
        }
    },
    config = { extra = { rounds_needed = 1, rounds = 0 } },
    pos = {
        x = 3,
        y = 31
    },
    cost = 5,
    rarity = 1,
    blueprint_compat = false,
    eternal_compat = false,
    unlocked = true,
    discovered = true,
    atlas = 'IsaactroJokers',

    loc_vars = function(self, info_queue, card)
        return {vars = { card.ability.extra.rounds_needed, card.ability.extra.rounds }}
    end,

    calculate = function(self, card, context)
        if context.end_of_round and not context.blueprint and not context.individual and not context.repetition and card.ability.extra.rounds < card.ability.extra.rounds_needed then
            card.ability.extra.rounds = card.ability.extra.rounds + 1
            if card.ability.extra.rounds >= card.ability.extra.rounds_needed then
                local eval = function(card) return not card.REMOVED end
                juice_card_until(card, eval, true)
                return {
                    message = localize('k_active_ex'),
                    colour = G.C.FILTER
                }
            end

        elseif context.selling_self and card.ability.extra.rounds >= card.ability.extra.rounds_needed then
            if #G.consumeables.cards + G.GAME.consumeable_buffer < G.consumeables.config.card_limit then
                G.GAME.consumeable_buffer = G.GAME.consumeable_buffer + 1
                G.E_MANAGER:add_event(Event({
                    trigger = 'before',
                    delay = 0.0,
                    func = (function()
                            local card = create_card('Tarot', G.consumeables, nil, nil, nil, nil, nil, 'box')
                            card:add_to_deck()
                            G.consumeables:emplace(card)
                            G.GAME.consumeable_buffer = 0
                        return true
                    end)}))
                card_eval_status_text(context.blueprint_card or card, 'extra', nil, nil, nil, {message = localize('k_plus_tarot'), colour = G.C.SECONDARY_SET.Spectral})
            end

            if #G.consumeables.cards + G.GAME.consumeable_buffer < G.consumeables.config.card_limit then
                G.GAME.consumeable_buffer = G.GAME.consumeable_buffer + 1
                G.E_MANAGER:add_event(Event({
                    trigger = 'before',
                    delay = 0.0,
                    func = (function()
                            local card = create_card('Planet', G.consumeables, nil, nil, nil, nil, nil, 'box')
                            card:add_to_deck()
                            G.consumeables:emplace(card)
                            G.GAME.consumeable_buffer = 0
                        return true
                    end)}))
                card_eval_status_text(context.blueprint_card or card, 'extra', nil, nil, nil, {message = localize('k_plus_planet'), colour = G.C.SECONDARY_SET.Planet})
            end
        end
    end
}

-- Pageant Boy
SMODS.Joker {
    key = "pageantboy",
    loc_txt = {
        name = 'Pageant Boy',
        text = {
            "Earn {C:attention}$#1#{} after",
            "defeating each {C:attention}Boss Blind{}"
        }
    },
    config = { extra = { money = 7 } },
    pos = {
        x = 9,
        y = 26
    },
    cost = 4,
    rarity = 1,
    blueprint_compat = false,
    eternal_compat = true,
    unlocked = true,
    discovered = true,
    atlas = 'IsaactroJokers',

    loc_vars = function(self, info_queue, card)
        return {vars = { card.ability.extra.money }}
    end,

    calc_dollar_bonus = function(self, card)
        -- ensure this is a boss blind
        if not G.GAME.blind.boss then return nil end
        local bonus = card.ability.extra.money
        if bonus > 0 then return bonus end
        return nil
    end
}

-- Dead Bird
SMODS.Joker {
    key = "deadbird",
    loc_txt = {
        name = 'Dead Bird',
        text = {
            "Each scored card on {C:attention}Last Hand Played{}",
            "gives {C:mult}+#1# Mult"
        }
    },
    config = { extra = { mult = 2 } },
    pos = {
        x = 4,
        y = 25
    },
    cost = 3,
    rarity = 1,
    blueprint_compat = true,
    eternal_compat = true,
    unlocked = true,
    discovered = true,
    atlas = 'IsaactroJokers',

    loc_vars = function(self, info_queue, card)
        return {vars = {card.ability.extra.mult}}
    end,

    calculate = function(self, card, context)
        if context.individual and context.cardarea == G.play and G.GAME.current_round.hands_left == 0 then
            return {
                mult = card.ability.extra.mult,
                card = context.other_card
            }
        end
    end
}

-- Poop
SMODS.Joker {
    key = "poop",
    loc_txt = {
        name = 'The Poop',
        text = {
            "Each {C:red}discard{} has a",
            "{C:green}#1# in #2#{} chance to",
            "give {C:money}$#3#{}"
        }
    },
    config = { extra = { odds = 4, money = 2 } },
    pos = {
        x = 8,
        y = 6
    },
    cost = 4,
    rarity = 1,
    blueprint_compat = true,
    eternal_compat = true,
    unlocked = true,
    discovered = true,
    atlas = 'IsaactroJokers',

    loc_vars = function(self, info_queue, card)
        return {vars = { G.GAME.probabilities.normal, card.ability.extra.odds, card.ability.extra.money }}
    end,

    calculate = function(self, card, context)
        if context.discard then
            if pseudorandom('poop') < G.GAME.probabilities.normal / card.ability.extra.odds then
                card_eval_status_text(context.blueprint_card or card, 'extra', nil, nil, nil, {message = "$"..tostring(card.ability.extra.money), colour = G.C.MONEY})
                ease_dollars(card.ability.extra.money)
            end
        end
    end
}

-- Little Baggy
SMODS.Joker {
    key = "littlebaggy",
    loc_txt = {
        name = 'Little Baggy',
        text = {
            "When {C:attention}Tarot Card{} is purchased,",
            "destroy it and gain a random",
            "{C:attention}Planet Card{}"
        }
    },
    pos = {
        x = 6,
        y = 36
    },
    cost = 3,
    rarity = 1,
    blueprint_compat = false,
    eternal_compat = true,
    unlocked = true,
    discovered = true,
    atlas = 'IsaactroJokers',

    loc_vars = function(self, info_queue, card)
        return {vars = {}}
    end,

    calculate = function(self, card, context)
        if context.buying_card and context.card.ability.set == "Tarot" and not context.blueprint then
            card_eval_status_text(card, 'extra', nil, nil, nil, {message = localize('k_nope_ex')})
            -- destroy the tarot card
            G.E_MANAGER:add_event(Event({
                func = function()
                    play_sound('tarot1')
                    card:juice_up(0.3, 0.4)
                    G.E_MANAGER:add_event(Event({
                        trigger = 'immediate',
                        blockable = false,
                        func = function()
                            context.card:remove()
                            context.card = nil
                            return true;
                        end
                    }))
                    return true
                end
            }))

            -- gain a random planet card
            G.E_MANAGER:add_event(Event({
                trigger = 'after',
                delay = 0.5,
                blockable = false,
                func = (function()
                        local card = create_card('Planet', G.consumeables, nil, nil, nil, nil, nil, 'littlebaggy')
                        card:add_to_deck()
                        G.consumeables:emplace(card)
                        play_sound('holo1', 1.2 + math.random()*0.1, 0.4)
                    return true
                end
            )}))
        end
    end
}

-- Quality 1 Jokers (all common or uncommon)

-- The Bible (uncommon)
SMODS.Joker {
    -- if first played hand each round contains only one card, each card held in hand permanently gains 10 chips
    key = "bible",
    loc_txt = {
        name = 'The Bible',
        text = {
            "If {C:attention}First Hand{} of round",
            "has only {C:attention}1{} card, each",
            "card held permanently gains {C:chips}+#1#{} Chips",
        }
    },
    config = { extra = { chip_mod = 8, used = false } },
    pos = {
        x = 6,
        y = 5
    },
    cost = 5,
    rarity = 2,
    blueprint_compat = true,
    eternal_compat = true,
    unlocked = true,
    discovered = true,
    atlas = 'IsaactroJokers',

    loc_vars = function(self, info_queue, card)
        return {vars = { card.ability.extra.chip_mod }}
    end,

    calculate = function(self, card, context)
        if context.setting_blind and not context.blueprint then
            card.ability.extra.used = false
            local eval = function() return not card.ability.extra.used end
            juice_card_until(card, eval, true)
        end

        if context.cardarea == G.hand and context.other_card and context.individual and G.GAME.current_round.hands_played == 0 then
            card.ability.extra.used = true
            if #context.full_hand == 1 then
                if context.blueprint then
                    G.E_MANAGER:add_event(Event({
                        trigger = 'before',
                        delay = 0.0,
                        func = (function()
                            context.blueprint_card:juice_up(0.3, 0.4)
                            context.other_card.ability.perma_bonus = context.other_card.ability.perma_bonus + card.ability.extra.chip_mod
                            return true
                        end
                    )}))
                else
                    G.E_MANAGER:add_event(Event({
                        trigger = 'before',
                        delay = 0.0,
                        func = (function()
                            card:juice_up(0.3, 0.4)
                            context.other_card.ability.perma_bonus = context.other_card.ability.perma_bonus + card.ability.extra.chip_mod
                            return true
                        end
                    )}))
                end
                card_eval_status_text(context.other_card, 'extra', nil, nil, nil, {message = localize('k_upgrade_ex'), colour = G.C.BLUE})
            end
        end
    end
}

-- Wooden Nickel (common)
SMODS.Joker {
    key = "woodennickel",
    loc_txt = {
        name = 'Wooden Nickel',
        text = {
            "Each {C:red}hand played{} has a",
            "{C:green}#1# in #2#{} chance to",
            "give {C:money}$#1#{}"
        }
    },
    config = { extra = { money = 1, odds = 2 } },
    pos = {
        x = 2,
        y = 9
    },
    cost = 4,
    rarity = 1,
    blueprint_compat = true,
    eternal_compat = true,
    unlocked = true,
    discovered = true,
    atlas = 'IsaactroJokers',

    loc_vars = function(self, info_queue, card)
        return {vars = { G.GAME.probabilities.normal, card.ability.extra.odds, card.ability.extra.money }}
    end,

    calculate = function(self, card, context)
        if context.cardarea == G.jokers and context.before then
            if pseudorandom('woodennickel') < G.GAME.probabilities.normal / card.ability.extra.odds then
                card_eval_status_text(context.blueprint_card or card, 'extra', nil, nil, nil, {message = "$"..tostring(card.ability.extra.money), colour = G.C.MONEY})
                ease_dollars(card.ability.extra.money)
            end
        end
    end
}

-- Sack of Pennies (common)
SMODS.Joker {
    key = "sackofpennies",
    loc_txt = {
        name = 'Sack of Pennies',
        text = {
            "{C:green}#1# in #2#{} chance to",
            "gain {C:money}$#3#{} at the",
            "end of {C:attention}each round{}"
        }
    },
    config = { extra = { money = 8, odds = 3 } },
    pos = {
        x = 6,
        y = 23
    },
    cost = 4,
    rarity = 1,
    blueprint_compat = false,
    eternal_compat = true,
    unlocked = true,
    discovered = true,
    atlas = 'IsaactroJokers',

    loc_vars = function(self, info_queue, card)
        return {vars = { G.GAME.probabilities.normal, card.ability.extra.odds, card.ability.extra.money }}
    end,

    calc_dollar_bonus = function(self, card)
        if pseudorandom('sackofpennies') < G.GAME.probabilities.normal / card.ability.extra.odds then
            return card.ability.extra.money
        end
        return nil
    end
}

-- Bucket of Lard (uncommon)
SMODS.Joker {
    key = "bucketoflard",
    loc_txt = {
        name = 'Bucket of Lard',
        text = {
            "Gain {C:blue}+#1#{} hands when",
            "{C:attention}blind{} is selected",
            "{X:mult,C:white}X#2#{} Mult"
        }
    },
    config = { extra = { extra_hands = 2, Xmult = 0.8 } },
    pos = {
        x = 2,
        y = 26
    },
    cost = 5,
    rarity = 2,
    blueprint_compat = true,
    eternal_compat = true,
    unlocked = true,
    discovered = true,
    atlas = 'IsaactroJokers',

    loc_vars = function(self, info_queue, card)
        return {vars = { card.ability.extra.extra_hands, card.ability.extra.Xmult }}
    end,

    calculate = function(self, card, context)
        if context.setting_blind then
            G.GAME.current_round.hands_left = G.GAME.current_round.hands_left + card.ability.extra.extra_hands
            return {}
        end

        if context.joker_main then
            return {
                message = localize { type = 'variable', key = 'a_xmult', vars = { card.ability.extra.Xmult } },
                Xmult_mod = card.ability.extra.Xmult,
            }
        end
    end
}

-- Cube of Meat (uncommon)
SMODS.Tag {
    key = "cubeofmeat",
    loc_txt = {
        name = 'Cube of Meat Tag',
        text = {
            "Next {C:red}Joker{} in shop",
            "becomes {C:red}Cube of Meat{}",
        }
    },
    requires = 'j_itro_cubeofmeat',
    config = { type = 'store_joker_create' },
    atlas = 'IsaactroTags',
    pos = { x = 0, y = 0 },
    discovered = true,
    unlocked = true,
    apply = function(self, tag, context)
        local card
        if context.type == "store_joker_create" then
            card = create_card("Joker", context.area, nil, nil, nil, nil, "j_itro_cubeofmeat")
            create_shop_card_ui(card, "Joker", context.area)
            card.states.visible = false
            tag:yep("+", G.C.RED, function()
                card:start_materialize()
                card:set_cost()
                return true
            end)
            tag.triggered = true
            return card
        end
    end,
    in_pool = function()
        return false
    end
}
SMODS.Joker {
    key = "cubeofmeat",
    loc_txt = {
        name = 'Cube of Meat',
        text = {
            "When {C:red}Cube of Meat{} is purchased,",
            "this joker gains {X:mult,C:white}X#1#{} Mult and",
            "destroys the other {C:red}Cube of Meat{}",
            "{C:inactive}(Currently {X:mult,C:white}X#2#{C:inactive}){}",
            "Gain a {C:attention}Cube of Meat Tag{}",
            "after {C:attention}#3# rerolls{}",
            "{C:inactive}(Currently {C:attention}#4#{C:inactive}/#3#)"
        }
    },
    config = { extra = { Xmult_mod = 1, Xmult = 1, required_rerolls = 15, num_rerolls = 0 } },
    pos = {
        x = 2,
        y = 22
    },
    cost = 5,
    rarity = 2,
    blueprint_compat = true,
    eternal_compat = true,
    unlocked = true,
    discovered = true,
    atlas = 'IsaactroJokers',

    loc_vars = function(self, info_queue, card)
        info_queue[#info_queue+1] = {key = 'tag_itro_cubeofmeat', set = 'Tag'}

        return { vars = { card.ability.extra.Xmult_mod, card.ability.extra.Xmult, card.ability.extra.required_rerolls, card.ability.extra.num_rerolls } }
    end,

    calculate = function(self, card, context)
        -- apply xmult
        if context.joker_main then
            if card.ability.extra.Xmult > 1 then
                return {
                    message = localize { type = 'variable', key = 'a_xmult', vars = { card.ability.extra.Xmult } },
                    Xmult_mod = card.ability.extra.Xmult,
                }
            end
        end

        -- if purchasing cube of meat
        if context.buying_card and context.card.config.center.key == "j_itro_cubeofmeat" and context.card ~= card and not context.blueprint then
            -- remove the other cube of meat
            G.E_MANAGER:add_event(Event({
                func = function()
                play_sound('tarot1')
                context.card.T.r = -0.2
                context.card:juice_up(0.3, 0.4)
                context.card.states.drag.is = true
                context.card.children.center.pinch.x = true
                G.E_MANAGER:add_event(Event({
                    trigger = 'immediate',
                    blockable = false,
                    func = function()
                    G.jokers:remove_card(context.card)
                    context.card:remove()
                    context.card = nil
                    return true;
                    end
                }))
                return true
                end
            }))

            -- upgrade this card
            card.ability.extra.Xmult = card.ability.extra.Xmult + card.ability.extra.Xmult_mod
            card_eval_status_text(card, 'extra', nil, nil, nil,
                { message = localize('k_upgrade_ex'), colour = G.C.RED})
            return {}
        end

        -- if rerolling
        if context.reroll_shop and not context.blueprint then
            card.ability.extra.num_rerolls = card.ability.extra.num_rerolls + 1
            if card.ability.extra.num_rerolls >= card.ability.extra.required_rerolls then
                G.E_MANAGER:add_event(Event({
                    func = (function()
                        local tag = Tag("tag_itro_cubeofmeat")
                        add_tag(tag)
                        play_sound('generic1', 0.9 + math.random()*0.1, 0.8)
                        play_sound('holo1', 1.2 + math.random()*0.1, 0.4)
                        return true
                    end)
                }))
                card.ability.extra.num_rerolls = 0
            end
            return {}
        end
    end
}

-- Epiphora (uncommon)
SMODS.Joker {
    key = "epiphora",
    loc_txt = {
        name = 'Epiphora',
        text = {
            "This joker gains {C:chips}+#1#{} Chips",
            "for each {C:attention}consecutive{} round",
            "won playing only {C:attention}one hand{}",
            "{C:inactive}(Currently {C:chips}+#2#{C:inactive}){}"
        }
    },
    config = { extra = { chip_mod = 20, chips = 0 } },
    pos = {
        x = 3,
        y = 45
    },
    cost = 5,
    rarity = 2,
    blueprint_compat = true,
    eternal_compat = true,
    unlocked = true,
    discovered = true,
    atlas = 'IsaactroJokers',

    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.extra.chip_mod, card.ability.extra.chips } }
    end,

    calculate = function(self, card, context)
        -- apply chips
        if context.joker_main then
            return {
                chips = card.ability.extra.chips,
                message = localize {type = 'variable', key = 'a_chips', vars = {card.ability.extra.chips}}
            }
        end

        -- if won round
        if context.end_of_round and not context.repetition and not context.individual and not context.game_over and not context.blueprint and G.GAME.current_round.hands_played == 1 then
            card.ability.extra.chips = card.ability.extra.chips + card.ability.extra.chip_mod
            return {
                message = localize('k_upgrade_ex'),
                card = card,
                colour = G.C.BLUE
            }
        end
        
        -- reset before second hand
        if context.cardarea == G.jokers and context.before and not context.blueprint and card.ability.extra.chips > 0 and G.GAME.current_round.hands_played == 1 then
            card.ability.extra.chips = 0
            return{
                message = localize('k_reset'),
                colour = G.C.RED
            }
        end
    end
}

-- Booster Pack  (uncommon)
SMODS.Joker { 
    key = "boosterpack",
    loc_txt = {
        name = 'Booster Pack',
        text = {
            "After {C:attention}#1#{} rounds, sell this card",
            "to gain {C:attention}#2# Negative Tarot Cards{}",
            "{C:inactive}(Currently {C:attention}#3#{C:inactive}/#1#)"
        }
    },
    config = { extra = { rounds_needed = 2, cards_given = 3, rounds = 0 } },
    pos = {
        x = 7,
        y = 64
    },
    cost = 4,
    rarity = 1,
    blueprint_compat = false,
    eternal_compat = false,
    unlocked = true,
    discovered = true,
    atlas = 'IsaactroJokers',

    loc_vars = function(self, info_queue, card)
        return {vars = { card.ability.extra.rounds_needed, card.ability.extra.cards_given, card.ability.extra.rounds }}
    end,

    calculate = function(self, card, context)
        if context.end_of_round and not context.blueprint and not context.individual and not context.repetition and card.ability.extra.rounds < card.ability.extra.rounds_needed then
            card.ability.extra.rounds = card.ability.extra.rounds + 1
            if card.ability.extra.rounds >= card.ability.extra.rounds_needed then
                local eval = function(card) return not card.REMOVED end
                juice_card_until(card, eval, true)
                return {
                    message = localize('k_active_ex'),
                    colour = G.C.FILTER
                }
            end

        elseif context.selling_self and card.ability.extra.rounds >= card.ability.extra.rounds_needed then
            for i = 1, card.ability.extra.cards_given do
                G.E_MANAGER:add_event(Event({
                    trigger = 'before',
                    delay = 0.0,
                    func = (function()
                            local card = create_card('Tarot', G.consumeables, nil, nil, nil, nil, nil, 'box')
                            card:set_edition('e_negative')
                            card:add_to_deck()
                            G.consumeables:emplace(card)
                        return true
                    end)}))
            end
            card_eval_status_text(card, 'extra', nil, nil, nil, {message = localize('k_plus_tarot'), colour = G.C.SECONDARY_SET.Spectral})
        end
    end
}

-- Guppy's Collar (uncommon)
SMODS.Joker {
    key = "guppyscollar",
    loc_txt = {
        name = "Guppy's Collar",
        text = {
            "{C:green}1 in #1#{} chance to",
            "prevent {C:attention}Death{}",
            "{C:inactive}(These odds cannot be increased)"
        }
    },
    config = { extra = { odds = 2 } },
    pos = {
        x = 7,
        y = 32
    },
    cost = 5,
    rarity = 2,
    blueprint_compat = false,
    eternal_compat = true,
    unlocked = true,
    discovered = true,
    atlas = 'IsaactroJokers',

    loc_vars = function(self, info_queue, card)
        return {vars = { card.ability.extra.odds }}
    end,

    calculate = function(self, card, context)
        if context.end_of_round and not context.blueprint and not context.individual and not context.repetition and context.game_over then
            if pseudorandom('guppyscollar') < 1 / card.ability.extra.odds then
                return {
                    message = localize('k_saved_ex'),
                    colour = G.C.RED,
                    saved = true
                }
            end
        end
    end
}

-- Experimental Treatment (common)
SMODS.Joker {
    -- Gives chips between -20 and +20
	-- Gives multiplier between x0.5 and x1.5
    key = "experimentaltreatment",
    loc_txt = {
        name = 'Experimental Treatment',
        text = {
            "Random {C:red}Multiplier{} from",
            "{X:mult,C:white}X#1#{} to {X:mult,C:white}X#2#{}"
        }
    },
    config = { extra = { Xmult_min = 0.5, Xmult_max = 1.5 } },
    pos = {
        x = 4,
        y = 35
    },
    cost = 3,
    rarity = 1,
    blueprint_compat = true,
    eternal_compat = true,
    unlocked = true,
    discovered = true,
    atlas = 'IsaactroJokers',

    loc_vars = function(self, info_queue, card)
        return {vars = { card.ability.extra.Xmult_min, card.ability.extra.Xmult_max }}
    end,

    calculate = function(self, card, context)
        if context.joker_main then
            local Xmult = card.ability.extra.Xmult_min + (card.ability.extra.Xmult_max - card.ability.extra.Xmult_min) * math.random()
            return {
                message = localize { type = 'variable', key = 'a_xmult', vars = { Xmult } },
                Xmult_mod = Xmult
            }
        end
    end
}

-- Quality 2 Jokers (all uncommon or common)

-- Guppy's Head (common)
SMODS.Joker {
    -- Gains 9 chips for each round played
    key = "guppyshead",
    loc_txt = {
        name = "Guppy's Head",
        text = {
            "This Joker gains {C:chips}+#1#{} Chips",
            "for each {C:attention}round played{}",
            "{C:inactive}(Currently {C:chips}+#2#{C:inactive}){}"
        }
    },
    config = { extra = { chip_mod = 9, chips = 0 } },
    pos = {
        x = 5,
        y = 2
    },
    cost = 5,
    rarity = 1,
    blueprint_compat = true,
    eternal_compat = true,
    unlocked = true,
    discovered = true,
    atlas = 'IsaactroJokers',

    loc_vars = function(self, info_queue, card)
        info_queue[#info_queue+1] = {key = 'tag_itro_cubeofmeat', set = 'Tag'}

        return { vars = { card.ability.extra.chip_mod, card.ability.extra.chips } }
    end,

    calculate = function(self, card, context)
        -- apply chips
        if context.joker_main then
            return {
                chips = card.ability.extra.chips,
                message = localize {type = 'variable', key = 'a_chips', vars = {card.ability.extra.chips}}
            }
        end

        -- if won round
        if context.end_of_round and not context.repetition and not context.individual and not context.game_over and not context.blueprint then
            card.ability.extra.chips = card.ability.extra.chips + card.ability.extra.chip_mod
            return {
                message = localize('k_upgrade_ex'),
                card = card,
                colour = G.C.BLUE
            }
        end
    end
}

-- Crooked Penny (uncommon)
SMODS.Joker { 
    -- When sold (after holding for 2 rounds), 1 in 2 chance to either destroy all other jokers, or creates a copy of each until all joker spots full (left to right)
    key = "crookedpenny",
    loc_txt = {
        name = 'Crooked Penny',
        text = {
            "After {C:attention}#1#{} rounds, sell this card",
            "for a {C:green}1 in #2#{} chance to either",
            "{C:attention}destroy all held Jokers{} or",
            "create {C:attention}copies of each Joker{}",
            "until all Joker slots full",
            "{C:inactive}(Currently {C:attention}#3#{C:inactive}/#1#)",
            "{C:inactive}(These odds cannot be increased)",
            "{C:inactive}(Copies are created from left to right)"
        }
    },
    config = { extra = { rounds_needed = 2, odds = 2, rounds = 0 } },
    pos = {
        x = 0,
        y = 10
    },
    cost = 6,
    rarity = 2,
    blueprint_compat = false,
    eternal_compat = false,
    unlocked = true,
    discovered = true,
    atlas = 'IsaactroJokers',

    loc_vars = function(self, info_queue, card)
        return {vars = { card.ability.extra.rounds_needed, card.ability.extra.odds, card.ability.extra.rounds }}
    end,

    calculate = function(self, card, context)
        if context.end_of_round and not context.blueprint and not context.individual and not context.repetition and card.ability.extra.rounds < card.ability.extra.rounds_needed then
            card.ability.extra.rounds = card.ability.extra.rounds + 1
            if card.ability.extra.rounds >= card.ability.extra.rounds_needed then
                local eval = function(card) return not card.REMOVED end
                juice_card_until(card, eval, true)
                return {
                    message = localize('k_active_ex'),
                    colour = G.C.FILTER
                }
            end

        elseif context.selling_self and card.ability.extra.rounds >= card.ability.extra.rounds_needed then
            -- check the odds
            if pseudorandom('crookedpenny') < 1 / card.ability.extra.odds then
                -- destroy all other
                card_eval_status_text(card, 'extra', nil, nil, nil, {message = localize('k_nope_ex')})
                if #G.jokers.cards > 1 then
                    for _, other_joker in ipairs(G.jokers.cards) do
                        if other_joker ~= card then
                            G.E_MANAGER:add_event(Event({
                                func = function()
                                play_sound('tarot1')
                                other_joker.T.r = -0.2
                                other_joker:juice_up(0.3, 0.4)
                                other_joker.states.drag.is = true
                                other_joker.children.center.pinch.x = true
                                G.E_MANAGER:add_event(Event({
                                    trigger = 'immediate',
                                    blockable = false,
                                    func = function()
                                    G.jokers:remove_card(other_joker)
                                    other_joker:remove()
                                    other_joker = nil
                                    return true;
                                    end
                                }))
                                return true
                                end
                            }))
                            -- G.E_MANAGER:add_event(Event({
                            --     trigger = 'after',
                            --     delay = 0.5,
                            --     func = (function()
                            --         G.jokers:remove_card(other_joker)
                            --         other_joker:remove()
                            --         play_sound('cancel', 0.7 + math.random()*0.1, 0.7)
                            --         return true
                            --     end)
                            -- }))
                        end
                    end
                end
            
            -- copy all other jokers
            else
                card_eval_status_text(card, 'extra', nil, nil, nil, {message = localize('k_copied_ex')})
                local joker_slots = G.jokers.config.card_limit
                local jokers = {}
                for _, other_joker in ipairs(G.jokers.cards) do
                    if other_joker ~= card then
                        jokers[#jokers+1] = other_joker
                    end
                end
                local num_copies = math.min(joker_slots - #G.jokers.cards, #jokers)
                for i = 1, num_copies do
                    local other_joker = jokers[i]
                    G.E_MANAGER:add_event(Event({
                        trigger = 'after',
                        delay = 0.5,
                        func = (function()
                            local new_joker = create_card('Joker', G.jokers, nil, nil, nil, nil, other_joker.config.center.key)
                            new_joker:add_to_deck()
                            G.jokers:emplace(new_joker)
                            play_sound('holo1', 1.2 + math.random()*0.1, 0.4)
                            return true
                        end)
                    }))
                end
            end
        end
    end
}

-- Sacrificial Altar (uncommon)
SMODS.Joker { 
    -- When sold (after 2 rounds), destroys up to two other jokers (to the right of this joker) and replaces them with random eternal uncommon or rare jokers
    key = "sacrificialaltar",
    loc_txt = {
        name = 'Sacrifical Altar',
        text = {
            "After {C:attention}#1#{} rounds, sell this card",
            "to destroy up to {C:attention}#2#{} Jokers",
            "from {C:attention}left to right{} and replace with random",
            "{C:attention}Eternal {C:green}Uncommon{} or {C:red}Rare {C:attention}Jokers{}",
            "{C:inactive}(Currently {C:attention}#3#{C:inactive}/#1#)",
            "{C:inactive}({C:attention}Eternal{C:inactive} Jokers cannot be sold or destroyed)"
        }
    },
    config = { extra = { rounds_needed = 2, num_jokers = 2, rounds = 0 } },
    pos = {
        x = 6,
        y = 11
    },
    cost = 6,
    rarity = 2,
    blueprint_compat = false,
    eternal_compat = false,
    unlocked = true,
    discovered = true,
    atlas = 'IsaactroJokers',

    loc_vars = function(self, info_queue, card)
        return {vars = { card.ability.extra.rounds_needed, card.ability.extra.num_jokers, card.ability.extra.rounds }}
    end,

    calculate = function(self, card, context)
        if context.end_of_round and not context.blueprint and not context.individual and not context.repetition and card.ability.extra.rounds < card.ability.extra.rounds_needed then
            card.ability.extra.rounds = card.ability.extra.rounds + 1
            if card.ability.extra.rounds >= card.ability.extra.rounds_needed then
                local eval = function(card) return not card.REMOVED end
                juice_card_until(card, eval, true)
                return {
                    message = localize('k_active_ex'),
                    colour = G.C.FILTER
                }
            end

        elseif context.selling_self and card.ability.extra.rounds >= card.ability.extra.rounds_needed then
            -- destroy up to two other jokers to the right
            local jokers = {}
            local num_destroyed = 0
            for _, other_joker in ipairs(G.jokers.cards) do
                if other_joker ~= card and num_destroyed < card.ability.extra.num_jokers then
                    jokers[#jokers+1] = other_joker
                    num_destroyed = num_destroyed + 1
                end
            end
            -- if no jokers to destroy, do nothing
            if num_destroyed == 0 then return end

            -- destroy the jokers
            for _, other_joker in ipairs(jokers) do
                G.E_MANAGER:add_event(Event({
                    trigger = 'after',
                    delay = 0.5,
                    func = (function()
                        G.jokers:remove_card(other_joker)
                        other_joker:remove()
                        play_sound('tarot1', 0.7 + math.random()*0.1, 0.7)
                        return true
                    end)
                }))
            end

            -- replace with random eternal uncommon or rare jokers
            for i = 1, num_destroyed do
                -- 50/50 for uncommon or rare (either rarity 2 or 3)
                local rarity
                if math.random() < 0.5 then
                    rarity = 2
                else
                    rarity = 3
                end

                -- create the joker
                G.E_MANAGER:add_event(Event({
                    trigger = 'after',
                    delay = 0.5,
                    blockable = false,
                    blocking = true,
                    func = function()
                        local joker = create_card('Joker', G.joker, nil, rarity, nil, nil, nil, 'sacrificialaltar')
                        if joker.ability.eternal_compat then
                            joker:set_eternal()
                        end
                        joker:add_to_deck()
                        G.jokers:emplace(joker)
                        play_sound('holo1', 1.2 + math.random()*0.1, 0.4)
                        return true
                    end
                }))
            end
        end
    end
}

-- Number one (uncommon)
SMODS.Joker {
    -- Gains 2 hands when blind is selected, but hand size is reduced by 2
    key = "numberone",
    loc_txt = {
        name = 'Number One',
        text = {
            "{C:blue}+#1#{} hands when {C:attention}Blind{} is selected",
            "{C:red}#2#{} Hand Size"
        }
    },
    config = { extra = { hands = 2, hand_size = -2 } },
    pos = {
        x = 6,
        y = 17
    },
    cost = 5,
    rarity = 2,
    blueprint_compat = true,
    eternal_compat = true,
    unlocked = true,
    discovered = true,
    atlas = 'IsaactroJokers',

    loc_vars = function(self, info_queue, card)
        return {vars = { card.ability.extra.hands, card.ability.extra.hand_size }}
    end,

    add_to_deck = function(self, card, from_debuff)
        G.hand:change_size(card.ability.extra.hand_size)
    end,

    remove_from_deck = function(self, card, from_debuff)
        G.hand:change_size(-card.ability.extra.hand_size)
    end,

    calculate = function(self, card, context)
        if context.setting_blind then
            G.GAME.current_round.hands_left = G.GAME.current_round.hands_left + card.ability.extra.hands
            card_eval_status_text(context.blueprint_card or card, 'extra', nil, nil, nil, {message = localize{type = 'variable', key = 'a_hands', vars = {card.ability.extra.hands}}})
        end
    end
}

-- Lucky Foot (uncommon)
SMODS.Joker {
    -- Retrigger all lucky cards
    key = "luckyfoot",
    loc_txt = {
        name = 'Lucky Foot',
        text = {
            "{C:attention}Retrigger{} all {C:attention}Lucky Cards{}"
        }
    },
    config = { extra = 1 },
    pos = {
        x = 3,
        y = 20
    },
    cost = 6,
    rarity = 2,
    blueprint_compat = true,
    eternal_compat = true,
    unlocked = true,
    discovered = true,
    atlas = 'IsaactroJokers',

    loc_vars = function(self, info_queue, card)
        info_queue[#info_queue+1] = G.P_CENTERS.m_lucky
        return
    end,

    -- help from Double Rainbow joker in ExtraCredit mod: https://github.com/GuilloryCraft/ExtraCredit/blob/main/src/essay.lua
    calculate = function(self, card, context)
        if context.repetition and context.cardarea == G.play and context.other_card.ability.name == 'Lucky Card' then
            return {
                message = localize('k_again_ex'),
                repetitions = 1,
                card = card
            }
        
        elseif context.repetition and context.cardarea == G.hand and context.other_card.ability.name == 'Lucky Card' then
            if (next(context.card_effects[1]) or #context.card_effects > 1) then
                return {
                    message = localize('k_again_ex'),
                    repetitions = card.ability.extra,
                    card = card
                }
            end
        end
    end
}

-- Soy Milk (uncommon)
SMODS.Joker {
    -- Gains 3 chips each time a played card is retriggered
    key = "soymilk",
    loc_txt = {
        name = 'Soy Milk',
        text = {
            "This {C:attention}Joker{} gains {C:chips}+#1#{} Chips",
            "for {C:attention}each time{} a played card",
            "is {C:attention}Retriggered{}",
            "{C:inactive}(Currently {C:chips}+#2#{C:inactive}){}"
        }
    },
    config = { extra = { chip_mod = 3, chips = 0, triggers = 0, cards_played = 0 } },
    pos = {
        x = 2,
        y = 42
    },
    cost = 6,
    rarity = 2,
    blueprint_compat = true,
    eternal_compat = true,
    unlocked = true,
    discovered = true,
    atlas = 'IsaactroJokers',

    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.extra.chip_mod, card.ability.extra.chips } }
    end,

    calculate = function(self, card, context)
        -- before scoring, count the number of cards played
        if context.cardarea == G.jokers and context.before and not context.blueprint then
            card.ability.extra.cards_played = card.ability.extra.cards_played + 1
            return
        end

        -- every time called while scoring, increment the number of triggers
        if context.cardarea == G.play and context.other_card and context.individual and not context.blueprint then
            card.ability.extra.triggers = card.ability.extra.triggers + 1
        end

        -- apply chips
        if context.joker_main then
            local retriggers = card.ability.extra.triggers - card.ability.extra.cards_played
            if retriggers > 0 then
                card.ability.extra.chips = card.ability.extra.chips + card.ability.extra.chip_mod * retriggers
                card_eval_status_text(card, 'extra', nil, nil, nil, {message = localize('k_upgrade_ex'), colour = G.C.BLUE})
            end
            card.ability.extra.triggers = 0
            card.ability.extra.cards_played = 0
            return {
                chips = card.ability.extra.chips,
                message = localize {type = 'variable', key = 'a_chips', vars = {card.ability.extra.chips}}
            }
        end
    end
}

-- Member Card (uncommon)
SMODS.Joker {
    -- After each reroll, add a random card to the shop, but double the price
    key = "membercard",
    loc_txt = {
        name = 'Member Card',
        text = {
            "After each {C:attention}Reroll{}, add a",
            "{C:attention}Random Card{} to the shop",
            "with the price {C:red}Doubled{}",
        }
    },
    pos = {
        x = 3,
        y = 63
    },
    cost = 5,
    rarity = 2,
    blueprint_compat = true,
    eternal_compat = true,
    unlocked = true,
    discovered = true,
    atlas = 'IsaactroJokers',

    calculate = function(self, card, context)
        -- if rerolling
        if context.reroll_shop then
            local new_card = create_card_for_shop(G.shop_jokers)
            new_card:set_cost()
            new_card.cost = new_card.cost * 2
            G.shop_jokers:emplace(new_card)
            card_eval_status_text(card, 'extra', nil, nil, nil, {message = "Deal!", colour = G.C.RED})
        end
    end
}

-- Blank Card (uncommon)
SMODS.Joker {
    -- The first consumable used each round gives a copy in consumable slot
    -- resets after blind is defeated
    key = "blankcard",
    loc_txt = {
        name = 'Blank Card',
        text = {
            "Creates a copy of the first",
            "{C:attention}Consumable{} used each round",
            "{C:inactive}(Resets after {C:attention}Blind{C:inactive} is defeated)"
        }
    },
    pos = {
        x = 3,
        y = 0
    },
    config = { extra = { used = false } },
    cost = 5,
    rarity = 2,
    blueprint_compat = false,
    eternal_compat = true,
    unlocked = true,
    discovered = true,
    atlas = 'IsaactroJokers',

    loc_vars = function(self, info_queue, card)
        return {vars = { }}
    end,

    add_to_deck = function(self, card, from_debuff)
        card.ability.extra.used = false
        local eval = function() return not card.ability.extra.used end
        juice_card_until(card, eval, true)
    end,

    calculate = function(self, card, context)
        -- create copy if active
        if context.using_consumeable and not card.ability.extra.used and not context.blueprint then
            local consumeable_used = context.consumeable
            local key = consumeable_used.config.center.key
            local set = consumeable_used.config.center.set
            
            G.E_MANAGER:add_event(Event({
                trigger = 'after',
                delay = 0.5,
                blockable = false,
                func = function()
                    card_eval_status_text(card, 'extra', nil, nil, nil, {message = localize('k_copied_ex'), colour = G.C.FILTER})
                    local new_consumeable = create_card(set, G.consumeables, nil, nil, nil, nil, key)
                    new_consumeable:add_to_deck()
                    G.consumeables:emplace(new_consumeable)
                    play_sound('holo1', 1.2 + math.random()*0.1, 0.4)
                    return true
                end
            }))

            card.ability.extra.used = true
            return
        end

        -- reset after blind defeated
        if context.end_of_round and not context.game_over and not context.repetition and not context.individual and not context.blueprint then
            card.ability.extra.used = false
            local eval = function() return not card.ability.extra.used end
            juice_card_until(card, eval, true)
            if card.ability.extra.used then
                card_eval_status_text(card, 'extra', nil, nil, nil, {message = localize('k_reset'), colour = G.C.RED})
            end
            return
        end
    end
}

-- Jesus Juice (common)
SMODS.Joker {
    -- Each played diamond or heart gives +2 mult and +5 chips
    key = "jesusjuice",
    loc_txt = {
        name = 'Jesus Juice',
        text = {
            "Each played {C:attention}Diamond{} or {C:attention}Heart{}",
            "gives {C:chips}+#2#{} Chips and",
            "{C:mult}+#1#{} Mult when scored"
        }
    },
    config = { extra = { mult = 3, chips = 5 } },
    pos = {
        x = 2,
        y = 31
    },
    cost = 4,
    rarity = 1,
    blueprint_compat = true,
    eternal_compat = true,
    unlocked = true,
    discovered = true,
    atlas = 'IsaactroJokers',

    loc_vars = function(self, info_queue, card)
        return {vars = { card.ability.extra.chips, card.ability.extra.mult }}
    end,

    calculate = function(self, card, context)
        if context.cardarea == G.play and context.other_card then
            if context.other_card:is_suit("Diamonds") or context.other_card:is_suit("Hearts") then
                return {
                    mult = card.ability.extra.mult,
                    chips = card.ability.extra.chips,
                    card = card
                }
            end
        end
    end
}

-- Starter Deck (uncommon)
SMODS.Joker {
    -- +1 consumable slot
	-- When planet card is purchased, destroy it and gain a random tarot card
    key = "starterdeck",
    loc_txt = {
        name = 'Starter Deck',
        text = {
            "When {C:attention}Planet Card{} is purchased,",
            "destroy it and gain a random",
            "{C:attention}Tarot Card{}",
            "{C:attention}+#1#{} Consumable Slots"
        }
    },
    pos = {
        x = 5,
        y = 36
    },
    config = { extra = { card_limit = 1 } },
    cost = 6,
    rarity = 2,
    blueprint_compat = false,
    eternal_compat = true,
    unlocked = true,
    discovered = true,
    atlas = 'IsaactroJokers',

    loc_vars = function(self, info_queue, card)
        return {vars = { card.ability.extra.card_limit }}
    end,

    add_to_deck = function(self, card, from_debuff)
        G.E_MANAGER:add_event(Event({func = function()
            G.consumeables.config.card_limit = G.consumeables.config.card_limit + card.ability.extra.card_limit
            return true end }))
    end,

    remove_from_deck = function(self, card, from_debuff)
        G.E_MANAGER:add_event(Event({func = function()
            G.consumeables.config.card_limit = G.consumeables.config.card_limit - card.ability.extra.card_limit
            return true end }))
    end,

    calculate = function(self, card, context)
        if context.buying_card and context.card.ability.set == "Planet" and not context.blueprint then
            card_eval_status_text(card, 'extra', nil, nil, nil, {message = localize('k_nope_ex')})
            -- destroy the planet card
            G.E_MANAGER:add_event(Event({
                func = function()
                    play_sound('tarot1')
                    card:juice_up(0.3, 0.4)
                    G.E_MANAGER:add_event(Event({
                        trigger = 'immediate',
                        blockable = false,
                        func = function()
                            context.card:remove()
                            context.card = nil
                            return true;
                        end
                    }))
                    return true
                end
            }))

            -- gain a random tarot card
            G.E_MANAGER:add_event(Event({
                trigger = 'after',
                delay = 0.5,
                blockable = false,
                func = (function()
                        local card = create_card('Tarot', G.consumeables, nil, nil, nil, nil, nil, 'starterdeck')
                        card:add_to_deck()
                        G.consumeables:emplace(card)
                        play_sound('holo1', 1.2 + math.random()*0.1, 0.4)
                    return true
                end
            )}))
        end
    end
}

-- Cain's Other Eye (common)
SMODS.Joker {
    -- 1 in 4 chance to give X2 Mult
    key = "cainsothereye",
    loc_txt = {
        name = "Cain's Other Eye",
        text = {
            "{C:green}#1# in #2#{} chance to give",
            "{X:mult,C:white}X#3#{} Mult"
        }
    },
    config = { extra = { odds = 4, Xmult = 2 } },
    pos = {
        x = 5,
        y = 41
    },
    cost = 4,
    rarity = 1,
    blueprint_compat = true,
    eternal_compat = true,
    unlocked = true,
    discovered = true,
    atlas = 'IsaactroJokers',

    loc_vars = function(self, info_queue, card)
        return {vars = { G.GAME.probabilities.normal, card.ability.extra.odds, card.ability.extra.Xmult }}
    end,

    calculate = function(self, card, context)
        if context.joker_main then
            if pseudorandom('cainsothereye') < 1 / card.ability.extra.odds then
                return {
                    Xmult_mod = card.ability.extra.Xmult,
                    message = localize { type = 'variable', key = 'a_xmult', vars = {card.ability.extra.Xmult} }
                }
            end
        end
    end
}

-- Quality 3 Jokers (all uncommon or rare)

-- Forget Me Now (rare)
SMODS.Joker { 
    -- After 4 rounds, sell for -1 ante
    key = "forgetmenow",
    loc_txt = {
        name = 'Forget Me Now',
        text = {
            "After {C:attention}#1#{} rounds,",
            "sell this {C:attention}Joker{} for",
            "{C:attention}-#2#{} Ante",
            "{C:inactive}(Currently {C:attention}#3#{C:inactive}/#1#)"
        }
    },
    config = { extra = { rounds = 0, rounds_needed = 4, antes = 1 } },
    pos = {
        x = 4,
        y = 2
    },
    cost = 6,
    rarity = 3,
    blueprint_compat = false,
    eternal_compat = false,
    unlocked = true,
    discovered = true,
    atlas = 'IsaactroJokers',

    loc_vars = function(self, info_queue, card)
        return {vars = { card.ability.extra.rounds_needed, card.ability.extra.antes, card.ability.extra.rounds }}
    end,

    calculate = function(self, card, context)
        if context.end_of_round and not context.blueprint and not context.individual and not context.repetition and card.ability.extra.rounds < card.ability.extra.rounds_needed then
            card.ability.extra.rounds = card.ability.extra.rounds + 1
            if card.ability.extra.rounds >= card.ability.extra.rounds_needed then
                local eval = function(card) return not card.REMOVED end
                juice_card_until(card, eval, true)
                return {
                    message = localize('k_active_ex'),
                    colour = G.C.FILTER
                }
            end

        elseif context.selling_self and card.ability.extra.rounds >= card.ability.extra.rounds_needed and not context.blueprint then
            G.GAME.round_resets.ante = G.GAME.round_resets.ante - card.ability.extra.antes
            card_eval_status_text(card, 'extra', nil, nil, nil, {message = localize('k_redeemed_ex')})
            play_sound('holo1')
        end
    end
}

-- Spoon Bender (rare)
SMODS.Joker { 
    -- Chips and Mult are balanced (plasma effect)
    -- effect is handled in patch
    key = "spoonbender",
    loc_txt = {
        name = 'Spoon Bender',
        text = {
            "Balances {C:chips}Chips{} and",
            "{C:mult}Mult{} when calculating",
            "score for played hand"
        }
    },
    pos = {
        x = 3,
        y = 17
    },
    cost = 7,
    rarity = 3,
    blueprint_compat = false,
    eternal_compat = true,
    unlocked = true,
    discovered = true,
    atlas = 'IsaactroJokers'
}

--The Inner Eye (uncommon)
SMODS.Joker { 
    -- 3x mult, -5 chips each round
    key = "innereye",
    loc_txt = {
        name = 'The Inner Eye',
        text = {
            "{X:mult,C:white}X#1#{} Mult",
            "Played cards {C:attention}permanently{}",
            "{C:attention}lose {C:chips}#2#{} Chips when scored"
        }
    },
    config = { extra = { Xmult = 3, suck = 8, min_bonus = 0 } },
    pos = {
        x = 2,
        y = 17
    },
    cost = 5,
    rarity = 2,
    blueprint_compat = true,
    eternal_compat = true,
    unlocked = true,
    discovered = true,
    atlas = 'IsaactroJokers',

    loc_vars = function(self, info_queue, card)
        return {vars = { card.ability.extra.Xmult, card.ability.extra.suck }}
    end,

    calculate = function(self, card, context)
        if context.joker_main then
            return {
                chips = card.ability.extra.chips,
                Xmult_mod = card.ability.extra.Xmult,
                message = localize { type = 'variable', key = 'a_xmult', vars = {card.ability.extra.Xmult} }
            }
        end
        
        -- help from Rubber Ducky joker in ExtraCredit mod: https://github.com/GuilloryCraft/ExtraCredit/blob/main/src/essay.lua
        if context.cardarea == G.play and context.individual and not context.blueprint then

            card.ability.extra.min_bonus = 0
            context.other_card.ability.perma_bonus = context.other_card.ability.perma_bonus or 0
            if context.other_card.ability.name == 'Stone Card' then
                card.ability.extra.min_bonus = 50 * -1
            elseif context.other_card.ability.name == 'Bonus' then
                card.ability.extra.min_bonus = (30 + context.other_card.base.nominal) * -1
            else
                card.ability.extra.min_bonus = context.other_card.base.nominal * -1
            end
            
            if context.other_card.ability.perma_bonus > card.ability.extra.min_bonus then 
                context.other_card.ability.perma_bonus = math.max((context.other_card.ability.perma_bonus - card.ability.extra.suck), (card.ability.extra.min_bonus))
                return {
                    extra = {message = localize('k_eaten_ex'), colour = G.C.CHIPS},
                    colour = G.C.CHIPS,
                    card = card
                }
            end
        end
    end
}

-- Technology (uncommon)
SMODS.Joker {
    -- If hand played is four of a kind and contains 5 cards, convert the unscored card's rank to the rank of the four of a kind
    key = "technology",
    loc_txt = {
        name = 'Technology',
        text = {
            "If a {C:attention}Four of a Kind{} is played",
            "with {C:attention}1{} unscored card,",
            "convert the unscored card's rank",
            "to the rank of the other cards"
        }
    },
    config = { extra = { } },
    pos = {
        x = 7,
        y = 21
    },
    cost = 5,
    rarity = 2,
    blueprint_compat = false,
    eternal_compat = true,
    unlocked = true,
    discovered = true,
    atlas = 'IsaactroJokers',

    calculate = function(self, card, context)
        if context.cardarea == G.jokers and context.joker_main and context.scoring_name == "Four of a Kind" and #context.full_hand == 5 and not context.blueprint then
            local new_value = context.scoring_hand[1].base.value
            -- convert the unscored card's rank to the rank of the other cards
            for _, playing_card in ipairs(context.full_hand) do
                if playing_card.base.value ~= new_value then
                    G.E_MANAGER:add_event(Event({
                        trigger = 'after',
                        delay = 0.5,
                        func = (function()
                            card:juice_up(0.3, 0.4)
                            playing_card:juice_up(0.3, 0.4)
                            SMODS.change_base(playing_card, nil, new_value)
                            play_sound('holo1', 1.2 + math.random()*0.1, 0.4)
                            return true
                        end)
                    }))
                    card_eval_status_text(playing_card, 'extra', nil, nil, nil, {message = localize('k_duplicated_ex')})
                    return
                end
            end
        end
    end
}

-- The Parasite (uncommon)
SMODS.Joker {
    -- If discard contains only 1 card, draw an additional two cards
    key = "parasite",
    loc_txt = {
        name = 'The Parasite',
        text = {
            "If {C:attention}Discard{} contains ",
            "only {C:attention}#1#{} card, gain",
            "{C:red}+#2#{} hand size for",
            "the round"
        }
    },
    config = { extra = { contains = 1, additional = 2, times_used = 0 } },
    pos = {
        x = 4,
        y = 24
    },
    cost = 5,
    rarity = 2,
    blueprint_compat = false,
    eternal_compat = true,
    unlocked = true,
    discovered = true,
    atlas = 'IsaactroJokers',
    loc_vars = function(self, info_queue, card)
        return {vars = { card.ability.extra.contains, card.ability.extra.additional }}
    end,
    calculate = function(self, card, context)
        if context.discard and #context.full_hand == card.ability.extra.contains then
            G.hand:change_size(card.ability.extra.additional)
            card.ability.extra.times_used = card.ability.extra.times_used + 1
            card_eval_status_text(card, 'extra', nil, nil, nil, {message = localize('k_upgrade_ex')})
        end

        if context.end_of_round and not context.blueprint and not context.repetition and not context.individual then
            G.hand:change_size(-card.ability.extra.additional * card.ability.extra.times_used)
            card.ability.extra.times_used = 0
        end
    end
}

-- Mutant Spider (rare)
SMODS.Joker { 
    -- X4 mult if most played hand is at least level 8
    key = "mutantspider",
    loc_txt = {
        name = 'Mutant Spider',
        text = {
            "{X:mult,C:white}X#1#{} Mult if",
            "{C:attention}Most Played Hand{} is",
            "at least {C:attention}Level #2#{}",
            "{C:inactive}(Currently {C:attention}#3#{C:inactive}/#2#)"
        }
    },
    config = { extra = { Xmult = 4, level = 8 } },
    pos = {
        x = 8,
        y = 27
    },
    cost = 6,
    rarity = 3,
    blueprint_compat = true,
    eternal_compat = true,
    unlocked = true,
    discovered = true,
    atlas = 'IsaactroJokers',

    loc_vars = function(self, info_queue, card)
        return {vars = { card.ability.extra.Xmult, card.ability.extra.level, level_of_most_played() }}
    end,

    calculate = function(self, card, context)
        if context.joker_main and level_of_most_played() >= card.ability.extra.level then
            return {
                Xmult_mod = card.ability.extra.Xmult,
                message = localize { type = 'variable', key = 'a_xmult', vars = {card.ability.extra.Xmult} }
            }
        end
    end
}

-- Cricket's Body (rare)
SMODS.Joker {
    -- If first played hand is 1 face card, destroy it and add 4 random number cards to hand
    key = "cricketsbody",
    loc_txt = {
        name = "Cricket's Body",
        text = {
            "If {C:attention}first hand{} of",
            "round is {C:attention}#1# face card{},",
            "destroy it and add {C:attention}#2#{}",
            "random {C:attention}numbered cards{}",
            "to your hand"
        }
    },
    config = { extra = { face_cards = 1, numbered_cards = 4, used = false } },
    pos = {
        x = 9,
        y = 33
    },
    cost = 7,
    rarity = 3,
    blueprint_compat = false,
    eternal_compat = true,
    unlocked = true,
    discovered = true,
    atlas = 'IsaactroJokers',
    loc_vars = function(self, info_queue, card)
        return {vars = { card.ability.extra.face_cards, card.ability.extra.numbered_cards }}
    end,
    calculate = function(self, card, context)
        if context.first_hand_drawn and not context.blueprint then
            card.ability.extra.used = false
            local eval = function() return not card.ability.extra.used end
            juice_card_until(card, eval, true)
        end

        if context.destroying_card and context.destroying_card:get_id() >= 11 and G.GAME.current_round.hands_played == 0 and #context.full_hand == 1 and not context.blueprint then
            card.ability.extra.used = true
            card_eval_status_text(context.destroying_card, 'extra', nil, nil, nil, {message = localize('k_eaten_ex')})
            G.E_MANAGER:add_event(Event({
                trigger = 'after',
                delay = 0.7,
                func = function()
                    for i = 1, card.ability.extra.numbered_cards do
                        local numbers = {}
                        for _, v in ipairs(SMODS.Rank.obj_buffer) do
                            local r = SMODS.Ranks[v]
                            if v ~= 'Ace' and not r.face then table.insert(numbers, r) end
                        end
                        local _suit, _rank =
                            pseudorandom_element(SMODS.Suits, pseudoseed('cricketsbody')).card_key,
                            pseudorandom_element(numbers, pseudoseed('cricketsbody')).card_key
                        create_playing_card({
                            front = G.P_CARDS[_suit .. '_' .. _rank],
                            center = nil,
                        }, G.hand, nil, i ~= 1, { G.C.SECONDARY_SET.Spectral })
                    end
                    return true
                end
            }))

            return true
        end

        
    end
}

-- Holy Light (uncommon)
SMODS.Joker {
    -- 1 in 4 chance for each played card to gain random enhancement when scored
    key = "holylight",
    loc_txt = {
        name = "Holy Light",
        text = {
            "{C:green}#1# in #2#{} chance for",
            "each played card to gain",
            "a {C:attention}random enhancement{} when scored"
        }
    },
    config = { extra = { odds = 4 } },
    pos = {
        x = 9,
        y = 45
    },
    cost = 5,
    rarity = 2,
    blueprint_compat = false,
    eternal_compat = true,
    unlocked = true,
    discovered = true,
    atlas = 'IsaactroJokers',
    loc_vars = function(self, info_queue, card)
        return {vars = { G.GAME.probabilities.normal, card.ability.extra.odds }}
    end,
    calculate = function(self, card, context)
        if context.cardarea == G.play and context.individual and not context.blueprint then
            if pseudorandom('holylight') < 1 / 5 then
                local cen_pool = {}
                for k, v in pairs(G.P_CENTER_POOLS["Enhanced"]) do
                    if v.key ~= 'm_stone' and not v.overrides_base_rank then
                        cen_pool[#cen_pool + 1] = v
                    end
                end
                local enhancement = pseudorandom_element(cen_pool, pseudoseed('holylight'))
                context.other_card:set_ability(enhancement, nil, true)
                G.E_MANAGER:add_event(Event({
                    func = function()
                        context.other_card:juice_up()
                        return true
                    end
                })) 
                card_eval_status_text(context.other_card, 'extra', nil, nil, nil, {message = localize('k_upgrade_ex')})
            end
        end
    end
}


-- --- Tester challenges for isaactro jokers
SMODS.Challenge {
    loc_txt = "Isaactro Tester",
    key = "isaactro_tester",
    rules = {
        custom = {},
        modifiers = {
            {id = 'hands', value = 10},
            {id = 'discards', value = 10},
            {id = 'joker_slots', value = 10},
            {id = 'dollars', value = 10000}
        }
    },
    vouchers = {
        {id = "v_overstock_norm"},
        {id = "v_overstock_plus"},
        {id = "v_paint_brush"},
        {id = "v_palette"},
        {id = "v_reroll_surplus"},
        {id = "v_reroll_glut"}
    },
    jokers = { 
        {id = "j_blueprint"},
        {id = "j_itro_holylight"}, 
        {id = "j_bootstraps"},
        {id = "j_cavendish"},
        {id = "j_blue_joker"},
        {id = "j_oops"},
        {id = "j_hanging_chad"},
    },
    unlocked = true
}

