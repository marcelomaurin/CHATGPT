"""Build and run the nine restored/new examples without remote services or microphone."""
from pathlib import Path
import argparse
import csv
import json
import os
import shutil
import subprocess
import tempfile

from run_pascal_regressions import find_lazarus

ROOT = Path(__file__).resolve().parents[1]
SAMPLES = (
    ('AI Core', 'modelregistry_demo'),
    ('AI Core', 'promptbuilder_demo'),
    ('AI Graph', 'training_exporter_demo'),
    ('AI Graph', 'training_report_demo'),
    ('AI Agent', 'wizard_config_demo'),
    ('AI Voice', 'chrome_speech_demo'),
    ('AI Agent', 'topic_continuity_demo'),
    ('AI Agent', 'person_session_demo'),
    ('AI Agent', 'presentation_agent_demo'),
)
SOURCE_DIRS = (
    'AI', 'AI Agent', 'AI Graph', 'AI Output', 'AI Project', 'AI Math',
    'AI Input/AIInput', 'AI Industrial', 'AI Voice',
)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--fpc')
    parser.add_argument('--lazarus-root')
    parser.add_argument('--widgetset', default='win32' if os.name == 'nt' else 'gtk2', help='Widgetset used by the wizard smoke run.')
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
    paths = [ROOT / 'pacote' / directory for directory in SOURCE_DIRS]
    paths += [
        lazarus / 'lcl/units' / target,
        lazarus / 'lcl/units' / target / args.widgetset,
        lazarus / 'components/lazutils/lib' / target,
        lazarus / 'packager/units' / target,
    ]
    env = dict(os.environ)
    env.pop('CHATGPT_API_KEY', None)
    failures = []
    with tempfile.TemporaryDirectory(prefix='chatgpt-new-samples-') as directory:
        for category, name in SAMPLES:
            build = Path(directory) / name
            build.mkdir()
            source = ROOT / 'pacote/samples' / category / name / (name + '.lpr')
            command = [fpc, '-B', '-gl', f'-FU{build}', f'-FE{build}']
            command += [f'-Fu{path}' for path in paths]
            command += [str(source)]
            compiled = subprocess.run(command, cwd=build, env=env, capture_output=True,
                                      text=True, errors='replace', timeout=180)
            if compiled.returncode:
                print(f'{name}: BUILD FAIL\n{compiled.stdout}\n{compiled.stderr}', flush=True)
                failures.append(name)
                continue
            executable = build / (name + ('.exe' if os.name == 'nt' else ''))
            result = subprocess.run([str(executable)], cwd=build, env=env, capture_output=True,
                                    text=True, errors='replace', timeout=30)
            if result.returncode or 'PASS:' not in result.stdout:
                print(f'{name}: RUN FAIL\n{result.stdout}\n{result.stderr}', flush=True)
                failures.append(name)
                continue
            if name == 'training_exporter_demo':
                with (build / 'output/training.csv').open(encoding='utf-8-sig', newline='') as handle:
                    assert len(list(csv.reader(handle))) >= 3, 'CSV has no dataset rows.'
                records = [json.loads(line) for line in
                           (build / 'output/training.jsonl').read_text(encoding='utf-8-sig').splitlines()
                           if line.strip()]
                assert len(records) == 2, 'Expected two JSONL records.'
            if name == 'training_report_demo':
                assert (build / 'output/training_report.txt').stat().st_size > 0, 'Empty report.'
            print(f'{name}: BUILD + RUN PASS', flush=True)
    if failures:
        raise SystemExit('Failed samples: ' + ', '.join(failures))
    print(f'PASS: {len(SAMPLES)} samples compiled and executed ({target}).')


if __name__ == '__main__':
    main()
