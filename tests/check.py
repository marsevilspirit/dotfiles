"""Run regression checks in a temporary chezmoi destination; never sync the real home."""

import json
import os
from pathlib import Path
import re
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

    result = run(nvim + ["-l", str(ROOT / "tests/lsp-roots.lua")], env=env)
    print(result.stdout + result.stderr)
    print("PASS: native LSP workspace roots and project fallbacks")

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
        zsh = shutil.which("zsh")
        for with_framework, with_go in ((False, False), (True, False),
                                        (False, True), (True, True)):
            zsh_home = base / f"zsh home-{with_framework}-{with_go}"
            zsh_bin = zsh_home / "bin"
            zsh_bin.mkdir(parents=True)
            if with_framework:
                framework = zsh_home / ".oh-my-zsh/oh-my-zsh.sh"
                framework.parent.mkdir()
                framework.write_text('dotfiles_omz_loaded="$ZSH_THEME:${(j:,:)plugins}"\n')
            if with_go:
                go = zsh_bin / "go"
                go.write_text(
                    '#!/bin/sh\n'
                    '[ "$#" -eq 2 ] && [ "$1" = env ] && [ "$2" = GOPATH ] || exit 1\n'
                    'printf \'%s\\n\' "$HOME/custom go"\n')
                go.chmod(0o755)
            result = run([zsh, "-f", "-c",
                          'source "$1"; print -r -l -- "${dotfiles_omz_loaded:-}" '
                          '"$PATH" "$EDITOR" "${aliases[vi]}"',
                          "zsh-check", str(ROOT / "dot_zshrc")],
                         env={"HOME": str(zsh_home), "PATH": str(zsh_bin)})
            assert not result.stderr, result.stderr
            loaded, shell_path, editor, vi = result.stdout.splitlines()
            assert loaded == ("clean:git,wakatime" if with_framework else ""), result.stdout
            assert editor == "nvim" and vi == "nvim", result.stdout
            assert str(zsh_home / ".local/bin") in shell_path.split(":"), shell_path
            assert str(zsh_home / "go/bin") in shell_path.split(":"), shell_path
            assert (str(zsh_home / "custom go/bin") in shell_path.split(":")) == with_go, shell_path
        print("PASS: zsh starts with optional framework/Go present or absent")

        fish = shutil.which("fish")
        assert fish, "Install fish to run shell checks"
        for file in (ROOT / "dot_config/fish").rglob("*.fish"):
            run([fish, "--no-config", "-n", str(file)], env=env)
        env["XDG_CONFIG_HOME"] = str(target / ".config")
        env["HOME"] = str(target)
        minimal_bin = base / "minimal-bin"
        minimal_bin.mkdir()
        (minimal_bin / "cat").symlink_to(shutil.which("cat"))
        result = run([fish, "--no-config", "-i", "-c",
                      'set -gx PATH "$argv[2]"; source "$argv[1]"',
                      str(ROOT / "dot_config/fish/config.fish"), str(minimal_bin)], env=env)
        assert "Unknown command" not in result.stderr, result.stderr
        print("PASS: fish/zsh syntax; fish starts without optional tools")

        local_bin, cargo_bin, go_bin = target / ".local/bin", target / ".cargo/bin", base / "go/bin"
        cargo_bin.mkdir(parents=True)
        go_bin.mkdir(parents=True)
        tail_bin = base / "last-bin"
        tail_bin.mkdir()
        (minimal_bin / "go").write_text(
            '#!/bin/sh\n'
            '[ "$#" = 2 ] && [ "$1" = env ] && [ "$2" = GOPATH ] || exit 1\n'
            'printf "%s\\n" "$GOPATH"\n')
        (minimal_bin / "go").chmod(0o755)
        path_probe = """
            printf '%s\\n' (string join : $PATH)
            source "$argv[1]"
            printf '%s\\n' (string join : $PATH)
            source "$argv[1]"
            printf '%s\\n' (string join : $PATH)
            "$argv[2]" -c 'printf "%s\\n" (string join : $PATH)'
            "$argv[2]" -i -c 'printf "%s\\n" (string join : $PATH)'
        """
        for local_exists in (False, True):
            if local_exists:
                local_bin.mkdir()
            for local_inherited in (0, 1, 3):
                for cargo_inherited in (True, False):
                    initial_path = [str(minimal_bin), str(tail_bin)]
                    expected_path = [str(local_bin), str(cargo_bin), *initial_path]
                    if cargo_inherited:
                        initial_path.append(str(cargo_bin))
                        expected_path = [str(local_bin), *initial_path]
                    if local_inherited:
                        initial_path.insert(1, str(local_bin))
                    if local_inherited == 3:
                        initial_path.insert(0, str(local_bin))
                        initial_path.append(str(local_bin))
                    for flags in ([], ["-i"]):
                        go_path = ":".join([*expected_path, str(go_bin)])
                        parent_path = go_path if flags else ":".join(expected_path)
                        result = run([fish, *flags, "-c", path_probe,
                                      str(target / ".config/fish/config.fish"), fish],
                                     env={**env, "PATH": ":".join(initial_path)})
                        assert result.stdout.splitlines() == [parent_path] * 4 + [go_path], (
                            local_exists, local_inherited, cargo_inherited, flags,
                            result.stdout, result.stderr)
        print("PASS: fish PATH priority/order; inherited duplicates; repeated source/nested shells; missing local bin")

        prompt_dir = base / "prompt directory"
        prompt_dir.mkdir()
        (minimal_bin / "uname").symlink_to(shutil.which("uname"))
        prompt_env = {**env, "HOME": str(target), "TERM": "xterm-256color",
                      "PATH": str(minimal_bin)}
        prompt_check = [fish, "-i", str(ROOT / "tests/fish-prompt.fish"), str(prompt_dir)]
        result = run(prompt_check, env=prompt_env)
        plain_prompt = re.sub(r"\x1b(?:\[[0-?]*[ -/]*[@-~]|\([A-Z])", "", result.stdout)
        assert plain_prompt == "prompt-user:prompt directory/ $ " * 2, plain_prompt
        assert "Unknown command" not in result.stderr, result.stderr

        (minimal_bin / "git").symlink_to(shutil.which("git"))
        run(["git", "init", "-b", "prompt-check", str(prompt_dir)], env=prompt_env)
        run(["git", "-c", "user.name=Prompt Check", "-c", "user.email=prompt@example.invalid",
             "commit", "--allow-empty", "-m", "Prompt fixture"], cwd=prompt_dir, env=prompt_env)
        clean = run(prompt_check, env=prompt_env).stdout
        (prompt_dir / "untracked.txt").write_text("prompt fixture\n")
        untracked = run(prompt_check, env=prompt_env).stdout
        assert "prompt-check" in clean and "prompt-check" in untracked, (clean, untracked)
        assert clean != untracked, "Prompt must show untracked Git files"
        print("PASS: fish prompt uses builtins, shows Git state, and avoids Git option events on redraw")

        (target / ".config/fish/secrets.fish").write_text("set -ga dotfiles_load_order secrets\n")
        (target / ".config/fish/local.fish").write_text(
            "set -g fish_autosuggestion_enabled 0\n"
            "set -g __fish_git_prompt_showuntrackedfiles false\n"
            "set -g __fish_git_prompt_color_branch magenta\n"
            "set -gx PATH /dotfiles-local-bin\n"
            "set -ga dotfiles_local_loads loaded\n"
            "set -ga dotfiles_load_order local\n")
        for flags in ([], ["-i"]):
            result = run([fish, *flags, "-c",
                          'test "$fish_autosuggestion_enabled" = 0; '
                          'and test "$PATH" = /dotfiles-local-bin; '
                          'and set -gx PATH "$argv[1]"; '
                          'and fish_prompt >/dev/null; '
                          'and test "$__fish_git_prompt_showuntrackedfiles" = false; '
                          'and test "$__fish_git_prompt_color_branch" = magenta; '
                          'and test (count $dotfiles_local_loads) -eq 1; '
                          'and test "$dotfiles_load_order" = "secrets local"', str(minimal_bin)],
                         cwd=prompt_dir, env={**env, "HOME": str(target)})
            assert "Unknown command" not in result.stderr, result.stderr
        print("PASS: fish local overrides load last and once in both shell modes")

    if "--integration" in sys.argv:
        env["XDG_CONFIG_HOME"] = str(target / ".config")
        result = run(["nvim", "--headless", "-i", "NONE"] + gate, env=env, timeout=900)
        print(result.stdout + result.stderr)
        print("PASS: applied Neovim config, LSP/formatter installs, HTML parser, core health")
