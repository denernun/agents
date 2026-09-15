from pathlib import Path
import unittest


ROOT = Path(__file__).parents[2]
TEMPLATES = ROOT / "templates" / "agents"
MARKER = "## Eficiência de execução"


class AgentTemplateTests(unittest.TestCase):
    def test_templates_include_safe_efficiency_policy(self):
        templates = sorted(TEMPLATES.glob("*.md"))
        self.assertTrue(templates, "No AGENTS templates found")

        for template in templates:
            content = template.read_text(encoding="utf-8")
            self.assertIn(MARKER, content, template.name)
            self.assertIn("Nunca economize em segurança", content, template.name)

    def test_rendered_templates_remain_below_always_on_budget(self):
        for template in TEMPLATES.glob("*.md"):
            rendered = template.read_text(encoding="utf-8").replace(
                "{{PROJECT}}", "sample-project"
            )
            self.assertLess(
                len(rendered.encode("utf-8")),
                2 * 1024,
                f"{template.name} exceeds the 2 KB always-on budget",
            )


if __name__ == "__main__":
    unittest.main()
