package;

import assembler.Instruction;
import assembler.PInstOrDataTraceTools;
import assembler.Parser;
import assembler.Preprocessor;
import assembler.Tokenizer;
import assembler.Validator;
import haxe.io.Bytes;
import machine.Comet2;
import sys.io.File;

class Main {
    static function main() {
        final bytes = File.read("test.casl").readAll();
        final src = bytes.getString(0, bytes.length, UTF8);

        final tokens = Tokenizer.tokenize(src);
        final node = Parser.parse(tokens);
        final validated = Validator.validate(node);
        final instructions:Array<VInstruction> = validated.filter(v -> v.match(Success(_))).map(v -> v.getParameters()[0]);
        final instructions = Preprocessor.preprocess(instructions);

        File.write("dump.casl", false).write(Bytes.ofString(PInstOrDataTraceTools.toString(instructions.instructions, instructions.startLabel)));

        final assembly = assembler.Assembler.assembleAll(instructions.instructions);
        trace(assembly.map(a -> a.toString("")));

        final machine = new Comet2(assembly, 0);
        while (!machine.step()) {
        }

        trace(machine.state);
    }
}
