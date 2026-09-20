local COMP_NAMES = {
    [11] = 'Top (Geaca / Hanorac / Haina)',
    [8]  = 'Tricou (Undershirt)',
    [9]  = 'Vesta Antiglont (Body Armor)',
    [4]  = 'Pantaloni (Legs)',
    [6]  = 'Pantofi (Shoes)',
    [7]  = 'Accesorii / Lant (Necklace)',
    [1]  = 'Masca (Mask)',
    [3]  = 'Brate / Maini (Torso/Gloves)',
    [10] = 'Decals (Insigne / Embleme)'
}

local PROP_NAMES = {
    [0] = 'Palarie / Casca / Sapca (Hat)',
    [1] = 'Ochelari (Glasses)',
    [2] = 'Cercei (Ears)',
    [6] = 'Ceas (Watch)',
    [7] = 'Bratara (Wrist)'
}

local function getGender()
    local ped = PlayerPedId()
    local model = GetEntityModel(ped)
    if model == GetHashKey('mp_f_freemode_01') then
        return 'female'
    end
    return 'male'
end

local function inspectComponents(filterComp)
    local ped = PlayerPedId()
    local gender = getGender()
    local items = {}

    local targets = { 11, 8, 9, 4, 7, 6, 1 }
    if filterComp ~= nil then
        targets = { filterComp }
    end

    for _, compId in ipairs(targets) do
        local draw = GetPedDrawableVariation(ped, compId)
        local tex = GetPedTextureVariation(ped, compId)
        local totalDraw = GetNumberOfPedDrawableVariations(ped, compId)
        local totalTex = GetNumberOfPedTextureVariations(ped, compId, draw)

        table.insert(items, {
            id = compId,
            label = COMP_NAMES[compId] or ('Componenta ' .. compId),
            isProp = false,
            drawable = draw,
            texture = tex,
            totalDrawables = totalDraw,
            totalTextures = totalTex
        })
    end

    TriggerServerEvent('cauta_haine:checkItem', {
        gender = gender,
        items = items
    })
end

local function inspectProp(propId)
    local ped = PlayerPedId()
    local gender = getGender()
    local draw = GetPedPropIndex(ped, propId)
    local tex = GetPedPropTextureIndex(ped, propId)
    local totalDraw = GetNumberOfPedPropDrawableVariations(ped, propId)

    if draw == -1 then
        TriggerEvent('chat:addMessage', {
            color = { 255, 180, 0 },
            args = { '[CAUTA HAINE]', ('Nu porti niciun accesoriu pe slotul %s.'):format(PROP_NAMES[propId] or propId) }
        })
        return
    end

    TriggerServerEvent('cauta_haine:checkItem', {
        gender = gender,
        items = {
            {
                id = propId,
                label = PROP_NAMES[propId] or ('Prop ' .. propId),
                isProp = true,
                drawable = draw,
                texture = tex,
                totalDrawables = totalDraw
            }
        }
    })
end

RegisterCommand('haina', function(_, args)
    local sub = string.lower(args[1] or '')

    if sub == 'search' or sub == 'cauta' then
        local kw = args[2] or ''
        if kw == '' then
            TriggerEvent('chat:addMessage', {
                color = { 255, 60, 60 },
                args = { '[CAUTA HAINE]', 'Sintaxa: /haina search [cuvant]' }
            })
            return
        end
        TriggerServerEvent('cauta_haine:searchByKeyword', kw)
        return
    end

    if sub == 'top' or sub == 'geaca' or sub == 'jacket' or sub == '11' then
        inspectComponents(11)
    elseif sub == 'vesta' or sub == 'vest' or sub == '9' then
        inspectComponents(9)
    elseif sub == 'tricou' or sub == 'shirt' or sub == 'tshirt' or sub == '8' then
        inspectComponents(8)
    elseif sub == 'pantaloni' or sub == 'pants' or sub == 'legs' or sub == '4' then
        inspectComponents(4)
    elseif sub == 'acc' or sub == 'accesorii' or sub == 'lant' or sub == 'chain' or sub == '7' then
        inspectComponents(7)
    elseif sub == 'pantofi' or sub == 'shoes' or sub == 'incaltaminte' or sub == 'feet' or sub == '6' then
        inspectComponents(6)
    elseif sub == 'masca' or sub == 'mask' or sub == '1' then
        inspectComponents(1)
    elseif sub == 'palarie' or sub == 'hat' or sub == 'casca' or sub == 'sapca' or sub == 'cap' or sub == 'helmet' or sub == 'p0' or sub == '0' then
        inspectProp(0)
    elseif sub == 'ochelari' or sub == 'glasses' or sub == 'p1' then
        inspectProp(1)
    elseif sub == 'ceas' or sub == 'watch' or sub == 'p6' then
        inspectProp(6)
    elseif sub == 'bratara' or sub == 'wrist' or sub == 'p7' then
        inspectProp(7)
    else
        if sub == 'all' or sub == 'toate' then
            inspectComponents(nil)
            inspectProp(0)
            inspectProp(1)
        else
            inspectComponents(11)
        end
    end
end, false)

RegisterCommand('cautahaina', function(_, args)
    ExecuteCommand('haina ' .. table.concat(args, ' '))
end, false)

RegisterNetEvent('cauta_haine:displayResults', function(results)
    print('^2==============================================================^7')
    print('^2[CAUTA HAINE] REZULTATE PENTRU HAINELE ECHIPATE:^7')

    for _, item in ipairs(results) do
        local r = item.result
        if r then
            if r.isVanilla then
                local msg = ('^3%s^7: Haina este din GTA V Vanilla (jocul de baza, ID #%d, Textura #%d). Nu face parte dintr-un pack custom.'):format(item.label, r.drawable, r.texture)
                TriggerEvent('chat:addMessage', {
                    color = { 255, 200, 0 },
                    multiline = true,
                    args = { '[CAUTA HAINE]', msg }
                })
                print(('   • %s: Vanilla GTA V (Drawable #%d, Texture #%d)'):format(item.label, r.drawable, r.texture))
            else
                local chatMsg = ('\n^2[%s]^7\n^3Model 3D (.ydd):^7 %s\n^3Textura (.ytd):^7 %s\n^3Folder Pack:^7 %s\n^5In-Game:^7 Drawable #%d | Textura #%d'):format(
                    item.label,
                    r.model,
                    r.textureFile,
                    r.path,
                    r.drawable,
                    r.texture
                )

                TriggerEvent('chat:addMessage', {
                    color = { 0, 255, 136 },
                    multiline = true,
                    args = { '[CAUTA HAINE]', chatMsg }
                })

                print('   ----------------------------------------------------')
                print(('   • Categorie:     %s'):format(item.label))
                print(('   • Model 3D:      %s'):format(r.model))
                print(('   • Textura (.ytd): %s'):format(r.textureFile))
                print(('   • Cale folder:   %s'):format(r.path))
                print(('   • In-Game ID:    Drawable #%d | Textura #%d'):format(r.drawable, r.texture))
                if #(r.allTextures or {}) > 1 then
                    print(('   • Toate texturile acestui model (%d variante):'):format(#r.allTextures))
                    for idx, tName in ipairs(r.allTextures) do
                        print(('      [%d] %s'):format(idx - 1, tName))
                    end
                end
            end
        else
            print(('   • %s: %s'):format(item.label, item.error or 'N/A'))
        end
    end
    print('^2==============================================================^7')
end)

RegisterNetEvent('cauta_haine:displaySearch', function(keyword, matches)
    if #matches == 0 then
        TriggerEvent('chat:addMessage', {
            color = { 255, 60, 60 },
            args = { '[CAUTA HAINE]', ('Nicio haina gasita pentru cuvantul "%s".'):format(keyword) }
        })
        return
    end

    TriggerEvent('chat:addMessage', {
        color = { 0, 255, 136 },
        args = { '[CAUTA HAINE]', ('Am gasit %d rezultate pentru "%s" (vezi detaliile in consola F8).'):format(#matches, keyword) }
    })

    print('^2==============================================================^7')
    print(('^2[CAUTA HAINE] REZULTATE PENTRU: "%s"^7'):format(keyword))
    for idx, m in ipairs(matches) do
        print(('^3[%d]^7 Model: ^2%s^7 | Pack: ^5%s^7'):format(idx, m.model, m.pack))
        print(('     Cale: %s'):format(m.path))
        if #(m.textures or {}) > 0 then
            print(('     Texturi: %s'):format(table.concat(m.textures, ', ')))
        end
    end
    print('^2==============================================================^7')
end)
