package;

import casl2macro.Casl2MacroExpand;
import casl2macro.StartEndChecker;
import dump.ObjectDump;
import haxe.io.Bytes;
import parser.Parser;
import sys.io.File;
import tokenizer.Tokenizer;

class Casl2 {
    static function main() {
        final options = {
            srcFile: null,
            outPath: null,
            dump: false,
        }
        var i = 0;
        while (i < Sys.args().length) {
            final arg = Sys.args()[i];
            switch (arg) {
                case "-s", "--src":
                    options.srcFile = Sys.args()[++i];
                case "-o", "--out":
                    options.outPath = Sys.args()[++i];
                case "-d", "--dump":
                    options.dump = true;
                    i++;
                case _:
                    i++;
            }
        }

        if (options.srcFile == null || options.outPath == null) {
            trace("usage: assembler -s [source file path] -o [output file] {-d}");
            return;
        }

        assemble(options.srcFile, options.outPath, options.dump);
    }

    static function assemble(src:String, out:String, dump:Bool) {
        final bytes = File.read(src).readAll();
        final src = bytes.getString(0, bytes.length, UTF8);

        final outFile = File.write(out);

        final tokens = Tokenizer.tokenize(src);
        final node = Parser.parse(tokens);

        final node = switch (node) {
            case Success(r, w):
                if (w.length != 0)
                    trace(w.join("\n"));
                r;
            case Failed(e, w):
                trace(e.join("\n"));
                trace(w.join("\n"));
                trace("コンパイル失敗");
                return;
        }

        final errors = StartEndChecker.check(node);
        switch (errors) {
            case []:
            case _:
                trace(errors.join("\n"));
                trace("コンパイル失敗");
                return;
        }

        final object = Casl2MacroExpand.macroExpand(node);

        final offset = 0;
        final assembly = casl2.Casl2.assembleAll(object.instructions, object.startLabel, offset);
        ObjectDump.dump(object);

        final bytes = Bytes.alloc(assembly.text.length * 2);
        for (i => w in assembly.text) {
            bytes.setUInt16(i * 2, w.toUnsigned());
        }

        outFile.writeFullBytes(bytes, 0, bytes.length);
    }
}
