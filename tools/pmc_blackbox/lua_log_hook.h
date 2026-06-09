/**
 * lua_log_hook.h — native capture of the game's Lua print/Debug.Printf stream
 *
 * Patches the game's `print` and `Debug.Printf` luaL_Reg func-pointer slots
 * (which ship pointing at the stubbed-out print routine 0x006D5640) so the
 * engine registers our bridge instead. Every Lua-level message the game emits
 * — including world-load milestones like "global start" — is then routed to
 * pmc_log() and lands in pmc_blackbox.log natively, with no separate ASI.
 *
 * This makes the call/message logging that used to live in dlc_enable.asi a
 * built-in feature of pmc_bb.
 */
#pragma once

/**
 * Patch the Lua print / Debug.Printf func-pointer slots to our logging bridge.
 * Call once from DllMain AFTER InitDebugConsole() (needs pmc_log) and BEFORE
 * LoadASIPlugins() (so pmc_bb claims the slots first; a later dlc_enable.asi
 * sees a non-stub pointer and cleanly skips, avoiding a double hook).
 *
 * Returns the number of slots successfully patched (0-2).
 */
int InstallLuaLogHook(void);
