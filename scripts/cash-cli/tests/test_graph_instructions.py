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
        self.assertEqual(set(DISCIPLINES), {"tdd", "audit"})
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


if __name__ == "__main__":
    unittest.main()
