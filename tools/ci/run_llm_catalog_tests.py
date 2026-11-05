#!/usr/bin/env python3
"""Build and run the LLM catalog contract tests without API keys or network calls."""
from __future__ import annotations

import argparse
import json
import os
from pathlib import Path
import shutil
import subprocess


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--lazarus-dir', type=Path)
    parser.add_argument('--fpc', default=os.environ.get('FPC', 'fpc'))
    args = parser.parse_args()
    repo = Path(__file__).resolve().parents[2]
    output = repo / 'build' / 'llm-model-catalog'
    output.mkdir(parents=True, exist_ok=True)
    lazbuild = shutil.which('lazbuild')
    lazarus = args.lazarus_dir
    if lazarus is None and lazbuild:
        lazarus = Path(lazbuild).resolve().parent
    if lazarus is None:
        raise RuntimeError('Lazarus not found; supply --lazarus-dir')
    fpc = shutil.which(args.fpc)
    if not fpc and os.name == 'nt':
        candidates = list(lazarus.glob('fpc/*/bin/x86_64-win64/fpc.exe'))
        if candidates:
            fpc = str(candidates[0])
    if not fpc:
        raise RuntimeError('FPC not found; supply --fpc')
    os.environ['PATH'] = str(Path(fpc).parent) + os.pathsep + os.environ['PATH']

    def info(option: str) -> str:
        return subprocess.check_output([fpc, option], text=True).strip()

    target = info('-iTP') + '-' + info('-iTO')
    widgetset = 'win32' if os.name == 'nt' else 'nogui'
    paths = [repo / 'pacote' / 'AI']
    paths += [lazarus / suffix for suffix in (
        'lcl/units/' + target,
        'lcl/units/' + target + '/' + widgetset,
        'components/lazutils/lib/' + target,
        'packager/units/' + target,
    )]
    paths += list(lazarus.glob('fpc/*/source/packages/openssl/src'))
    paths += list(lazarus.glob('fpc/*/fpcsrc/packages/openssl/src'))
    paths = [path.resolve() for path in paths if path.is_dir()]
    command = [fpc, '-B', '-Mobjfpc', '-Sh', '-FU' + str(output), '-FE' + str(output)]
    command += ['-Fu' + str(path) for path in paths]
    command += [str(repo / 'pacote/tests/llm_model_catalog_test/llm_model_catalog_test.lpr')]
    result = {'target': target, 'fpc': info('-iV'), 'lazarus': str(lazarus),
              'command': command}
    process = subprocess.run(command, stdout=subprocess.PIPE, stderr=subprocess.STDOUT,
                             text=True, encoding='utf-8', errors='replace', timeout=180)
    (output / 'compile.log').write_text(process.stdout, encoding='utf-8')
    result['compile_exit'] = process.returncode
    print(process.stdout, end='')
    if process.returncode == 0:
        binary = output / ('llm_model_catalog_test.exe' if os.name == 'nt' else 'llm_model_catalog_test')
        process = subprocess.run([str(binary)], stdout=subprocess.PIPE, stderr=subprocess.STDOUT,
                                 text=True, encoding='utf-8', errors='replace', timeout=60)
        (output / 'tests.log').write_text(process.stdout, encoding='utf-8')
        result['test_exit'] = process.returncode
        result['test_output'] = process.stdout.strip()
        print(process.stdout, end='')
    (output / 'results.json').write_text(json.dumps(result, indent=2), encoding='utf-8')
    print(json.dumps(result, ensure_ascii=False))
    return process.returncode


if __name__ == '__main__':
    raise SystemExit(main())
