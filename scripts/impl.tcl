# args: outdir fast incremental threads
set outdir      [lindex $argv 0]
set fast        [lindex $argv 1]
set incremental [lindex $argv 2]
set threads     [lindex $argv 3]

if {$threads ne ""} { set_param general.maxThreads $threads }

open_checkpoint $outdir/post_synth.dcp

set ref $outdir/post_route.dcp
if {$incremental && [file exists $ref]} {
    read_checkpoint -incremental $ref
}

opt_design

if {$fast} {
    place_design -directive Quick
    route_design -directive Quick
} else {
    place_design
    route_design
}

write_checkpoint -force $outdir/post_route.dcp
report_timing_summary -file $outdir/post_route_timing_summary.rpt
report_utilization    -file $outdir/post_route_utilization.rpt
