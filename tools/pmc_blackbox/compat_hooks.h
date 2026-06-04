/**
 * compat_hooks.h — Runtime compatibility hook layer for Mercenaries 2
 *
 * Provides inline hooks via MinHook for the game's core lookup functions.
 * When a lookup fails (NULL return, -1 index, out-of-bounds), the hooks
 * log structured diagnostics and optionally break into the debugger.
 *
 * Three operating modes (PMC_HOOK_*) control verbosity.
 */

#pragma once

#define WIN32_LEAN_AND_MEAN
#include <windows.h>

/* --- Hook operating modes --- */
#define PMC_HOOK_SILENT  0   /* Safe stubs only, no logging */
#define PMC_HOOK_LOG     1   /* Safe stubs + structured log lines (default) */
#define PMC_HOOK_BREAK   2   /* Safe stubs + log + __debugbreak() on miss */

/* --- Public API --- */

/**
 * Install all compatibility hooks. Call once from DllMain after
 * InitDebugConsole() and before LoadASIPlugins().
 * Returns the number of hooks successfully installed.
 */
int InstallCompatHooks(void);

/**
 * Remove all hooks and print session statistics.
 * Safe to call even if InstallCompatHooks() was never called.
 */
void ShutdownCompatHooks(void);

/**
 * Print the current session statistics via pmc_log().
 * Can be called at any time (e.g., from a console command).
 */
void PrintCompatStats(void);

/**
 * Set the hook operating mode at runtime.
 * Accepts PMC_HOOK_SILENT, PMC_HOOK_LOG, or PMC_HOOK_BREAK.
 */
void SetCompatHookMode(int mode);

/**
 * Get the current hook operating mode.
 */
int GetCompatHookMode(void);
