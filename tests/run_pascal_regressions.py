"""Compile and run console regressions without hardware, credentials or remote APIs."""
from pathlib import Path
import argparse
import os
import shutil
import subprocess
import tempfile

ROOT = Path(__file__).resolve().parents[1]
TESTS = (
    'test_aibase',
    'test_aiagent_deterministicmemory',
    'test_aiagentsafety',
    'test_agentsafety_matrix',
    'test_chatgpt_config',
    'test_aitopiccontinuity',
)


def find_lazarus(explicit):
    if explicit:
        candidates = [Path(explicit)]
    else:
        candidates = [Path(os.environ['LAZARUS_ROOT'])] if os.environ.get('LAZARUS_ROOT') else []
        candidates += [Path('C:/lazarus'), Path('/usr/lib/lazarus'), Path('/usr/share/lazarus')]
        for parent in (Path('/usr/lib/lazarus'), Path('/usr/share/lazarus')):
            if parent.is_dir():
                candidates.extend(sorted(parent.iterdir(), reverse=True))
    for path in candidates:
        if (path / 'lcl').is_dir() and (path / 'components/lazutils').is_dir():
            return path.resolve()
    raise SystemExit('Lazarus not found. Pass --lazarus-root or set LAZARUS_ROOT.')


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--fpc')
    parser.add_argument('--lazarus-root')
    args = parser.parse_args()
    lazarus = find_lazarus(args.lazarus_root)
    fpc = args.fpc or shutil.which('fpc')
    if not fpc:
        candidates = sorted((lazarus / 'fpc').glob('*/bin/*/fpc.exe'))
        if candidates:
            fpc = str(candidates[-1])
    if not fpc:
        raise SystemExit('Free Pascal not found. Pass --fpc.')
    cpu = subprocess.check_output([fpc, '-iTP'], text=True).strip()
    system = subprocess.check_output([fpc, '-iTO'], text=True).strip()
    target = f'{cpu}-{system}'
    search_paths = [
        ROOT / 'pacote/AI', ROOT / 'pacote/AI Agent',
        lazarus / 'lcl/units' / target,
        lazarus / 'components/lazutils/lib' / target,
    ]
    env = dict(os.environ)
    # These tests must never pick up real credentials from the host.
    env.pop('CHATGPT_API_KEY', None)
    with tempfile.TemporaryDirectory(prefix='chatgpt-regressions-') as directory:
        build = Path(directory)
        for name in TESTS:
            command = [fpc, '-B', '-gl', '-Cr', '-Co', f'-FU{build}', f'-FE{build}']
            command += [f'-Fu{path}' for path in search_paths]
            command.append(str(ROOT / 'tests' / f'{name}.lpr'))
            compiled = subprocess.run(command, cwd=build, env=env, capture_output=True, text=True,
                                      errors='replace', timeout=180)
            if compiled.returncode:
                print(compiled.stdout, compiled.stderr)
                raise SystemExit(f'Compilation failed: {name}')
            executable = build / (name + ('.exe' if os.name == 'nt' else ''))
            result = subprocess.run([str(executable)], cwd=build, env=env,
                                    capture_output=True, text=True, errors='replace', timeout=30)
            print(f'{name}: {"PASS" if result.returncode == 0 else "FAIL"}', flush=True)
            if result.returncode:
                print(result.stdout, result.stderr)
                raise SystemExit(result.returncode)
    print(f'PASS: {len(TESTS)} Pascal regression programs ({target}, range/overflow checks enabled).')


if __name__ == '__main__':
    main()
