package parser;

import extype.Tuple.Tuple2;
import haxe.Exception;

class Tokenizer {
    final lines:Array<String>;
    var line:String;
    var lineIndex:Int = 0;
    var colIndex:Int = 0;

    final tokens:Array<Array<TokenInfo>>;

    function new(src:String) {
        lines = splitlines(src);
        tokens = [];
    }

    public static function tokenize(src:String) {
        final tokenizer = new Tokenizer(src);
        final tokens = tokenizer.tokenizeInner();
        return tokens;
    }

    function tokenizeInner() {
        for (linei in 0...lines.length) {
            lineIndex = linei;
            line = lines[lineIndex];
            colIndex = 0;
            tokens.push([]);

            tokenizeReg(~/^\s+/, LeadSpace);
            while (true) {
                if (line == "") {
                    break;
                } else if (tokenizeReg(~/^,/, Comma)) {
                } else if (tokenizeMnemonic()) {
                } else if (tokenizeReg(~/^GR[0-7]+/i, R)) {
                } else if (tokenizeReg(~/^[0-9]+/, Dec)) {
                } else if (tokenizeReg(~/^#[0-9a-f]+/i, Hex)) {
                } else if (tokenizeReg(~/^'.*'/, String)) { // TODO: "'"のエスケープ
                } else if (tokenizeReg(~/^=[0-9]+/, DecLiteral)) {
                } else if (tokenizeReg(~/^=#[0-9a-f]+/i, HexLiteral)) {
                } else if (tokenizeReg(~/^='.*'/, StringLiteral)) { // TODO: "'"のエスケープ
                } else if (tokenizeReg(~/^[a-z_][a-z0-9_]*/i, Label)) {
                } else if (tokenizeReg(~/^;.*$/i, Comment)) {
                } else if (consumeSpace()) {
                } else
                    throw new Exception('unknown token: at ${lineIndex + 1}:${colIndex + 1} (${line})');
            }
        }
        return tokens;
    }

    function tokenizeReg(reg:EReg, token:Token):Bool {
        if (reg.match(line)) {
            final len = reg.matchedPos().len;
            tokens[lineIndex].push({
                token: token,
                src: line.substr(0, len),
                line: lineIndex,
                col: colIndex
            });
            colIndex += len;
            line = line.substr(len);
            return true;
        }
        return false;
    }

    function tokenizeMnemonic():Bool {
        for (pair in regMnemonicTokenPair) {
            final reg = pair.value1;
            if (reg.match(line)) {
                final mnemonicStr = reg.matched(1);
                final len = mnemonicStr.length;
                tokens[lineIndex].push({
                    token: Mnemonic(pair.value2),
                    src: line.substr(0, len),
                    line: lineIndex,
                    col: colIndex
                });
                colIndex += len;
                line = line.substr(len);
                return true;
            }
        }
        return false;
    }

    function tokenizeRegGrouped1(reg:EReg, token:Token):Bool {
        if (reg.match(line)) {
            final len = reg.matchedPos().len;
            tokens[lineIndex].push({
                token: token,
                src: line.substr(0, len),
                line: lineIndex,
                col: colIndex
            });
            colIndex += len;
            line = line.substr(len);
            return true;
        }
        return false;
    }

    function consumeSpace():Bool {
        final reg = ~/^\s+/;
        if (reg.match(line)) {
            final len = reg.matchedPos().len;
            colIndex += len;
            line = line.substr(len);
            return true;
        }
        return false;
    }

    static function lstripSpace(s:String) {
        final reg = ~/^\s+/;
    }

    static function splitlines(s:String) {
        return ~/(\r\n)|\r|\n/g.split(s);
    }

    static final regMnemonicTokenPair = [
        new Tuple2(~/^(ld)(\s|$)/i, MnemonicToken.LD),
        new Tuple2(~/^(st)(\s|$)/i, MnemonicToken.ST),
        new Tuple2(~/^(lad)(\s|$)/i, MnemonicToken.LAD),
        new Tuple2(~/^(adda)(\s|$)/i, MnemonicToken.ADDA),
        new Tuple2(~/^(suba)(\s|$)/i, MnemonicToken.SUBA),
        new Tuple2(~/^(addl)(\s|$)/i, MnemonicToken.ADDL),
        new Tuple2(~/^(subl)(\s|$)/i, MnemonicToken.SUBL),
        new Tuple2(~/^(and)(\s|$)/i, MnemonicToken.AND),
        new Tuple2(~/^(or)(\s|$)/i, MnemonicToken.OR),
        new Tuple2(~/^(xor)(\s|$)/i, MnemonicToken.XOR),
        new Tuple2(~/^(cpa)(\s|$)/i, MnemonicToken.CPA),
        new Tuple2(~/^(cpl)(\s|$)/i, MnemonicToken.CPL),
        new Tuple2(~/^(sla)(\s|$)/i, MnemonicToken.SLA),
        new Tuple2(~/^(sra)(\s|$)/i, MnemonicToken.SRA),
        new Tuple2(~/^(sll)(\s|$)/i, MnemonicToken.SLL),
        new Tuple2(~/^(srl)(\s|$)/i, MnemonicToken.SRL),
        new Tuple2(~/^(jmi)(\s|$)/i, MnemonicToken.JMI),
        new Tuple2(~/^(jnz)(\s|$)/i, MnemonicToken.JNZ),
        new Tuple2(~/^(jze)(\s|$)/i, MnemonicToken.JZE),
        new Tuple2(~/^(jump)(\s|$)/i, MnemonicToken.JUMP),
        new Tuple2(~/^(jpl)(\s|$)/i, MnemonicToken.JPL),
        new Tuple2(~/^(jov)(\s|$)/i, MnemonicToken.JOV),
        new Tuple2(~/^(push)(\s|$)/i, MnemonicToken.PUSH),
        new Tuple2(~/^(pop)(\s|$)/i, MnemonicToken.POP),
        new Tuple2(~/^(call)(\s|$)/i, MnemonicToken.CALL),
        new Tuple2(~/^(ret)(\s|$)/i, MnemonicToken.RET),
        new Tuple2(~/^(svc)(\s|$)/i, MnemonicToken.SVC),
        new Tuple2(~/^(nop)(\s|$)/i, MnemonicToken.NOP),
        new Tuple2(~/^(start)(\s|$)/i, MnemonicToken.START),
        new Tuple2(~/^(end)(\s|$)/i, MnemonicToken.END),
        new Tuple2(~/^(ds)(\s|$)/i, MnemonicToken.DS),
        new Tuple2(~/^(dc)(\s|$)/i, MnemonicToken.DC),
        new Tuple2(~/^(in)(\s|$)/i, MnemonicToken.IN),
        new Tuple2(~/^(out)(\s|$)/i, MnemonicToken.OUT),
        new Tuple2(~/^(rpush)(\s|$)/i, MnemonicToken.RPUSH),
        new Tuple2(~/^(rpop)(\s|$)/i, MnemonicToken.RPOP),
    ];
}

typedef TokenInfo = {
    final token:Token;
    final src:String;
    final line:Int;
    final col:Int;
}

enum Token {
    // NewLine;
    LeadSpace;
    Comma;
    Mnemonic(mnemonic:MnemonicToken);
    R;
    Label;
    Dec;
    Hex;
    String;
    DecLiteral;
    HexLiteral;
    StringLiteral;
    Comment;
}

enum MnemonicToken {
    LD;
    ST;
    LAD;
    ADDA;
    SUBA;
    ADDL;
    SUBL;
    AND;
    OR;
    XOR;
    CPA;
    CPL;
    SLA;
    SRA;
    SLL;
    SRL;
    JMI;
    JNZ;
    JZE;
    JUMP;
    JPL;
    JOV;
    PUSH;
    POP;
    CALL;
    RET;
    SVC;
    NOP;
    START;
    END;
    DS;
    DC;
    IN;
    OUT;
    RPUSH;
    RPOP;
}
