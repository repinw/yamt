#!/usr/bin/env python3
"""Prints the integration tests that CI should run, as a JSON list.

Usage:
  tool/ci_integration_targets.py --all
  tool/ci_integration_targets.py <base-ref> [--since <sha> --passed <file>]
                                            [--carried-out <file>]

With a base ref, a test is selected when its import closure contains a file
that changed against the merge base, or when the test file itself changed.
Changes to files that every test depends on (packages, the Android project,
the test driver, this workflow) select every test.

With --since and --passed, a selected test is carried over instead of run
when it is listed in the passed file (one test per line, the tests that passed
on commit <sha>) and nothing in its import closure changed since <sha>. The
carried tests are written as a JSON list to the --carried-out file.
"""

import glob
import json
import os
import re
import subprocess
import sys

PACKAGE = 'yamt'
# Changes to these paths select every integration test.
RUN_ALL_PREFIXES = (
    'pubspec.yaml',
    'pubspec.lock',
    'analysis_options.yaml',
    'android/',
    'assets/',
    'test_driver/',
    '.github/workflows/ci.yml',
    'tool/ci_integration_targets.py',
    'tool/ci_integration_drive.sh',
    'tool/ci_previous_integration_passes.sh',
)
# A whole directive up to its semicolon, so the URIs in conditional import
# clauses (`if (dart.library.io) '...'`) are followed too. Following every
# branch over-selects a little, which is safe.
DIRECTIVE = re.compile(r'^\s*(?:import|export|part)\b([^;]*);', re.MULTILINE)
URI = re.compile(r"""['"]([^'"]+)['"]""")


def all_tests():
    return sorted(glob.glob('integration_test/**/*_test.dart', recursive=True))


def directives(path, cache):
    if path in cache:
        return cache[path]
    try:
        with open(path, encoding='utf-8') as source:
            text = source.read()
    except OSError:
        cache[path] = []
        return []
    result = []
    uris = [uri for clause in DIRECTIVE.findall(text) for uri in URI.findall(clause)]
    for uri in uris:
        if uri.startswith(f'package:{PACKAGE}/'):
            result.append('lib/' + uri[len(f'package:{PACKAGE}/'):])
        elif not uri.startswith(('package:', 'dart:')):
            result.append(os.path.normpath(os.path.join(os.path.dirname(path), uri)))
    cache[path] = result
    return result


def closure(test, cache):
    seen = set()
    stack = [test]
    while stack:
        path = stack.pop()
        if path in seen:
            continue
        seen.add(path)
        stack.extend(directives(path, cache))
    return seen


def changed_files(base_ref):
    merge_base = subprocess.check_output(
        ['git', 'merge-base', base_ref, 'HEAD'], text=True
    ).strip()
    output = subprocess.check_output(
        ['git', 'diff', '--name-only', merge_base, 'HEAD'], text=True
    )
    return [line for line in output.splitlines() if line]


def changed_since(sha):
    """Files changed from sha to HEAD, or None if sha is not available."""
    try:
        output = subprocess.check_output(
            ['git', 'diff', '--name-only', sha, 'HEAD'],
            text=True,
            stderr=subprocess.DEVNULL,
        )
    except subprocess.CalledProcessError:
        return None
    return [line for line in output.splitlines() if line]


def runs_all(changed):
    return any(path.startswith(RUN_ALL_PREFIXES) for path in changed)


def parse_options(args):
    options = {}
    while args:
        if len(args) < 2 or args[0] not in ('--since', '--passed', '--carried-out'):
            sys.exit(__doc__)
        options[args[0]] = args[1]
        args = args[2:]
    return options


def main():
    os.chdir(
        subprocess.check_output(['git', 'rev-parse', '--show-toplevel'], text=True).strip()
    )
    if len(sys.argv) < 2:
        sys.exit(__doc__)
    tests = all_tests()
    if sys.argv[1] == '--all':
        print(json.dumps(tests))
        return
    options = parse_options(sys.argv[2:])

    changed = changed_files(sys.argv[1])
    cache = {}
    if runs_all(changed):
        selected = tests
    else:
        changed_set = set(changed)
        selected = [test for test in tests if closure(test, cache) & changed_set]

    carried = []
    if '--since' in options and '--passed' in options:
        since = changed_since(options['--since'])
        if since is not None and not runs_all(since):
            with open(options['--passed'], encoding='utf-8') as source:
                passed = {line.strip() for line in source if line.strip()}
            since_set = set(since)
            carried = [
                test
                for test in selected
                if test in passed and not closure(test, cache) & since_set
            ]
            selected = [test for test in selected if test not in carried]

    if '--carried-out' in options:
        with open(options['--carried-out'], 'w', encoding='utf-8') as target:
            json.dump(carried, target)
    print(json.dumps(selected))


if __name__ == '__main__':
    main()
