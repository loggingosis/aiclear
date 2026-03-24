RegisterCommand('deleteallai', function(source, args, rawCommand)
    -- Console can run it too, but if from server console, broadcast to all players
    TriggerClientEvent('deleteallai:run', -1)
end, true)

-- Optional alias, similar feel to dvall
RegisterCommand('aiclear', function(source, args, rawCommand)
    TriggerClientEvent('deleteallai:run', -1)
end, true)
