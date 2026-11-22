import argparse
from pathlib import Path
import shutil
import subprocess
import tempfile

ROOT = Path(__file__).resolve().parents[1]
IRIS_COMMIT = "8867c9a801a051e2bc5f9c03f06e8f88e6c574f9"


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("iris_checkout", type=Path)
    parser.add_argument("--haxe", default="haxe")
    args = parser.parse_args()
    revision = subprocess.check_output(
        ["git", "-C", str(args.iris_checkout), "rev-parse", "HEAD"], text=True
    ).strip()
    if revision != IRIS_COMMIT:
        parser.error(f"Expected hscript-iris 1.1.3 at commit {IRIS_COMMIT}")

    version = subprocess.check_output([args.haxe, "--version"], text=True).strip()
    if version != "4.3.7":
        parser.error("Expected Haxe 4.3.7")

    output = ROOT / "funkin/backend/scripts/psych"
    with tempfile.TemporaryDirectory() as directory:
        checkout = Path(directory)
        archive = subprocess.check_output(
            ["git", "-C", str(args.iris_checkout), "archive", IRIS_COMMIT, "crowplexus", "LICENSE"]
        )
        subprocess.run(["tar", "-x", "-C", directory], input=archive, check=True)
        iris = checkout / "crowplexus/iris/Iris.hx"
        source = iris.read_text()
        start = source.index('\n\t\tif (prefix != "" && prefix != null) {', source.index("var posPrefix"))
        end = source.index("\n\t}", start)
        iris.write_text(source[:start] + '\n\t\ttrace(posPrefix + ": " + out);' + source[end:])

        lexer = checkout / "crowplexus/hscript/Parser.hx"
        source = lexer.read_text()
        source = source.replace("StringTools.isEof(", "isEof(")
        source = source.replace("return StringTools.fastCodeAt(input, readPos++);",
                                "return readPos < input.length ? StringTools.fastCodeAt(input, readPos++) : -1;")
        source = source.replace("inline function readChar()",
                                "static inline function isEof(c:Int):Bool return c == -1;\n\n\tinline function readChar()")
        lexer.write_text(source)

        interpreter = checkout / "crowplexus/hscript/Interp.hx"
        source = interpreter.read_text()
        interpreter.write_text(source.replace("var cls = Tools.getClass(name);", "var cls = getOrImportClass(name);"))

        runtime = checkout / "runtime.lua"
        subprocess.run([
            args.haxe, "-cp", str(ROOT / "tools/psych-hscript"), "-cp", directory,
            "-D", "lua_vanilla", "-D", "lua-jit", "-D", "hscriptPos", "-dce", "full",
            "-main", "Main", "-lua", str(runtime),
        ], check=True)
        (output / "runtime.lua").write_text("\n".join(line.rstrip() for line in runtime.read_text().splitlines()) + "\n")
        shutil.copyfile(checkout / "LICENSE", output / "IRIS-LICENSE.txt")


if __name__ == "__main__":
    main()
