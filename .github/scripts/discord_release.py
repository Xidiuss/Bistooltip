"""Pure formatting helpers for Discord release notifications."""

from dataclasses import dataclass


ROLE_ID = "1545592862920671252"
DESCRIPTION_LIMIT = 3500
PREFIX_COMPONENTS = (
    ("whitemane-frostmourne-v", "BiSTooltip Whitemane Frostmourne"),
    ("wotlk5-s2-v", "BiSTooltip WOTLK5 S2"),
    ("scanner-v", "BiSTooltip Scanner"),
    ("core-v", "BiSTooltip Core"),
)
BRANCH_COMPONENTS = {
    "main": "BiSTooltip Core",
    "Bistooltip_Scanner": "BiSTooltip Scanner",
    "Bistooltip_WOTLK5_S2": "BiSTooltip WOTLK5 S2",
    "Bistooltip_Whitemane_Frostmourne": "BiSTooltip Whitemane Frostmourne",
}


@dataclass(frozen=True)
class Notification:
    component: str
    name: str
    tag: str
    url: str
    body: str
    target: str
    is_test: bool
    ping_role: bool


def component_name(tag: str, target: str) -> str:
    for prefix, display_name in PREFIX_COMPONENTS:
        if tag.startswith(prefix):
            return display_name
    return BRANCH_COMPONENTS.get(target, f"BiSTooltip ({target})")


def required_string(source: dict, key: str) -> str:
    value = source.get(key)
    if not isinstance(value, str) or not value.strip():
        raise ValueError(f"GitHub Release is missing required field: {key}")
    return value.strip()


def notification_from_event(
    event_name: str, event: dict, manual_ping: bool, run_url: str
) -> Notification:
    if event_name == "release":
        release = event.get("release")
        if not isinstance(release, dict):
            raise ValueError("GitHub Release event is missing the release object.")
        tag = required_string(release, "tag_name")
        url = required_string(release, "html_url")
        target = required_string(release, "target_commitish")
        name = str(release.get("name") or tag).strip()
        body = str(release.get("body") or "").strip() or "No release notes were provided."
        return Notification(
            component_name(tag, target), name, tag, url, body, target, False, True
        )
    if event_name == "workflow_dispatch":
        target = str(event.get("repository", {}).get("default_branch") or "main")
        return Notification(
            "BiSTooltip Test",
            "Manual delivery test",
            "manual-test",
            run_url,
            "This is a manual GitHub Actions delivery test; no Release was published.",
            target,
            True,
            manual_ping,
        )
    raise ValueError(f"Unsupported GitHub event: {event_name}")


def clip(value: str, limit: int) -> str:
    suffix = "\u0102\u02d8\u00e2\u201a\u00ac\u00c2\u00a6"
    return value if len(value) <= limit else value[: limit - len(suffix)].rstrip() + suffix


def build_payload(notification: Notification, role_id: str) -> dict:
    return {
        "username": "BiSTooltip Releases",
        "content": f"<@&{role_id}>" if notification.ping_role else "",
        "allowed_mentions": (
            {"roles": [role_id]} if notification.ping_role else {"parse": []}
        ),
        "embeds": [{
            "title": clip(f"\u00c4\u2018\u0139\u015f\u0139\u02c7\u00e2\u201a\u00ac {notification.component}: {notification.name}", 256),
            "url": notification.url,
            "description": clip(notification.body, DESCRIPTION_LIMIT),
            "fields": [
                {"name": "\u00c4\u2018\u0139\u015f\u00e2\u20ac\u015b\u00c2\u00a6 Version", "value": f"`{clip(notification.tag, 100)}`", "inline": True},
                {"name": "\u00c4\u2018\u0139\u015f\u0139\u0161\u0139\u013d Target", "value": clip(notification.target, 100), "inline": True},
                {"name": "\u0102\u02d8\u00c2\u00ac\u00e2\u20ac\u02c7\u00c4\u0179\u00c2\u00b8\u0139\u0105 Download", "value": f"[Open GitHub Release]({clip(notification.url, 900)})", "inline": False},
            ],
            "footer": {"text": "BiSTooltip - WotLK \u0102\u02d8\u00e2\u201a\u00ac\u00cb\u0098 GitHub Release"},
        }],
    }


def embed_character_count(embed: dict) -> int:
    total = len(embed.get("title", "")) + len(embed.get("description", ""))
    total += len(embed.get("author", {}).get("name", ""))
    total += len(embed.get("footer", {}).get("text", ""))
    return total + sum(
        len(field["name"]) + len(field["value"]) for field in embed.get("fields", [])
    )


def validate_payload(payload: dict) -> None:
    content = payload.get("content")
    allowed_mentions = payload.get("allowed_mentions")
    if content:
        if (
            content != f"<@&{ROLE_ID}>"
            or allowed_mentions != {"roles": [ROLE_ID]}
        ):
            raise ValueError("Pinging payload must allow only its one role mention.")
    elif content != "" or allowed_mentions != {"parse": []}:
        raise ValueError("Silent payload must have empty content and disable mention parsing.")

    embeds = payload.get("embeds")
    if not isinstance(embeds, list):
        raise ValueError("Payload embeds must be a list.")
    for embed in embeds:
        if not isinstance(embed, dict):
            raise ValueError("Each embed must be an object.")
        if len(embed.get("title", "")) > 256:
            raise ValueError("Embed title exceeds Discord's 256-character limit.")
        if len(embed.get("description", "")) > 4096:
            raise ValueError("Embed description exceeds Discord's 4096-character limit.")
        fields = embed.get("fields", [])
        if not isinstance(fields, list) or len(fields) > 25:
            raise ValueError("Embed has too many fields.")
        for field in fields:
            if len(field.get("name", "")) > 256:
                raise ValueError("Embed field name exceeds Discord's 256-character limit.")
            if len(field.get("value", "")) > 1024:
                raise ValueError("Embed field value exceeds Discord's 1024-character limit.")
        footer = embed.get("footer", {})
        if not isinstance(footer, dict) or len(footer.get("text", "")) > 2048:
            raise ValueError("Embed footer exceeds Discord's 2048-character limit.")
        if embed_character_count(embed) > 6000:
            raise ValueError("Embed exceeds Discord's 6000-character aggregate limit.")
