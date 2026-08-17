#!/usr/bin/env python3
"""Validate the CameraSync constructor contract in robot configurations."""

from pathlib import Path
import sys

import yaml


REPO_ROOT = Path(__file__).resolve().parents[1]
CONFIG_ROOT = REPO_ROOT / "User" / "RobotConfig"
EXPECTED_PERIOD_US = {
    "User/RobotConfig/omni_infantry_3.yaml": 10_000,
    "User/RobotConfig/omni_infantry_4.yaml": 10_000,
    "User/RobotConfig/pi_sync_bench.yaml": 50_000,
}


def main() -> int:
    errors: list[str] = []
    found: set[str] = set()

    for config_path in sorted(CONFIG_ROOT.glob("*.yaml")):
        relative_path = config_path.relative_to(REPO_ROOT).as_posix()
        try:
            config = yaml.safe_load(config_path.read_text(encoding="utf-8"))
        except (OSError, yaml.YAMLError) as exc:
            errors.append(f"{relative_path}: cannot parse YAML: {exc}")
            continue

        modules = config.get("modules", []) if isinstance(config, dict) else []
        if not isinstance(modules, list):
            errors.append(f"{relative_path}: modules must be a list")
            continue

        for index, module in enumerate(modules):
            if not isinstance(module, dict) or module.get("name") != "CameraSync":
                continue

            location = f"{relative_path}: modules[{index}]"
            if relative_path in found:
                errors.append(f"{location}: duplicate CameraSync instance")
            found.add(relative_path)

            constructor_args = module.get("constructor_args")
            if not isinstance(constructor_args, dict):
                errors.append(f"{location}: constructor_args must be a mapping")
                continue

            if "trigger_div" in constructor_args:
                errors.append(
                    f"{location}: trigger_div is obsolete; use trigger_period_us"
                )

            period_us = constructor_args.get("trigger_period_us")
            if (
                isinstance(period_us, bool)
                or not isinstance(period_us, int)
                or period_us <= 0
            ):
                errors.append(
                    f"{location}: trigger_period_us must be a positive integer"
                )
                continue

            expected_period_us = EXPECTED_PERIOD_US.get(relative_path)
            if expected_period_us is None:
                errors.append(
                    f"{location}: register the expected trigger period in "
                    "tools/check_camera_sync_configs.py"
                )
            elif period_us != expected_period_us:
                errors.append(
                    f"{location}: trigger_period_us={period_us}, expected "
                    f"{expected_period_us}"
                )

    for relative_path in sorted(EXPECTED_PERIOD_US.keys() - found):
        errors.append(f"{relative_path}: expected CameraSync instance not found")

    if errors:
        print("CameraSync config contract: FAIL", file=sys.stderr)
        for error in errors:
            print(f"- {error}", file=sys.stderr)
        return 1

    print(f"CameraSync config contract: PASS ({len(found)} instances)")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
