# DungGUI

![Lifecycle](https://img.shields.io/badge/lifecycle-experimental-orange.svg)<!--
![Lifecycle](https://img.shields.io/badge/lifecycle-maturing-blue.svg)
![Lifecycle](https://img.shields.io/badge/lifecycle-stable-green.svg)
![Lifecycle](https://img.shields.io/badge/lifecycle-retired-orange.svg)
![Lifecycle](https://img.shields.io/badge/lifecycle-archived-red.svg)
![Lifecycle](https://img.shields.io/badge/lifecycle-dormant-blue.svg) -->
[![Build Status](https://travis-ci.org/yakir12/DungGUI.jl.svg?branch=master)](https://travis-ci.org/yakir12/DungGUI.jl)
[![codecov.io](http://codecov.io/github/yakir12/DungGUI.jl/coverage.svg?branch=master)](http://codecov.io/github/yakir12/DungGUI.jl?branch=master)

# DungGUI
This is a `Julia` script for registering the raw data into a long lasting and coherent data base. 

## How to install
1. If you haven't already, install the current release of [Julia](https://julialang.org/downloads/) -> you should be able to launch it (some icon on the Desktop or some such).
2. Start Julia -> a Julia-terminal popped up.
3. Copy: 
   ```julia
   using Pkg
   Pkg.add(PackageSpec(url = "https://github.com/yakir12/DungGUI.jl"))
   ```
   and paste it in the newly opened Julia-terminal, press Enter -> this may take some time.

## How to run

1. Locate the original videos: Find all of the original .MTS video files.
2. Identify whole/fragmented files: Take one of the (earliest) .MTS files, check to see if there are any other .MTS files that subsequently follow it, for example:
    File "name.MTS" starts at 2018-01-01T12:00:00 and is 10 minutes long, and file "other name.MTS" starts at 2018-01-01T12:10:00. Additionally, you can tell that the video is obviously a continuation of the video in the previous file, "name.MTS", because the stuff that happens in the first file ends abruptly and continues in the next file.
    Compare that to an `.MTS` file that starts at 2018-01-01T12:00:00 and is 10 minutes long and another one that starts at 2018-01-01T12:50:00. Those two files couldn't possibly be connected.
3. Copy the found file or fragmented files to the source folder: A new folder was created for you in your home directory (type `homedir()` in the julia terminal if you're uncertain where your "home directory" is) when you installed this package. The name of this folder is `coffee source`. Copy the file/s you found in step #2 into this folder. **Always copy one file at a time. If you identified a few files all connected to each other (so called fragmented files), then copy all of them together**.
4. Start Julia -> a Julia-terminal popped up.
5. Copy: 
   ```julia
   using DungGUI
   main()
   ```
   and paste it in the newly opened Julia-terminal, press Enter
6. Creation date & time: The program will ask you for the original creation date & time of the video file (if you copied a few fragmented files, it will ask only about the first of them). Determine what the real creation date & time are for the video you copied over. If you identified multiple videos that "should" have been one video (there are no real gaps between the videos), you only need to find the real creation date & time for the first video. Discovering the creation date & time can be done by either looking at the notes, listening to what people say in the video, looking at the video file's meta-data, or a combination of all of these methods. The program will supply you with an initial guess taken from the file's metadata.
7. Setting the correct start and end times for the calibration POIs: Each calibration POI would have occurred in one or more of the videos. It has a calibration type (`Moving_checkerboard_calibration`: the classic moving checkerboard or `Stationary_checkerboard_calibration`: a large flat checkerboard on the ground), video file name, and start time (note: "start time" means the video starting time, e.g. 25 seconds, 0:25, 00:25, 0:0:25, or 00:00:25). If the POI is a `Moving_checkerboard_calibration` it stretched across time and it will also have an end video file name and a end time. If it was a `Stationary_checkerboard_calibration` its end video file name and time will be equal to its starting video file name and time (you won't need to input those). 
8. Associate the correct runs with this calibration: Next you'll be asked to select an experiment that included that specific calibration. Following that, you'll need to select all of the runs within that experiment that were calibrated by that calibration. 

That's basically it. You can rerun the `main()` command to:
- Either register some more `.MTS` files that you found.
- Or register more calibrations from files you already registered.

One thing you can't currently do is add more runs to a calibration you already registered. This means that when you are about to check-in the runs the currecnt calibration is for, make sure you check-in all the runs without missing a single one. 
