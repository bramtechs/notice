import std.stdio;
import std.string;
import std.getopt;
import std.conv;
import std.file;

// FIXME: Todos are still sometimes taken out of TODO.md

const string[] KEYWORDS = ["HACK", "TODO", "FIX", "FIXME", "BUG"];
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

bool containsKeyword(string line)
{
    foreach(string key; KEYWORDS)
    {
        if (line.indexOf(key) != -1)
            return true;
    }
    return false;
}

string[] parseFile(DirEntry entry)
{
    if (IsVerbose) writeln("Parsing file " ~ entry.name ~ " ...");

    string[] notes;
    string content;
    try
    {
        content = readText(entry);
    }
    catch (Exception ex)
    {
        if (IsVerbose) writeln("Couldn't read " ~ entry.name);
        return [];
    }

    foreach (string line; content.split("\n"))
    {
        if (line.indexOf("//") == -1)
            continue;

        if (!containsKeyword(line))
            continue;

        // remove comment markers
        string note = line.strip().chompPrefix("//").strip();
        notes ~= note;
    }
    return notes;
}

struct SearchQuery
{
    DirEntry source;
    string[] extFilters;
    string outputFile;

    this(DirEntry source, string outputFile, string[] extFilters)
    {
        this.source = source;
        this.outputFile = outputFile;
        this.extFilters = extFilters;
    }

    bool hasExtensions()
    {
        return extFilters.length > 0;
    }

    bool matchesAnyExtension(string path)
    {
        if (extFilters.length == 0)
            return true;

        foreach (string ext; extFilters)
        {
            string e = "." ~ ext.chompPrefix(".");
            if (path.indexOf(e) != -1)
                return true;
        }
        return false;
    }
};

bool shouldRead(DirEntry entry, SearchQuery query, string* rejectReason=null)
{
    string fileName = getFileName(entry);

    // only include extensions
    if (!query.matchesAnyExtension(fileName))
    {
        if (rejectReason) *rejectReason = "Unwanted filetype";
        return false;
    }

    // don't include output file (if exists)
    if (!query.outputFile.empty && fileName.indexOf(query.outputFile) != -1)
    {
        if (rejectReason) *rejectReason = "Is output file";
        return false;
    }

    // don't include hidden files
    if (fileName.indexOf(".") == 0)
    {
        if (rejectReason) *rejectReason = "Hidden file";
        return false;
    }

    // don't include empty or large files
    if (entry.size == 0 || entry.size > 1000000)
    {
        if (rejectReason) *rejectReason = "Too large";
        return false;
    }

    return true;
}

DirEntry[] crawlDir(DirEntry path, SearchQuery query)
{
    DirEntry[] entries;
    foreach(DirEntry entry; dirEntries(path, SpanMode.shallow))
    {
        string rejection;
        if (entry.isDir && entry.name.lastIndexOf("/.") == -1)
        {
            if (IsVerbose) writeln(">> Entering: ", entry.name);
            entries ~= crawlDir(entry, query);
        }
        else if (shouldRead(entry, query, &rejection))
        {
            if (IsVerbose) writeln("Found " ~ entry.name);
            entries ~= entry;
        }
        else if (IsVerbose)
        {
            writeln("Skipped " ~ entry.name ~ " (" ~ rejection ~ ")");
        }
    }
    return entries;
}

string collectNotes(DirEntry path, SearchQuery query, bool isDetailed)
{
    string result;
    if (isDetailed)
    {
        result ~= "# Things to do\n";
        result ~= "Automatically generated. Do not edit by hand!\n\n";
    }

    foreach(DirEntry entry; crawlDir(path, query))
    {
        string[] notes = parseFile(entry);
        if (notes.length == 0)
            continue;

        string relFilePath = entry.name.chompPrefix(path).chompPrefix("/");
        if (isDetailed) result ~= "## " ~ relFilePath ~ " (" ~ text(notes.length) ~ " items)\n";

        foreach (string note; notes)
        {
            result ~= (isDetailed ? "- [ ] ":"") ~ note ~ "\n";
        }

        if (isDetailed) result ~= "\n";
    }
    return result;
}

int main(string[] args)
{
    string sourceFolder = "";
    string outputFile = "";
    string extensions = "";
    bool isBare = false;

    auto helpInfo = getopt(
        args,
        "src|i", &sourceFolder,
        "output|o", &outputFile,
        "bare|b", &isBare,
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

    try
    {
        DirEntry srcEntry = DirEntry(sourceFolder);

        string[] exts;
        if (extensions.empty)
        {
            if (IsVerbose) writeln("No extensions given.");
            exts = [];
        }
        else
        {
            exts = extensions.split(",");
        }

        SearchQuery query = SearchQuery(srcEntry, outputFile, exts);

        string result = collectNotes(srcEntry, query, !isBare);
        if (outputFile.empty)
        {
            write(result);
        }
        else
        {
            std.file.write(outputFile, result);
            if (IsVerbose) writeln("Wrote to file " ~ outputFile);
        }
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
