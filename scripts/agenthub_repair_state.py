"""One-shot repair for state desynchronised by the CR CR LF writer bug.

Until the newline='' fix in agenthub_config.atomic(), every tracked text file
was written with each CRLF expanded to CR CR LF. Reading it back through
universal newlines produced '\\n\\n', which never matched the CRLF held in
.agenthub-state, so the installer classified all of them as manually edited and
silently stopped updating them.

Fixing the writer is not enough: the files already on disk carry the corruption,
so the mismatch persists. This script repairs only what is provably hub-written:

  * the file's bytes contain CR CR LF, and
  * normalising that corruption reproduces the text recorded in state.

When both hold, the content is the hub's own, only mis-encoded: the file is
rewritten with correct CRLF and the state is re-synchronised. Anything else (a
real manual edit, an untracked file, a file whose state was never written) is
left untouched and reported, so genuine edits are never overwritten.

Read-only by default; pass --apply to write.
"""
import argparse
import hashlib
import json
import os
from pathlib import Path
import sys
import uuid


def write_verbatim(path, text):
    path.parent.mkdir(parents=True, exist_ok=True)
    temporary = path.with_name(path.name + '.tmp-' + uuid.uuid4().hex)
    with open(temporary, 'w', encoding='utf-8', newline='') as stream:
        stream.write(text)
    os.replace(temporary, path)


def read_verbatim(path):
    with open(path, 'r', encoding='utf-8-sig', newline='') as stream:
        return stream.read()


def undo_cr_doubling(text):
    """Reverse the writer bug: CR CR LF -> CR LF, and a lone CR LF LF that the
    same translation produced from a bare '\\n' payload stays untouched."""
    while '\r\r\n' in text:
        text = text.replace('\r\r\n', '\r\n')
    return text


def classify(state_path, hub):
    """Return (verdict, detail) for one state file."""
    try:
        state = json.loads(state_path.read_text(encoding='utf-8'))
    except (ValueError, OSError) as error:
        return 'unreadable-state', str(error)
    if 'text' not in state or 'path' not in state:
        return 'not-text', ''
    target = Path(state['path'])
    if not target.exists():
        return 'missing-file', str(target)
    try:
        disk = read_verbatim(target)
    except OSError as error:
        return 'unreadable-file', str(error)
    expected = state['text']
    if disk == expected:
        # State agrees, but the bytes may still carry the CR doubling (state was
        # written from the same corrupted text). Clean both sides.
        if '\r\r\n' in disk:
            return 'resync-only', str(target)
        return 'already-in-sync', str(target)
    repaired = undo_cr_doubling(disk)
    if repaired == expected:
        return 'repairable', str(target)
    # Same content modulo any line-ending style: still hub content, just
    # normalised differently by an editor. Re-sync state instead of rewriting.
    if repaired.replace('\r\n', '\n') == expected.replace('\r\n', '\n'):
        return 'resync-only', str(target)
    return 'manual-edit', str(target)


def main():
    parser = argparse.ArgumentParser(description=__doc__,
                                     formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument('--hub', type=Path, default=Path(__file__).resolve().parents[1])
    parser.add_argument('--apply', action='store_true', help='write changes (default: report only)')
    args = parser.parse_args()
    root = args.hub.resolve() / '.agenthub-state'
    if not root.is_dir():
        print('No .agenthub-state directory at ' + str(root))
        return 0

    buckets = {}
    actions = []
    for state_path in sorted(root.glob('*.json')):
        verdict, detail = classify(state_path, args.hub)
        buckets.setdefault(verdict, []).append(detail)
        if verdict in ('repairable', 'resync-only'):
            actions.append((state_path, verdict, detail))

    for verdict in sorted(buckets):
        print('{:<18} {}'.format(verdict, len(buckets[verdict])))

    if not actions:
        print('\nNothing to repair.')
        return 0

    if not args.apply:
        print('\n{} file(s) would be repaired. Re-run with --apply.'.format(len(actions)))
        for _, verdict, detail in actions[:10]:
            print('  [{}] {}'.format(verdict, detail))
        if len(actions) > 10:
            print('  ... and {} more'.format(len(actions) - 10))
        return 0

    repaired = 0
    for state_path, verdict, detail in actions:
        state = json.loads(state_path.read_text(encoding='utf-8'))
        target = Path(state['path'])
        if verdict == 'repairable':
            # The hub's own text, only mis-encoded: rewrite the file correctly.
            write_verbatim(target, state['text'])
        else:
            # Same content, different line-ending style. Strip the CR doubling
            # first so the file stops carrying the corruption, then record
            # exactly what is on disk so the next install compares equal.
            cleaned = undo_cr_doubling(read_verbatim(target))
            write_verbatim(target, cleaned)
            state['text'] = cleaned
        write_verbatim(state_path, json.dumps(state, ensure_ascii=False, indent=2))
        repaired += 1
    print('\nRepaired {} file(s).'.format(repaired))
    return 0


if __name__ == '__main__':
    sys.exit(main())
