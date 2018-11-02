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
   Pkg.add("https://github.com/yakir12/DungGUI.jl")
   ```
   and paste it in the newly opened Julia-terminal, press Enter -> this may take some time.

## How to run

1. Start Julia -> a Julia-terminal popped up.
2. Copy: 
   ```julia
   using DungGUI
   main()
   ```
   and paste it in the newly opened Julia-terminal, press Enter
3. Locate the original videos: Find all of the original .MTS video files.
4. Identify whole/fragmented files: Take one of the (earliest) .MTS files, check to see if there are any other .MTS files that subsequently follow it, for example:
    File "name.MTS" starts at 2018-01-01T12:00:00 and is 10 minutes long, and file "other name.MTS" starts at 2018-01-01T12:10:00. Additionally, you can tell that the video is obviously a continuation of the video in the previous file, "name.MTS", because the stuff that happens in the first file ends abruptly and continues in the next file.
5. Copy the found file (or fragmented files) to the source folder: A new folder was created for you in your home directory (type `homedir()` in the julia terminal if you're uncertain where it is), its name is `coffee source`. Copy the file/s you foundin step #4 into this folder. Always copy one file at a time. If you identified a few files all connected to each other (the where fragmented), then copy all of them together.
6. Creation date & time: Determine what the real creation date & time are for the video you found in step #1. If you identified multiple videos that "should" have been one video (there are no real gaps between the videos), you only need to find the real creation date & time for the first video. Discovering the creation date & time can be done by either looking at the notes, listening to what people say in the video, looking at the video file's meta-data, or a combination of all of these methods. The program will ask you to input the correct date and time, but will supply you with an initial guess (taken from the file).
7. Setting the correct start and end dates & times for the POIs: Each POI would have occurred in one or more of the videos. It has a video file name, start time (note: "start time" means the video starting time, e.g. 25 seconds or 00:00:25), and a name. If the POI stretched across time it will also have an end video file name and a end time (for example for a track POI). If it was instantaneous its end video file name and time will be equal to its starting video file name and time (for instance for a north POI). This point is especially important for the calibrations in the videos. Without the correct start and end times it will be impossible to auto-calibrate the videos. It is currently not crucial to find the correct start and end date & time for all the other POIs (nest, north, feeder, track, etc) but it would be very very very nice.

There are really two large efforts involved here: one is finding the `.MTS` files and discovering their true creation date & time. The other is identifying the video file, start, and end times for the calibrations and connecting those to the runs that relied on that calibration. 
