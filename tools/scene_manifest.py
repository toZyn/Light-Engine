import argparse
import json
from pathlib import Path

KINDS = {'image', 'sound', 'audio', 'inst', 'voices', 'animate'}
SLOTS = {'bf', 'dad', 'gf', 'boyfriend', 'girlfriend', 'player', 'opponent', 'player1', 'player2', 'gfversion', '0', '1', '2'}

def validate(data, roots):
    errors = []
    if not isinstance(data, dict):
        return ['scene must be an object']
    def exists(relative):
        return any((root / relative).is_file() for root in roots)
    def image(name):
        return any(exists('images/' + name + ext) for ext in ('.png', '.dds', '.ktx', '.astc'))
    for key in ('assets', 'shaders', 'characters'):
        entries = data.get(key, [])
        if not isinstance(entries, list):
            errors.append(key + ' must be an array')
            continue
        for i, item in enumerate(entries):
            label = f'{key}[{i}]'
            if key == 'assets':
                if not isinstance(item, list) or len(item) < 2 or not isinstance(item[0], str) or item[0] not in KINDS or not isinstance(item[1], str) or not item[1]:
                    errors.append(label + ': expected [kind, path]')
                    continue
                kind, name = item[:2]
                if kind == 'image':
                    found = image(name)
                elif kind == 'animate':
                    found = exists('images/' + name + '/Animation.json')
                else:
                    suffix = '-' + str(item[2]) if len(item) > 2 and item[2] else ''
                    base = {'sound': 'sounds/', 'audio': '', 'inst': 'songs/', 'voices': 'songs/'}[kind] + name
                    if kind in ('inst', 'voices'):
                        base += '/' + kind.title() + suffix
                    found = any(exists(base + ext) for ext in ('.ogg', '.wav', '.mp3'))
                if not found:
                    errors.append(f'{label}: missing {kind} {name}')
            elif key == 'shaders':
                if not isinstance(item, str) or not item:
                    errors.append(label + ': expected a shader name')
                elif not any(exists('shaders/' + item + ext) for ext in ('.frag', '.vert')):
                    errors.append(label + ': missing shader ' + item)
            else:
                if not isinstance(item, dict) or not isinstance(item.get('character'), str) or not item['character'] or str(item.get('slot', 'dad')).lower() not in SLOTS:
                    errors.append(label + ': expected slot and character')
                elif not exists('data/characters/' + item['character'] + '.json'):
                    errors.append(label + ': missing character ' + item['character'])
    return errors

def main():
    parser = argparse.ArgumentParser(description='Validate a native scene manifest and its resources.')
    parser.add_argument('manifest', type=Path)
    parser.add_argument('--root', type=Path, action='append', default=[])
    args = parser.parse_args()
    try:
        data = json.loads(args.manifest.read_text(encoding='utf-8-sig'))
        errors = validate(data, args.root or [Path('assets')])
    except (OSError, ValueError) as error:
        errors = [str(error)]
    for error in errors:
        print(error)
    if not errors:
        print('Scene manifest valid; referenced files exist. Shader compilation is checked by LÖVE on the target device.')
    return bool(errors)

if __name__ == '__main__':
    raise SystemExit(main())
