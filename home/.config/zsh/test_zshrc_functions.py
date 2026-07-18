import subprocess
import tempfile
import unittest
from pathlib import Path


FUNCTIONS = Path(__file__).with_name(".zshrc-functions")


class WorktreeHelpersTest(unittest.TestCase):
    def test_configured_worktree_can_be_created_merged_and_removed(self) -> None:
        with tempfile.TemporaryDirectory() as temp:
            source = Path(temp) / "source"
            worktrees = Path(temp) / "worktrees"
            source.mkdir()
            worktrees.mkdir()
            subprocess.run(["git", "init", "-b", "develop", str(source)], check=True)
            subprocess.run(
                ["git", "-C", str(source), "config", "user.name", "Test"], check=True
            )
            subprocess.run(
                ["git", "-C", str(source), "config", "user.email", "test@example.com"],
                check=True,
            )
            subprocess.run(
                ["git", "-C", str(source), "commit", "--allow-empty", "-m", "initial"],
                check=True,
            )

            expected = worktrees / "source--test-1"
            result = subprocess.run(
                [
                    "zsh",
                    "-c",
                    'source "$1"; cd "$2"; unset TMUX; export WT_ROOT="$3"; '
                    "wt-new test-1 >/dev/null; pwd; "
                    "touch reconciled; git add reconciled; git commit -m worktree >/dev/null; "
                    "wt-done >/dev/null; pwd",
                    "test",
                    str(FUNCTIONS),
                    str(source),
                    str(worktrees),
                ],
                check=True,
                capture_output=True,
                text=True,
            )

            self.assertEqual(result.stdout.splitlines(), [str(expected), str(source)])
            self.assertTrue((source / "reconciled").exists())
            self.assertFalse(expected.exists())
            branches = subprocess.run(
                ["git", "-C", str(source), "branch", "--format=%(refname:short)"],
                check=True,
                capture_output=True,
                text=True,
            )
            self.assertEqual(branches.stdout.strip(), "develop")


if __name__ == "__main__":
    unittest.main()
