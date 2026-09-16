# Modern Start Menu icon sources

## Production NikoIchu set (v0.1.12)

The current atlas uses selected files from NikoIchu's native 16×16
[1-bit Pixel Icons v1.2](https://nikoichu.itch.io/pixel-icons), released under
CC0 1.0. Thirty-one source frames live in `nikoichu/source/`; exact converted
frames live in `nikoichu/native/` alongside the custom party frame.

| Menu frame | Selected NikoIchu source |
| --- | --- |
| Pokédex | `Tools_Crafting_Books_Manual_Codex_Instructions_Tutorial_Documentation.png` |
| Bag | `Travel_Backpack_Bag_School.png` |
| Trainer | `Travel_Person_Player_Character_Single.png` |
| Save | `Software_Save_Button_Floppy_Disk.png` |
| Options | `Software_Options_Settings_Sliders_Knobs_Audio.png` |
| Pokégear | `Software_Hardware_Mobile_Smartphone_Touchscreen_Input.png` |
| Link | `Software_Link_Chain_Shortcut_Combo.png` |
| Mods | `Software_Options_Settings_Cogwheel_Gear_Mechanics.png` |
| Quit | `Software_Exit_Quit_Crossout_Button.png` |
| Generic mod | `Controller_Buttons_Menu_Options_Settings.png` |
| Auto | `Arrows_Reload_Refresh_Rotate_Clockwise.png` |
| Quest | `Tools_Crafting_Writing_Parchment_Scroll_Document_Quill_Pen.png` |
| Map | `Map_Markers_Scroll_Map_Location.png` |
| Music | `Media_Musical_Note_Quaver.png` |
| Camera | `Media_Camera_Photo_Shoot_1.png` |
| Trophy | `Sports_Winner_Award_Cup_Achievement_Trophy.png` |
| Heart | `RPG_Stat_HP_Health_Heart.png` |
| Star | `RPG_Stat_MP_Mana_Star.png` |
| Tools | `Software_Options_Settings_Tools_Mechanics_Wrench.png` |
| Key | `Tools_Crafting_Key_Unlock_1.png` |
| Clock | `Software_Clock_Time_Wait_1.png` |
| Mail | `Software_Email_Message_Unread_Closed.png` |
| Chat | `Software_Speech_Bubble_Three_Dots_Dialogue.png` |
| Home | `Map_Markers_Building_Home_House.png` |
| Shop | `Map_Markers_Building_Shop_Storefront.png` |
| Chest | `Tools_Crafting_Chest_Locked_Loot.png` |
| Battle | `RPG_Crossed_Swords_Duel_PvP_Combat_Battle_War.png` |
| Potion | `Alchemy_Potion_Vial_Bottle_Full.png` |
| Bicycle | `Sports_Bicycle_Bike_Riding.png` |
| Craft | `Tools_Crafting_Smithing_Anvil_Hammer.png` |
| Search | `Software_Magnifier_Zoom_Looking_Magnifying_Glass.png` |

The 32nd frame, Party, is an original generic three-person team symbol declared directly
in `tools/start_menu_icon_nikoichu/main.lua`. The packer asserts a 16×16
source grid, pure one-bit input, binary transparency, one opaque output shade
and at least one visible pixel per frame. It preserves every source coordinate
exactly and performs no scaling, tracing, interpolation or contour cleanup.

Rebuild from the repository root:

```sh
tools/start_menu_icon_nikoichu/run.sh
```

Only the resulting `assets/start_menu_icons.png`
ships at runtime. `THIRD_PARTY_NOTICES.md` records
the CC0 source in the distributable package.
