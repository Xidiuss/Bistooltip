import sys
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parents[1] / "scripts"))
import discord_release as sender


class FormatterTests(unittest.TestCase):
    def release(self, **overrides):
        release = {
            "name": "Core 3.1.0",
            "tag_name": "core-v3.1.0",
            "html_url": "https://github.com/Xidiuss/Bistooltip/releases/tag/core-v3.1.0",
            "body": "Release notes",
            "target_commitish": "main",
        }
        release.update(overrides)
        return {"release": release, "repository": {"default_branch": "main"}}

    def test_tag_prefixes_are_authoritative(self):
        cases = {
            "core-v3.1.0": "BiSTooltip Core",
            "scanner-v1.0.0": "BiSTooltip Scanner",
            "wotlk5-s2-v1.0.0": "BiSTooltip WOTLK5 S2",
            "whitemane-frostmourne-v1.0.0": "BiSTooltip Whitemane Frostmourne",
        }
        for tag, expected in cases.items():
            with self.subTest(tag=tag):
                self.assertEqual(sender.component_name(tag, "maintenance"), expected)

    def test_branch_mapping_and_unknown_fallback(self):
        self.assertEqual(sender.component_name("v1", "Bistooltip_Scanner"), "BiSTooltip Scanner")
        self.assertEqual(sender.component_name("v1", "hotfix-x"), "BiSTooltip (hotfix-x)")

    def test_release_payload_pings_only_updates_role(self):
        note = sender.notification_from_event("release", self.release(), False, "unused")
        payload = sender.build_payload(note, "1545592862920671252")
        self.assertEqual(payload["content"], "<@&1545592862920671252>")
        self.assertEqual(payload["allowed_mentions"], {"roles": ["1545592862920671252"]})
        self.assertIn("BiSTooltip Core", payload["embeds"][0]["title"])
        self.assertEqual(payload["embeds"][0]["fields"][1]["value"], "main")

    def test_manual_payload_is_labelled_and_silent_by_default(self):
        event = {"repository": {"default_branch": "main"}}
        note = sender.notification_from_event("workflow_dispatch", event, False, "https://github/run/1")
        payload = sender.build_payload(note, "1545592862920671252")
        self.assertIn("Manual delivery test", payload["embeds"][0]["title"])
        self.assertEqual(payload["content"], "")
        self.assertEqual(payload["allowed_mentions"], {"parse": []})

    def test_manual_payload_can_ping_explicitly(self):
        event = {"repository": {"default_branch": "main"}}
        note = sender.notification_from_event("workflow_dispatch", event, True, "https://github/run/1")
        payload = sender.build_payload(note, "1545592862920671252")
        self.assertEqual(payload["allowed_mentions"]["roles"], ["1545592862920671252"])

    def test_empty_and_long_release_notes_stay_within_discord_limits(self):
        empty = sender.notification_from_event("release", self.release(body=""), False, "unused")
        self.assertIn("No release notes", sender.build_payload(empty, "1545592862920671252")["embeds"][0]["description"])
        long_note = sender.notification_from_event("release", self.release(body="x" * 10000), False, "unused")
        payload = sender.build_payload(long_note, "1545592862920671252")
        sender.validate_payload(payload)
        self.assertLessEqual(len(payload["embeds"][0]["description"]), 4096)
        self.assertLessEqual(sender.embed_character_count(payload["embeds"][0]), 6000)

    def test_missing_release_field_and_unknown_event_fail_clearly(self):
        with self.assertRaisesRegex(ValueError, "tag_name"):
            sender.notification_from_event("release", self.release(tag_name=""), False, "unused")
        with self.assertRaisesRegex(ValueError, "Unsupported GitHub event"):
            sender.notification_from_event("push", {}, False, "unused")


if __name__ == "__main__":
    unittest.main()
