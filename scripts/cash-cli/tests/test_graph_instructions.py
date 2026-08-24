import unittest

from cash_cli.commands.discovery import skill_payload
from cash_cli.resources import (
    APPLY_INSTRUCTION,
    ARTIFACT_GRAPH,
    DISCIPLINES,
    LOCALE,
    artifact_resource,
)


class GraphInstructionTests(unittest.TestCase):
    def test_spec_driven_graph_has_one_stable_definition(self) -> None:
        self.assertEqual(
            [
                (artifact.id, artifact.output_path, artifact.dependencies)
                for artifact in ARTIFACT_GRAPH
            ],
            [
                ("proposal", "proposal.md", ()),
                ("design", "design.md", ("proposal",)),
                ("specs", "specs/**/*.md", ("proposal",)),
                ("tasks", "tasks.md", ("proposal", "design", "specs")),
            ],
        )

    def test_every_artifact_has_description_and_template(self) -> None:
        for artifact in ARTIFACT_GRAPH:
            with self.subTest(artifact=artifact.id):
                self.assertTrue(artifact.description)
                self.assertTrue(artifact.template)
                self.assertNotIn("TBD", artifact.template)

    def test_proposal_template_has_stable_required_structure(self) -> None:
        first_template = artifact_resource("proposal").template
        second_template = artifact_resource("proposal").template
        headings = [
            "## Summary",
            "## Motivation",
            "## Proposed Solution",
            "## Non-Goals",
            "## Alternatives Considered",
            "## Capabilities",
            "## Impact",
        ]

        self.assertEqual(first_template, second_template)
        self.assertEqual(
            [first_template.index(heading) for heading in headings],
            sorted(first_template.index(heading) for heading in headings),
        )
        self.assertIn(
            "## Capabilities\n\n"
            "### New Capabilities\n\n"
            "### Modified Capabilities",
            first_template,
        )
        self.assertIn(
            "## Impact\n\n"
            "- Affected specs:\n"
            "- Affected code:\n"
            "  - New:\n"
            "  - Modified:\n"
            "  - Removed:",
            first_template,
        )

    def test_apply_and_discipline_resources_are_cash_owned(self) -> None:
        self.assertEqual(LOCALE, "Traditional Chinese (繁體中文)")
        self.assertIn("tasks", APPLY_INSTRUCTION)
        self.assertEqual(
            set(DISCIPLINES),
            {"tdd", "test-quality", "audit"},
            "DISCIPLINES 必須恰好擁有 tdd、test-quality 與 audit 三個 canonical discipline",
        )
        self.assertIn("Scoundrel", DISCIPLINES["audit"])
        for text in (APPLY_INSTRUCTION, *DISCIPLINES.values()):
            self.assertNotIn("spectra", text.lower())

    def test_tdd_skill_payload_uses_the_canonical_instruction(self) -> None:
        self.assertEqual(skill_payload("tdd")["instruction"], DISCIPLINES["tdd"])

    def test_tdd_discipline_covers_each_required_behavior(self) -> None:
        instruction = DISCIPLINES["tdd"]
        required_meanings = {
            "observable executable behavior": "可觀察可執行行為",
            "target failure reason": "目標行為尚未存在",
            "unrelated failure exclusion": "不相關的較早 guard",
            "executed RED": "必須在任何 production edit 前實際執行目前 workflow 命名的 primary verification target",
            "same-target GREEN": "重跑同一個 primary verification target",
            "related regression": "再執行目前 workflow 命名的相關 regression targets",
            "minimal green": "最小實作",
            "green refactor": "綠燈狀態",
            "bug reproduction": "能辨識該缺陷的失敗測試",
            "pure-refactor evidence": "characterization test",
            "remaining-task verification": "命名的 verification target",
        }

        for meaning, marker in required_meanings.items():
            with self.subTest(meaning=meaning):
                self.assertIn(marker, instruction)

    def test_tdd_discipline_classifies_tasks_by_precedence(self) -> None:
        instruction = DISCIPLINES["tdd"]
        branch_markers = [
            "bug fix 且存在實際可行的自動測試邊界",
            "非 bug fix 的可觀察可執行行為變更",
            "不改變可觀察行為的純 refactor",
            "其餘 task",
        ]
        branch_lines = [
            line
            for line in instruction.splitlines()
            if any(line.startswith(f"{index}. ") for index in range(1, 5))
        ]

        self.assertEqual(len(branch_lines), 4)
        for index, marker in enumerate(branch_markers, start=1):
            with self.subTest(branch=marker):
                self.assertTrue(branch_lines[index - 1].startswith(f"{index}. {marker}"))
        self.assertIn("由前至後判定", instruction)
        self.assertIn("命中後不再落入後續分支", instruction)

    def test_tdd_discipline_keeps_bug_reproduction_as_regression(self) -> None:
        instruction = DISCIPLINES["tdd"]
        bug_branch = next(
            line for line in instruction.splitlines() if line.startswith("1. ")
        )

        self.assertIn("能辨識該缺陷的失敗測試", bug_branch)
        self.assertIn("以最小實作使重現測試通過", bug_branch)
        self.assertIn("保留為 regression evidence", bug_branch)

    def test_tdd_discipline_routes_remaining_task_boundaries(self) -> None:
        instruction = DISCIPLINES["tdd"]
        remaining_branch = next(
            line for line in instruction.splitlines() if line.startswith("4. ")
        )

        self.assertIn("沒有實際可行自動測試邊界的 bug fix", remaining_branch)
        self.assertIn("文件、metadata、checker-only", remaining_branch)
        self.assertIn("命名的 verification target", remaining_branch)
        self.assertIn("有可用自動 checker 時可以使用", remaining_branch)
        self.assertIn("不要求 red phase", remaining_branch)

    def test_tdd_discipline_requires_distinguishable_red_evidence(self) -> None:
        instruction = DISCIPLINES["tdd"]

        self.assertIn("因目標行為尚未存在而失敗", instruction)
        self.assertIn("不相關的較早 guard", instruction)
        self.assertIn("pre-existing suite failure", instruction)
        self.assertIn("只有相同 exit code", instruction)
        self.assertIn("不構成有效 red", instruction)
        self.assertIn("diagnostic、state、artifact 或等價 assertion", instruction)

    def test_tdd_discipline_keeps_green_steps_minimal_and_safe(self) -> None:
        instruction = DISCIPLINES["tdd"]

        self.assertIn("以最小實作使測試通過", instruction)
        self.assertIn("只在綠燈狀態進行 refactor", instruction)

    def test_tdd_discipline_is_language_and_framework_neutral(self) -> None:
        instruction = DISCIPLINES["tdd"]

        self.assertIn("不要求特定程式語言或 test framework", instruction)
        for specific_tool in (
            "Python",
            "pytest",
            "unittest",
            "JavaScript",
            "Jest",
            "Vitest",
        ):
            with self.subTest(specific_tool=specific_tool):
                self.assertNotIn(specific_tool, instruction)


    def test_tdd_discipline_requires_executed_red_and_same_target_green(self) -> None:
        instruction = DISCIPLINES["tdd"]

        for literal in TDD_RED_GREEN_CONTRACT:
            with self.subTest(literal=literal):
                self.assertIn(literal, instruction)

    def test_tdd_discipline_is_evidence_carrier_neutral(self) -> None:
        instruction = DISCIPLINES["tdd"]

        self.assertIn(TDD_CARRIER_NEUTRAL, instruction)
        self.assertNotIn("tasks.md", instruction)

    def test_tdd_red_green_gates_reject_removal_and_inversion(self) -> None:
        instruction = DISCIPLINES["tdd"]
        self.assert_accepted(validate_tdd_red_green, instruction)

        for literal in TDD_RED_GREEN_CONTRACT + (TDD_CARRIER_NEUTRAL,):
            with self.subTest(mutation=f"remove {literal}"):
                self.assert_rejected(
                    validate_tdd_red_green,
                    instruction.replace(literal, "removed-gate", 1),
                    because="missing",
                )
        for label, mutated in (
            (
                "red after production edit",
                instruction.replace(
                    TDD_EXECUTED_RED,
                    "可以在 production edit 後再執行目前 workflow 命名的 primary verification target",
                    1,
                ),
            ),
            (
                "green on another target",
                instruction.replace(
                    TDD_SAME_TARGET_GREEN,
                    "改跑另一個 verification target",
                    1,
                ),
            ),
            (
                "inferred red evidence",
                instruction.replace(TDD_INVALID_RED, "推測結果即可構成 red", 1),
            ),
            (
                "carrier pinned to tasks.md",
                instruction.replace(
                    TDD_CARRIER_NEUTRAL,
                    "evidence carrier 一定是 tasks.md",
                    1,
                ),
            ),
        ):
            with self.subTest(mutation=label):
                self.assert_rejected(validate_tdd_red_green, mutated, because="missing")

    def test_test_quality_skill_payload_uses_the_canonical_instruction(self) -> None:
        instruction = self.canonical_test_quality()
        payload = skill_payload("test-quality")

        self.assertEqual(set(payload), {"skill", "locale", "instruction"})
        self.assertEqual(payload["skill"], "test-quality")
        self.assertEqual(payload["locale"], LOCALE)
        self.assertEqual(payload["instruction"], instruction)

    def test_test_quality_discipline_covers_each_required_gate(self) -> None:
        instruction = self.canonical_test_quality()

        for meaning, marker in TEST_QUALITY_GATES.items():
            with self.subTest(gate=meaning):
                self.assertIn(marker, instruction)
        for meaning, marker in TEST_QUALITY_BOUNDARIES.items():
            with self.subTest(boundary=meaning):
                self.assertIn(marker, instruction)

    def test_test_quality_discipline_only_governs_edited_tests(self) -> None:
        instruction = self.canonical_test_quality()

        self.assertIn(TEST_QUALITY_SCOPE, instruction)
        self.assertIn("不要求特定程式語言或 test framework", instruction)
        for specific_tool in ("Python", "pytest", "unittest", "Jest", "Vitest"):
            with self.subTest(specific_tool=specific_tool):
                self.assertNotIn(specific_tool, instruction)

    def test_test_quality_gates_reject_removal_and_inversion(self) -> None:
        instruction = self.canonical_test_quality()
        self.assert_accepted(validate_test_quality, instruction)

        removable = (
            *TEST_QUALITY_GATES.values(),
            *TEST_QUALITY_BOUNDARIES.values(),
            TEST_QUALITY_SCOPE,
        )
        for literal in removable:
            with self.subTest(mutation=f"remove {literal}"):
                self.assert_rejected(
                    validate_test_quality,
                    instruction.replace(literal, "removed-gate", 1),
                    because="missing",
                )
        for label, mutated in (
            (
                "expected derived from code under test",
                instruction.replace(
                    TEST_QUALITY_BOUNDARIES["independent expected"],
                    "expected value 可由受測程式或其 helper 推導",
                    1,
                ),
            ),
            (
                "mock existence as result",
                instruction.replace(
                    TEST_QUALITY_BOUNDARIES["observable assertion"],
                    "可以用 mock 自身存在代替結果",
                    1,
                ),
            ),
            (
                "mutation framework required",
                instruction.replace(
                    TEST_QUALITY_BOUNDARIES["bounded mutation check"],
                    "必須新增 mutation framework",
                    1,
                ),
            ),
            (
                "tests demanded for every task",
                instruction.replace(
                    TEST_QUALITY_SCOPE,
                    "每個 task 都必須新增測試",
                    1,
                ),
            ),
        ):
            with self.subTest(mutation=label):
                self.assert_rejected(validate_test_quality, mutated, because="missing")

    def test_tasks_resource_requires_five_field_evidence_contract(self) -> None:
        tasks = artifact_resource("tasks")
        self.assert_accepted(
            validate_tasks_resource, tasks.description, tasks.template
        )

        for field in TASK_EVIDENCE_FIELDS:
            with self.subTest(field=field):
                self.assertIn(field, tasks.description)
        for meaning, marker in TASK_EVIDENCE_RULES.items():
            with self.subTest(rule=meaning):
                self.assertIn(marker, tasks.description)

    def test_tasks_template_keeps_every_field_on_the_checkbox_line(self) -> None:
        template = artifact_resource("tasks").template
        checkbox_lines = [
            line for line in template.splitlines() if line.startswith("- [ ] ")
        ]

        self.assertEqual(len(checkbox_lines), 1)
        for field in TASK_EVIDENCE_FIELDS:
            with self.subTest(field=field):
                self.assertIn(f"{field}: ", checkbox_lines[0])
        self.assertNotIn("TODO", template)

    def test_tasks_resource_rejects_field_removal_and_inversion(self) -> None:
        tasks = artifact_resource("tasks")

        for field in TASK_EVIDENCE_FIELDS:
            with self.subTest(mutation=f"remove field {field}"):
                self.assert_rejected(
                    validate_tasks_resource,
                    tasks.description.replace(field, "removed-field"),
                    tasks.template.replace(f"{field}: ", "removed-field: "),
                    because="missing",
                )
        for label, description in (
            (
                "multiple primary targets",
                tasks.description.replace(
                    TASK_EVIDENCE_RULES["single primary target"],
                    "verification 可以命名多個 target",
                    1,
                ),
            ),
            (
                "success mixes regression evidence",
                tasks.description.replace(
                    TASK_EVIDENCE_RULES["success excludes regression"],
                    "success 可以一併記錄 regression 與 publication 結果",
                    1,
                ),
            ),
            (
                "red left blank",
                tasks.description.replace(
                    TASK_EVIDENCE_RULES["red classification reason"],
                    "red 不適用時可以留空",
                    1,
                ),
            ),
            (
                "placeholders allowed",
                tasks.description.replace(
                    TASK_EVIDENCE_RULES["no placeholder"],
                    "欄位可以留空或填 TBD",
                    1,
                ),
            ),
        ):
            with self.subTest(mutation=label):
                self.assert_rejected(
                    validate_tasks_resource, description, tasks.template,
                    because="missing",
                )

    def test_contradiction_inventories_match_the_fixed_categories(self) -> None:
        for label, detector, fixtures, categories in (
            (
                "TDD",
                TDD_CONTRADICTIONS,
                EXPECTED_TDD_CONTRADICTION_FIXTURES,
                {"carrier-fixed", "unexecuted-red", "red-after-edit"},
            ),
            (
                "test-quality",
                TEST_QUALITY_CONTRADICTIONS,
                EXPECTED_TEST_QUALITY_CONTRADICTION_FIXTURES,
                {
                    "derived-expected",
                    "non-observable-result",
                    "unbounded-mock",
                    "framework-required",
                    "test-for-every-task",
                    "mutation-skippable",
                },
            ),
            (
                "tasks",
                TASKS_CONTRADICTIONS,
                EXPECTED_TASKS_CONTRADICTION_FIXTURES,
                {
                    "multiple-primary",
                    "mixed-success",
                    "blank-red",
                    "placeholder-fields",
                },
            ),
        ):
            with self.subTest(inventory=label):
                self.assertEqual(set(detector), categories)
                self.assertEqual(set(fixtures), categories)
                self.assertEqual(detector, fixtures)

    def test_no_contradiction_literal_matches_its_legitimate_negation(self) -> None:
        detectors = {
            **TDD_CONTRADICTIONS,
            **TEST_QUALITY_CONTRADICTIONS,
            **TASKS_CONTRADICTIONS,
        }
        self.assertEqual(
            set(EXPECTED_NEGATION_RESTATEMENTS),
            {
                "carrier-fixed",
                "unexecuted-red",
                "red-after-edit",
                "derived-expected",
                "non-observable-result",
                "unbounded-mock",
                "framework-required",
                "test-for-every-task",
                "mutation-skippable",
                "multiple-primary",
                "mixed-success",
                "blank-red",
                "placeholder-fields",
            },
        )

        tasks = artifact_resource("tasks")
        canonical_scopes = {
            **dict.fromkeys(
                TDD_CONTRADICTIONS,
                (validate_tdd_red_green, DISCIPLINES["tdd"], (), "TDD"),
            ),
            **dict.fromkeys(
                TEST_QUALITY_CONTRADICTIONS,
                (validate_test_quality, DISCIPLINES["test-quality"], (), "test-quality"),
            ),
            **dict.fromkeys(
                TASKS_CONTRADICTIONS,
                (validate_tasks_resource, tasks.description, (tasks.template,), "tasks"),
            ),
        }
        self.assertEqual(set(NEGATION_PARTICLES), {"不", "並非"})

        for category, negation in EXPECTED_NEGATION_RESTATEMENTS.items():
            with self.subTest(category=category):
                self.assertNotIn(
                    detectors[category],
                    negation,
                    "contradiction literal is still a substring of a legitimate"
                    " negated restatement of the same obligation",
                )
                self.assertTrue(
                    any(
                        f"{detectors[category][:index]}{particle}"
                        f"{detectors[category][index:]}" in negation
                        for index in range(len(detectors[category]) + 1)
                        for particle in NEGATION_PARTICLES
                    ),
                    "negation restatement is not the literal with a single negating"
                    " particle inserted, so it does not restate the same obligation",
                )
                validator, canonical, extra, label = canonical_scopes[category]
                self.assert_rejected(
                    validator,
                    f"{canonical}\n{detectors[category]}。",
                    *extra,
                    because=f"forbidden {label} contradiction: {category}",
                )
                self.assert_accepted(validator, f"{canonical}\n{negation}。", *extra)

    def test_tdd_gates_reject_each_additive_contradiction(self) -> None:
        instruction = DISCIPLINES["tdd"]
        self.assert_accepted(validate_tdd_red_green, instruction)

        for category, contradiction in EXPECTED_TDD_CONTRADICTION_FIXTURES.items():
            with self.subTest(contradiction=category):
                mutated = f"{instruction}\n{contradiction}。"
                self.assert_rejected(
                    validate_tdd_red_green,
                    mutated,
                    because=f"forbidden TDD contradiction: {category}",
                )

    def test_test_quality_gates_reject_each_additive_contradiction(self) -> None:
        instruction = self.canonical_test_quality()
        self.assert_accepted(validate_test_quality, instruction)

        for category, contradiction in EXPECTED_TEST_QUALITY_CONTRADICTION_FIXTURES.items():
            with self.subTest(contradiction=category):
                mutated = f"{instruction}\n{contradiction}。"
                self.assert_rejected(
                    validate_test_quality,
                    mutated,
                    because=f"forbidden test-quality contradiction: {category}",
                )

    def test_tasks_resource_rejects_each_additive_contradiction(self) -> None:
        tasks = artifact_resource("tasks")
        self.assert_accepted(validate_tasks_resource, tasks.description, tasks.template)

        for category, contradiction in EXPECTED_TASKS_CONTRADICTION_FIXTURES.items():
            with self.subTest(contradiction=category):
                mutated = f"{tasks.description}{contradiction}。"
                self.assert_rejected(
                    validate_tasks_resource,
                    mutated,
                    tasks.template,
                    because=f"forbidden tasks contradiction: {category}",
                )

    def test_validators_accept_legitimate_phrasings_with_retired_tokens(self) -> None:
        self.assertEqual(set(RETIRED_PERMISSIVE_TOKENS), {"可以不", "不必", "視情況"})

        for scope, token, phrasing in (
            ("TDD remaining-task", "可以不", LEGITIMATE_TDD_PHRASING),
            ("test-quality no-test scope", "不必", LEGITIMATE_TEST_QUALITY_PHRASING),
            ("tasks manual verification", "視情況", LEGITIMATE_TASKS_PHRASING),
        ):
            with self.subTest(scope=scope):
                self.assertIn(token, phrasing)
        for label, inventory in (
            ("TDD", TDD_CONTRADICTIONS),
            ("test-quality", TEST_QUALITY_CONTRADICTIONS),
            ("tasks", TASKS_CONTRADICTIONS),
        ):
            with self.subTest(inventory=label):
                self.assertEqual(
                    [
                        category
                        for category, contradiction in inventory.items()
                        if contradiction in RETIRED_PERMISSIVE_TOKENS
                    ],
                    [],
                    f"{label} reinstated a retired bare permissive token as a whole contradiction",
                )

        tasks = artifact_resource("tasks")
        self.assert_accepted(
            validate_tdd_red_green,
            f"{DISCIPLINES['tdd']}\n{LEGITIMATE_TDD_PHRASING}",
        )
        self.assert_accepted(
            validate_test_quality,
            f"{self.canonical_test_quality()}\n{LEGITIMATE_TEST_QUALITY_PHRASING}",
        )
        self.assert_accepted(
            validate_tasks_resource,
            tasks.description + LEGITIMATE_TASKS_PHRASING,
            tasks.template,
        )

    def canonical_test_quality(self) -> str:
        self.assertIn(
            "test-quality",
            DISCIPLINES,
            "canonical test-quality discipline contract 尚不存在於 DISCIPLINES",
        )
        return DISCIPLINES["test-quality"]

    def assert_accepted(self, validator, *arguments: str) -> None:
        try:
            validator(*arguments)
        except ValueError as error:
            self.fail(str(error))

    def assert_rejected(self, validator, *arguments: str, because: str) -> None:
        with self.assertRaises(ValueError) as raised:
            validator(*arguments)
        self.assertTrue(
            str(raised.exception).startswith(because),
            f"expected a {because!r} rejection, got: {raised.exception}",
        )


TDD_EXECUTED_RED = (
    "必須在任何 production edit 前實際執行目前 workflow 命名的 primary verification target"
)
TDD_RED_MARKER = "實際觀察到目前 workflow 命名的 failure marker"
TDD_INVALID_RED = "未實際執行、primary target 通過、execution error"
TDD_SAME_TARGET_GREEN = "重跑同一個 primary verification target"
TDD_SUCCESS_MARKER = "觀察到目前 workflow 命名的 success marker"
TDD_RELATED_REGRESSION = "再執行目前 workflow 命名的相關 regression targets"
TDD_CARRIER_NEUTRAL = "evidence carrier 由目前 workflow 命名，本 discipline 不假設任何特定檔案"
TDD_RED_GREEN_CONTRACT = (
    TDD_EXECUTED_RED,
    TDD_RED_MARKER,
    TDD_INVALID_RED,
    TDD_SAME_TARGET_GREEN,
    TDD_SUCCESS_MARKER,
    TDD_RELATED_REGRESSION,
)

TEST_QUALITY_GATES = {
    "named defect": "命名一個會使該測試失敗的 realistic production defect",
    "independent expected": "expected value 以 literal 或手工驗證 fixture 獨立推導",
    "observable assertion": "斷言 consumer-visible output、state、side effect 或 failure mode",
    "mock boundary": "mock 只切 slow 或 external boundary",
    "bounded mutation check": "執行有限 mutation check",
}
TEST_QUALITY_BOUNDARIES = {
    "independent expected": "不得由受測程式、其 helper 或同一套邏輯推導",
    "observable assertion": "不得以 source text、private structure 或 mock 自身存在代替結果",
    "mock boundary": "mock response 必須涵蓋該測試路徑實際消費的完整 contract shape",
    "bounded mutation check": "不要求新增 mutation framework、外部 dependency 或無關 coverage threshold",
}
TEST_QUALITY_SCOPE = (
    "只治理已決定新增或修改的測試，不要求沒有測試需求的 task 為形式而新增測試"
)

TASK_EVIDENCE_FIELDS = ("delivery", "verification", "regression", "success", "red")
TASK_EVIDENCE_RULES = {
    "root-relative delivery": "project-root-relative delivery paths",
    "single primary target": "verification 恰好命名一個 primary",
    "regression fallback reason": "只有 primary target 已涵蓋完整相關範圍時才填 N/A 並附上理由",
    "success excludes regression": "不得混入 regression、publication 或 task completion 結果",
    "red classification reason": "不適用時填 N/A 並指明 pure-refactor 或 remaining-task 分類理由",
    "no placeholder": "五個欄位都不得留空，也不得填 TBD 或 TODO",
}

EXPECTED_TDD_CONTRADICTION_FIXTURES = {
    "carrier-fixed": "evidence carrier 一定是 tasks.md",
    "unexecuted-red": "推測結果即可視為有效 red evidence",
    "red-after-edit": "primary verification target 可以在 production edit 後再執行",
}
EXPECTED_TEST_QUALITY_CONTRADICTION_FIXTURES = {
    "derived-expected": "expected value 可以由受測程式、其 helper 或同一套邏輯推導",
    "non-observable-result": "結果可以用 source text、private structure 或 mock 自身存在代替",
    "unbounded-mock": "mock 可以切任何 internal boundary",
    "framework-required": "有限 mutation check 必須新增 mutation framework",
    "test-for-every-task": "本 discipline 要求每個 task 都必須新增測試",
    "mutation-skippable": "時間不足時可以略過 mutation check",
}
EXPECTED_TASKS_CONTRADICTION_FIXTURES = {
    "multiple-primary": "verification 可以命名多個 primary targets",
    "mixed-success": "success 可以一併記錄 regression、publication 或 task completion 結果",
    "blank-red": "red 不適用時可以留空",
    "placeholder-fields": "欄位可以留空或填 TBD／TODO",
}

EXPECTED_NEGATION_RESTATEMENTS = {
    "carrier-fixed": "evidence carrier 不一定是 tasks.md",
    "unexecuted-red": "推測結果並非即可視為有效 red evidence",
    "red-after-edit": "primary verification target 不可以在 production edit 後再執行",
    "derived-expected": "expected value 不可以由受測程式、其 helper 或同一套邏輯推導",
    "non-observable-result": "結果不可以用 source text、private structure 或 mock 自身存在代替",
    "unbounded-mock": "mock 不可以切任何 internal boundary",
    "framework-required": "有限 mutation check 並非必須新增 mutation framework",
    "test-for-every-task": "本 discipline 不要求每個 task 都必須新增測試",
    "mutation-skippable": "時間不足時不可以略過 mutation check",
    "multiple-primary": "verification 不可以命名多個 primary targets",
    "mixed-success": "success 不可以一併記錄 regression、publication 或 task completion 結果",
    "blank-red": "red 不適用時不可以留空",
    "placeholder-fields": "欄位不可以留空或填 TBD／TODO",
}

NEGATION_PARTICLES = ("不", "並非")
RETIRED_PERMISSIVE_TOKENS = ("可以不", "不必", "視情況")
LEGITIMATE_TDD_PHRASING = (
    "remaining task 可以不建立 red phase，直接執行命名的 verification target。"
)
LEGITIMATE_TEST_QUALITY_PHRASING = (
    "未修改任何測試的 task 不必取得 test-quality instruction。"
)
LEGITIMATE_TASKS_PHRASING = (
    "沒有自動測試邊界時，verification 視情況採用 manual assertion。"
)


TDD_CONTRADICTIONS = {
    "carrier-fixed": "evidence carrier 一定是 tasks.md",
    "unexecuted-red": "推測結果即可視為有效 red evidence",
    "red-after-edit": "primary verification target 可以在 production edit 後再執行",
}
TEST_QUALITY_CONTRADICTIONS = {
    "derived-expected": "expected value 可以由受測程式、其 helper 或同一套邏輯推導",
    "non-observable-result": "結果可以用 source text、private structure 或 mock 自身存在代替",
    "unbounded-mock": "mock 可以切任何 internal boundary",
    "framework-required": "有限 mutation check 必須新增 mutation framework",
    "test-for-every-task": "本 discipline 要求每個 task 都必須新增測試",
    "mutation-skippable": "時間不足時可以略過 mutation check",
}
TASKS_CONTRADICTIONS = {
    "multiple-primary": "verification 可以命名多個 primary targets",
    "mixed-success": "success 可以一併記錄 regression、publication 或 task completion 結果",
    "blank-red": "red 不適用時可以留空",
    "placeholder-fields": "欄位可以留空或填 TBD／TODO",
}


def _require(condition: bool, message: str) -> None:
    if not condition:
        raise ValueError(message)


def _reject_contradictions(text: str, contradictions: dict, label: str) -> None:
    for category, contradiction in contradictions.items():
        _require(
            contradiction not in text,
            f"forbidden {label} contradiction: {category}",
        )


def validate_tdd_red_green(instruction: str) -> None:
    for literal in TDD_RED_GREEN_CONTRACT:
        _require(literal in instruction, f"missing TDD red/green gate: {literal}")
    _require(
        TDD_CARRIER_NEUTRAL in instruction,
        "missing carrier-neutral evidence statement",
    )
    _reject_contradictions(instruction, TDD_CONTRADICTIONS, "TDD")


def validate_test_quality(instruction: str) -> None:
    for meaning, marker in TEST_QUALITY_GATES.items():
        _require(marker in instruction, f"missing test-quality gate: {meaning}")
    for meaning, marker in TEST_QUALITY_BOUNDARIES.items():
        _require(marker in instruction, f"missing test-quality boundary: {meaning}")
    _require(TEST_QUALITY_SCOPE in instruction, "missing test-quality scope bound")
    _reject_contradictions(instruction, TEST_QUALITY_CONTRADICTIONS, "test-quality")


def validate_tasks_resource(description: str, template: str) -> None:
    for field in TASK_EVIDENCE_FIELDS:
        _require(field in description, f"missing task evidence field: {field}")
    for meaning, marker in TASK_EVIDENCE_RULES.items():
        _require(marker in description, f"missing task evidence rule: {meaning}")
    checkbox_lines = [line for line in template.splitlines() if line.startswith("- [ ] ")]
    _require(bool(checkbox_lines), "tasks template has no checkbox task line")
    for line in checkbox_lines:
        for field in TASK_EVIDENCE_FIELDS:
            _require(
                f"{field}: " in line,
                f"tasks template checkbox line omits field: {field}",
            )
    _reject_contradictions(description, TASKS_CONTRADICTIONS, "tasks")

if __name__ == "__main__":
    unittest.main()
