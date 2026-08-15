set outdir [lindex $argv 0]
set top    [lindex $argv 1]

open_checkpoint $outdir/post_route.dcp
write_bitstream -force $outdir/$top.bit
