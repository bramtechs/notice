import std.stdio;
import std.string;
import std.getopt;
import std.file;

const string EXAMPLE_CMD = "Example: ./notice -i ~/dev/my-project -o ~/dev/my-project/TODO.md -v -e c,cpp";

static bool IsVerbose = false;

string getFileName(string entryName)
{
    long slashIndex = entryName.lastIndexOf("/");

    if (slashIndex == -1)
        slashIndex = entryName.lastIndexOf("\\");

    if (slashIndex == -1)
        throw new StringException("Invalid directory entry " ~ entryName ~ "!");

    return entryName[(slashIndex+1)..$];
}

unittest {
    assert(getFileName("test/hello/world.txt") == "world.txt");
}

bool shouldRead(DirEntry entry, string outputFile, string[] extensions=[])
{
    string fileName = getFileName(entry);

    // only include extensions
    if (extensions.length > 0)
    {
        bool matches = false;
        foreach (string ext; extensions)
        {
            string e = "." ~ ext.chompPrefix(".");
            if (fileName.indexOf(e) != -1)
            {
                matches = true;
                break;
            }
        }
        if (!matches)
            return false;
    }

    // don't include output file (if exists)
    if (fileName.indexOf(outputFile))
    {

    }

    // don't include hidden files
    if (fileName.indexOf(".") == 0)
        return false;

    // don't include empty or large files
    if (entry.size == 0 || entry.size > 1000000)
        return false;

    return true;
}

DirEntry[] crawlDir(DirEntry path, string outputFile, string[] extensions=[])
{
    DirEntry[] entries;
    foreach(DirEntry entry; dirEntries(path, SpanMode.shallow))
    {
        if (entry.isDir && entry.name.lastIndexOf("/.") == -1)
        {
            if (IsVerbose) writeln(">> ", entry.name);
            entries ~= crawlDir(entry, outputFile, extensions);
        }
        else if (shouldRead(entry, outputFile, extensions))
        {
            if (IsVerbose) writeln(entry.name, "\t", entry.size);
            entries ~= entry;
        }
    }
    return entries;
}

string[] collectNotes(DirEntry path, string outputFile, string[] extensions=[])
{
    DirEntry[] entries = crawlDir(path, outputFile, extensions);
    return [];
}

int main(string[] args)
{
    string sourceFolder = "";
    string outputFile = "";
    string extensions = "";
    bool showBanner = false;

    auto helpInfo = getopt(
        args,
        "src|i", &sourceFolder,
        "output|o", &outputFile,
        "banner|b", &showBanner,
        "verbose|v", &IsVerbose,
        "extensions|e", &extensions,
    );

    if (helpInfo.helpWanted)
    {
        defaultGetoptPrinter(EXAMPLE_CMD, helpInfo.options);
        return 0;
    }

    if (sourceFolder.empty)
    {
        writeln("No source folder provided!");
        return 1;
    }

    if (outputFile.empty)
    {
        writeln("No output file provided!");
        return 1;
    }

    // split extensions
    string[] extensionList = [];
    if (!extensions.empty)
        extensionList = extensions.split(",");

    try
    {
        DirEntry srcEntry = DirEntry(sourceFolder);
        collectNotes(srcEntry, outputFile, extensionList);
    }
    catch (FileException ex)
    {
        writeln("Source folder %s doesn't exist!", sourceFolder);
        return 1;
    }
    catch (StringException ex)
    {
        writeln("Error: ", ex.msg);
    }

    if (IsVerbose) writeln("Finished...");
    return 0;
}
