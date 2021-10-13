# TrackSort Algorithm

This repository provides an implementation for multitarget tracking for optical belt sorters. It was used as the basis for a variety of papers on this topic.

## Requirements
Check out the git repository and the submodules for example via
```
git clone --recurse-submodules https://github.com/KIT-ISAS/TrackSortAlgorithm.git
```

For the evaluation, Matlab with multiple toolboxes is required. The code was tested on Matlab 2021b. The code requires [libDirectional](https://github.com/KIT-ISAS/libDirectional), which itself requires certain Matlab toolboxes. Both libDirectional is included as a submodule for your convenience. The code also requires a solver for the assignment problem and includes several. However, in recent Matlab versions, a reasonably fast implementation is available so they are no longer required.

## Getting started

By running

```
trackingDemo
```
in the root folder of the repository, you can launch the tracker on an example case and see a visualization of the tracking result. The demo script adds relevant folders to the Matlab path. You may want to permanently add the folders to your path if you use the framework more extensively.

## Data Sets

A variety of data sets are available online. You can find data and useful links our in [Zenodo entry](https://zenodo.org/record/5506551). 


## License

The code is under GPL 3.0. Two assignment problem solvers with different (but compatible) licenses are included in this repository. A third assignment problem solver with an incompatible license is only included as submodule and the code is not part of this repository.


## Contributing

Open an issue or write me an email to <pfaff@kit.edu> if you have suggestions or experience issues.

Lead author: Florian Pfaff

This repository contains contributions by Juan Hussain (GUI and some code for test cases) and Jakob Thumm (convertMatToCSV.m). The repository also includes a [Mex wrapper for the C implemention of LAPJV by Maxim Dolgov](https://github.com/Mxttak/lapjv_matlab) and some solvers for association problems by the respective authors.