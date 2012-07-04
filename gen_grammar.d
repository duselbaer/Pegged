const header = 
`
/**
 * This module was generated by gen_grammar.d
 * It is composed of a parser generated from pegged.examples.PEGGED and
 * the auxiliary functions from pegged.development.grammarfunctions
 */
module pegged.grammar;

public import pegged.peg;
public import std.traits:isSomeString;
`;

import pegged.examples.PEGGED;
import pegged.grammar;
import pegged.peg;
import std.file, std.conv, std.algorithm;

import std.array, std.typecons;
auto findSplitAmong(Range, Ranges...)(Range data, Ranges matches) {
    auto rest = data;
    for(; !rest.empty; rest.popFront()) {
        foreach(match; matches) {
            if(rest.startsWith(match)) {
                auto restStart = data.length-rest.length;
                auto pre = data[0..restStart];
                // we'll fetch it from the data instead of using the supplied
                // match to be consistent with findSplit
                auto dataMatch = data[restStart..restStart+match.length];
                auto post = rest[match.length..$];
                return tuple(pre, dataMatch, post);
            }
        }
    }
    return tuple(data, Range.init, Range.init);
}

unittest {
    auto text = "1\n2\r\n3\r4";

    auto res = text.findSplitAmong("\r\n", "\n", "\r");
    assert(res[0] == "1");
    assert(res[1] == "\n");
    assert(res[2] == "2\r\n3\r4");

    res = res[2].findSplitAmong("\r\n", "\n", "\r");
    assert(res[0] == "2");
    assert(res[1] == "\r\n");
    assert(res[2] == "3\r4");

    res = res[2].findSplitAmong("\r\n", "\n", "\r");
    assert(res[0] == "3");
    assert(res[1] == "\r");
    assert(res[2] == "4");

    res = res[2].findSplitAmong("\r\n", "\n", "\r");
    assert(res[0] == "4");
    assert(res[1] == "");
    assert(res[2] == "");
}

string removeFirstLine(string s)
{
    auto res = s.findSplitAmong("\r\n","\n","\r");
    return res[2];
}

string snip(string fileText)
{
    const snipStr = "// -- snip --";
    
    // Split fileText based on "// -- snip --"
    auto res = fileText.findSplit(snipStr);
    auto head = res[0];
    auto tail = res[2];
    if ( tail.length == 0 ) // Not found.
        return head;
    fileText = removeFirstLine(tail);
    
    return fileText;
}

unittest
{
    assert(
`foo
// -- snip --
bar`.snip() == "bar");

    assert(
`foo
bar`.snip() == 
`foo
bar`);

    assert(`foobar`.snip() == `foobar`);

    assert(
`foo
// -- snip -- blah blah
bar`.snip() == "bar");

}

void main()
{
    if ( !std.file.exists("pegged") )
        std.file.mkdir("pegged");
    if ( std.file.exists("pegged/grammar.d") )
        std.file.remove("pegged/grammar.d");
    string code = cast(string)std.file.read("pegged/development/grammarfunctions.d");
    std.file.write("pegged/grammar.d",//"Hello world!");
        to!string(
            header ~ 
            "/+\n"~
            PEGGEDgrammar~"\n"~
            "+/\n"~
            to!string(grammar(PEGGEDgrammar))~
            snip(code)
            ));
}