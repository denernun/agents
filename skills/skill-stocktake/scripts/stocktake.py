"""Read-only skill inventory; writes a snapshot only to an explicit output path."""
import argparse
import hashlib
import json
import os
from pathlib import Path
import re
import sys
from datetime import datetime, timezone


def source_files(root):
    """Follow support directories without following cycles or escaping the skill."""
    seen = set()
    for current, directories, files in os.walk(root, followlinks=True, onerror=lambda e: (_ for _ in ()).throw(e)):
        resolved = Path(current).resolve(strict=True)
        if not resolved.is_relative_to(root):
            raise ValueError(f'Support directory outside skill: {current}')
        if resolved in seen:
            directories[:] = []
            continue
        seen.add(resolved)
        directories[:] = sorted(d for d in directories if d not in {'.git', '__pycache__', 'node_modules'})
        for name in sorted(files):
            if name == '.agenthub-managed' or name.endswith('.pyc'):
                continue
            path = Path(current) / name
            if not path.resolve(strict=True).is_relative_to(root):
                raise ValueError(f'Support file outside skill: {path}')
            yield path


def inventory(roots):
    sources = {}
    errors = []
    for root in roots:
        try:
            root = Path(root).absolute()
            for directory in sorted(root.iterdir()):
                if not directory.is_dir():
                    if directory.is_symlink():
                        errors.append(f'Broken skill link: {directory}')
                    continue
                resolved = directory.resolve(strict=True)
                if not (resolved / 'SKILL.md').is_file():
                    errors.append(f'Missing SKILL.md: {directory}')
                    continue
                key = os.path.normcase(str(resolved))
                if key in sources:
                    sources[key]['aliases'].append(str(directory))
                    continue
                content = (resolved / 'SKILL.md').read_text(encoding='utf-8-sig')
                front = re.match(r'\A---\r?\n(.*?)\r?\n---(?:\r?\n|$)', content, re.S)
                if not front:
                    raise ValueError(f'Invalid frontmatter: {directory}')
                fields = {}
                for field in ('name', 'description'):
                    found = re.search(rf'^{field}:\s*(.+)$', front[1], re.M)
                    if not found:
                        raise ValueError(f'Missing {field}: {directory}')
                    fields[field] = found[1].strip().strip('\"\'')
                digest = hashlib.sha256()
                for path in source_files(resolved):
                    digest.update(path.relative_to(resolved).as_posix().encode())
                    digest.update(b'\0')
                    digest.update(hashlib.sha256(path.read_bytes()).digest())
                sources[key] = dict(fields, path=str(resolved), aliases=[str(directory)],
                                    sha256=digest.hexdigest(), use_7d=None, use_30d=None)
        except (OSError, ValueError) as error:
            errors.append(str(error))
    return {'schema_version': 1, 'evaluated_at': datetime.now(timezone.utc).isoformat(),
            'status': 'incomplete' if errors else 'inventoried', 'usage': 'unknown',
            'roots': [str(Path(r).absolute()) for r in roots],
            'skills': sorted(sources.values(), key=lambda s: (s['name'], s['path'])), 'errors': errors}


def changes(previous, current):
    old = {os.path.normcase(s['path']): s for s in previous['skills']}
    new = {os.path.normcase(s['path']): s for s in current['skills']}
    return {'added': [new[k]['path'] for k in sorted(new.keys() - old.keys())],
            'removed': [old[k]['path'] for k in sorted(old.keys() - new.keys())],
            'changed': [new[k]['path'] for k in sorted(new.keys() & old.keys())
                        if new[k]['sha256'] != old[k]['sha256']]}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--hub', type=Path, default=Path(__file__).resolve().parents[3])
    parser.add_argument('--root', type=Path, action='append', default=[])
    parser.add_argument('--previous', type=Path)
    parser.add_argument('--output', type=Path)
    args = parser.parse_args()
    result = inventory([args.hub.resolve() / 'skills', *args.root])
    if args.previous:
        if result['errors']:
            raise ValueError('Current inventory is incomplete; comparison refused: ' + '; '.join(result['errors']))
        previous = json.loads(args.previous.read_text(encoding='utf-8-sig'))
        if previous.get('status') != 'inventoried' or previous.get('roots') != result['roots']:
            raise ValueError('Previous inventory is incomplete or uses different roots')
        result['changes'] = changes(previous, result)
    text = json.dumps(result, indent=2, ensure_ascii=False) + '\n'
    if args.output:
        output = args.output.resolve()
        protected = [Path(s['path']) for s in result['skills']]
        protected += [Path(r).resolve() for r in result['roots']]
        protected.append(args.hub.resolve() / 'vendor')
        if any(output.is_relative_to(root) for root in protected):
            raise ValueError('Output must be outside skill and vendor directories')
        output.parent.mkdir(parents=True, exist_ok=True)
        output.write_text(text, encoding='utf-8')
    else:
        print(text, end='')
    return 1 if result['errors'] else 0


if __name__ == '__main__':
    try:
        sys.exit(main())
    except (OSError, ValueError, KeyError) as error:
        print(str(error), file=sys.stderr)
        sys.exit(1)
