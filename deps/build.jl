using BinDeps

basedir = @__DIR__

source = joinpath(homedir(), "coffee source")
if isdir(source)
    @warn "$source exists, not overwriting it"
else
    mkdir(source)
    cp(abspath(joinpath(basedir, "..", "src", "metadata.json")), joinpath(source, "metadata.json"), force = true)
end

program = "ffprobe"

if Sys.isunix()
    file = "ffprobe-4.0.1-linux-64"
    extension = ".zip"
    binary_name = target = program
end

filename = file*extension
url = "https://github.com/vot/ffbinaries-prebuilt/releases/download/v4.0/$filename"

if Sys.isunix()
    run(
        @build_steps begin
            FileDownloader(url, joinpath(basedir, "downloads", filename))
            CreateDirectory(joinpath(basedir, "src"))
            FileUnpacker(joinpath(basedir, "downloads", filename), joinpath(basedir, "src"), program)
        end
       )
end

