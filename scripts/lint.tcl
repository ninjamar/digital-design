set top  [lindex $argv 0]
set part [lindex $argv 1]
set srcs [lindex $argv 2]
set xdc  [lindex $argv 3]

foreach f [split $srcs] {
    if {[string match "*.sv" $f]} { read_verilog -sv $f } else { read_verilog $f }
}
read_xdc $xdc

check_syntax
synth_design -rtl -lint -top $top -part $part
