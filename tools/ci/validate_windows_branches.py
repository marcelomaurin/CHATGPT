#!/usr/bin/env python3
"""Compile the reviewed CHATGPT snapshots on a native Windows runner."""
from __future__ import annotations
import argparse
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
SNAPSHOTS = {
    'main': '56034debfc03a322d4d75ba471dc90e25adb3b4c',
    'voice': '838d24158dab7fa19df0f565c83b000da77d3095',
    'printer': 'd3682ea1bab4816555e74a720356e267e4cbfac0',
    'packages': 'f8e335fba391c77556f7e1cbc6b1a8629d87b9a9',
    'historical': '3affa4e6a01c2148e537aed4efdb6a2ee6d499b0',
}
DEPENDENCIES = {
    'zeoslib': ('https://github.com/frones/ZeosLib.git', '66c3ce219893fca03247d7653a0b140bd8011e27'),
    'dcpcrypt': ('https://github.com/ziceptor/DCPcrypt.git', '14586ed66d15fd91530ed5dfaab8a8e4bb8959ff'),
    'cef4delphi': ('https://github.com/salvadordf/CEF4Delphi.git', '84d5f7670056aed6753bf4dc855a5cb3e468fd60'),
}
PATTERNS = ['*.pas', '*.pp', '*.inc', '*.lpk', '*.lpi', '*.lpr', '*.lfm', '*.lrs', '*.res', '*.rc', '*.ico', '*.bmp', '*.md', '*.json', '*.cfg', '*.ini', '*.xml', '*.txt']
ROOT = Path(os.environ.get('RUNNER_TEMP', '.')).resolve() / 'chatgpt-windows-validation'
ARTIFACTS = Path(os.environ.get('GITHUB_WORKSPACE', '.')).resolve() / 'windows-build-artifacts'
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
    print(f'{log_name}: exit {status}', flush=True)
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
        matches = list(Path('C:/lazarus').glob('lazbuild.exe'))
        if not matches:
            raise RuntimeError('Native Lazarus/lazbuild not found')
        lazbuild = str(matches[0])
    lazarus = Path(lazbuild).resolve().parent
    candidates = list(lazarus.glob('fpc/*/bin/x86_64-win64/fpc.exe'))
    fpc = str(candidates[0]) if candidates else shutil.which('fpc')
    if not fpc:
        raise RuntimeError('Native FPC executable not found')
    def info(flag):
        return subprocess.check_output([fpc, flag], text=True, encoding='utf-8', errors='replace').strip()
    METADATA.update({'fpc_version': info('-iV'), 'cpu': info('-iTP'), 'os': info('-iTO'),
        'lazarus_version': subprocess.check_output([lazbuild, '--version'], text=True).strip(),
        'fpc': fpc, 'lazbuild': lazbuild})
    if METADATA['os'] not in ('win32', 'win64'):
        raise RuntimeError('Compiler is not targeting native Windows: ' + METADATA['os'])
    print(json.dumps(METADATA, indent=2), flush=True)
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
    for suffix in ('lcl/units/' + target, 'lcl/units/' + target + '/win32',
        'components/lazutils/lib/' + target, 'packager/units/' + target,
        'components/ideintf/units/' + target + '/win32'):
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
        '--compiler=' + str(fpc), '--ws=win32', '--no-write-project']
    links = list((repo / 'pacote/packages').glob('*.lpk'))
    links += list((ROOT / 'deps/zeoslib/packages/lazarus').glob('*.lpk'))
    links += [ROOT / 'deps/dcpcrypt/dcpcrypt.lpk', ROOT / 'deps/cef4delphi/packages/cef4delphi_lazarus.lpk']
    for index, package in enumerate(links):
        if package.is_file():
            command([*base, '--add-package-link=' + str(package)], name + f'-link-{index}', repo, True)
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
        binary = path.with_suffix('.exe')
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


def write_report():
    ARTIFACTS.mkdir(parents=True, exist_ok=True)
    (ARTIFACTS / 'results.json').write_text(json.dumps({'environment': METADATA, 'results': RESULTS}, indent=2), encoding='utf-8')
    lines = ['# Native Windows compilation', '',
        'Environment: ' + METADATA.get('cpu', '?') + '-' + METADATA.get('os', '?') +
        '; FPC ' + METADATA.get('fpc_version', '?') + '; Lazarus ' + METADATA.get('lazarus_version', '?'), '',
        '| Snapshot | Target | Build exit | Test exit |', '|---|---|---:|---:|']
    for result in RESULTS:
        lines.append('| ' + result['snapshot'] + ' | ' + result['target'] + ' | ' + str(result['exit_code']) + ' | ' + str(result.get('test_exit_code', '-')) + ' |')
    lines += ['', 'Builds use native Windows, win32 widgetset, isolated package profiles and configured source paths.',
        'Lazbuild uses --skip-dependencies; this is not a clean installer certification.',
        'GUI applications are compiled, not interactively exercised. Hardware and paid remote API calls are not used.']
    (ARTIFACTS / 'REPORT.md').write_text('\n'.join(lines) + '\n', encoding='utf-8')


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--plan', action='store_true')
    options = parser.parse_args()
    if options.plan:
        print(json.dumps({'snapshots': SNAPSHOTS, 'dependencies': DEPENDENCIES}, indent=2))
        return 0
    if sys.platform != 'win32':
        raise RuntimeError('This validation must execute on a native Windows runner')
    ROOT.mkdir(parents=True, exist_ok=True)
    write_report()
    fpc, lazbuild, lazarus = identify_toolchain()
    for name, (url, ref) in DEPENDENCIES.items():
        checkout(name, url, ref, dependency=True)
    for name, ref in SNAPSHOTS.items():
        repo = checkout(name, REPOSITORY, ref)
        base, directories = prepare_profile(name, repo, fpc, lazbuild, lazarus)
        if name == 'main':
            build_fpc(name, repo, fpc, directories, 'pacote/AI Industrial/aimodbus.pas', 'main-modbus-timeval')
            for package in ('openai_input', 'openai_voice', 'openai_output'):
                build_lazarus(name, repo, base, directories, 'pacote/packages/' + package + '.lpk', 'main-' + package)
        elif name == 'voice':
            build_lazarus(name, repo, base, directories, 'pacote/packages/openai_voice.lpk', 'voice-package')
            build_lazarus(name, repo, base, directories, 'pacote/samples/AI Voice/voice_remote_provider_demo/voice_remote_provider_demo.lpi', 'voice-demo')
            build_fpc(name, repo, fpc, directories, 'tests/test_voice_providers.lpr', 'voice-tests', execute=True)
        elif name == 'printer':
            build_lazarus(name, repo, base, directories, 'pacote/packages/openai_output.lpk', 'printer-package')
            build_lazarus(name, repo, base, directories, 'pacote/samples/AI Output/posprinter_demo/posprinter_demo.lpi', 'printer-demo')
            build_fpc(name, repo, fpc, directories, 'pacote/tests/test_openai_output.lpr', 'printer-tests', execute=True, test_args=['--all', '--format=plain'])
        elif name == 'packages':
            target = 'pacote/AI Input/AIChromiumBrowser/aichromiumbrowser.pas'
            build_fpc(name, repo, fpc, directories, target, 'chromium-original')
            path = repo / target
            original = path.read_text(encoding='utf-8-sig')
            needle = '    FChromiumWindow.ChromiumBrowser.DefaultUrl,\n    0\n'
            if original.count(needle) != 1:
                raise RuntimeError('Chromium compatibility patch context changed')
            path.write_text(original.replace(needle, '    FChromiumWindow.ChromiumBrowser.DefaultUrl,\n    \'\',\n    \'\',\n    0\n'), encoding='utf-8')
            build_fpc(name, repo, fpc, directories, target, 'chromium-local-compatibility')
            build_lazarus(name, repo, base, directories, 'pacote/packages/openai_input.lpk', 'chromium-package-after-local-patch')
        else:
            for module, project in [('AI Core','modelregistry_demo'), ('AI Core','promptbuilder_demo'),
                ('AI Core','wizard_config_demo'), ('AI Graph','training_exporter_demo'), ('AI Graph','training_report_demo')]:
                build_lazarus(name, repo, base, directories, f'pacote/samples/{module}/{project}/{project}.lpi', 'historical-' + project)
    write_report()
    return 1 if any(item['exit_code'] or item.get('test_exit_code', 0) for item in RESULTS) else 0


if __name__ == '__main__':
    try:
        sys.exit(main())
    except Exception as error:
        ARTIFACTS.mkdir(parents=True, exist_ok=True)
        (ARTIFACTS / 'SETUP_ERROR.txt').write_text(traceback.format_exc(), encoding='utf-8')
        METADATA['setup_error'] = str(error)
        write_report()
        raise
