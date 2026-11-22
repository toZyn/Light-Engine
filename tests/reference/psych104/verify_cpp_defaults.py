import argparse
import json
import os
from pathlib import Path
import re
import subprocess
import tempfile

parser = argparse.ArgumentParser()
parser.add_argument('--haxe', required=True)
parser.add_argument('--cxx', default='g++')
parser.add_argument('--check', action='store_true')
args = parser.parse_args()
root = Path(__file__).resolve().parent
fixture = root.parents[1] / 'fixtures/psych-1.0.4/initialization.json'
source = (root / 'ReferenceInitialization.hx').read_text()
fields = re.findall(r'public var (\w+):(Int|Float|Bool|String)(?:\s*=\s*([^;]+))?;', source)
assert len(fields) == 9
with tempfile.TemporaryDirectory(prefix='psych-cpp-defaults-') as directory:
    work = Path(directory)
    tools = work / 'tools'
    tools.mkdir()
    (work / 'hxcpp-metadata').mkdir()
    shim = tools / 'haxelib'
    shim.write_text('#!/bin/sh\n[ "$1" = "path" ] || exit 1\nprintf "%s\\n" "' + str(work / 'hxcpp-metadata') + '" "-D hxcpp=4.3.2"\n')
    shim.chmod(0o755)
    probe = 'class NativeDefaults {\n' + '\n'.join('public var ' + name + ':' + kind + (' = ' + value if value else '') + ';' for name, kind, value in fields) + '\npublic var boolProbe:Bool;\npublic function new() {}\nstatic function main() { var value = new NativeDefaults(); trace(value); }\n}'
    (work / 'NativeDefaults.hx').write_text(probe)
    env = dict(os.environ, PATH=str(tools) + os.pathsep + os.environ['PATH'])
    subprocess.run([args.haxe, '-cp', str(work), '--main', 'NativeDefaults', '--cpp', str(work / 'generated'), '-D', 'no-compilation'], env=env, check=True)
    header = (work / 'generated/include/NativeDefaults.h').read_text()
    cpp_types = {'Int': 'int', 'Float': 'Float', 'Bool': 'bool', 'String': '::String'}
    for name, kind, value in fields + [('boolProbe', 'Bool', '')]:
        assert re.search(re.escape(cpp_types[kind]) + r'\s+' + name + r'\s*;', header), (name, kind)
    declarations = []
    for name, kind, value in fields + [('boolProbe', 'Bool', '')]:
        native_type = {'Int': 'int', 'Float': 'double', 'Bool': 'bool', 'String': 'const char*'}[kind]
        initial = value.replace("'", '"') if value else ''
        declarations.append(native_type + ' ' + name + (' = ' + initial if initial else '') + ';')
    output = []
    for name, kind, value in fields:
        expression = '(p->' + name + ' ? std::string("\\\"") + p->' + name + ' + "\\\"" : "null")' if kind == 'String' else 'p->' + name
        output.append('std::cout << "\\\"' + name + '\\\":" << ' + expression + ' << "' + (',' if name != fields[-1][0] else '') + '";')
    cpp = '#include <cstdlib>\n#include <new>\n#include <iostream>\n#include <string>\n#include <cassert>\nstruct Probe {\n' + '\n'.join(declarations) + '\n};\nint main() {void* memory=std::calloc(1,sizeof(Probe)); assert(memory); Probe* p=new(memory) Probe; assert(p->boolProbe==false); std::cout << "{";\n' + '\n'.join(output) + '\nstd::cout << "}\\n"; p->~Probe();std::free(memory);}\n'
    (work / 'probe.cpp').write_text(cpp)
    subprocess.run([args.cxx, '-std=c++17', '-Wall', '-Wextra', '-Werror', str(work / 'probe.cpp'), '-o', str(work / 'probe')], check=True)
    result = json.loads(subprocess.check_output([str(work / 'probe')], text=True))
    rendered = json.dumps(result, separators=(',', ':')) + '\n'
    if args.check:
        assert json.loads(fixture.read_text()) == result, 'Native initialization fixture differs'
    else:
        fixture.write_text(rendered)
    print('C++ target types and zeroed-allocation probe: 9 fields and Bool passed')
    print('Code generation uses metadata-only haxelib shim; probe models hxcpp zeroed allocation, not the full hxcpp runtime or Psych executable.')
