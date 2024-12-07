---Distriubtes labs between available research
function process_research_queue()
    local labs = storage.labs
    local queue = game.forces["player"].research_queue
    refresh_lab_inventory(labs)
    distribute_research(labs, queue)
end

---Checks both inventories of labs, digitizing science packs if necessary
---@param labs_data table <uint, LabData>
function refresh_lab_inventory(labs_data)
    for _, lab_data in pairs(labs_data) do
        local inventory_contents = lab_data.inventory.get_contents()
        local digital_inventory = lab_data.digital_inventory
        for _, item in pairs(inventory_contents) do
            if not digital_inventory[item.name] then digital_inventory[item.name] = 0 end
            if digital_inventory[item.name] < 1 then
                digitize_science_packs(item, lab_data)
            end
        end
    end
end

---Removes up to 10 science packs from the lab's regular inventory and adds it durability to the lab's digital inventory.
---@param item ItemWithQualityCounts
---@param lab_data LabData
---@return boolean --Returns true if at least one science pack was digitized
function digitize_science_packs(item, lab_data)
    local durability = prototypes.item[item.name].get_durability(item.quality)
    local removed = lab_data.inventory.remove({name = item.name, quality = item.quality, count = 10})
    lab_data.digital_inventory[item.name] = lab_data.digital_inventory[item.name] + durability * removed
    return removed > 0
end

---Distributes technologies between all labs.
---@param labs table <uint, LabData>
---@param queue LuaTechnology[]
function distribute_research(labs, queue)
    -- Step 1. Turn the queue array into something more useful

    ---Table indexed by technology name containing a set of science packs
    ---@type table <string, table <string, boolean>>
    local tech_pack_key_sets = {}
    for _, technology in pairs(queue) do
        -- Check if the technology can be researched
        local researchable = true
        for _, prerequisite in pairs(technology.prerequisites) do
            if not prerequisite.researched then
                researchable = false
                break
            end
        end
        if researchable then
            local ingredient_set = {}
            for _, ingredient in pairs(technology.research_unit_ingredients) do
                ingredient_set[ingredient.name] = true
            end
            tech_pack_key_sets[technology.name] = ingredient_set
        end
    end

    -- Step 2: Compute relevance scores for each lab against each technology pack
    local relevance_scores = {}
    for lab_index, lab in pairs(labs) do
        relevance_scores[lab_index] = {}
        for name, key_set in pairs(tech_pack_key_sets) do
            -- Check if the lab satisfies all keys in the tech pack
            local satisfies_all_keys = true
            for key, _ in pairs(key_set) do
                if not lab.digital_inventory[key] or lab.digital_inventory[key] <= 0 then
                    satisfies_all_keys = false
                    break
                end
            end
            relevance_scores[lab_index][name] = satisfies_all_keys and 1 or 0
        end
    end

    -- Step 3: Initialize table assignment counts
    local tech_pack_counts = {}
    for name, _ in pairs(tech_pack_key_sets) do
        tech_pack_counts[name] = 0
    end

    -- Step 4: Assign labs to the best matching technology
    for lab_index, _ in pairs(labs) do
        local best_pack = nil
        local min_count = math.huge

        for name, score in pairs(relevance_scores[lab_index]) do
            if score > 0 and tech_pack_counts[name] < min_count then
                best_pack = name
                min_count = tech_pack_counts[name]
            end
        end

        -- Assign only if a valid technology is found
        if best_pack then
            labs[lab_index].assigned_tech = best_pack
            tech_pack_counts[best_pack] = tech_pack_counts[best_pack] + 1
        else
            labs[lab_index].assigned_tech = nil -- Explicitly set to nil if no tech is valid
        end
    end
end