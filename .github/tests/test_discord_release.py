import contextlib
import io
import json
import os
import runpy
import sys
import tempfile
import unittest
import unittest.mock
import urllib.error
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
        cases = {
            "main": "BiSTooltip Core",
            "Bistooltip_Scanner": "BiSTooltip Scanner",
            "Bistooltip_WOTLK5_S2": "BiSTooltip WOTLK5 S2",
            "Bistooltip_Whitemane_Frostmourne": "BiSTooltip Whitemane Frostmourne",
        }
        for branch, expected in cases.items():
            with self.subTest(branch=branch):
                self.assertEqual(sender.component_name("v1", branch), expected)
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
        self.assertLessEqual(len(payload["embeds"][0]["description"]), 3500)
        self.assertLessEqual(len(payload["embeds"][0]["description"]), 4096)
        self.assertLessEqual(sender.embed_character_count(payload["embeds"][0]), 6000)

    def test_payload_uses_intended_icons_and_ellipsis(self):
        note = sender.notification_from_event("release", self.release(), False, "unused")
        payload = sender.build_payload(note, sender.ROLE_ID)
        embed = payload["embeds"][0]
        self.assertEqual(embed["title"], "\U0001F4E6 BiSTooltip Core: Core 3.1.0")
        self.assertEqual(embed["fields"][0]["name"], "\U0001F3F7\uFE0F Version")
        self.assertEqual(embed["fields"][1]["name"], "\U0001F3AF Target")
        self.assertEqual(embed["fields"][2]["name"], "\U0001F517 Download")
        self.assertEqual(
            embed["footer"]["text"], "BiSTooltip - WotLK \u2022 GitHub Release"
        )
        self.assertEqual(sender.clip("abcd", 1), "\u2026")

    def test_clip_stays_within_nonpositive_and_small_limits(self):
        cases = {
            -3: "",
            0: "",
            1: "\u2026",
            2: "a\u2026",
        }
        for limit, expected in cases.items():
            with self.subTest(limit=limit):
                clipped = sender.clip("abcd", limit)
                self.assertEqual(clipped, expected)
                self.assertLessEqual(len(clipped), max(limit, 0))

    def test_validate_payload_rejects_another_role_id(self):
        note = sender.notification_from_event("release", self.release(), False, "unused")
        payload = sender.build_payload(note, "999")
        with self.assertRaises(ValueError):
            sender.validate_payload(payload)

    def test_validate_payload_rejects_pinging_payload_with_parse_enabled(self):
        note = sender.notification_from_event("release", self.release(), False, "unused")
        payload = sender.build_payload(note, sender.ROLE_ID)
        payload["allowed_mentions"] = {"parse": ["roles"]}
        with self.assertRaises(ValueError):
            sender.validate_payload(payload)

    def test_missing_release_field_and_unknown_event_fail_clearly(self):
        with self.assertRaisesRegex(ValueError, "tag_name"):
            sender.notification_from_event("release", self.release(tag_name=""), False, "unused")
        with self.assertRaisesRegex(ValueError, "Unsupported GitHub event"):
            sender.notification_from_event("push", {}, False, "unused")


class RuntimeTests(unittest.TestCase):
    def test_validate_config_rejects_missing_secret_and_bad_role(self):
        self.assertTrue(
            callable(getattr(sender, "validate_config", None)),
            "validate_config must be implemented",
        )
        with self.assertRaisesRegex(ValueError, "DISCORD_WEBHOOK_URL"):
            sender.validate_config("", sender.ROLE_ID)
        with self.assertRaisesRegex(ValueError, "role ID"):
            sender.validate_config("https://discord.com/api/webhooks/1/token", "BiSTooltip Updates")

    def test_http_error_is_bounded_and_never_exposes_webhook_url(self):
        self.assertTrue(
            callable(getattr(sender, "send_webhook", None)),
            "send_webhook must be implemented",
        )
        secret = "https://discord.com/api/webhooks/123/SECRET_TOKEN"
        error = sender.urllib.error.HTTPError(secret, 401, "Unauthorized", {}, None)
        with unittest.mock.patch.object(sender.urllib.request, "urlopen", side_effect=error):
            with self.assertRaises(RuntimeError) as raised:
                sender.send_webhook(secret, {"content": "test"}, timeout=10)
        self.assertIn("HTTP 401", str(raised.exception))
        self.assertNotIn("SECRET_TOKEN", str(raised.exception))

    def test_http_error_redacts_query_bearing_url_and_bare_token(self):
        secret = "https://discord.com/api/webhooks/123/SECRET_TOKEN?wait=true"
        error = sender.urllib.error.HTTPError(secret, 401, "Unauthorized", {}, None)
        error.read = unittest.mock.MagicMock(
            return_value=(f"delivery failed: {secret}; token=SECRET_TOKEN").encode()
        )
        with unittest.mock.patch.object(sender.urllib.request, "urlopen", side_effect=error):
            with self.assertRaises(RuntimeError) as raised:
                sender.send_webhook(secret, {"content": "test"}, timeout=10)
        self.assertIn("HTTP 401", str(raised.exception))
        self.assertNotIn(secret, str(raised.exception))
        self.assertNotIn("SECRET_TOKEN", str(raised.exception))
        self.assertIn("[redacted]", str(raised.exception))

    def test_success_writes_status_without_secret(self):
        self.assertTrue(
            callable(getattr(sender, "send_webhook", None)),
            "send_webhook must be implemented",
        )
        response = unittest.mock.MagicMock()
        response.status = 204
        response.__enter__.return_value = response
        response.__exit__.return_value = False
        with unittest.mock.patch.object(sender.urllib.request, "urlopen", return_value=response):
            self.assertEqual(sender.send_webhook("https://discord.com/api/webhooks/1/token", {"content": "test"}), 204)

    def test_summary_contains_delivery_metadata_only(self):
        self.assertTrue(
            callable(getattr(sender, "write_summary", None)),
            "write_summary must be implemented",
        )
        note = sender.notification_from_event(
            "workflow_dispatch",
            {"repository": {"default_branch": "main"}},
            False,
            "https://github/run/1",
        )
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / "summary.md"
            sender.write_summary(path, note, 204)
            summary = path.read_text(encoding="utf-8")
        self.assertIn("BiSTooltip Test", summary)
        self.assertIn("manual-test", summary)
        self.assertIn("main", summary)
        self.assertIn("204", summary)
        self.assertNotIn("webhooks", summary)

    def test_main_rejects_invalid_config_before_http(self):
        self.assertTrue(callable(getattr(sender, "main", None)), "main must be implemented")
        environment = {
            "DISCORD_WEBHOOK_URL": "not-a-webhook",
            "BISTOOLTIP_UPDATES_ROLE_ID": sender.ROLE_ID,
        }
        errors = io.StringIO()
        with unittest.mock.patch.dict(os.environ, environment, clear=True):
            with unittest.mock.patch.object(sender.urllib.request, "urlopen") as urlopen:
                with contextlib.redirect_stderr(errors):
                    self.assertEqual(sender.main(), 1)
        urlopen.assert_not_called()
        self.assertIn("::error::", errors.getvalue())
        self.assertNotIn("not-a-webhook", errors.getvalue())

    def test_main_rejects_alternate_valid_role_id_before_http(self):
        alternate_role_id = "1545592862920671253"
        environment = {
            "DISCORD_WEBHOOK_URL": "https://discord.com/api/webhooks/1/SECRET_TOKEN",
            "BISTOOLTIP_UPDATES_ROLE_ID": alternate_role_id,
        }
        errors = io.StringIO()
        with unittest.mock.patch.dict(os.environ, environment, clear=True):
            with unittest.mock.patch.object(sender.urllib.request, "urlopen") as urlopen:
                with contextlib.redirect_stderr(errors):
                    self.assertEqual(sender.main(), 1)
        urlopen.assert_not_called()
        self.assertIn("role ID", errors.getvalue())
        self.assertNotIn(alternate_role_id, errors.getvalue())

    def test_main_delivers_once_and_writes_summary(self):
        self.assertTrue(callable(getattr(sender, "main", None)), "main must be implemented")
        response = unittest.mock.MagicMock()
        response.status = 204
        response.__enter__.return_value = response
        response.__exit__.return_value = False
        with tempfile.TemporaryDirectory() as directory:
            event_path = Path(directory) / "event.json"
            summary_path = Path(directory) / "summary.md"
            event_path.write_text(
                '{"repository": {"default_branch": "main"}}', encoding="utf-8"
            )
            environment = {
                "DISCORD_WEBHOOK_URL": "https://discord.com/api/webhooks/1/SECRET_TOKEN",
                "BISTOOLTIP_UPDATES_ROLE_ID": sender.ROLE_ID,
                "GITHUB_EVENT_NAME": "workflow_dispatch",
                "GITHUB_EVENT_PATH": str(event_path),
                "GITHUB_SERVER_URL": "https://github.com",
                "GITHUB_REPOSITORY": "Xidiuss/Bistooltip",
                "GITHUB_RUN_ID": "1",
                "GITHUB_STEP_SUMMARY": str(summary_path),
                "MANUAL_PING_ROLE": "yes",
            }
            output = io.StringIO()
            with unittest.mock.patch.dict(os.environ, environment, clear=True):
                with unittest.mock.patch.object(sender.urllib.request, "urlopen", return_value=response) as urlopen:
                    with contextlib.redirect_stdout(output):
                        self.assertEqual(sender.main(), 0)
            summary = summary_path.read_text(encoding="utf-8")
        self.assertEqual(urlopen.call_count, 1)
        self.assertIn("BiSTooltip Test", summary)
        self.assertIn("204", summary)
        self.assertIn("BiSTooltip Test", output.getvalue())
        self.assertIn("manual-test", output.getvalue())
        self.assertIn("204", output.getvalue())
        self.assertNotIn("SECRET_TOKEN", output.getvalue())

    def test_main_rejects_invalid_built_payload_before_http(self):
        environment = {
            "DISCORD_WEBHOOK_URL": "https://discord.com/api/webhooks/1/SECRET_TOKEN",
            "BISTOOLTIP_UPDATES_ROLE_ID": sender.ROLE_ID,
            "GITHUB_EVENT_NAME": "workflow_dispatch",
            "GITHUB_SERVER_URL": "https://github.com",
            "GITHUB_REPOSITORY": "Xidiuss/Bistooltip",
            "GITHUB_RUN_ID": "1",
        }
        with tempfile.TemporaryDirectory() as directory:
            event_path = Path(directory) / "event.json"
            event_path.write_text(
                json.dumps({"repository": {"default_branch": "main"}}), encoding="utf-8"
            )
            environment["GITHUB_EVENT_PATH"] = str(event_path)
            errors = io.StringIO()
            with unittest.mock.patch.dict(os.environ, environment, clear=True):
                with unittest.mock.patch.object(
                    sender, "build_payload", return_value={"content": "unsafe"}
                ):
                    with unittest.mock.patch.object(sender.urllib.request, "urlopen") as urlopen:
                        with contextlib.redirect_stderr(errors):
                            self.assertEqual(sender.main(), 1)
            urlopen.assert_not_called()
        self.assertIn("::error::", errors.getvalue())

    def test_direct_script_execution_defines_helpers_before_main(self):
        response = unittest.mock.MagicMock()
        response.status = 204
        response.__enter__.return_value = response
        response.__exit__.return_value = False
        script_path = Path(__file__).parents[1] / "scripts" / "discord_release.py"
        with tempfile.TemporaryDirectory() as directory:
            event_path = Path(directory) / "event.json"
            summary_path = Path(directory) / "summary.md"
            event_path.write_text(
                json.dumps({"repository": {"default_branch": "main"}}), encoding="utf-8"
            )
            environment = {
                "DISCORD_WEBHOOK_URL": "https://discord.com/api/webhooks/1/SECRET_TOKEN",
                "BISTOOLTIP_UPDATES_ROLE_ID": sender.ROLE_ID,
                "GITHUB_EVENT_NAME": "workflow_dispatch",
                "GITHUB_EVENT_PATH": str(event_path),
                "GITHUB_SERVER_URL": "https://github.com",
                "GITHUB_REPOSITORY": "Xidiuss/Bistooltip",
                "GITHUB_RUN_ID": "1",
                "GITHUB_STEP_SUMMARY": str(summary_path),
            }
            with unittest.mock.patch.dict(os.environ, environment, clear=True):
                with unittest.mock.patch.object(sender.urllib.request, "urlopen", return_value=response) as urlopen:
                    with self.assertRaises(SystemExit) as exited:
                        runpy.run_path(str(script_path), run_name="__main__")
            self.assertEqual(exited.exception.code, 0)
            self.assertIn("BiSTooltip Test", summary_path.read_text(encoding="utf-8"))
        self.assertEqual(urlopen.call_count, 1)


if __name__ == "__main__":
    unittest.main()
