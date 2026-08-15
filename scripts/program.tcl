# args: bitfile mode cfgmem_part cfgmem_size
set bitfile     [lindex $argv 0]
set mode        [lindex $argv 1]
set cfgmem_part [lindex $argv 2]
set cfgmem_size [lindex $argv 3]

open_hw_manager
connect_hw_server -allow_non_jtag
open_hw_target

set dev [lindex [get_hw_devices] 0]
current_hw_device $dev
refresh_hw_device -update_hw_probes false $dev

if {$mode eq "flash"} {
    set mcsfile [file rootname $bitfile].mcs
    write_cfgmem -force -format mcs -size $cfgmem_size -interface spix4 \
        -loadbit "up 0x0 $bitfile" -file $mcsfile

    create_hw_cfgmem -hw_device $dev [lindex [get_cfgmem_parts $cfgmem_part] 0]
    set cfgmem [get_property PROGRAM.HW_CFGMEM $dev]
    set_property PROGRAM.FILES [list $mcsfile] $cfgmem
    set_property PROGRAM.ADDRESS_RANGE {use_file} $cfgmem
    set_property PROGRAM.BLANK_CHECK 0 $cfgmem
    set_property PROGRAM.ERASE 1 $cfgmem
    set_property PROGRAM.CFG_PROGRAM 1 $cfgmem
    set_property PROGRAM.VERIFY 1 $cfgmem

    program_hw_cfgmem -hw_cfgmem $cfgmem
} else {
    set_property PROGRAM.FILE $bitfile $dev
    program_hw_devices $dev
}

close_hw_target
