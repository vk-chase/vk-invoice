local QBCore = exports['qb-core']:GetCoreObject()

local function formatCurrency(amount)
    return string.format("$%.2f", amount)
end

RegisterNetEvent('vk-invoice:client:receiveInvoice', function(senderId, amount, reason)
    print("Received invoice event")
    
    -- Simple notification
    QBCore.Functions.Notify('New Invoice Received', 'info')
    QBCore.Functions.Notify('From: ' .. tostring(senderId), 'info')
    QBCore.Functions.Notify('Amount: ' .. formatCurrency(amount), 'info')
    QBCore.Functions.Notify('Reason: ' .. tostring(reason), 'info')
    
    -- Show TextUI
    lib.showTextUI('[E] Pay Invoice | [G] Decline')
    
    -- Flag to control the loop
    local awaitingResponse = true
    
    CreateThread(function()
        while awaitingResponse do
            if IsControlJustReleased(0, 38) then -- E key
                awaitingResponse = false
                lib.hideTextUI()
                TriggerServerEvent('vk-invoice:server:invoiceResponse', true, senderId, amount, reason)
                QBCore.Functions.Notify('Processing payment...', 'info', 2000)
            elseif IsControlJustReleased(0, 47) then -- G key
                awaitingResponse = false
                lib.hideTextUI()
                TriggerServerEvent('vk-invoice:server:invoiceResponse', false, senderId, amount, reason)
                QBCore.Functions.Notify('Invoice declined.', 'warn', 2000)
            end
            Wait(0)
        end
    end)
end)

RegisterNetEvent('vk-invoice:client:openInvoiceMenu', function()
    local input = lib.inputDialog('Create New Invoice', {
        {type = 'number', label = 'Recipient ID', required = true},
        {type = 'number', label = 'Amount ($)', required = true},
        {type = 'input', label = 'Reason', required = true}
    })

    if input then
        local recipientId, amount, reason = table.unpack(input)
        if recipientId and amount and reason then
            TriggerServerEvent('vk-invoice:server:chargeBill', recipientId, amount, reason)
            QBCore.Functions.Notify('Invoice sent successfully!', 'success')
        else
            QBCore.Functions.Notify('Invalid input. Please fill all fields.', 'error')
        end
    else
        QBCore.Functions.Notify('Invoice creation cancelled.', 'error')
    end
end)

RegisterCommand('invoice', function()
    TriggerEvent('vk-invoice:client:openInvoiceMenu')
end, false)
