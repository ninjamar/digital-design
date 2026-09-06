import sys
words = open(sys.argv[1]).read().split()
for w in words:
    print(f"{int(w) & 0xFFFFFFFF:08x}")