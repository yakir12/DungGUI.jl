module DungGUI

using Dates, JSON, TimeZones, TerminalMenus, UUIDs

export main

const source = joinpath(homedir(), "coffee source")

@assert isdir(source)

const ffprobe = abspath(joinpath(pathof(DungGUI), "..", "..", "deps", "src", "ffprobe"))

badfile(x) = x[1] == '.' || last(splitext(x)) ∉ [".MTS", ".mp4", ".MP4", ".avi", ".AVI", ".mpg", ".MPG", ".mov", ".MOV"] || !isfile(joinpath(source, x))

function baddatetime(x)
    try
        DateTime(x)
        return false
    catch
        return true
    end
end

const df = DateFormat("YYYY:mm:dd HH:MM:SSzzzz")

function getalldatetimes(file)
    str = read(`$ffprobe -show_streams -of json -v quiet -i $file`, String)
    jsn = JSON.parse(str)
    stream = findfirst(x -> x["codec_type"] == "video", jsn["streams"])
    txt = jsn["streams"][stream]
    dts = [DateTime(ZonedDateTime(v, df)) for (k,v) in txt if occursin(r"date"i, k)]
    push!(dts, unix2datetime(ctime(file)))
    push!(dts, unix2datetime(mtime(file)))
end

function getdatetime(file)
    alldts = getalldatetimes(file)
    opts = string.(alldts)
    push!(opts, "Enter other")
    lastn = length(opts)
    menu = RadioMenu(opts)
    dti = request("Choose a creation date & time for \"$file\"?", menu)
    if dti == lastn
        l = strip(readline(stdin))
        while baddatetime(l)
            @warn "the format of the date or time is wrong, try something like `2018-11-01T12:47`"
            l = strip(readline(stdin))
        end
        DateTime(l)
    else
        alldts[dti]
    end
end

parse_floating_seconds(x) = Time(0) + Nanosecond(round(Int, x*10^9))

function parsetime(x)
    n = count(isequal(':'), x)
    t = if n == 0
        s = parse(Float64, x)
        parse_floating_seconds(s)
    elseif n == 1
        m, s = parse.(Float64, split(x, ':'))
        parse_floating_seconds(s) + Minute(m)
    elseif n == 2
        h, m, s = parse.(Float64, split(x, ':'))
        parse_floating_seconds(s) + Minute(m) + Hour(h)
    else
        error("""one too many colons in this "time": $x""")
    end
    t - Time(0)
end

function getduration(file)
    str = read(`$ffprobe -show_streams -of json -v quiet -i $file`, String)
    jsn = JSON.parse(str)
    stream = findfirst(x -> x["codec_type"] == "video", jsn["streams"])
    parsetime(jsn["streams"][stream]["duration"])
end

function registervideos(unregistered)
    videos = Vector{Dict{String, Any}}()
    fn = first(unregistered)
    dt = getdatetime(joinpath(source, fn))
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

function getstarttime(duration)
    while true
        println("When in that file did the calibration start?")
        l = strip(readline(stdin))
        starttime = parsetime(l)
        bad = starttime > duration
        bad ? println("time specified is longer than the duration of the video, $(nano2sec(duration)) sec. Try again") : return starttime
    end
end

function getstoptime(samefile, starttime, duration)
    while true
        println("When in that file did the calibration end?")
        l = strip(readline(stdin))
        stoptime = parsetime(l)
        bad = samefile ? !(starttime < stoptime ≤ duration) : stoptime > duration
        bad ? println("time specified is longer than the duration of the video, $(nano2sec(duration)) sec (or equal/shorter than the starting time if the start and end videos are the same). Try again") : return stoptime
    end
end

nano2sec(x) = x/Nanosecond(Second(1))

makeft(file, time) = Dict("file" => file, "nanosecond" => time)
makepoi(name; startfile = "", starttime = Nanosecond(0), stopfile = "", stoptime = Nanosecond(0)) = Dict{String, Any}("name" => name, "start" => makeft(startfile, starttime), "stop" => makeft(stopfile, stoptime))

const calibration_pois = ["Moving_checkerboard_calibration", "Stationary_checkerboard_calibration"]

function getpoi(videos)
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
        stoptime = getstoptime(startfile == stopfile, starttime, videos[stopfilei]["duration_ns"])
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

function format_run(x) 
    msg = ""
    for k in ["run_folder", "id", "date", "comment"]
        if haskey(x, k)
            msg *= string(uppercase.(k), ": ", x[k], "; ")
        end
    end
    msg
end

function getruns(db)
        remainingexps = filter(x -> any(notcalibrated(k, db) for k in keys(x["runs"])), db["experiments"])
        opts = get.(remainingexps, "name", nothing)
        menu = RadioMenu(opts)
        expi = request("Which experiment is this calibration in?", menu)

        runuuids = collect(filter(k -> notcalibrated(k, db), keys(remainingexps[expi]["runs"])))
        opts = [format_run(remainingexps[expi]["runs"][k]) for k in runuuids]
        menu = MultiSelectMenu(opts)
        runi = request("Select all the runs that are calibrated by this calibration", menu)
        runuuids[collect(runi)]
end

function addruns!(db, poiuuid)
    while true 
        runuuid = getruns(db)
        for uuid in runuuid
            push!(db["associations"][uuid], poiuuid)
        end
        println("Are there any more experiments/runs for this calibration? [y/[n]]")
        l = strip(readline(stdin))
        l ≠ "y" && return nothing
    end
end

function convert2ns!(db)
    for k in keys(db["pois"]), f in ["stop", "start"]
        db["pois"][k][f]["nanosecond"] = Nanosecond(db["pois"][k][f]["nanosecond"])
    end
    for vs in db["videos"], v in vs
        v["duration_ns"] = Nanosecond(v["duration_ns"])
        v["datetime"] = DateTime(v["datetime"])
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

function addpoiruns!(db, videos)
    while true
        poi = getpoi(videos)
        poiuuid = string(uuid1())
        db["pois"][poiuuid] = poi

        addruns!(db, poiuuid)

        println("Are there any more calibrations in these video file/s? [y/[n]]")
        l = strip(readline(stdin))
        l ≠ "y" && return nothing
    end
end


function main()

    db = open(joinpath(source, "metadata.json"), "r") do io
        JSON.parse(io)
    end
    convert2ns!(db)


    registered = [v["file"] for x in db["videos"] for v in x]
    both = filter(!badfile, readdir(source))
    unregistered = setdiff(both, registered)
    if isempty(unregistered)
        opts = String[string(get.(x, "file", nothing)) for x in db["videos"]]
        menu = RadioMenu(opts)
        vidi = request("No newly added videos were detected. Which of the already registered videos would you like to work with?", menu)
        videos = db["videos"][vidi]
    else
        videos = registervideos(unregistered)
        push!(db["videos"], videos)
    end

    addpoiruns!(db, videos)

    convert2int!(db)
    open(joinpath(source, "metadata.json"), "w") do io
        JSON.print(io, db, 3)
    end

end




end # module
