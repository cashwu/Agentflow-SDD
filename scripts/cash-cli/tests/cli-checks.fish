#!/usr/bin/env fish

set -g root_dir (path resolve (dirname (status filename))/../../..)
set -g test_group all
if test (count $argv) -gt 0
    set test_group $argv[1]
end

function fail
    echo "FAIL: $argv" >&2
    exit 1
end

function run_python_tests --argument-names pattern
    set -lx PYTHONPATH "$root_dir/.cash-skills/lib"
    python3 -m unittest discover \
        -s "$root_dir/scripts/cash-cli/tests" \
        -p "$pattern"; or fail "$pattern"
end

switch "$test_group"
    case runtime-and-errors
        run_python_tests test_runtime_and_errors.py
    case workspace-config-boundaries
        run_python_tests test_workspace_config_boundaries.py
    case graph-instructions
        run_python_tests test_graph_instructions.py
    case discovery-contracts
        run_python_tests test_discovery_contracts.py
    case creation-task-lifecycle
        run_python_tests test_creation_task_lifecycle.py
    case park-unpark
        run_python_tests test_park_unpark.py
    case validation-matrix
        run_python_tests test_validation_matrix.py
    case analyze-drift
        run_python_tests test_analyze_drift.py
    case lexical-search
        run_python_tests test_lexical_search.py
    case sync-archive-transaction
        run_python_tests test_sync_archive_transaction.py
    case positive-lifecycle
        run_python_tests test_positive_lifecycle.py
    case negative-atomicity
        run_python_tests test_negative_atomicity.py
        run_python_tests 'test_*boundaries.py'
        run_python_tests test_park_unpark.py
        run_python_tests test_validation_matrix.py
        run_python_tests test_sync_archive_transaction.py
        run_python_tests test_lexical_search.py
        run_python_tests test_runtime_and_errors.py
    case all
        run_python_tests 'test_*.py'
    case '*'
        fail "unknown test group: $test_group"
end

echo "PASS: $test_group"
