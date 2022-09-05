# Disentangle

Exclude overlapping spots from multi-crystal diffraction patterns 

## Usage

```
   USAGE:
      ./disentangle.pl
           [--bin-size=<int:10>] \
           [--bin-overlap=<int:2>] \
           [--bin-field=<int:12>] \
           [--distance=<int:10>] \
           <file:left.HKL>
           <file:right.HKL>
      ./disentangle.pl --help

   OUTPUT
      output is written to:
      - {left}.filtered.HKL
      - {right}.filtered.HKL

   OPTIONS:
      --bin-size    : The size of the bins. (current value = 10)
                      How many axis units should map into a singular bin.
                      _optional_
      --bin-overlap : The overlap of the bins (current value = 2)
                      How many axis units should bins overlap.
                      _optional_
      --bin-field   : The column in the HKL file to use as bin input. Aka. bin
                      on this field. (current value = 12)
                      _optional_
      --distance    : Consider all points duplicates when the euclidean
                      distance between two points is less than --distance.
                      (current value = 10)
                      _optional_
```

## Background

Recommended input files ("left.HKL" and "right.HKL") are produced by the
INTEGRATE step of XDS (INTEGRATE.HKL).  To integrate the secundary lattice
("right.HKL") it is recommended to follow the method described in the
[XDS wiki ](https://strucbio.biologie.uni-konstanz.de/xdswiki/index.php/Indexing#Indexing_images_from_non-merohedrally_twinned_crystals_.28i.e._several_lattices.29).
The resulting filtered.HKL files can be used as input for the CORRECT step of
XDS. Copy the output left/right.filtered.HKL as INTEGRATE.HKL to new folders
and run XDS with `JOB=CORRECT` in each folder.  The spots not assigned to the
lattice (with indices `0 0 0`) are purged to speed up calculations.

## Manuscript

> K. Składanowska, Y. Bloch et al. (2022) <https://doi.org/10.2139/ssrn.4120771>

## Dependencies

- `perl` (>= v5.10)
- perl module `Getopt::Long`
- perl module `POSIX`
