# KOJA HUD

Free HUD for FiveM by **Koja Scripts**, built with Lua and React.

- Status bars (health, armour, hunger, thirst, stamina, oxygen, voice, stress) in 5 styles
- 5 speedometer styles with fuel, nitro, seatbelt, engine, RPM, lights and cruise control
- Notifications, progress bar, text UI, killfeed, status effects and low health / fuel warnings
- Compass, weapon & ammo panel, server watermark with a PVP mode
- Square minimap that players can move and resize in-game
- Vehicle control menu (signals, doors, hood, trunk, engine, seatbelt)
- Nitro system saved per owned vehicle
- In-game settings menu with a drag & drop layout editor and custom key binds
- Translations: English, Polski, Deutsch, Español, Français, Hindi

## Requirements

- [koja-lib](https://github.com/Koja-Scripts/koja-lib)
- [oxmysql](https://github.com/overextended/oxmysql)
- ESX, QBCore or QBox
- [pma-voice](https://github.com/AvarianKnight/pma-voice) for the voice indicator (optional)

## Installation

1. Download the latest release and put the `koja-hud` folder in your `resources` directory.
2. Add it to your `server.cfg` after its dependencies:

   ```cfg
   ensure oxmysql
   ensure koja-lib
   ensure koja-hud
   ```

3. Set `KOJA.Nitro.Tables` in `editable/shared/config.lua` to your owned vehicles table. The `nitro` column is created automatically.
4. Restart the server.

## Configuration

| File | What it controls |
| --- | --- |
| `editable/shared/config.lua` | Language, keys, nitro, seatbelt, engine, cruise control, minimap, killfeed, watermark, refresh rates |
| `editable/shared/js.json` | Keybind hints, Discord and logo, default player settings, settings menu layout |
| `editable/shared/utils.lua` | `Misc.Utils.CustomNotify` for `KOJA.Notify = 'custom'` |
| `locales/*.json` | All texts |

Players open the settings menu with `/settings` (`KOJA.SettingsCommand`). Their settings are stored in their own game client.

## Exports (client)

```lua
local hud = exports['koja-hud']

hud:sendNotify({ title = 'Bank', desc = 'You received <strong>$500</strong>', icon = 'fa-solid fa-building-columns', color = '#35c76c', time = 5000 })

hud:startProgressbar({
    label = 'Repairing',
    icon = 'fa-solid fa-wrench',
    time = 5,
    cancelable = true,
    animation = { dict = 'mini@repair', name = 'fixing_a_ped' },
    inputBlock = { keys = { 'W', 'A', 'S', 'D' } }
}, function(finished) end)
hud:cancelProgressbar()
hud:isProgressbarActive()

hud:TextUI({ type = 'press', input = 'E', desc = 'Open the stash' })
hud:HideUI()

hud:ToggleHUD(false)
hud:HideComponent('carhud', true)
hud:HideComponents({ status = true, informations = true })

hud:SetStatusEffects({ { id = 'drunk', icon = 'fa-solid fa-wine-bottle', color = '#c77dff', duration = 30 } })
hud:AddStatusEffect({ id = 'cold', icon = 'fa-solid fa-snowflake', color = '#6ab7ff' })
hud:RemoveStatusEffect('cold')

hud:AddKillfeed('Killer', 'Victim', 'fa-solid fa-gun', 25.0, { headshot = true })

hud:IsSeatbeltOn()
hud:SeatbeltState(true)
hud:GetStress()
hud:GetNitro()
hud:SetNitro()
```

`SetNitro` installs nitro in the owned vehicle in front of the player. When `KOJA.Nitro.Item` is set, the server checks and removes that item.

## Events

| Event | Side | Arguments |
| --- | --- | --- |
| `koja-hud:addStress` | client | `amount` |
| `koja-hud:removeStress` | client | `amount` |
| `koja_hud:killfeed` | client | `{ killer, victim, weapon, distance, headshot, self }` |
| `koja_hud:setStatusEffects` | client | list of effects |
| `koja_hud:startTextUI` | client | `{ type, input, desc }` |
| `koja_hud:cancelTextUI` | client | — |

## Building the UI

The compiled UI in `web/build` is included. To change it:

```bash
cd web
pnpm install
pnpm build      # production build
pnpm start      # browser preview with mock data
pnpm lint
```

## Support

Discord: [discord.gg/hexelstore](https://discord.gg/hexelstore)
