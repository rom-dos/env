import subprocess
import tempfile
import unittest
from pathlib import Path
from unittest.mock import patch

import post_install


class InstallTmuxPluginsTest(unittest.TestCase):
    def test_runs_tpm_plugin_installer(self) -> None:
        with tempfile.TemporaryDirectory() as home:
            installer = Path(home) / ".tmux/plugins/tpm/bin/install_plugins"
            installer.parent.mkdir(parents=True)
            installer.touch()

            with (
                patch.object(Path, "home", return_value=Path(home)),
                patch.object(subprocess, "run") as run,
            ):
                post_install.install_tmux_plugins()

            run.assert_called_once_with([str(installer)], check=True)

    def test_main_installs_tmux_plugins(self) -> None:
        with (
            patch.object(post_install, "install_tmux_config"),
            patch.object(post_install, "install_tmux_plugins") as install_plugins,
            patch.object(post_install, "install_nvim_plugins"),
            patch.object(post_install, "ensure_dir_ownership"),
            patch.object(post_install, "ensure_claude_config"),
            patch.object(post_install, "ensure_zsh_config"),
        ):
            post_install.main()

        install_plugins.assert_called_once_with()


class InstallNvimPluginsTest(unittest.TestCase):
    def test_runs_lazy_sync_headlessly(self) -> None:
        with patch.object(subprocess, "run") as run:
            post_install.install_nvim_plugins()

        run.assert_called_once_with(
            ["nvim", "--headless", "+Lazy! sync", "+qa"], check=True
        )

    def test_main_installs_nvim_plugins_after_tmux_plugins(self) -> None:
        calls: list[str] = []
        with (
            patch.object(post_install, "install_tmux_config"),
            patch.object(
                post_install,
                "install_tmux_plugins",
                side_effect=lambda: calls.append("tmux"),
            ),
            patch.object(
                post_install,
                "install_nvim_plugins",
                side_effect=lambda: calls.append("nvim"),
            ),
            patch.object(post_install, "ensure_dir_ownership"),
            patch.object(post_install, "ensure_claude_config"),
            patch.object(post_install, "ensure_zsh_config"),
        ):
            post_install.main()

        self.assertEqual(calls, ["tmux", "nvim"])


class WorktreeStorageTest(unittest.TestCase):
    def test_main_ensures_worktree_storage_is_writable(self) -> None:
        with (
            patch.object(post_install, "install_tmux_config"),
            patch.object(post_install, "install_tmux_plugins"),
            patch.object(post_install, "install_nvim_plugins"),
            patch.object(post_install, "ensure_dir_ownership") as ensure_ownership,
            patch.object(post_install, "ensure_claude_config"),
            patch.object(post_install, "ensure_zsh_config"),
        ):
            post_install.main()

        self.assertIn(((Path("/worktrees"),), {}), ensure_ownership.call_args_list)


if __name__ == "__main__":
    unittest.main()
