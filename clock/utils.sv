package utils;
    // non-synthesizable: outputs a constant so it gets inlined
    function automatic int cycles_half_period_conversion(int from_freq, int to_freq);
        // given a clock frequency, and an output frequency, calculate how many
        // cycles half a period (single edge) is
        real period = 1.0 / real'(to_freq); // in a function you can have variables
        return int'((period / 2.0) * real'(from_freq));
    endfunction
endpackage;