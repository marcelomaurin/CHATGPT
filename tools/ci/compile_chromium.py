#!/usr/bin/env python3
"""Compile the reviewed CHATGPT snapshots on a native Windows runner."""
from __future__ import annotations
import argparse
import hashlib
import json
import os
from pathlib import Path
import re
import shutil
import subprocess
import sys
import traceback
import xml.etree.ElementTree as ET

REPOSITORY = 'https://github.com/marcelomaurin/CHATGPT.git'
SNAPSHOTS = {'main': os.environ.get('GITHUB_SHA', 'local'),
    'historical': '3affa4e6a01c2148e537aed4efdb6a2ee6d499b0'}
DEPENDENCIES = {
    'zeoslib': ('https://github.com/frones/ZeosLib.git', '66c3ce219893fca03247d7653a0b140bd8011e27'),
    'dcpcrypt': ('https://github.com/ziceptor/DCPcrypt.git', '14586ed66d15fd91530ed5dfaab8a8e4bb8959ff'),
    'cef4delphi': ('https://github.com/salvadordf/CEF4Delphi.git', '84d5f7670056aed6753bf4dc855a5cb3e468fd60'),
}
PATTERNS = ['*.pas', '*.pp', '*.inc', '*.lpk', '*.lpi', '*.lpr', '*.lfm', '*.lrs', '*.res', '*.rc', '*.ico', '*.bmp', '*.md', '*.json', '*.cfg', '*.ini', '*.xml', '*.txt']
ROOT = Path(os.environ.get('RUNNER_TEMP', '.')).resolve() / 'chromium-validation'
ARTIFACTS = Path(os.environ.get('GITHUB_WORKSPACE', '.')).resolve() / 'build/chromium-compile'
RESULTS = []
METADATA = {'snapshots': SNAPSHOTS, 'dependencies': DEPENDENCIES, 'platform': sys.platform}


def command(args, log_name, cwd=None, required=False, stdin=None):
    logfile = ARTIFACTS / 'logs' / (log_name + '.log')
    logfile.parent.mkdir(parents=True, exist_ok=True)
    with logfile.open('w', encoding='utf-8') as output:
        output.write('COMMAND: ' + repr([str(arg) for arg in args]) + '\n')
        output.flush()
        try:
            process = subprocess.run([str(arg) for arg in args], cwd=cwd, input=stdin,
                stdout=output, stderr=subprocess.STDOUT, text=True, encoding='utf-8',
                errors='replace', timeout=900)
            status = process.returncode
        except subprocess.TimeoutExpired:
            output.write('\nCOMMAND TIMED OUT AFTER 900 SECONDS\n')
            status = 124
    if status or '-link-' not in log_name:
        print(f'{log_name}: exit {status}', flush=True)
    if status:
        lines = logfile.read_text(errors='replace').splitlines()
        print('\n'.join(line for line in lines if re.search(r'Error:|Fatal:|fatal:', line))[:4000], flush=True)
    if required and status:
        raise RuntimeError(f'{log_name} failed; see {logfile.name}')
    return status, logfile


def checkout(name, url, ref, dependency=False):
    target = ROOT / ('deps' if dependency else 'src') / name
    target.mkdir(parents=True, exist_ok=True)
    command(['git', 'init', '-q'], name + '-git-init', target, True)
    command(['git', 'config', 'core.longpaths', 'true'], name + '-git-config', target, True)
    command(['git', 'remote', 'add', 'origin', url], name + '-git-remote', target, True)
    command(['git', 'fetch', '--filter=blob:none', '--depth=1', 'origin', ref], name + '-git-fetch', target, True)
    command(['git', 'sparse-checkout', 'init', '--no-cone'], name + '-sparse-init', target, True)
    command(['git', 'sparse-checkout', 'set', '--no-cone', '--stdin'], name + '-sparse-set', target, True, '\n'.join(PATTERNS) + '\n')
    command(['git', 'checkout', '--detach', ref], name + '-git-checkout', target, True)
    return target


def identify_toolchain():
    lazbuild = shutil.which('lazbuild')
    if not lazbuild:
        lazbuild = 'C:/lazarus/lazbuild.exe'
    lazarus = Path(lazbuild).resolve().parent
    matches = list(lazarus.glob('fpc/*/bin/x86_64-win64/fpc.exe'))
    fpc = shutil.which('fpc') or (str(matches[0]) if matches else None)
    if not fpc:
        raise RuntimeError('Native FPC executable not found')
    os.environ['PATH'] = str(Path(fpc).parent) + os.pathsep + os.environ['PATH']
    def info(flag):
        return subprocess.check_output([fpc, flag], text=True).strip()
    METADATA.update({'fpc_version': info('-iV'), 'cpu': info('-iTP'), 'os': info('-iTO'),
        'lazarus_version': subprocess.check_output([lazbuild, '--version'], text=True).strip(),
        'fpc': fpc, 'lazbuild': lazbuild})
    print(json.dumps(METADATA), flush=True)
    return Path(fpc), Path(lazbuild), lazarus

def unit_directories(repo, lazarus):
    pacote = repo / 'pacote'
    directories = [pacote, pacote / 'AI', pacote / 'AI Voice']
    excluded = {'samples', 'tests', 'python', 'lib', 'backup', '.git', 'demos', 'demos_lazarus'}
    for parent in (pacote, ROOT / 'deps/zeoslib/src', ROOT / 'deps/dcpcrypt', ROOT / 'deps/cef4delphi/source'):
        for current, children, files in os.walk(parent):
            children[:] = [child for child in children if child.lower() not in excluded]
            if any(file.lower().endswith(('.pas', '.pp', '.inc')) for file in files):
                directories.append(Path(current))
    target = METADATA['cpu'] + '-' + METADATA['os']
    for suffix in ('lcl/units/' + target, 'lcl/units/' + target + ('/win32' if os.name == 'nt' else '/nogui'),
        'components/lazutils/lib/' + target, 'packager/units/' + target,
        'components/ideintf/units/' + target + ('/win32' if os.name == 'nt' else '/nogui')):
        directories.append(lazarus / suffix)
    for candidate in lazarus.glob('fpc/*/source/packages/openssl/src'):
        directories.append(candidate)
    for candidate in lazarus.glob('fpc/*/fpcsrc/packages/openssl/src'):
        directories.append(candidate)
    return list(dict.fromkeys(path.resolve() for path in directories if path.is_dir()))


def prepare_profile(name, repo, fpc, lazbuild, lazarus):
    directories = unit_directories(repo, lazarus)
    # Configure paths only in this disposable checkout. Runtime sources stay intact.
    for package in (repo / 'pacote/packages').glob('*.lpk'):
        append_paths(package, directories)
    pcp = ROOT / 'build' / name / 'lazarus-config'
    pcp.mkdir(parents=True, exist_ok=True)
    base = [lazbuild, '--pcp=' + str(pcp), '--lazarusdir=' + str(lazarus),
        '--compiler=' + str(fpc), '--ws=' + ('win32' if os.name == 'nt' else 'nogui'), '--no-write-project']
    links = list((repo / 'pacote/packages').glob('*.lpk'))
    links += list((ROOT / 'deps/zeoslib/packages/lazarus').glob('*.lpk'))
    links += [ROOT / 'deps/dcpcrypt/dcpcrypt.lpk', ROOT / 'deps/cef4delphi/packages/cef4delphi_lazarus.lpk']
    for index, package in enumerate(links):
        if package.is_file():
            command([*base, '--add-package-link', str(package)], name + f'-link-{index}', repo, True)
    return base, directories


def append_paths(path, directories):
    tree = ET.parse(path)
    config = tree.find('.//CompilerOptions')
    if config is None:
        raise RuntimeError('CompilerOptions absent: ' + str(path))
    search = config.find('SearchPaths')
    if search is None:
        search = ET.SubElement(config, 'SearchPaths')
    for tag in ('OtherUnitFiles', 'IncludeFiles'):
        node = search.find(tag)
        if node is None:
            node = ET.SubElement(search, tag)
        old = node.get('Value', '')
        node.set('Value', ';'.join([old, *(str(item) for item in directories)]).lstrip(';'))
    tree.write(path, encoding='utf-8', xml_declaration=True)


def add_result(name, target, status, logfile, **extra):
    record = {'snapshot': name, 'target': target, 'exit_code': status,
        'log': str(logfile.relative_to(ARTIFACTS)), **extra}
    RESULTS.append(record)
    write_report()
    return record


def build_lazarus(name, repo, base, directories, target, label):
    path = repo / target
    if path.suffix == '.lpi':
        append_paths(path, directories)
    status, logfile = command([*base, '--skip-dependencies', '--build-all', path], label, repo)
    record = add_result(name, target, status, logfile,
        kind='package' if path.suffix == '.lpk' else 'project')
    if not status and path.suffix == '.lpi':
        binary = path.with_suffix('.exe' if os.name == 'nt' else '')
        if binary.is_file():
            destination = ARTIFACTS / 'bin' / name
            destination.mkdir(parents=True, exist_ok=True)
            shutil.copy2(binary, destination / binary.name)
    return record


def build_fpc(name, repo, fpc, directories, target, label, execute=False, test_args=None):
    output = ROOT / 'build' / name / label
    output.mkdir(parents=True, exist_ok=True)
    flags = ['-B', '-Mobjfpc', '-Sh', '-FU' + str(output), '-FE' + str(output)]
    flags += ['-Fu' + str(item) for item in directories]
    flags += ['-Fi' + str(item) for item in directories]
    status, logfile = command([fpc, *flags, repo / target], label + '-build', repo)
    record = add_result(name, target, status, logfile, kind='program' if execute else 'unit')
    if status == 0 and execute:
        binary = output / (Path(target).stem + '.exe')
        run_status, run_log = command([binary, *(test_args or [])], label + '-run', repo)
        record.update({'test_exit_code': run_status, 'test_log': str(run_log.relative_to(ARTIFACTS))})
        destination = ARTIFACTS / 'bin' / name
        destination.mkdir(parents=True, exist_ok=True)
        shutil.copy2(binary, destination / binary.name)
        write_report()
    return record


# This driver reuses the package/path setup already exercised in the earlier
# native Windows branch validation. It builds current Chromium sources only.
def write_report():
    ARTIFACTS.mkdir(parents=True, exist_ok=True)
    (ARTIFACTS / 'results.json').write_text(json.dumps(
        {'environment': METADATA, 'results': RESULTS}, indent=2), encoding='utf-8')
    lines = ['# Chromium compilation', '',
        '| Snapshot | Target | Exit | Required |', '|---|---|---:|---|']
    for item in RESULTS:
        lines.append('| ' + item['snapshot'] + ' | ' + item['target'] + ' | ' +
            str(item['exit_code']) + ' | ' + str(item.get('required', True)) + ' |')
    lines += ['', 'Native compilation only; JavaScript execution and GUI are not exercised.',
        'Historical projects are diagnostics; their individual failures remain visible.']
    if METADATA.get('setup_error'):
        lines += ['', 'Setup error: ' + METADATA['setup_error']]
    (ARTIFACTS / 'REPORT.md').write_text('\n'.join(lines) + '\n', encoding='utf-8')


def main():
    repo = Path(__file__).resolve().parents[2]
    ROOT.mkdir(parents=True, exist_ok=True)
    ARTIFACTS.mkdir(parents=True, exist_ok=True)
    fpc, lazbuild, lazarus = identify_toolchain()
    # Resolve exactly the CEF/DCPcrypt/Zeos pins from the current manifest.
    manifest = json.loads((repo / 'installer/dependencies.json').read_text(encoding='utf-8'))
    aliases = {'CEF4Delphi': 'cef4delphi', 'DCPcrypt': 'dcpcrypt', 'ZeosLib Core': 'zeoslib'}
    for entry in manifest['dependencies']:
        name = aliases.get(entry['name'])
        if name:
            DEPENDENCIES[name] = (entry['repository'], entry['commit'])
    for name, (url, ref) in DEPENDENCIES.items():
        checkout(name, url, ref, dependency=True)
    base, directories = prepare_profile('main', repo, fpc, lazbuild, lazarus)
    record = build_fpc('main', repo, fpc, directories,
        'pacote/AI Input/AIChromiumBrowser/aichromiumbrowser.pas',
        'chromium-unit')
    record['required'] = True
    for path, label in [
        ('pacote/samples/AI Input/chromium_capture_demo/chromium_capture_demo.lpi', 'chromium-capture'),
        ('pacote/AI Input/AIChromiumBrowser/AIChromiumBrowser_Test.lpi', 'chromium-test-demo')]:
        record = build_lazarus('main', repo, base, directories, path, label)
        record['required'] = True
    historical = checkout('historical', REPOSITORY, SNAPSHOTS['historical'])
    METADATA['historical_overlays'] = []
    for path in ('pacote/AI Input/AIChromiumBrowser/aichromiumbrowser.pas',
                 'pacote/AI Industrial/aimodbus.pas'):
        data = (repo / path).read_bytes()
        (historical / path).write_bytes(data)
        METADATA['historical_overlays'].append(
            {'path': path, 'sha256': hashlib.sha256(data).hexdigest()})
    base, directories = prepare_profile('historical', historical, fpc, lazbuild, lazarus)
    for module, project in [('AI Core', 'wizard_config_demo'),
                            ('AI Graph', 'training_exporter_demo'),
                            ('AI Graph', 'training_report_demo')]:
        record = build_lazarus('historical', historical, base, directories,
            'pacote/samples/' + module + '/' + project + '/' + project + '.lpi',
            'historical-' + project)
        record['required'] = False
    write_report()
    print(json.dumps({'environment': METADATA, 'results': RESULTS}), flush=True)
    return int(any(item['exit_code'] != 0 and item.get('required', True) for item in RESULTS))


if __name__ == '__main__':
    try:
        sys.exit(main())
    except Exception as error:
        ARTIFACTS.mkdir(parents=True, exist_ok=True)
        (ARTIFACTS / 'SETUP_ERROR.txt').write_text(traceback.format_exc(), encoding='utf-8')
        METADATA['setup_error'] = str(error)
        write_report()
        raise
