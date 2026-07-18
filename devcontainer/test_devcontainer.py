import json
import unittest
from pathlib import Path


class DevcontainerConfigTest(unittest.TestCase):
    def test_configures_persistent_worktree_storage(self) -> None:
        config = json.loads(
            (Path(__file__).with_name("devcontainer.json")).read_text(encoding="utf-8")
        )

        self.assertIn(
            "source=${localWorkspaceFolderBasename}-worktrees,target=/worktrees,type=volume",
            config["mounts"],
        )
        self.assertEqual(config["containerEnv"]["WT_ROOT"], "/worktrees")


if __name__ == "__main__":
    unittest.main()
