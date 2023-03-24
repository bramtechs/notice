import std.stdio;
import std.string;
import std.getopt;
import std.file;

const long MEGABYTE = 1024*1024*1024;
const string EXAMPLE_CMD = "Example: notice -i ./src/ -o todos.md";

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

bool shouldRead(DirEntry entry)
{
    // don't include hidden files
    string fileName = getFileName(entry);

    if (fileName.indexOf('.') == 0)
        return false;

    // don't include empty or large files
    if (entry.size == 0 || entry.size > MEGABYTE/2)
        return false;

    return true;
}

DirEntry[] crawlDir(DirEntry path)
{
    DirEntry[] entries;
    foreach(DirEntry entry; dirEntries(path, SpanMode.shallow))
    {
        if (shouldRead(entry))
        {
            if (entry.isDir)
            {
                if (IsVerbose) writeln(">> ", entry.name);
            }
            else
            {
                if (IsVerbose) writeln(entry.name, "\t", entry.size);
                entries ~= entry;
            }
        }
    }
    return entries;
}

string[] collectNotes(DirEntry path)
{
    DirEntry[] entries = crawlDir(path);
    return [];
}

int main(string[] args)
{
    string sourceFolder = "";
    string outputFile = "";
    bool showBanner = false;

    auto helpInfo = getopt(
        args,
        "src|i", &sourceFolder,
        "output|o", &outputFile,
        "banner|b", &showBanner,
        "verbose|v", &IsVerbose,
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

    try
    {
        DirEntry srcEntry = DirEntry(sourceFolder);
        collectNotes(srcEntry);
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

    return 0;
}
