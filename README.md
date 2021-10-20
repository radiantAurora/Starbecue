# ZyganSSVMAddons

To install simply visit the [releases page](https://github.com/Zygahedron/ZyganSSVMAddons/releases), download the latest one (the .pak file), and put it in your Starbound mods folder.

This mod Requires [Stardust Core](https://steamcommunity.com/sharedfiles/filedetails/?id=764887546)

Alternatively, if you want the latest and greatest changes, download this repo as a zip and extract in your starbound mods folder, or better yet, use git to clone it there so that you can update it more easily. Just be warned that things won't always be perfectly stable.

While not required it is recommended you install the Monster Config Core Loader mods found [here](https://steamcommunity.com/sharedfiles/filedetails/?id=2442860690) and [here](https://steamcommunity.com/sharedfiles/filedetails/?id=2442873217), and if you're using FU you'll also need [this](https://steamcommunity.com/sharedfiles/filedetails/?id=2442880727) because it should fix potential compatibility issues.

## Features

![](/vehicles/sbq/sbqVaporeon/sbqVaporeon.png)![](/vehicles/sbq/sbqEgg/sbqEgg.png)![](/vehicles/sbq/sbqXeronious/sbqXeronious.png)![](/vehicles/sbq/sbqEgg/sbqEggXeronious.png)![](/vehicles/sbq/sbqCharem/sbqCharem.png)

### Playable Predators
- Vaporeon
- Veronious

### Object Predators
- Charem

### Other Things
- Egg

### Playable Predator Info

Special potions can be purchased from Auri's shop which can transform you into large predators, and grants you a head tech that allows you to choose which one you wish to transform into if you've unlocked multiple.

Full use of this system requires you to bind Tech Action 2 and 3 in the options if they aren't already bound. We recommend the G and H keyes respectively, because they're right by F, and that's what they were back in really old versions of the game when they were actually used in vanilla.

When turning into a predator you will be given a controller item, this is required for the predator transformation to detect some keys being pressed, such as Shift, as well as pass some more data to the vehicle that it cannot detect without it.

Holding Tech Action 1 (F) while controlling a pred allows you to bring up its action wheel, the X at the bottom will despawn the pred, choosing another action will attempt to perform that action, some of these will need to be aimed, so you might want to assign that action to a controller by clicking on it, if you have a controller in the hand of the click, it will assign it that action, if the hand was empty, it will spawn a new controller for you. Keep in mind a pred might have some actions that are available in some states but not others, clicking with a controller with an assigned action that the pred does not have will not result in anything.

Most predators will have the same movement controls a player would, but tapping movment keys can be used to transition between different poses, like standing or sitting or sleeping, etc.

To let people out that you previously ate, simply press Tech Action 2 (G).

In the bottom right you will have a HUD to show what occupants you've eaten, as well as your current belly effect, this can be used to quickly change the effect, as well as access the settings quickly, and peform actions on the prey by clicking on them, such as letting them out, turbo digesting them, or predator specific actions, like transforming them

### Prey Info

Whether you are being eaten by a object predator, or a player transformed into a predator, as prey you will have a HUD in the bottom right, this indicates which directions you can struggle to cause the predator to do something.

For player controlled predators, most struggles are disabled so that player is in full control of their state, but if they are in a state where an escape is available, you may be able to struggle out still, but it is possible for them to disable being able to escape entirely in their settings.

#### Red
indicates a direction in which you could escape, such as out the mouth or butt, your prey settings do not impact whether the arrow appears or not, but they do effect whether you can actally escape, a red arrow may indicate an anal vore escape, but if it isn't enabled in your settings, struggling that direction will not do anything.

#### Blue
Indicates a state change, such as making the predator stand up or sit down.

#### Green
Indicates a state change, but only for state changes that would bring you closer to a state you can escape from.

#### Cyan
Indicates a direction that would move you to another location within the predator's body.

#### Yellow
Indicates a direction that would cause you to get eaten, only appears if you're just being held or hugged.

### Settings

The settings menu can be accessed from the quickbar, or from the predator HUD.

#### Pred Tab

The Settings menu will open to the Global Pred settings tab by default, these settings effect how you will perform as a predator.

The belly effect names are self explanitory, the rate at which they work is effected by your attack power.

Escape modifier controls the difficulty of your prey being able to escape if you're in a state they can escape from

Display DoT effects causes the prey to emit numbers based on damage being taken.

Belly Sounds controls whether your belly will be silent or emit gurgles.

#### Prey Tab

Some people don't like certain kinds of vore, some people don't like vore at all! but they still might want to play games with other people who do, and this is meant to make that much easier.

Players can use the quickbar to access Starbecue's settings, the prey tab brings up a window with a bunch of checkboxes, this allows you to opt in and out of what types of vore can be done to you, check it if you're ok being prey for it, uncheck if you aren't, if you don't want to be prey at all just uncheck the "Prey Enabled" at the bottom of the menu, which overrides all the others.

Currently this does not affect whether any other vore mods can or can't perform vore on the player.

# Support Us!

https://www.patreon.com/LokiVulpix

Vote on what should be the next feature worked on!

## Main Credits

### Zygan (Zygahedron)

Created and animated much of the original Vaporeon sprite.

Does most of the lua scripting, the reason all of this works at all.

### LokiVulpix / Wasabi_Raptor

Edited and animated some of the Vaporeon sprite, and created the Xeronious sprites.

Helps out with debugging and coding a little here and there.

> I take commissions! contact me if I am open!
>
> https://www.furaffinity.net/user/lokithevulpix/
> https://twitter.com/LokiVulpix

## Planned Future Additions

### Vore RP tech
To replace the one used by SSVM
- will be further improved by allowing player prey to warp with you when warping to another world
- may have a setting to warp prey into a special "belly" world for that predator player

### Vore Tenants
A system to replace the one used by SSVM
- will make it be compatible with our prey enabling system

### Predators

From Scratch
- Eevee
- Flareon
- Jolteon
- Espeon
- Umbreon
- Leafeon
- Glaceon
- Sylveon
- Yoshi
- Masotan
- Protogen

Vanilla Races
- Humans
- Avian
- Apex
- Floran
- Hylotl
- Glitch
- Novakid

Modded Races
- Avali (Forum page gives permssion to use assets)
- Crylan (Permission granted by Crescent)
- Hibani (Premission granted by htfcuddles and Sheights)
- Rodent (Premission granted by Sheights)
- Draikin (Abandoned by creator)

## Do Not Ask/Contact

People who were previously asked about compatibilty and requested not to be contacted further

Bun (Protogen Race Mod)
- There is to be no compatibility
- Nobody is to extract assets to modify
- Do not contact or ask further

Crescent (Crylan Race Mod)
- Permission granted to use assets
- Do not contact or ask further
