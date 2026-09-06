# Compiles the HSQ program down to a $readmemh-able hex image.
#   prog.hsq --(hsq -q)--> prog.sq --(sq2hex.py)--> prog.hex
# Invoked as a PREBUILD hook from the root Makefile (see config.mk), or
# directly with `make -C subleq`.

HSQ := toolchain/hsq/hsq

.DEFAULT_GOAL := prog/prog.hex

prog/prog.hex: prog/prog.hsq $(HSQ)
	$(HSQ) -q -o -n $< > prog/prog.sq
	python3 toolchain/sq2hex.py prog/prog.sq > $@

# Build the HSQ compiler from the vendored submodule if it isn't present.
# -std=c++14 -w: the 2009 source uses `register` and other pre-C++17 forms.
$(HSQ): $(HSQ).cpp
	c++ -O2 -std=c++14 -w -o $@ $<

.PHONY: clean
clean:
	rm -f prog/prog.sq prog/prog.hex

.PHONY: distclean
distclean: clean
	rm -f $(HSQ)
