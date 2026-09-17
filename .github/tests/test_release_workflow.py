import re
import unittest
from pathlib import Path


WORKFLOW = Path(__file__).parents[1] / "workflows" / "discord-release.yml"


def indented_section(text: str, header: str) -> str:
    lines = text.splitlines()
    if header not in lines:
        return ""
    start = lines.index(header)
    indent = len(header) - len(header.lstrip())
    selected = [header]
    for line in lines[start + 1 :]:
        line_indent = len(line) - len(line.lstrip())
        if line.strip() and line_indent <= indent:
            break
        selected.append(line)
    return "\n".join(selected)


class ReleaseWorkflowContractTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.workflow = WORKFLOW.read_text(encoding="utf-8")

    def test_central_workflow_keeps_direct_and_manual_triggers(self):
        event_block = indented_section(self.workflow, "on:")
        self.assertIn("  release:", event_block)
        self.assertIn("    types: [published]", event_block)
        self.assertIn("  workflow_dispatch:", event_block)

    def test_central_workflow_exposes_reusable_interface(self):
        call_block = indented_section(self.workflow, "  workflow_call:")
        self.assertTrue(call_block, "workflow_call trigger is missing")
        self.assertIn("    inputs:", call_block)
        self.assertIn("      ping_role:", call_block)
        self.assertIn("        required: false", call_block)
        self.assertIn("        default: false", call_block)
        self.assertIn("        type: boolean", call_block)
        self.assertIn("    secrets:", call_block)
        self.assertIn("      DISCORD_WEBHOOK_URL:", call_block)
        self.assertIn("        required: true", call_block)

        secrets_block = indented_section(call_block, "    secrets:")
        declared = re.findall(r"(?m)^      ([A-Z][A-Z0-9_]*):$", secrets_block)
        self.assertEqual(declared, ["DISCORD_WEBHOOK_URL"])
        self.assertNotIn("secrets: inherit", self.workflow)

    def test_central_job_remains_least_privilege_and_uses_main_sender(self):
        self.assertIn("permissions:\n  contents: read", self.workflow)
        self.assertIn("ref: ${{ github.event.repository.default_branch }}", self.workflow)
        self.assertIn(
            "DISCORD_WEBHOOK_URL: ${{ secrets.DISCORD_WEBHOOK_URL }}",
            self.workflow,
        )
        self.assertIn("MANUAL_PING_ROLE: ${{ inputs.ping_role }}", self.workflow)


if __name__ == "__main__":
    unittest.main()
