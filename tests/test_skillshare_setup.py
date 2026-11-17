import json
import os
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile
import unittest


REPO = Path(__file__).resolve().parents[1]


def entry(name, commit="a" * 40):
    return {
        "source": f"github.com/example/skills/skills/{name}",
        "type": "github-subdir",
        "repo_url": "https://github.com/example/skills.git",
        "subdir": f"skills/{name}",
        "commit": commit,
    }


class SkillshareSetupTest(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        root = Path(self.temp.name).resolve()
        self.repo = root / "dotfiles"
        for name in ("scripts", ".config/skillshare", ".obsidian", "extensions"):
            shutil.copytree(REPO / name, self.repo / name)
        self.home = root / "home"
        self.local = self.home / ".config/skillshare"
        self.live = self.local / "skills"
        self.live.mkdir(parents=True)
        self.managed = self.repo / ".config/skillshare/skills/.metadata.json"
        self.managed.write_text(json.dumps({"version": 1, "entries": {"pinned": entry("pinned")}}))
        bin_dir = root / "bin"
        bin_dir.mkdir()
        stub = bin_dir / "skillshare"
        stub.write_text(
            "#!/usr/bin/env python3\n"
            "import json, os, pathlib, sys\n"
            "with (pathlib.Path.home() / 'calls.jsonl').open('a') as f:\n"
            "    f.write(json.dumps(sys.argv[1:]) + '\\n')\n"
            "if os.environ.get('FAIL_INSTALL') and sys.argv[1] == 'install': sys.exit(1)\n"
        )
        stub.chmod(0o755)
        self.env = dict(os.environ, HOME=str(self.home), GITDIR=str(self.repo),
                        PATH=str(bin_dir) + os.pathsep + os.environ["PATH"])

    def run_script(self, install=False, **env):
        return subprocess.run(
            [sys.executable, str(self.repo / "scripts/setup-skillshare.py")]
            + (["--install"] if install else []),
            env=dict(self.env, **env), capture_output=True, text=True,
        )

    def assert_success(self, result):
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)

    def test_migration_keeps_runtime_metadata_and_payloads(self):
        extra = entry("runtime-extra", "b" * 40)
        (self.live / ".metadata.json").write_text(json.dumps({
            "version": 1, "entries": {"runtime-extra": extra, "pinned": entry("pinned", "c" * 40)},
            "target_overrides": {"runtime-extra": ["claude"]},
        }))
        (self.live / "runtime-extra").mkdir()
        (self.live / "runtime-extra/SKILL.md").write_text("local payload")
        apm = self.home / "git/skills/.agents/skills"
        apm.mkdir(parents=True)
        (self.live / "_apm").symlink_to(apm)
        self.assert_success(self.run_script())
        metadata = json.loads(self.managed.read_text())
        self.assertEqual(metadata["entries"]["runtime-extra"], extra)
        self.assertEqual(metadata["entries"]["pinned"]["commit"], "a" * 40)
        self.assertEqual(metadata["target_overrides"]["runtime-extra"], ["claude"])
        self.assertEqual((self.live / "runtime-extra/SKILL.md").read_text(), "local payload")
        self.assertEqual((self.live / "_apm").resolve(), apm)
        self.assertTrue(list(self.local.glob(".dotfiles-backup.*/skills/.metadata.json")))
        self.assert_success(self.run_script())
        self.assertEqual(json.loads(self.managed.read_text()), metadata)

    def test_restore_uses_recorded_commit(self):
        self.assert_success(self.run_script(install=True))
        calls = [json.loads(line) for line in (self.home / "calls.jsonl").read_text().splitlines()]
        install = next(call for call in calls if call[0] == "install")
        self.assertIn(entry("pinned")["source"], install)
        self.assertEqual(install[install.index("--branch") + 1], "a" * 40)
        self.assertNotIn("--force", install)
        self.assertEqual(calls[-2:], [["sync", "-g"], ["sync", "extras", "-g"]])

    def test_failed_install_does_not_sync(self):
        self.assertNotEqual(self.run_script(install=True, FAIL_INSTALL="1").returncode, 0)
        calls = [json.loads(line) for line in (self.home / "calls.jsonl").read_text().splitlines()]
        self.assertFalse(any(call[0] == "sync" for call in calls))

    def test_legacy_chrome_path_and_atomic_metadata_save(self):
        (self.local / "ui").symlink_to(self.repo / ".config/skillshare/ui")
        for _ in range(2):
            self.assert_success(self.run_script())
            ui = self.local / "ui"
            self.assertEqual((ui / "manifest.json").resolve(),
                             self.repo / "extensions/skillshare-ui-pink-theme/manifest.json")
            self.assertEqual((ui / "theme.css").resolve(),
                             self.repo / ".obsidian/plugins/skillshare-ui/theme.css")
        replacement = self.live / ".metadata-test.tmp"
        replacement.write_text('{"version":1,"entries":{}}\n')
        replacement.replace(self.live / ".metadata.json")
        self.assertTrue(self.live.is_symlink())
        self.assertEqual(json.loads(self.managed.read_text())["entries"], {})

    def test_tracked_collection_without_repo_url_is_restored(self):
        self.managed.write_text(json.dumps({"version": 1, "entries": {
            "_team": {"source": "https://github.com/example/team.git", "tracked": True, "branch": "main"},
        }}))
        self.assert_success(self.run_script(install=True))
        calls = [json.loads(line) for line in (self.home / "calls.jsonl").read_text().splitlines()]
        install = next(call for call in calls if call[0] == "install")
        self.assertIn("--track", install)
        self.assertEqual(install[install.index("--name") + 1], "_team")
        self.assertEqual(install[install.index("--branch") + 1], "main")


if __name__ == "__main__":
    unittest.main()
