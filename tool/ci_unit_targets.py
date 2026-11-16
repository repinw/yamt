#!/usr/bin/env python3
"""Prints the unit and widget tests that a pull request needs.

Usage:
  tool/ci_unit_targets.py <base-ref>
  tool/ci_unit_targets.py --analyze <base-ref>

The change is the diff from the merge base of <base-ref> and HEAD to HEAD.
The first form prints one of:
  none   no changed file can affect a unit test, so Flutter is not needed;
  all    run the whole suite;
  a list of test paths, one per line, always with test/architecture.
The second form prints `true` when analyze, the changed-file lints and the
provider hash check must run, and `false` otherwise.

On doubt the script runs more: a file that no rule below knows selects every
test, and any error prints `all` (or `true`).

A test is selected when its import closure contains a changed file, or when
the test file itself changed. Some tests read files without importing them;
INPUTS maps those files to the tests that read them.
"""

import fnmatch
import glob
import os
import subprocess
import sys

from ci_integration_targets import closure

ARCHITECTURE = 'test/architecture'

# Changes to these select every test. A path that ends with `/` matches the
# whole folder.
RUN_ALL = (
    'pubspec.yaml',
    'pubspec.lock',
    'analysis_options.yaml',
    'dart_test.yaml',
    'assets/',
    '.metadata',
    '.github/workflows/ci.yml',
    '.github/actions/select-unit-tests/',
    'tool/ci_*',
    'tool/clock_change_tz.sh',
    'tool/check_provider_hashes.sh',
    'tools/architecture_lints/',
)

# Files that tests read without importing them, mapped to those tests.
# Found with a grep of test/ for File(, Directory(, readAsString, rootBundle
# and Platform.script.
INPUTS = {
    # The architecture rules read the feature order.
    'architecture/feature-boundaries.md': [ARCHITECTURE],
    # integration_page_coverage_test reads every integration test.
    'integration_test/**': [ARCHITECTURE],
    'firestore.rules': ['test/firestore_*_test.dart'],
    'firestore.indexes.json': ['test/firestore_serving_suggestion_rules_test.dart'],
}

# Tests that scan the Dart files under lib/ by listing the folder, so any
# change there selects them.
LIB_SCANNERS = [
    ARCHITECTURE,
    'test/firestore_rules_default_deny_test.dart',
    'test/core/widgets/app_feedback_usage_test.dart',
]

# Changes to these affect no unit test. Markdown is here unless INPUTS names
# it. A path that ends with `/` matches the whole folder.
NOTHING = (
    '.gitignore',
    '.firebaserc',
    '.jscpd.json',
    '.nvmrc',
    '.tool-versions',
    'LICENSE',
    'database.rules.json',
    'devtools_options.yaml',
    'firebase.json',
    'remoteconfig.template.json',
    'storage.rules',
    '*.md',
    '.github/',
    'android/',
    'distribution/',
    'functions/',
    'ios/',
    'test_driver/',
    'tool/',
)

# Changes to these need analyze, the changed-file lints and the provider hash
# check. ARB files generate lib/l10n.
ANALYZE = (
    '*.dart',
    '*.arb',
    'pubspec.yaml',
    'pubspec.lock',
    '*analysis_options.yaml',
)

# Above this share of all test files, the whole suite runs.
MAX_SHARE = 0.6


def matches(path, patterns):
    for pattern in patterns:
        if pattern.endswith('/'):
            if path.startswith(pattern):
                return True
        elif fnmatch.fnmatchcase(path, pattern):
            return True
    return False


def changed_files(base_ref):
    merge_base = subprocess.check_output(
        ['git', 'merge-base', base_ref, 'HEAD'], text=True
    ).strip()
    # Without rename detection a renamed file shows its old path too, so a
    # test that still imports the old path is found.
    output = subprocess.check_output(
        ['git', 'diff', '--name-only', '--no-renames', merge_base, 'HEAD'], text=True
    )
    return [line for line in output.splitlines() if line]


def runs_all(path):
    if path.endswith('flutter_test_config.dart'):
        return True
    if path.startswith('test/') and not path.endswith('.dart'):
        return True
    return matches(path, RUN_ALL)


def expand(pattern):
    """Test files that a path or glob from INPUTS or LIB_SCANNERS names."""
    if os.path.isdir(pattern):
        return set(glob.glob(f'{pattern}/**/*_test.dart', recursive=True))
    return set(glob.glob(pattern))


def select(changed):
    """Returns 'all', or the set of test paths (folders allowed) to run."""
    selected = set()
    dart = set()
    for path in changed:
        if runs_all(path):
            return 'all'
        inputs = [tests for pattern, tests in INPUTS.items() if fnmatch.fnmatchcase(path, pattern)]
        if inputs:
            for tests in inputs:
                selected.update(tests)
            if path.endswith('.dart'):
                dart.add(path)
        elif path.startswith('lib/') and path.endswith('.dart'):
            dart.add(path)
            selected.update(LIB_SCANNERS)
        elif path.startswith('lib/') and path.endswith('.arb'):
            # The localizations are generated from the ARB files.
            dart.update(glob.glob('lib/l10n/app_localizations*.dart'))
            selected.update(LIB_SCANNERS)
        elif path.startswith('test/') and path.endswith('.dart'):
            dart.add(path)
            if path.endswith('_test.dart') and os.path.exists(path):
                selected.add(path)
        elif path.startswith('lib/') and path.endswith('.md'):
            pass
        elif matches(path, NOTHING):
            pass
        else:
            return 'all'

    if dart:
        cache = {}
        for test in all_tests():
            if test not in selected and closure(test, cache) & dart:
                selected.add(test)
    return selected


def all_tests():
    return sorted(glob.glob('test/**/*_test.dart', recursive=True))


def targets(base_ref):
    selected = select(changed_files(base_ref))
    if selected == 'all':
        return 'all'
    if not selected:
        return 'none'
    selected.add(ARCHITECTURE)
    paths = sorted(selected)
    files = set()
    for path in paths:
        found = expand(path)
        if not found and not os.path.isdir(path):
            # A path that names nothing would fail the test run.
            raise FileNotFoundError(path)
        files |= found
    if len(files) > MAX_SHARE * len(all_tests()):
        return 'all'
    # A glob from INPUTS is handed on as the files it names, and a file in a
    # selected folder is left out, so no test runs twice.
    folders = [path for path in paths if os.path.isdir(path)]
    result = set()
    for path in paths:
        names = [path] if os.path.isdir(path) or os.path.isfile(path) else expand(path)
        for name in names:
            if not any(name.startswith(folder + '/') for folder in folders):
                result.add(name)
    return '\n'.join(sorted(result))


def needs_analyze(base_ref):
    changed = changed_files(base_ref)
    # Whatever selects every test also needs analyze: a file that no rule
    # knows, such as build.yaml, may change the generated code.
    if select(changed) == 'all':
        return True
    return any(matches(os.path.basename(path), ANALYZE) or matches(path, ANALYZE) for path in changed)


def main():
    args = sys.argv[1:]
    analyze = args[:1] == ['--analyze']
    if analyze:
        args = args[1:]
    if len(args) != 1:
        sys.exit(__doc__)
    try:
        os.chdir(
            subprocess.check_output(['git', 'rev-parse', '--show-toplevel'], text=True).strip()
        )
        if analyze:
            print('true' if needs_analyze(args[0]) else 'false')
        else:
            print(targets(args[0]))
    except Exception as error:  # Any doubt runs everything.
        print(f'ci_unit_targets: {error!r}; running everything', file=sys.stderr)
        print('true' if analyze else 'all')


if __name__ == '__main__':
    main()
