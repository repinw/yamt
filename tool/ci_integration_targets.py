#!/usr/bin/env python3
"""Prints the integration tests that CI should run, as a JSON list.

Usage:
  tool/ci_integration_targets.py --all
  tool/ci_integration_targets.py <base-ref>

With a base ref, a test is selected when its import closure contains a file
that changed against the merge base, or when the test file itself changed.
Changes to files that every test depends on (packages, the Android project,
the test driver, this workflow) select every test.
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


def main():
    os.chdir(
        subprocess.check_output(['git', 'rev-parse', '--show-toplevel'], text=True).strip()
    )
    if len(sys.argv) != 2:
        sys.exit(__doc__)
    tests = all_tests()
    if sys.argv[1] == '--all':
        print(json.dumps(tests))
        return

    changed = changed_files(sys.argv[1])
    if any(path.startswith(RUN_ALL_PREFIXES) for path in changed):
        print(json.dumps(tests))
        return

    changed_set = set(changed)
    cache = {}
    selected = [test for test in tests if closure(test, cache) & changed_set]
    print(json.dumps(selected))


if __name__ == '__main__':
    main()
