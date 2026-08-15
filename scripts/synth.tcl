set top    [lindex $argv 0]
set part   [lindex $argv 1]
set srcs   [lindex $argv 2]
set xdc    [lindex $argv 3]
set outdir [lindex $argv 4]

file mkdir $outdir

foreach f [split $srcs] {
    if {[string match "*.sv" $f]} { read_verilog -sv $f } else { read_verilog $f }
}
read_xdc $xdc

synth_design -top $top -part $part

write_checkpoint -force $outdir/post_synth.dcp
report_timing_summary -file $outdir/post_synth_timing_summary.rpt
report_utilization    -file $outdir/post_synth_utilization.rpt
