# Disentangle

Exclude overlapping spots from multi-crystal diffraction patterns 

```
   USAGE:
      ./disentangle.pl 
         [--bin-size=<int:10>] \
         [--bin-overlap=<int:2>] \
         [--bin-field=<int:12>] \
         [--distance=<int:10>] \
         <file:left.HKL> 
         <file:right.HKL>

   OUTPUT
      output is written to:
      - {left}.filtered.HKL
      - {right}.filtered.HKL

   OPTIONS:
      --bin-size    : The size of the bins. (current value = 10)
                      How many units should map into a singular bin.
                      _optional_
      --bin-overlap : The overlap of the bins (current value = 2)
                      How many units should bins overlap.
                      _optional_
      --bin-field   : The column in the HKL file to use as bin input. Aka. bin
                      on this field. (current value = 12)
                      _optional_
      --distance    : Remove all consider all points duplicates when the
                      distance between two points is less than --distance.
                      (current value = 10)
                      _optional_
```
