import unittest

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
        self.assertIn("Red-Green-Refactor", DISCIPLINES["tdd"])
        self.assertIn("Scoundrel", DISCIPLINES["audit"])
        for text in (APPLY_INSTRUCTION, *DISCIPLINES.values()):
            self.assertNotIn("spectra", text.lower())


if __name__ == "__main__":
    unittest.main()
