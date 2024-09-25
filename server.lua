local QBCore = exports['qb-core']:GetCoreObject()

local Config = {
    allowedJobs = {
        ['police'] = true,
        ['ambulance'] = true,
        ['smggarage'] = true,
        ['pawnshop'] = true,
        ['sals'] = true,
        --more jobs here...
    },
    commissionRate = 0.15, -- 15% commission
    serverTaxRate = 0.20, -- 20% server tax
    webhookUrl = "https://discord.com/api/webhooks/1288558149179277342/PLdrhQut2bSYT3Y5wJMEG2MxPNaWFsJWbecF7MtB9x6ExRK9gYYeQwrPwKeUOAMTl9P2" -- Replace with your actual webhook URL
}

local function isJobAllowed(job)
    return Config.allowedJobs[job] ~= nil
end

local function sendToDiscord(charger, target, amount, reason, status)
    local color
    local title
    if status == "created" then
        color = 3447003 -- Blue
        title = "New Invoice Created"
    elseif status == "paid" then
        color = 65280 -- Green
        title = "Invoice Paid"
    elseif status == "declined" then
        color = 16711680 -- Red
        title = "Invoice Declined"
    end

    local description
    if status == "created" then
        description = string.format("An invoice has been created by %s %s for %s %s", 
            charger.PlayerData.charinfo.firstname, 
            charger.PlayerData.charinfo.lastname,
            target.PlayerData.charinfo.firstname, 
            target.PlayerData.charinfo.lastname
        )
    else
        description = string.format("An invoice has been %s by %s %s - Invoicer: %s %s",
            status,
            target.PlayerData.charinfo.firstname,
            target.PlayerData.charinfo.lastname,
            charger.PlayerData.charinfo.firstname,
            charger.PlayerData.charinfo.lastname
        )
    end

    local embed = {
        {
            ["color"] = color,
            ["title"] = title,
            ["description"] = description,
            ["fields"] = {
                {
                    ["name"] = "Invoicer Details",
                    ["value"] = string.format("Name: %s %s\nCitizen ID: %s\nJob: %s", 
                        charger.PlayerData.charinfo.firstname, 
                        charger.PlayerData.charinfo.lastname,
                        charger.PlayerData.citizenid,
                        charger.PlayerData.job.name
                    ),
                    ["inline"] = true
                },
                {
                    ["name"] = "Recipient Details",
                    ["value"] = string.format("Name: %s %s\nCitizen ID: %s", 
                        target.PlayerData.charinfo.firstname, 
                        target.PlayerData.charinfo.lastname,
                        target.PlayerData.citizenid
                    ),
                    ["inline"] = true
                },
                {
                    ["name"] = "Invoice Details",
                    ["value"] = string.format("Amount: $%d\nReason: %s", amount, reason),
                    ["inline"] = false
                }
            },
            ["footer"] = {
                ["text"] = "Invoice System"
            },
            ["timestamp"] = os.date("!%Y-%m-%dT%H:%M:%SZ")
        }
    }

    PerformHttpRequest(Config.webhookUrl, function(err, text, headers) end, 'POST', json.encode({username = "Invoice Logger", embeds = embed}), { ['Content-Type'] = 'application/json' })
end

RegisterNetEvent('vk-invoice:server:chargeBill', function(targetId, amount, reason)
    local src = source
    local charger = QBCore.Functions.GetPlayer(src)
    local target = QBCore.Functions.GetPlayer(targetId)
    
    if not charger or not target then
        TriggerClientEvent('QBCore:Notify', src, 'Invalid player(s)', 'error')
        return
    end
    
    if not isJobAllowed(charger.PlayerData.job.name) then
        TriggerClientEvent('QBCore:Notify', src, 'You are not authorized to charge bills', 'error')
        return
    end
    
    if target.PlayerData.money['bank'] < amount then
        TriggerClientEvent('QBCore:Notify', src, 'They don\'t have enough money.', 'error')
        return
    end
    
    sendToDiscord(charger, target, amount, reason, "created")
    TriggerClientEvent('vk-invoice:client:receiveInvoice', targetId, src, amount, reason)
end)

RegisterNetEvent('vk-invoice:server:invoiceResponse', function(response, chargerId, amount, reason)
    local src = source
    local target = QBCore.Functions.GetPlayer(src)
    local charger = QBCore.Functions.GetPlayer(chargerId)
    
    if not target or not charger then
        return
    end
    
    if response then
        local commission = math.floor(amount * Config.commissionRate)
        local serverTax = math.floor(amount * Config.serverTaxRate)
        local bossmenuAmount = amount - commission - serverTax
        
        target.Functions.RemoveMoney('bank', amount, reason)
        charger.Functions.AddMoney('bank', commission, 'Bill commission')
        exports['qb-banking']:AddMoney(charger.PlayerData.job.name, bossmenuAmount)
        
        TriggerClientEvent('QBCore:Notify', chargerId, 'Invoice accepted. You received $' .. commission .. ' commission', 'success')
        TriggerClientEvent('QBCore:Notify', src, 'You paid $' .. amount .. ' for ' .. reason, 'inform')
        
        print(string.format("[vk-invoice] %s paid %s $%d for %s. Commission: $%d, Tax: $%d, Bossmenu: $%d",
            target.PlayerData.charinfo.firstname, charger.PlayerData.charinfo.firstname, amount, reason, commission, serverTax, bossmenuAmount))
        
        sendToDiscord(charger, target, amount, reason, "paid")
    else
        TriggerClientEvent('QBCore:Notify', chargerId, 'Invoice was denied by the recipient', 'error')
        TriggerClientEvent('QBCore:Notify', src, 'You denied the invoice', 'inform')
        
        sendToDiscord(charger, target, amount, reason, "declined")
    end
end)
