from __future__ import annotations

import argparse
from typing import Any

from firebase_admin import messaging

from services.firebase import db


DEVICE_COLLECTION = "notification_devices"


def _stringify_data(data: dict[str, Any]) -> dict[str, str]:
    payload: dict[str, str] = {}
    for key, value in data.items():
        if value is not None:
            payload[key] = str(value)
    return payload


def _get_android_tokens(role: str | None = None) -> list[str]:
    query = (
        db.collection(DEVICE_COLLECTION)
        .where("platform", "==", "android")
        .where("is_active", "==", True)
    )
    if role:
        query = query.where("role", "==", role.upper())

    tokens: list[str] = []
    seen: set[str] = set()
    for doc in query.stream():
        data = doc.to_dict() or {}
        token = data.get("fcm_token")
        if not isinstance(token, str):
            continue
        normalized = token.strip()
        if not normalized or normalized in seen:
            continue
        seen.add(normalized)
        tokens.append(normalized)
    return tokens


def broadcast_android(title: str, body: str, role: str | None = None) -> None:
    tokens = _get_android_tokens(role=role)
    print(f"Found {len(tokens)} active Android token(s)")
    if role:
        print(f"Role filter: {role.upper()}")
    if not tokens:
        return

    total_success = 0
    total_failure = 0
    data = _stringify_data(
        {
            "type": "TEST_NOTIFICATION",
            "target_platform": "android",
            "target_role": role.upper() if role else "ALL",
        }
    )

    for start in range(0, len(tokens), 500):
        token_chunk = tokens[start:start + 500]
        response = messaging.send_each_for_multicast(
            messaging.MulticastMessage(
                tokens=token_chunk,
                notification=messaging.Notification(title=title, body=body),
                data=data,
                android=messaging.AndroidConfig(
                    priority="high",
                    notification=messaging.AndroidNotification(
                        channel_id="high_importance_channel",
                    ),
                ),
            )
        )
        total_success += response.success_count
        total_failure += response.failure_count

        for idx, send_response in enumerate(response.responses):
            if send_response.success:
                continue
            print(f"Failed token index {start + idx}: {send_response.exception}")

    print(f"Success: {total_success}")
    print(f"Failure: {total_failure}")


def main() -> None:
    parser = argparse.ArgumentParser(description="Send a test FCM notification to Android devices.")
    parser.add_argument("--title", default="Test notification")
    parser.add_argument("--body", default="Hello Android from backend FCM")
    parser.add_argument(
        "--role",
        choices=["DOCTOR", "NURSE", "doctor", "nurse"],
        help="Optional role filter. Omit to send to all active Android app tokens.",
    )
    args = parser.parse_args()

    broadcast_android(title=args.title, body=args.body, role=args.role)


if __name__ == "__main__":
    main()
