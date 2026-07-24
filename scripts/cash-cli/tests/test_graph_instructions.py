import unittest

from cash_cli.resources import (
    APPLY_INSTRUCTION,
    ARTIFACT_GRAPH,
    DISCIPLINES,
    LOCALE,
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
