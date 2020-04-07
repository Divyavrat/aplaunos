
; Version numbers and names
%DEFINE OS_NAME_SHORT			'TachyonOS'
%DEFINE OS_NAME_LONG			'Tachyon Operating System'
%DEFINE OS_VERSION_NUMBER		11
%DEFINE OS_VERSION_STRING		'OS Build #11'

; Filenames to search for
%DEFINE OS_KERNEL_FILENAME		'KERNEL.BIN'
%DEFINE OS_KERNEL_EXT_FILENAME		'ZKERNEL.BIN'
%DEFINE OS_MENU_DATA_FILE		'MENU.TXT'
%DEFINE OS_BACKGROUND_FILE		'BACKGRND.AAP'
%DEFINE OS_AUTORUN_BIN_FILE		'AUTORUN.BIN'
%DEFINE OS_AUTORUN_BAS_FILE		'AUTORUN.BAS'
%DEFINE OS_MISSING_FILE_MSG		'An important operating system file is missing: '

%DEFINE OS_BOOT_MSG			OS_NAME_LONG, ' --- ', OS_VERSION_STRING
%DEFINE OS_TUI_TOP			'Welcome to the Tachyon Operating System'			
%DEFINE OS_TUI_BOTTOM			'Version ', OS_VERSION_STRING

; Time to wait, before entering the starting the shell (to view messages)
%define BOOT_DELAY 50
