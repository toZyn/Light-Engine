import argparse
import json
from pathlib import Path
import subprocess

parser = argparse.ArgumentParser()
parser.add_argument('--haxe', default='haxe')
parser.add_argument('--output', type=Path, default=Path(__file__).resolve().parents[2] / 'fixtures' / 'psych-1.0.4')
parser.add_argument('--check', action='store_true')
args = parser.parse_args()
args.output.mkdir(parents=True, exist_ok=True)
source = Path(__file__).resolve().parent
for main, name in [('Reference', 'utilities'), ('ReferenceInput', 'input'), ('ReferenceFiles', 'files'), ('ReferenceInitialization', 'initialization')]:
    result = subprocess.run([args.haxe, '-cp', str(source), '--main', main, '-D', 'MODS_ALLOWED', '--interp'], check=True, capture_output=True, text=True)
    records = json.loads(result.stdout)
    target = args.output / (name + '.json')
    rendered = json.dumps(records, ensure_ascii=False, separators=(',', ':')) + '\n'
    if args.check:
        if target.read_text() != rendered:
            raise SystemExit(name + ' fixture differs from Haxe execution')
    else:
        target.write_text(rendered)
    print(name, len(records), 'cases')
