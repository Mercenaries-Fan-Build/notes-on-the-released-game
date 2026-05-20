	.file	"dlc_enable.c"
	.text
	.p2align 4
	.def	_Hook_HasPlayerUnlockedCode;	.scl	3;	.type	32;	.endef
_Hook_HasPlayerUnlockedCode:
	movl	4(%esp), %edx
	movl	8(%edx), %eax
	movl	$1, (%eax)
	addl	$8, %eax
	movl	$1, -4(%eax)
	movl	%eax, 8(%edx)
	movl	$1, %eax
	ret
	.section .rdata,"dr"
LC0:
	.ascii "%s\0"
LC1:
	.ascii "dlc_enable\0"
	.text
	.p2align 4
	.def	_Log;	.scl	3;	.type	32;	.endef
_Log:
	pushl	%esi
	pushl	%ebx
	subl	$1076, %esp
	leal	1092(%esp), %eax
	leal	48(%esp), %esi
	movl	%eax, 8(%esp)
	movl	1088(%esp), %eax
	movl	%esi, (%esp)
	movl	%eax, 4(%esp)
	call	*__imp__wvsprintfA@12
	subl	$12, %esp
	testl	%eax, %eax
	jle	L3
	movl	%eax, %ebx
	movl	_g_pmc_log, %eax
	testl	%eax, %eax
	je	L5
	movl	%esi, 8(%esp)
	movl	$LC0, 4(%esp)
	movl	$LC1, (%esp)
	call	*%eax
L6:
	movl	_g_crashLog, %eax
	cmpl	$-1, %eax
	je	L3
	movl	$2573, %edx
	movw	%dx, 48(%esp,%ebx)
	leal	44(%esp), %edx
	addl	$2, %ebx
	movl	%edx, 12(%esp)
	movl	$0, 16(%esp)
	movl	%ebx, 8(%esp)
	movl	%esi, 4(%esp)
	movl	%eax, (%esp)
	call	*__imp__WriteFile@20
	movl	_g_crashLog, %eax
	subl	$20, %esp
	movl	%eax, (%esp)
	call	*__imp__FlushFileBuffers@4
	subl	$4, %esp
L3:
	addl	$1076, %esp
	popl	%ebx
	popl	%esi
	ret
	.p2align 4,,10
	.p2align 3
L5:
	movl	_g_fallbackLog, %eax
	cmpl	$-1, %eax
	je	L6
	leal	44(%esp), %edx
	movl	$2573, %ecx
	movw	%cx, 48(%esp,%ebx)
	movl	%edx, 12(%esp)
	leal	2(%ebx), %edx
	movl	$0, 16(%esp)
	movl	%edx, 8(%esp)
	movl	%esi, 4(%esp)
	movl	%eax, (%esp)
	call	*__imp__WriteFile@20
	subl	$20, %esp
	jmp	L6
	.section .rdata,"dr"
	.align 4
LC3:
	.ascii "DLC bootstrap: CRASH caught (exception 0x%08X at 0x%08X)\0"
	.text
	.p2align 4
	.def	_InjectionCrashGuard@4;	.scl	3;	.type	32;	.endef
_InjectionCrashGuard@4:
	movl	_g_inInjection, %eax
	testl	%eax, %eax
	jne	L24
	ret	$4
	.p2align 4,,10
	.p2align 3
L24:
	subl	$28, %esp
	movl	32(%esp), %eax
	movl	(%eax), %eax
	movl	12(%eax), %edx
	movl	%edx, 8(%esp)
	movl	(%eax), %eax
	movl	$LC3, (%esp)
	movl	%eax, 4(%esp)
	call	_Log
	movl	$1, %eax
	movl	$0, _g_inInjection
	addl	$28, %esp
	ret	$4
	.section .rdata,"dr"
	.align 4
LC4:
	.ascii "ERROR: VirtualProtect failed for 0x%08X (err=%d)\0"
	.text
	.p2align 4
	.def	_InstallInlineHook.isra.0;	.scl	3;	.type	32;	.endef
_InstallInlineHook.isra.0:
	pushl	%ebp
	pushl	%edi
	pushl	%esi
	movl	%edx, %esi
	pushl	%ebx
	movl	%eax, %ebx
	subl	$44, %esp
	movl	(%eax), %eax
	movl	__imp__VirtualProtect@16, %edi
	leal	28(%esp), %ebp
	movl	%eax, (%ecx)
	movzbl	4(%ebx), %eax
	movl	%ebx, 8(%ecx)
	movb	%al, 4(%ecx)
	movl	%ebp, 12(%esp)
	movl	$64, 8(%esp)
	movl	$5, 4(%esp)
	movl	%ebx, (%esp)
	call	*%edi
	subl	$16, %esp
	testl	%eax, %eax
	je	L29
	movl	28(%esp), %eax
	subl	$5, %esi
	movb	$-23, (%ebx)
	subl	%ebx, %esi
	movl	%esi, 1(%ebx)
	movl	%ebp, 12(%esp)
	movl	%ebx, (%esp)
	movl	%eax, 8(%esp)
	movl	$5, 4(%esp)
	call	*%edi
	subl	$16, %esp
	call	*__imp__GetCurrentProcess@0
	movl	%ebx, 4(%esp)
	movl	$5, 8(%esp)
	movl	%eax, (%esp)
	call	*__imp__FlushInstructionCache@12
	subl	$12, %esp
	addl	$44, %esp
	popl	%ebx
	popl	%esi
	popl	%edi
	popl	%ebp
	ret
	.p2align 4,,10
	.p2align 3
L29:
	call	*__imp__GetLastError@0
	movl	%ebx, 4(%esp)
	movl	%eax, 8(%esp)
	movl	$LC4, (%esp)
	call	_Log
	addl	$44, %esp
	popl	%ebx
	popl	%esi
	popl	%edi
	popl	%ebp
	ret
	.p2align 4
	.def	_Hook_IsMatchmakingInternet;	.scl	3;	.type	32;	.endef
_Hook_IsMatchmakingInternet:
	movl	4(%esp), %edx
	movl	8(%edx), %eax
	movl	$1, (%eax)
	addl	$8, %eax
	movl	$1, -4(%eax)
	movl	%eax, 8(%edx)
	movl	$1, %eax
	ret
	.section .rdata,"dr"
	.align 4
LC5:
	.ascii "DLC bootstrap: injecting via luaL_loadbuffer(0x%08X) + lua_pcall(0x%08X)\0"
LC6:
	.ascii "=dlc_enable\0"
	.align 4
LC7:
	.ascii "local ok, err = pcall(function()\12  print('[dlc_enable] Lua injection running')\12  print('[dlc_enable] _VERSION = ' .. tostring(_VERSION))\12  print('[dlc_enable] Sys = ' .. tostring(Sys))\12  print('[dlc_enable] import = ' .. tostring(import))\12  if import then\12    local function try_import(name)\12      local s, e = pcall(import, name)\12      if s then print('[dlc_enable] imported: ' .. name) end\12      return s\12    end\12    try_import('dlccon001')\12    try_import('dlccon002')\12    try_import('dlccon003')\12    try_import('dlccon004')\12  end\12end)\12if not ok and err then\12  print('[dlc_enable] ERROR: ' .. tostring(err))\12end\12\0"
	.align 4
LC8:
	.ascii "DLC bootstrap: fn=0x%08X L=0x%08X code=0x%08X len=%d name=0x%08X\0"
	.align 4
LC9:
	.ascii "DLC bootstrap: luaL_loadbuffer returned %d\0"
	.align 4
LC10:
	.ascii "DLC bootstrap: skipped (target addresses not executable)\0"
	.align 4
LC11:
	.ascii "DLC bootstrap: loadbuffer failed (code %d)\0"
	.align 4
LC12:
	.ascii "DLC bootstrap: calling lua_pcall...\0"
	.align 4
LC13:
	.ascii "DLC bootstrap: lua_pcall returned %d\0"
	.align 4
LC14:
	.ascii "DLC bootstrap: pcall failed (code %d)\0"
	.align 4
LC15:
	.ascii "DLC bootstrap: injection successful\0"
	.text
	.p2align 4
	.def	_TryDLCBootstrap.part.0;	.scl	3;	.type	32;	.endef
_TryDLCBootstrap.part.0:
	pushl	%ebp
	pushl	%edi
	pushl	%esi
	pushl	%ebx
	movl	%eax, %ebx
	subl	$108, %esp
	movl	__imp__VirtualQuery@12, %esi
	leal	68(%esp), %edi
	movl	$28, 8(%esp)
	movl	%edi, 4(%esp)
	movl	$8782400, (%esp)
	call	*%esi
	subl	$12, %esp
	testl	%eax, %eax
	je	L33
	cmpl	$4096, 84(%esp)
	je	L59
L33:
	movl	$LC10, (%esp)
	call	_Log
L31:
	addl	$108, %esp
	popl	%ebx
	popl	%esi
	popl	%edi
	popl	%ebp
	ret
	.p2align 4,,10
	.p2align 3
L59:
	testb	$-16, 88(%esp)
	je	L33
	movl	$28, 8(%esp)
	movl	%edi, 4(%esp)
	movl	$8773456, (%esp)
	call	*%esi
	subl	$12, %esp
	testl	%eax, %eax
	je	L33
	cmpl	$4096, 84(%esp)
	jne	L33
	testb	$-16, 88(%esp)
	je	L33
	movl	$8773456, 8(%esp)
	movl	$8782400, 4(%esp)
	movl	$LC5, (%esp)
	call	_Log
	movl	$_InjectionCrashGuard@4, 4(%esp)
	movl	$1, (%esp)
	call	*__imp__AddVectoredExceptionHandler@8
	subl	$8, %esp
	movl	%eax, %ebp
	movl	$1, _g_inInjection
	movl	$LC6, 20(%esp)
	movl	$614, 16(%esp)
	movl	$LC7, 12(%esp)
	movl	%ebx, 8(%esp)
	movl	$8782400, 4(%esp)
	movl	$LC8, (%esp)
	call	_Log
	movl	%ebx, 52(%esp)
	movl	$LC7, 56(%esp)
	movl	$614, 60(%esp)
	movl	$LC6, 64(%esp)
	movl	$8782400, 68(%esp)
/APP
 # 302 "dlc_enable.c" 1
	movl 64(%esp), %eax
	movl 52(%esp), %edx
	movl 60(%esp), %ecx
	movl 56(%esp), %esi
	pushl %ecx
	pushl %esi
	call *68(%esp)
	addl $8, %esp
	
 # 0 "" 2
/NO_APP
	movl	%eax, 4(%esp)
	movl	%eax, %edi
	movl	$LC9, (%esp)
	call	_Log
	testl	%edi, %edi
	je	L60
	movl	$0, _g_inInjection
	testl	%ebp, %ebp
	je	L39
	movl	%ebp, (%esp)
	call	*__imp__RemoveVectoredExceptionHandler@4
	subl	$4, %esp
L39:
	movl	%edi, 4(%esp)
	movl	$LC11, (%esp)
	call	_Log
	addl	$108, %esp
	popl	%ebx
	popl	%esi
	popl	%edi
	popl	%ebp
	ret
	.p2align 4,,10
	.p2align 3
L60:
	movl	$LC12, (%esp)
	call	_Log
	movl	$8773456, 44(%esp)
	movl	%ebx, 48(%esp)
/APP
 # 338 "dlc_enable.c" 1
	movl 48(%esp), %eax
	pushl $0
	xorl %ecx, %ecx
	xorl %edi, %edi
	call *44(%esp)
	addl $4, %esp
	
 # 0 "" 2
/NO_APP
	movl	%eax, 4(%esp)
	movl	%eax, %ebx
	movl	$LC13, (%esp)
	call	_Log
	movl	$0, _g_inInjection
	testl	%ebp, %ebp
	je	L40
	movl	%ebp, (%esp)
	call	*__imp__RemoveVectoredExceptionHandler@4
	subl	$4, %esp
L40:
	testl	%ebx, %ebx
	jne	L61
	movl	$LC15, (%esp)
	call	_Log
	addl	$108, %esp
	popl	%ebx
	popl	%esi
	popl	%edi
	popl	%ebp
	ret
	.p2align 4,,10
	.p2align 3
L61:
	movl	%ebx, 4(%esp)
	movl	$LC14, (%esp)
	call	_Log
	jmp	L31
	.section .rdata,"dr"
LC16:
	.ascii "Captured lua_State*: 0x%08X\0"
	.align 4
LC17:
	.ascii "DLC bootstrap: skipped (EXE mismatch)\0"
	.text
	.p2align 4
	.def	_Hook_IsOnlineConnected;	.scl	3;	.type	32;	.endef
_Hook_IsOnlineConnected:
	subl	$28, %esp
	movl	_g_capturedState, %ecx
	movl	32(%esp), %edx
	testl	%ecx, %ecx
	je	L69
L64:
	movl	8(%edx), %eax
	movl	$1, (%eax)
	addl	$8, %eax
	movl	$1, -4(%eax)
	movl	%eax, 8(%edx)
	movl	$1, %eax
	addl	$28, %esp
	ret
	.p2align 4,,10
	.p2align 3
L69:
	xorl	%eax, %eax
	lock cmpxchgl	%edx, _g_capturedState
	cmpl	%edx, _g_capturedState
	jne	L64
	movl	%edx, 4(%esp)
	movl	$LC16, (%esp)
	movl	%edx, 32(%esp)
	call	_Log
	xorl	%eax, %eax
	movl	$1, %ecx
	lock cmpxchgl	%ecx, _g_dlcBootstrapDone
	movl	32(%esp), %edx
	testl	%eax, %eax
	jne	L64
	testl	%edx, %edx
	je	L70
	movl	_g_exeVerified, %eax
	testl	%eax, %eax
	je	L71
	movl	%edx, %eax
	movl	%edx, 32(%esp)
	call	_TryDLCBootstrap.part.0
	movl	32(%esp), %edx
	jmp	L64
L71:
	movl	$LC17, (%esp)
	movl	%edx, 32(%esp)
	call	_Log
	movl	32(%esp), %edx
	jmp	L64
L70:
	movl	%edx, %eax
	xchgl	_g_dlcBootstrapDone, %eax
	jmp	L64
	.section .rdata,"dr"
	.align 4
LC18:
	.ascii "lua_State not captured after 120s; bootstrap skipped\0"
	.text
	.p2align 4
	.def	_InitThread@4;	.scl	3;	.type	32;	.endef
_InitThread@4:
	pushl	%ebx
	movl	$240, %ebx
	subl	$24, %esp
	jmp	L73
	.p2align 4,,10
	.p2align 3
L76:
	movl	$500, (%esp)
	call	*__imp__Sleep@4
	subl	$4, %esp
	subl	$1, %ebx
	je	L92
L73:
	movl	_g_capturedState, %edx
	testl	%edx, %edx
	je	L76
L74:
	movl	_g_dlcBootstrapDone, %eax
	testl	%eax, %eax
	je	L93
L78:
	movl	_g_fallbackLog, %eax
	cmpl	$-1, %eax
	je	L81
	movl	%eax, (%esp)
	call	*__imp__CloseHandle@4
	subl	$4, %esp
	movl	$-1, _g_fallbackLog
L81:
	movl	_g_crashLog, %eax
	cmpl	$-1, %eax
	je	L82
	movl	%eax, (%esp)
	call	*__imp__CloseHandle@4
	subl	$4, %esp
	movl	$-1, _g_crashLog
L82:
	addl	$24, %esp
	xorl	%eax, %eax
	popl	%ebx
	ret	$4
	.p2align 4,,10
	.p2align 3
L93:
	movl	$1, %ecx
	lock cmpxchgl	%ecx, _g_dlcBootstrapDone
	testl	%eax, %eax
	jne	L78
	movl	_g_exeVerified, %eax
	testl	%eax, %eax
	je	L94
	movl	%edx, %eax
	call	_TryDLCBootstrap.part.0
	jmp	L78
	.p2align 4,,10
	.p2align 3
L92:
	movl	_g_capturedState, %edx
	testl	%edx, %edx
	jne	L74
	movl	$LC18, (%esp)
	call	_Log
	jmp	L78
L94:
	movl	$LC17, (%esp)
	call	_Log
	jmp	L78
	.section .rdata,"dr"
LC19:
	.ascii "OK\0"
LC20:
	.ascii "FAIL\0"
LC21:
	.ascii "pmc_bb.dll\0"
LC22:
	.ascii "pmc_log\0"
	.align 4
LC23:
	.ascii "dlc_enable.asi loaded (PID %d)\0"
	.align 4
LC24:
	.ascii "WARNING: EXE size mismatch \342\200\224 hardcoded VAs may be wrong, injection disabled\0"
LC25:
	.ascii "IsOnlineConnected\0"
LC26:
	.ascii "HasPlayerUnlockedCode\0"
LC27:
	.ascii "IsMatchmakingInternet\0"
	.align 4
LC28:
	.ascii "Hooks: Online=%s Unlock=%s Matchmaking=%s\0"
	.text
	.p2align 4
	.globl	_DllMain@12
	.def	_DllMain@12;	.scl	2;	.type	32;	.endef
_DllMain@12:
	pushl	%esi
	pushl	%ebx
	subl	$340, %esp
	cmpl	$1, 356(%esp)
	je	L138
	addl	$340, %esp
	movl	$1, %eax
	popl	%ebx
	popl	%esi
	ret	$12
	.p2align 4,,10
	.p2align 3
L138:
	movl	352(%esp), %eax
	movl	$0, 40(%esp)
	movl	$0, 44(%esp)
	movl	$0, 48(%esp)
	movl	$0, 52(%esp)
	movl	$0, 56(%esp)
	movl	$0, 60(%esp)
	movl	$0, 64(%esp)
	movl	$0, 68(%esp)
	movl	$0, 72(%esp)
	movl	%eax, _g_hModule
	movl	%eax, (%esp)
	call	*__imp__DisableThreadLibraryCalls@4
	subl	$4, %esp
	movl	$LC21, (%esp)
	call	*__imp__GetModuleHandleA@4
	subl	$4, %esp
	testl	%eax, %eax
	je	L139
	movl	$LC22, 4(%esp)
	movl	%eax, (%esp)
	call	*__imp__GetProcAddress@8
	subl	$8, %esp
	movl	%eax, _g_pmc_log
L98:
	movl	__imp__CreateFileA@28, %esi
	testl	%eax, %eax
	je	L140
L99:
	movl	_g_hModule, %eax
	leal	76(%esp), %ebx
	movl	$260, 8(%esp)
	movl	%ebx, 4(%esp)
	movl	%eax, (%esp)
	call	*__imp__GetModuleFileNameA@12
	subl	$12, %esp
	movl	$46, 4(%esp)
	movl	%ebx, (%esp)
	call	_strrchr
	testl	%eax, %eax
	je	L102
	movl	$1814980723, 4(%eax)
	movl	$1634886495, (%eax)
	movl	$6778732, 7(%eax)
L103:
	movl	%ebx, (%esp)
	movl	$0, 24(%esp)
	movl	$128, 20(%esp)
	movl	$2, 16(%esp)
	movl	$0, 12(%esp)
	movl	$1, 8(%esp)
	movl	$1073741824, 4(%esp)
	call	*%esi
	subl	$28, %esp
	movl	%eax, _g_crashLog
	call	*__imp__GetCurrentProcessId@0
	movl	$LC23, (%esp)
	movl	%eax, 4(%esp)
	call	_Log
	movl	%ebx, 4(%esp)
	movl	$260, 8(%esp)
	movl	$0, (%esp)
	call	*__imp__GetModuleFileNameA@12
	subl	$12, %esp
	movl	%ebx, (%esp)
	movl	$0, 24(%esp)
	movl	$0, 20(%esp)
	movl	$3, 16(%esp)
	movl	$0, 12(%esp)
	movl	$1, 8(%esp)
	movl	$-2147483648, 4(%esp)
	call	*%esi
	subl	$28, %esp
	movl	%eax, %ebx
	cmpl	$-1, %eax
	je	L141
	movl	$0, 4(%esp)
	movl	%eax, (%esp)
	call	*__imp__GetFileSize@8
	subl	$8, %esp
	movl	%eax, %esi
	movl	%ebx, (%esp)
	call	*__imp__CloseHandle@4
	xorl	%eax, %eax
	subl	$4, %esp
	cmpl	$53482288, %esi
	sete	%al
	movl	%eax, _g_exeVerified
	jne	L105
L106:
	xorl	%esi, %esi
	.p2align 4
	.p2align 3
L108:
	leal	11554816(%esi), %ebx
	movl	$18, 8(%esp)
	movl	$LC25, 4(%esp)
	movl	%ebx, (%esp)
	call	_memcmp
	testl	%eax, %eax
	je	L121
	addl	$1, %esi
	cmpl	$987119, %esi
	jne	L108
L109:
	xorl	%esi, %esi
	.p2align 4
	.p2align 3
L112:
	leal	11554816(%esi), %ebx
	movl	$22, 8(%esp)
	movl	$LC26, 4(%esp)
	movl	%ebx, (%esp)
	call	_memcmp
	testl	%eax, %eax
	je	L122
	addl	$1, %esi
	cmpl	$987115, %esi
	jne	L112
L113:
	xorl	%esi, %esi
	.p2align 4
	.p2align 3
L116:
	leal	11554816(%esi), %ebx
	movl	$22, 8(%esp)
	movl	$LC27, 4(%esp)
	movl	%ebx, (%esp)
	call	_memcmp
	testl	%eax, %eax
	je	L123
	addl	$1, %esi
	cmpl	$987115, %esi
	jne	L116
L137:
	movl	$LC20, %ecx
L117:
	movl	_g_origHasPlayerUnlockedCode, %edx
	movl	_g_origIsOnlineConnected, %ebx
	movl	$LC19, %eax
	movl	%ecx, 12(%esp)
	movl	$LC28, (%esp)
	testl	%edx, %edx
	movl	$LC20, %edx
	cmovne	%eax, %edx
	testl	%ebx, %ebx
	movl	$LC20, %ebx
	cmove	%ebx, %eax
	movl	%edx, 8(%esp)
	movl	%eax, 4(%esp)
	call	_Log
	movl	$0, 20(%esp)
	movl	$0, 16(%esp)
	movl	$0, 12(%esp)
	movl	$_InitThread@4, 8(%esp)
	movl	$0, 4(%esp)
	movl	$0, (%esp)
	call	*__imp__CreateThread@24
	movl	$1, %eax
	subl	$24, %esp
	addl	$340, %esp
	popl	%ebx
	popl	%esi
	ret	$12
	.p2align 4,,10
	.p2align 3
L139:
	movl	_g_pmc_log, %eax
	jmp	L98
	.p2align 4,,10
	.p2align 3
L141:
	movl	$0, _g_exeVerified
L105:
	movl	$LC24, (%esp)
	call	_Log
	jmp	L106
	.p2align 4,,10
	.p2align 3
L122:
	movl	$11554816, %eax
	jmp	L111
	.p2align 4
	.p2align 4,,10
	.p2align 3
L114:
	addl	$4, %eax
	cmpl	$12541944, %eax
	je	L113
L111:
	cmpl	%ebx, (%eax)
	jne	L114
	movl	4(%eax), %esi
	leal	-4198400(%esi), %edx
	cmpl	$7352319, %edx
	ja	L114
	leal	52(%esp), %ecx
	movl	$_Hook_HasPlayerUnlockedCode, %edx
	movl	%esi, %eax
	movl	%esi, _g_origHasPlayerUnlockedCode
	call	_InstallInlineHook.isra.0
	jmp	L113
	.p2align 4,,10
	.p2align 3
L121:
	movl	$11554816, %eax
	jmp	L107
	.p2align 4
	.p2align 4,,10
	.p2align 3
L110:
	addl	$4, %eax
	cmpl	$12541944, %eax
	je	L109
L107:
	cmpl	(%eax), %ebx
	jne	L110
	movl	4(%eax), %esi
	leal	-4198400(%esi), %edx
	cmpl	$7352319, %edx
	ja	L110
	leal	40(%esp), %ecx
	movl	$_Hook_IsOnlineConnected, %edx
	movl	%esi, %eax
	movl	%esi, _g_origIsOnlineConnected
	call	_InstallInlineHook.isra.0
	jmp	L109
	.p2align 4,,10
	.p2align 3
L123:
	movl	$11554816, %eax
	jmp	L115
	.p2align 4
	.p2align 4,,10
	.p2align 3
L118:
	addl	$4, %eax
	cmpl	$12541944, %eax
	je	L137
L115:
	cmpl	(%eax), %ebx
	jne	L118
	movl	4(%eax), %esi
	leal	-4198400(%esi), %edx
	cmpl	$7352319, %edx
	ja	L118
	leal	64(%esp), %ecx
	movl	$_Hook_IsMatchmakingInternet, %edx
	movl	%esi, %eax
	call	_InstallInlineHook.isra.0
	movl	$LC19, %ecx
	jmp	L117
	.p2align 4,,10
	.p2align 3
L102:
	movl	%ebx, (%esp)
	call	_strlen
	movl	$1814980723, 4(%ebx,%eax)
	movl	$1634886495, (%ebx,%eax)
	movl	$6778732, 7(%ebx,%eax)
	jmp	L103
L140:
	movl	_g_hModule, %eax
	movl	$260, 8(%esp)
	movl	$_g_fallbackPath, 4(%esp)
	movl	%eax, (%esp)
	call	*__imp__GetModuleFileNameA@12
	subl	$12, %esp
	movl	$46, 4(%esp)
	movl	$_g_fallbackPath, (%esp)
	call	_strrchr
	testl	%eax, %eax
	je	L100
	movl	$1735355438, (%eax)
	movb	$0, 4(%eax)
L101:
	movl	$0, 24(%esp)
	movl	__imp__CreateFileA@28, %esi
	movl	$128, 20(%esp)
	movl	$2, 16(%esp)
	movl	$0, 12(%esp)
	movl	$1, 8(%esp)
	movl	$1073741824, 4(%esp)
	movl	$_g_fallbackPath, (%esp)
	call	*%esi
	subl	$28, %esp
	movl	%eax, _g_fallbackLog
	jmp	L99
L100:
	movl	$_g_fallbackPath, (%esp)
	call	_strlen
	movl	$1735355438, _g_fallbackPath(%eax)
	movb	$0, _g_fallbackPath+4(%eax)
	jmp	L101
.lcomm _g_inInjection,4,4
	.data
	.align 4
_g_crashLog:
	.long	-1
.lcomm _g_fallbackPath,260,32
	.align 4
_g_fallbackLog:
	.long	-1
.lcomm _g_pmc_log,4,4
.lcomm _g_exeVerified,4,4
.lcomm _g_dlcBootstrapDone,4,4
.lcomm _g_capturedState,4,4
.lcomm _g_origHasPlayerUnlockedCode,4,4
.lcomm _g_origIsOnlineConnected,4,4
.lcomm _g_hModule,4,4
	.ident	"GCC: (GNU) 15.2.0"
	.def	_strrchr;	.scl	2;	.type	32;	.endef
	.def	_memcmp;	.scl	2;	.type	32;	.endef
	.def	_strlen;	.scl	2;	.type	32;	.endef
