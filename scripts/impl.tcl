set outdir [lindex $argv 0]

open_checkpoint $outdir/post_synth.dcp

opt_design
place_design
route_design

write_checkpoint -force $outdir/post_route.dcp
report_timing_summary -file $outdir/post_route_timing_summary.rpt
report_utilization    -file $outdir/post_route_utilization.rpt
