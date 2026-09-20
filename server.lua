local clothingDb = nil

CreateThread(function()
    local dbFile = LoadResourceFile(GetCurrentResourceName(), 'clothing_db.json')
    if dbFile then
        clothingDb = json.decode(dbFile)
        print('^2[cauta_haine]^7 Baza de date haine incarcata cu succes!')
    else
        print('^1[cauta_haine]^7 EROARE: Nu s-a putut incarca clothing_db.json!')
    end
end)

local function resolveClothingItem(gender, compId, drawable, texture, totalDrawables)
    if not clothingDb or not clothingDb[gender] then
        return nil, 'Baza de date nu este initializata'
    end

    local items = clothingDb[gender][tostring(compId)]
    if not items or #items == 0 then
        return nil, 'Nu exista haine custom stream pentru aceasta componenta'
    end

    local addonCount = #items
    local baseCount = totalDrawables - addonCount
    if baseCount < 0 then baseCount = 0 end

    if drawable < baseCount then
        return {
            isVanilla = true,
            baseCount = baseCount,
            drawable = drawable,
            texture = texture
        }
    end

    local addonIndex = (drawable - baseCount) + 1
    local matched = items[addonIndex]
    if not matched then
        return nil, ('Index addon %d negasit (total addonuri: %d)'):format(addonIndex, addonCount)
    end

    local texList = matched.textures or {}
    local texIndex = texture + 1
    local texFile = texList[texIndex] or (texList[1] or 'Lipsa .ytd')

    return {
        isVanilla = false,
        pack = matched.pack,
        model = matched.model,
        code = matched.code,
        textureFile = texFile,
        allTextures = texList,
        path = matched.path,
        addonIndex = addonIndex,
        totalInPack = addonCount,
        drawable = drawable,
        texture = texture
    }
end

local function resolvePropItem(gender, propId, drawable, texture, totalDrawables)
    local key = gender .. '_props'
    if not clothingDb or not clothingDb[key] then return nil, 'Baza de date lipsa' end

    local items = clothingDb[key][tostring(propId)]
    if not items or #items == 0 then
        return nil, 'Nu exista propuri custom pentru acest slot'
    end

    local addonCount = #items
    local baseCount = totalDrawables - addonCount
    if baseCount < 0 then baseCount = 0 end

    if drawable < baseCount then
        return { isVanilla = true, baseCount = baseCount, drawable = drawable, texture = texture }
    end

    local addonIndex = (drawable - baseCount) + 1
    local matched = items[addonIndex]
    if not matched then return nil, 'Index negasit' end

    local texList = matched.textures or {}
    local texIndex = texture + 1
    local texFile = texList[texIndex] or (texList[1] or 'Lipsa .ytd')

    return {
        isVanilla = false,
        pack = matched.pack,
        model = matched.model,
        code = matched.code,
        textureFile = texFile,
        allTextures = texList,
        path = matched.path,
        addonIndex = addonIndex,
        totalInPack = addonCount,
        drawable = drawable,
        texture = texture
    }
end

RegisterNetEvent('cauta_haine:checkItem', function(data)
    local src = source
    local results = {}

    local gender = data.gender or 'male'
    local itemsToCheck = data.items or {}

    for _, c in ipairs(itemsToCheck) do
        if c.isProp then
            local res, err = resolvePropItem(gender, c.id, c.drawable, c.texture, c.totalDrawables)
            table.insert(results, {
                label = c.label,
                id = c.id,
                isProp = true,
                result = res,
                error = err
            })
        else
            local res, err = resolveClothingItem(gender, c.id, c.drawable, c.texture, c.totalDrawables)
            table.insert(results, {
                label = c.label,
                id = c.id,
                isProp = false,
                result = res,
                error = err
            })
        end
    end

    TriggerClientEvent('cauta_haine:displayResults', src, results)
end)

RegisterNetEvent('cauta_haine:searchByKeyword', function(keyword)
    local src = source
    if not clothingDb then return end
    keyword = string.lower(keyword or '')
    if #keyword < 2 then
        TriggerClientEvent('chat:addMessage', src, {
            color = { 255, 60, 60 },
            args = { '[CAUTA HAINE]', 'Cuvantul de cautare trebuie sa aiba minimum 2 caractere!' }
        })
        return
    end

    local matches = {}
    for g, comps in pairs(clothingDb) do
        for cId, list in pairs(comps) do
            for _, item in ipairs(list) do
                local matchFound = false
                if string.find(string.lower(item.model), keyword, 1, true) then
                    matchFound = true
                else
                    for _, t in ipairs(item.textures or {}) do
                        if string.find(string.lower(t), keyword, 1, true) then
                            matchFound = true
                            break
                        end
                    end
                end

                if matchFound then
                    table.insert(matches, {
                        gender = g,
                        compId = cId,
                        model = item.model,
                        textures = item.textures or {},
                        pack = item.pack,
                        path = item.path
                    })
                    if #matches >= 20 then break end
                end
            end
            if #matches >= 20 then break end
        end
        if #matches >= 20 then break end
    end

    TriggerClientEvent('cauta_haine:displaySearch', src, keyword, matches)
end)
