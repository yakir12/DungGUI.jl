module DungGUI

using Dates, JSON, TimeZones, TerminalMenus, UUIDs

export main

const source = joinpath(homedir(), "coffee source")

@assert isdir(source)

exiftool_base = abspath(joinpath(pathof(DungGUI), "..", "..", "deps", "src", "exiftool", "exiftool"))
const exiftool = exiftool_base*(Sys.iswindows() ? ".exe" : "")

badfile(source, x) = x[1] == '.' || last(splitext(x)) ∉ [".MTS", ".mp4", ".avi"] || !isfile(joinpath(source, x))

function baddatetime(x)
    try
        DateTime(x)
        return false
    catch
        return true
    end
end

function getsomething(msg, wrn, fun; default = "")
    println(msg)
    println(default)
    l = strip(readline(stdin))
    if isempty(l)
        l = default
    end
    while fun(l)
        @warn wrn
        println(msg)
        l = strip(readline(stdin))
    end
    l
end

df = DateFormat("YYYY:mm:dd HH:MM:SSzzzz")

function getearliest(file)
    str = read(`$exiftool -j $file`, String)
    jsn = JSON.parse(str)
    earliest = ZonedDateTime(DateTime(9999,12,30), tz"UTC")
    for (k, v) in first(jsn)
        if occursin(r"date"i, k)
            d = ZonedDateTime(v, df)
            if d < earliest
                earliest = d
            end
        end
    end
    earliest
end

function getduration(file)
    str = read(`$exiftool -j $file`, String)
    jsn = JSON.parse(str)
    Time(first(jsn)["Duration"]) - Time(0)
end

function registervideos(source, unregistered)
    videos = Vector{Dict{String, Any}}()
    wrn = "the format of the date or time is wrong, try `2018-11-01T12:47:51.783`, try again"
    fn = first(unregistered)
    msg = "What is the creation date & time of \"$fn\"?"
    dt = getsomething(msg, wrn, baddatetime, default = getearliest(joinpath(source, fn)))
    duration = getduration(joinpath(source, fn))
    push!(videos, Dict("file" => fn, "datetime" => dt, "duration_ns" => duration))
    for i in 2:length(unregistered)
        fn = unregistered[i]
        dt = videos[i-1]["datetime"] + videos[i-1]["duration_ns"]
        duration = getduration(joinpath(source, fn))
        push!(videos, Dict("file" => fn, "datetime" => dt, "duration_ns" => duration))
    end
    videos
end

format_run(folder, id, date, comment) = "FOLDER: $folder, ID: $id, DATE: $date, COMMENT: $comment"

function parsetime(x)
    t = if !occursin(":", x)
        s = parse(Int, x)
        Time(0,0,s)
    else
        y = split(x, ':')
        hms = parse.(Int, y)
        if length(hms) == 2
            Time(0, hms...)
        else
            Time(hms...)
        end
    end
    t - Time(0)
end

function getstarttime(duration)
    while true
        println("When in that file did the calibration start?")
        l = strip(readline(stdin))
        starttime = parsetime(l)
        bad = starttime > duration
        bad ? println("time specified is longer than the duration of the video, $(nano2sec(duration)) sec. Try again") : return starttime
    end
end

function getstoptime(startfile, stopfile, starttime, duration)
    while true
        println("When in that file did the calibration end?")
        l = strip(readline(stdin))
        stoptime = parsetime(l)
        bad = startfile == stopfile ? !(starttime ≤ stoptime ≤ duration) : stoptime > duration
        bad ? println("time specified is longer than the duration of the video, $(nano2sec(duration)) sec (or shorter than the starting time if the start and end videos are the same). Try again") : return stoptime
    end
end

nano2sec(x) = x/Nanosecond(Second(1))

makeft(file, time) = Dict("file" => file, "nanosecond" => time)
makepoi(name; startfile = "", starttime = Nanosecond(0), stopfile = "", stoptime = Nanosecond(0)) = Dict{String, Any}("name" => name, "start" => makeft(startfile, starttime), "stop" => makeft(stopfile, stoptime))

function getpoi(videos)
    calibration_pois = ["Moving_checkerboard_calibration", "Stationary_checkerboard_calibration"]
    menu = RadioMenu(calibration_pois)
    cali = request("What kind of calibration is this?", menu)

    videosfiles = get.(videos, "file", nothing)

    menu = RadioMenu(videosfiles)
    startvideoi = request("Select the video file where the calibration starts:", menu)
    startfile = videosfiles[startvideoi]

    starttime = getstarttime(videos[startvideoi]["duration_ns"])
    if cali == 1
        stopfilei = request("Select the video file where the calibration ended:", menu)
        stopfile = videosfiles[stopfilei]
        stoptime = getstoptime(startfile, stopfile, starttime, videos[stopfilei]["duration_ns"])
    else
        stopfile = startfile
        stoptime = starttime
    end

    makepoi(calibration_pois[cali], startfile = startfile, starttime = starttime, stopfile = stopfile, stoptime = stoptime)
end

function notcalibrated(target, db)
    for poi in db["associations"][target]
        name = db["pois"][poi]["name"]
        occursin(r"calibration", name) && return false
    end
    return true
end

function getruns(db)
    opts = get.(db["experiments"], "name", nothing)
    menu = RadioMenu(opts)
    expi = request("Which experiment is this calibration in?", menu)

    runuuids = collect(filter(k -> notcalibrated(k, db), keys(db["experiments"][expi]["runs"])))
    opts = String[]
    for uuid in runuuids
        x = db["experiments"][expi]["runs"][uuid]
        push!(opts, format_run(x["run_folder"], x["id"], x["date"], x["comment"]))
    end
    menu = MultiSelectMenu(opts)
    runi = request("Select all the runs that are calibrated by this calibration", menu)
    runuuids[collect(runi)]
end

function convert2ns!(db)
    for k in keys(db["pois"]), f in ["stop", "start"]
        db["pois"][k][f]["nanosecond"] = Nanosecond(db["pois"][k][f]["nanosecond"])
    end
    for vs in db["videos"], v in vs
        v["duration_ns"] = Nanosecond(v["duration_ns"])
    end
end

function convert2int!(db)
    for k in keys(db["pois"]), f in ["stop", "start"]
        db["pois"][k][f]["nanosecond"] = Dates.value(db["pois"][k][f]["nanosecond"])
    end
    for vs in db["videos"], v in vs
        v["duration_ns"] = Dates.value(v["duration_ns"])
    end
end


function main()

    db = open(joinpath(source, "metadata.json"), "r") do io
        JSON.parse(io)
    end

    convert2ns!(db)

    registered = [v["file"] for x in db["videos"] for v in x]
    all = filter(x -> !badfile(source, x), readdir(source))
    unregistered = setdiff(all, registered)
    if isempty(unregistered)
        opts = [string(get.(x, "file", nothing)) for x in db["videos"]]
        menu = RadioMenu(opts)
        vidi = request("No newly added videos were detected. Which of the already registered videos would you like to work with?", menu)
        videos = db["videos"][vidi]
    else
        videos = registervideos(source, unregistered)
        push!(db["videos"], videos)
    end

    more = true
    while more
        poi = getpoi(videos)
        runuuid = getruns(db)

        poiuuid = string(uuid1())
        db["pois"][poiuuid] = poi
        for uuid in runuuid
            push!(db["associations"][uuid], poiuuid)
        end

        println("Are there any more calibrations in these video file/s? [y/[n]]")
        l = strip(readline(stdin))
        more = l == "y"
    end

    convert2int!(db)

    open(joinpath(source, "metadata.json"), "w") do io
        JSON.print(io, db, 3)
    end

end




end # module
