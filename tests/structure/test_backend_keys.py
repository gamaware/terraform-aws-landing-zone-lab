"""Every deployable root keeps its own state: the backend key must match the
root's path and appear in no other root."""

import re
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
KEY = re.compile(r'^\s*key\s*=\s*"([^"]+)"', re.MULTILINE)


def backend_keys():
    keys = {}
    for versions in sorted(ROOT.glob("environments/*/*/*/versions.tf")):
        stack_dir = versions.parent.relative_to(ROOT / "environments")
        found = KEY.findall(versions.read_text())
        keys[stack_dir.as_posix()] = found
    return keys


class BackendKeyTest(unittest.TestCase):
    def test_roots_exist(self):
        self.assertGreater(len(backend_keys()), 0)

    def test_each_root_sets_one_key_derived_from_its_path(self):
        for stack, found in backend_keys().items():
            with self.subTest(stack=stack):
                self.assertEqual(found, [f"{stack}/terraform.tfstate"])

    def test_keys_are_unique(self):
        all_keys = [key for found in backend_keys().values() for key in found]
        self.assertEqual(len(all_keys), len(set(all_keys)))


if __name__ == "__main__":
    unittest.main()
