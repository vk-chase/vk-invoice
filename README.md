# QBCore Invoice System

This is a custom invoice system for QBCore framework, allowing authorized jobs to create, send, and manage invoices within the game.

## Features

- Authorized job-based invoice creation
- Discord webhook integration for invoice logging
- Commission system for invoice creators
- Server tax implementation
- Bossmenu integration for job accounts

## Configuration

The system can be configured in the `Config` table at the top of the script:

```lua
local Config = {
    allowedJobs = {
        ['police'] = true,
        ['ambulance'] = true,
        ['smggarage'] = true,
        ['pawnshop'] = true,
        ['sals'] = true,
        -- Add more jobs here...
    },
    commissionRate = 0.15, -- 15% commission
    serverTaxRate = 0.20, -- 20% server tax
    webhookUrl = "YOUR_DISCORD_WEBHOOK_URL_HERE"
}


allowedJobs: List of jobs allowed to create invoices
commissionRate: Percentage of the invoice amount given to the creator as commission
serverTaxRate: Percentage of the invoice amount taken as server tax
webhookUrl: Discord webhook URL for logging


# Authorized jobs can create an invoice
#Discord Webhook
The system sends detailed information to a Discord channel via webhook:

Blue embed: New invoice created
Green embed: Invoice paid
Red embed: Invoice declined
#Each embed includes details about the invoicer, recipient, and invoice specifics.

# Dependencies
QBCore framework
qb-banking (for bossmenu integration)
Support
For support, please open an issue on the GitHub repository or contact the script author.

# License
MIT License

# Credits
Me
