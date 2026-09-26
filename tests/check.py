"""Run regression checks in a temporary chezmoi destination; never sync the real home."""

import json
import os
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile

ROOT = Path(__file__).resolve().parents[1]


def run(args, *, cwd=ROOT, env=None, success=True, timeout=60):
    result = subprocess.run(args, cwd=cwd, env=env, encoding="utf-8", errors="replace",
                            capture_output=True, timeout=timeout)
    if (result.returncode == 0) != success:
        raise AssertionError(f"{args}: exit {result.returncode}\n{result.stdout}\n{result.stderr}")
    return result


with tempfile.TemporaryDirectory(prefix="dotfiles-check-") as directory:
    base = Path(directory).resolve()
    source, target = base / "source", base / "target"
    source.mkdir()
    target.mkdir()
    for path in ROOT.iterdir():
        if path.name.startswith("dot_"):
            if path.is_dir():
                shutil.copytree(path, source / path.name, ignore=shutil.ignore_patterns(
                    "*.log", "secrets.fish", "fish_variables", "local.fish"))
            else:
                shutil.copy2(path, source / path.name)
    for name in ("justfile", "Brewfile", ".chezmoiignore", ".chezmoiremove", ".gitignore"):
        shutil.copy2(ROOT / name, source / name)
    (source / "dot_probe.tmpl").write_text("{{ .chezmoi.os }}\n")
    (source / "nvim.log").write_text("must stay local\n")
    (source / "dot_config/nvim/nested.log").write_text("must stay local\n")
    (source / "tests").mkdir()
    (source / "tests/probe.txt").write_text("must stay local\n")

    retired_files = (".config/fish/completions/fisher.fish", ".config/fish/conf.d/fish_frozen_theme.fish",
                     ".config/fish/fish_plugins", ".config/fish/functions/fisher.fish",
                     ".config/nvim/plugin/render-markdown.lua")
    for name in retired_files:
        path = target / name
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text("retired\n")

    env = dict(os.environ)
    for variable, name in (("XDG_CONFIG_HOME", "config"), ("XDG_DATA_HOME", "data"),
                           ("XDG_CACHE_HOME", "cache"), ("XDG_STATE_HOME", "state")):
        env[variable] = str(base / name)
        (base / name).mkdir()
    env["NVIM_LOG_FILE"] = str(base / "nvim.log")
    env["npm_config_cache"] = str(base / "npm-cache")
    env["GOMODCACHE"] = str(base / "go-mod")
    env["GOCACHE"] = str(base / "go-cache")
    env["GOPATH"] = str(base / "go")
    config = base / "config/chezmoi"
    config.mkdir()
    (config / "chezmoi.json").write_text(json.dumps({"destDir": str(target)}))

    just = ["just", "--shell", "bash", "--shell-arg", "-cu"]
    run(just + ["--list"], cwd=source, env=env)
    managed = run(just + ["managed"], cwd=source, env=env).stdout.replace("\\", "/")
    assert ".config/nvim/init.lua" in managed
    assert ".log" not in managed and "tests/" not in managed, managed
    assert "Brewfile" not in managed, managed
    run(just + ["diff"], cwd=source, env=env)
    run(just + ["apply"], cwd=source, env=env)
    for name in retired_files:
        assert not (target / name).exists(), name
    assert (target / ".config/fish/themes/Dracula Official.theme").is_file()
    for name in (".config/nvim/init.lua", ".config/ghostty/config", ".config/fish/config.fish",
                 ".tmux.conf", ".vimrc", ".zshrc", ".ideavimrc",
                 ".local/share/nvim/leetcode/leetcode.hpp", ".local/share/nvim/leetcode/.clangd"):
        assert (target / name).is_file(), name
    assert not (target / "nvim.log").exists()
    assert not (target / "Brewfile").exists()
    original = (source / "dot_vimrc").read_text()
    template = (source / "dot_probe.tmpl").read_text()
    (target / ".vimrc").write_text(original + '\n" sync regression\n')
    (target / ".probe").write_text("do not replace the template\n")
    run(just + ["sync-diff"], cwd=source, env=env)
    assert (source / "dot_vimrc").read_text() == original, "Preview mutated source"
    run(just + ["sync"], cwd=source, env=env)
    assert (source / "dot_vimrc").read_text() == (target / ".vimrc").read_text()
    assert (source / "dot_probe.tmpl").read_text() == template, "Sync overwrote template"
    print("PASS: just apply/diff/managed/sync/sync-diff; templates preserved; logs excluded")

    nvim = ["nvim", "--clean", "--headless", "-i", "NONE"]
    env["DOTFILES_SOURCE"] = str(ROOT)
    env["DOTFILES_TEST_DIR"] = str(base)
    run(nvim + ["-l", str(ROOT / "tests/autosave.lua")], env=env)
    print("PASS: autosave behavior and visible write failures")

    gate = ["--cmd", "luafile " + str(ROOT / "tests/nvim-check.lua")]
    env["DOTFILES_HEALTH_CHECKS"] = "vim.treesitter"
    run(nvim + gate, env=env)
    run(nvim + gate + ["--cmd", 'lua error("startup regression probe")'], env=env, success=False)
    env["DOTFILES_HEALTH_CHECKS"] = "dotfiles_missing_healthcheck"
    run(nvim + gate, env=env, success=False)
    del env["DOTFILES_HEALTH_CHECKS"]
    print("PASS: Neovim gate accepts healthy startup and rejects startup/health errors")

    if os.name != "nt":
        run(["zsh", "-n", str(ROOT / "dot_zshrc")], env=env)
        fish = shutil.which("fish")
        assert fish, "Install fish to run shell checks"
        for file in (ROOT / "dot_config/fish").rglob("*.fish"):
            run([fish, "--no-config", "-n", str(file)], env=env)
        env["XDG_CONFIG_HOME"] = str(target / ".config")
        minimal_bin = base / "minimal-bin"
        minimal_bin.mkdir()
        (minimal_bin / "cat").symlink_to(shutil.which("cat"))
        result = run([fish, "--no-config", "-i", "-c",
                      'set -gx PATH "$argv[2]"; source "$argv[1]"',
                      str(ROOT / "dot_config/fish/config.fish"), str(minimal_bin)], env=env)
        assert "Unknown command" not in result.stderr, result.stderr
        print("PASS: fish/zsh syntax; fish starts without optional tools")

        (target / ".config/fish/local.fish").write_text(
            "set -g fish_autosuggestion_enabled 0\n"
            "set -gx PATH /dotfiles-local-bin\n"
            "set -ga dotfiles_local_loads loaded\n")
        for flags in ([], ["-i"]):
            run([fish, *flags, "-c",
                 'test "$fish_autosuggestion_enabled" = 0; '
                 'and test "$PATH" = /dotfiles-local-bin; '
                 'and test (count $dotfiles_local_loads) -eq 1'],
                env={**env, "HOME": str(target)})
        print("PASS: fish local overrides load last and once in both shell modes")

    if "--integration" in sys.argv:
        env["XDG_CONFIG_HOME"] = str(target / ".config")
        result = run(["nvim", "--headless", "-i", "NONE"] + gate, env=env, timeout=900)
        print(result.stdout + result.stderr)
        print("PASS: applied Neovim config, LSP/formatter installs, HTML parser, core health")
