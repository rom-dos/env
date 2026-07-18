import os
import subprocess
import tempfile
import unittest
from pathlib import Path


class DevcontainerInstallTest(unittest.TestCase):
    def test_rebuild_disables_build_cache(self) -> None:
        install_script = Path(__file__).with_name("install.sh")
        template_dir = install_script.parent

        with tempfile.TemporaryDirectory() as temp_dir:
            temp_path = Path(temp_dir)
            repo_path = temp_path / "repo"
            bin_path = temp_path / "bin"
            calls_path = temp_path / "devcontainer-calls"
            repo_path.mkdir()
            bin_path.mkdir()

            fake_devcontainer = bin_path / "devcontainer"
            fake_devcontainer.write_text(
                '#!/usr/bin/env bash\nprintf "%s\\n" "$@" >> "$DEVC_CALLS"\nprintf "\\n" >> "$DEVC_CALLS"\n',
                encoding="utf-8",
            )
            fake_devcontainer.chmod(0o755)

            env = os.environ.copy()
            env.update(
                {
                    "DEVC_CALLS": str(calls_path),
                    "DEVC_TEMPLATE_DIR": str(template_dir),
                    "PATH": f"{bin_path}{os.pathsep}{env['PATH']}",
                }
            )

            subprocess.run(
                [str(install_script), "rebuild", str(repo_path)],
                check=True,
                env=env,
                capture_output=True,
                text=True,
            )

            rebuild_call = (
                calls_path.read_text(encoding="utf-8").split("\n\n", maxsplit=1)[0]
            )
            self.assertEqual(
                rebuild_call.splitlines(),
                [
                    "up",
                    "--workspace-folder",
                    str(repo_path),
                    "--remove-existing-container",
                    "--build-no-cache",
                ],
            )


if __name__ == "__main__":
    unittest.main()
