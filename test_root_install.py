import os
import subprocess
import tempfile
import unittest
from pathlib import Path


class RootInstallTest(unittest.TestCase):
    def setUp(self) -> None:
        self.install_script = Path(__file__).with_name("install.sh").resolve()
        self.nvim_source_dir = self.install_script.parent / "home/.config/nvim"
        self.ghostty_source_dir = self.install_script.parent / "home/.config/ghostty"
        self.starship_source_file = (
            self.install_script.parent / "home/.config/starship.toml"
        )

    def test_installs_when_invoked_outside_repository(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            temp_path = Path(temp_dir)
            home = temp_path / "home"
            home.mkdir()
            env = os.environ.copy()
            env["HOME"] = str(home)

            subprocess.run(
                ["bash", str(self.install_script)],
                check=True,
                cwd=temp_path,
                env=env,
                capture_output=True,
                text=True,
            )

            self.assertEqual(
                (home / ".config/nvim").resolve(), self.nvim_source_dir
            )
            self.assertEqual(
                (home / ".config/ghostty").resolve(), self.ghostty_source_dir
            )
            self.assertEqual(
                (home / ".config/starship.toml").resolve(),
                self.starship_source_file,
            )

    def test_rerun_keeps_existing_link_without_creating_backup(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            home = Path(temp_dir) / "home"
            home.mkdir()
            env = os.environ.copy()
            env["HOME"] = str(home)

            for _ in range(2):
                subprocess.run(
                    ["bash", str(self.install_script)],
                    check=True,
                    cwd=self.install_script.parent,
                    env=env,
                    capture_output=True,
                    text=True,
                )

            self.assertEqual(
                (home / ".config/nvim").resolve(), self.nvim_source_dir
            )
            self.assertEqual(
                (home / ".config/ghostty").resolve(), self.ghostty_source_dir
            )
            self.assertEqual(
                (home / ".config/starship.toml").resolve(),
                self.starship_source_file,
            )
            self.assertFalse((home / ".config/nvim.bk").exists())
            self.assertFalse((home / ".config/ghostty.bk").exists())
            self.assertFalse((home / ".config/starship.toml.bk").exists())


if __name__ == "__main__":
    unittest.main()
