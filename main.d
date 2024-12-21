import std.ascii;
import std.json;
import std.array;
import std.stdio;
import std.algorithm;
import std.conv;
import std.file;
import std.range;
import std.string;
import core.thread.osthread;
import core.time;
import std.typecons;

struct GameData {
    string[] date;
    string name;
    int time;

    static fromJson(JSONValue json) {
        string[] _date = json["date"].str().split("-");
        string _name = json["name"].str();
        int _time = json["time"].str().split(".").to!(int[]).convert();
        return GameData(_date, _name, _time);
    }
    
    string dateToISO8601() {
        return date.join("-");
    }
    void print() {
        writeln(
            dateToISO8601(),
            ": ", name,
            ": ", time,
        );
    }
}

void main() {
    string text = readText("comp.json");
    JSONValue jsonData = parseJSON(text);
    GameData[] gameData = jsonData.array().map!(GameData.fromJson).array();

    while (true) {
        write(">> ");
        string str = readln().chomp();
        string[] tokens = str.split();

        if (tokens.length == 0 || str == "exit") break;
        switch (tokens[0]) {
        case "add":
            addCommand(gameData, str);
            break;
        case "sort":
            sortData(gameData, tokens);
            break;
        case "table":
            printTable(gameData);
            break;
        default:
            writeln("idk");
        }
    }
}

string[] parseAddCommand(string str) {
    string[] tokens = [];
    int i = 0, j = 0;

    foreach (_; iota(2)) {
        i = advanceWhile(str, j, x => isWhite(x));
        j = advanceWhile(str, i, x => !isWhite(x));
        tokens ~= str[i .. j];
    }
    
    i = advanceWhile(str, j, x => isWhite(x));
    tokens ~= str[i .. $];
    return tokens;
}

int advanceWhile(string str, int i, bool function(dchar) fn) {
    while (i < str.length && fn(str[i])) i += 1;
    return i;
}

void addCommand(ref GameData[] gameDate, string command) {
    string[] addTokens = parseAddCommand(command);
    writeln("calling add");
    if (addTokens[1] == "" || addTokens[2] == "") {
        writeln("not enough args");
    }
    writeln(addTokens);
}

void sortData(ref GameData[] gameData, string[] tokens) {
    string[] validSortKeys = ["time", "name", "date"];

    if (tokens.length < 2) {
        writeln("sort was not provided any keys");
        return;
    }
    if (tokens[1] == "time") {
        gameData.sort!((a, b) => a.time < b.time);
    } else if (tokens[1] == "name") {
        gameData.sort!((a, b) => a.name < b.name);
    } else if (tokens[1] == "date") {
        gameData.sort!((a, b) => a.date < b.date);
    } else {
        writeln(tokens[1], " is not a valid key");
        writeln("valid keys are ", validSortKeys.join(", "));
        return;
    }
    if (tokens.length >= 3 && tokens[2] == "-r") {
        reverse(gameData);
    }
}

void printTable(GameData[] data, int spacing = 2)
in (spacing >= 0) {
    const int ISO8601Length = 16; // length of ISO 8601 time format down to a minute
    int[string] maxLength = [
        "time": data.map!(x => digits(x.time)).maxElement() + 2 * spacing,
        "name": data.map!(x => x.name.length.to!int).maxElement() + 2 * spacing,
        "date": ISO8601Length + 2 * spacing,
    ];
    string[] keys = ["date", "name", "time"];
    char[] lSpace = repeat(' ', spacing).array();
    char[] delegate(string, ulong) rSpace = (string key, ulong maxL) {
        return repeat(' ', maxLength[key] - maxL - spacing).array();
    };
    char[] separator = '+' ~ keys.map!(x => repeat('-', maxLength[x])).join('+') ~ '+';
    char[] delegate(string, string, ulong) createLine = (string s, string s2, ulong l) => lSpace ~ s ~ rSpace(s2, l);
    writeln(typeid(createLine));
    char[] header = '|' ~ keys.map!(x => createLine(x, x, x.length)).array().join('|') ~ '|';
    
    void printLine(GameData d) {
        string date = d.dateToISO8601();
        Tuple!(string, string, ulong)[] a = [
            tuple(date, "date", date.length),
            tuple(d.name, "name", d.name.length),
            tuple(d.time.to!string, "time", digits(d.time).to!ulong),
        ];
        char[] str = a.map!(x => createLine(x[0], x[1], x[2])).join('|');
        writeln('|' ~ str ~ '|');
    }

    writeln(separator);
    writeln(header);
    writeln(separator);
    data.each!(printLine);
    writeln(separator);
}

int digits(int num) => num.to!string().length.to!int;

int convert(int[] t) => t[0] * 60 + t[1] * 6;