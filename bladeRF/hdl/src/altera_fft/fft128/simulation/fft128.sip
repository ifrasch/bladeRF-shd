set_global_assignment -entity "fft128" -library "lib_fft128" -name IP_TOOL_NAME "Qsys"
set_global_assignment -entity "fft128" -library "lib_fft128" -name IP_TOOL_VERSION "15.0"
set_global_assignment -entity "fft128" -library "lib_fft128" -name IP_TOOL_ENV "Qsys"
set_global_assignment -library "lib_fft128" -name SPD_FILE [file join $::quartus(sip_path) "../fft128.spd"]
set_global_assignment -library "lib_fft128" -name MISC_FILE [file join $::quartus(sip_path) "../../fft128.qsys"]

set_global_assignment -library "lib_fft128" -name MISC_FILE [file join $::quartus(sip_path) "fft128.vhd"]
set_global_assignment -library "lib_fft128" -name MISC_FILE [file join $::quartus(sip_path) "submodules/fft128_fft_ii_0_2n128cos.hex"]
set_global_assignment -library "lib_fft128" -name MISC_FILE [file join $::quartus(sip_path) "submodules/fft128_fft_ii_0_1n128sin.hex"]
set_global_assignment -library "lib_fft128" -name MISC_FILE [file join $::quartus(sip_path) "submodules/fft128_fft_ii_0_2n128sin.hex"]
set_global_assignment -library "lib_fft128" -name MISC_FILE [file join $::quartus(sip_path) "submodules/fft128_fft_ii_0_3n128cos.hex"]
set_global_assignment -library "lib_fft128" -name MISC_FILE [file join $::quartus(sip_path) "submodules/fft128_fft_ii_0_3n128sin.hex"]
set_global_assignment -library "lib_fft128" -name MISC_FILE [file join $::quartus(sip_path) "submodules/fft128_fft_ii_0_1n128cos.hex"]
set_global_assignment -library "lib_fft128" -name MISC_FILE [file join $::quartus(sip_path) "submodules/fft128_fft_ii_0.vho"]
