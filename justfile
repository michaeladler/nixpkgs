# update world
update-world: update-git update-librewolf push

cachix-push PKG:
    cachix push nur-packages $(nix-build -A {{PKG}})

# update git
update-git:
    #!/usr/bin/env bash
    set -eux
    git fetch -q --all
    git --no-pager log --color --date=short --pretty=format:'%Cgreen%cd %h %Creset%s %Cred%d%Creset' ..FETCH_HEAD
    git checkout -q nixos-unstable
    git reset --hard adlerm/nixos-unstable
    git rebase -q origin/nixos-unstable

# update zen-kernels
update-zen:
    #!/usr/bin/env bash
    set -eux
    pkgs/os-specific/linux/kernel/update-zen.py zen
    pkgs/os-specific/linux/kernel/update-zen.py lqx
    git diff --exit-code pkgs/os-specific/linux/kernel || {
        git add pkgs/os-specific/linux/kernel/zen-kernels.nix
        git commit -m 'update zen-kernels'
    }

# update librewolf
update-librewolf:
    #!/usr/bin/env bash
    set -eux
    old_version=$(jq -r '.packageVersion' < pkgs/applications/networking/browsers/librewolf/src.json)
    echo "" | nix-shell maintainers/scripts/update.nix --argstr package librewolf-unwrapped
    git diff --exit-code pkgs/applications/networking/browsers/librewolf/src.json || {
        new_version=$(jq -r '.packageVersion' < pkgs/applications/networking/browsers/librewolf/src.json)
        git add pkgs/applications/networking/browsers/librewolf/src.json
        git commit -m "librewolf-unwrapped: $old_version -> $new_version"
    }

# update firefox
update-firefox:
    #!/usr/bin/env bash
    echo "" | nix-shell maintainers/scripts/update.nix --argstr package firefox-unwrapped
    git diff --exit-code pkgs/applications/networking/browsers/firefox || {
        git add pkgs/applications/networking/browsers/firefox
        git commit -m "chore: updated firefox"
    }

update-brave:
    #!/usr/bin/env bash
    pkgs/applications/networking/browsers/brave/update.sh
    git diff --exit-code pkgs/applications/networking/browsers/brave || {
        git add pkgs/applications/networking/browsers/brave
        git commit -m "chore: updated brave"
    }

# force push
push:
    git push -q -f adlerm nixos-unstable

# find and build package
build:
    #!/usr/bin/env bash
    choice=$(rg "^(.*?) = callPackage " pkgs/top-level/all-packages.nix | awk -F= '{print $1;}' | fzy --lines=50 | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')
    if [[ "$choice" != "" ]; then
        rm -f result*
        nix-build -A "$choice"
    fi
