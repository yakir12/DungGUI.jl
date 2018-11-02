using BinDeps

basedir = @__DIR__

source = joinpath(homedir(), "coffee source")
if isfile(source)
    @warn "$source exists, not overwriting it"
else
    mkdir(source)
    cp(abspath(joinpath(basedir, "..", "src", "metadata.json")), joinpath(source, "metadata.json"), force = true)
end

program = "exiftool"

if Sys.isunix()
    file = "Image-ExifTool-11.16"
    extension = ".tar.gz"
    binary_name = target = program
end

if Sys.iswindows()
    file = "exiftool-10.49"
    extension = ".zip"
    binary_name = "$program.exe"
    target = "exiftool(-k).exe"
end

filename = file*extension
url = "http://www.sno.phy.queensu.ca/~phil/exiftool/$filename"

if Sys.isunix()
    run(
        @build_steps begin
        FileDownloader(url, joinpath(basedir, "downloads", filename))
        CreateDirectory(joinpath(basedir, "src"))
        FileUnpacker(joinpath(basedir, "downloads", filename), joinpath(basedir, "src"), "")
        end
       )
    mv(joinpath(basedir, "src", file), joinpath(basedir, "src", "exiftool"), force = true)
end

if Sys.iswindows()
    run(
        @build_steps begin
        FileDownloader(url, joinpath(basedir, "downloads", filename))
        CreateDirectory(joinpath(basedir, "src"))
        FileUnpacker(joinpath(basedir, "downloads", filename), joinpath(basedir, "src"), target)
        CreateDirectory(joinpath(basedir, "src", "exiftool"))
        end
       )
    mv(joinpath(basedir, "src", target), joinpath("src", "exiftool", binary_name), force = true)
end

