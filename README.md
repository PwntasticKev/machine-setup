# machine-setup

One command to set up a new Mac or Windows PC: apps, games, and Claude Code skills.

## Run it

**Mac** (Terminal):

```bash
curl -fsSL https://raw.githubusercontent.com/PwntasticKev/machine-setup/main/install.sh | bash
```

**Windows** (PowerShell):

```powershell
irm https://raw.githubusercontent.com/PwntasticKev/machine-setup/main/install.ps1 | iex
```

Add `--dry-run` (Mac: `... | bash -s -- --dry-run`) or `-DryRun` (Windows: run
`windows\setup.ps1 -DryRun`) to see what would happen without installing anything.

Re-running is safe: anything already installed is skipped.

## What happens

1. Asks for your password once (Mac) or for admin rights once (Windows).
2. Installs **Steam first** and opens it. Log in while the rest installs.
3. Windows: starts **League of Legends (with TFT) and Valorant** downloading in their
   own minimized window, and installs the **Jagex Launcher**.
4. Installs every app (Homebrew on Mac, winget on Windows), plus Dia and Navi.
5. Installs the Claude Code skills globally into `~/.claude/skills`.
6. Once Steam sees you logged in, queues every Steam game. Click **Install** in each
   Steam dialog.
7. Sets Dia as the default browser (Mac shows one confirm dialog; Windows opens the
   Default apps page for you to pick it).
8. Prints a checklist of what is left: logins, reboot, permissions.

Things no script can do for you: logging into accounts (Steam, Riot, Jagex, Slack,
...), 2FA codes, and clicking Install in Steam's dialogs.

## What gets installed

| | Mac | Windows |
|---|---|---|
| Slack, Discord, Spotify, Tailscale, f.lux | yes | yes |
| Claude Desktop, Claude Code, ChatGPT (includes Codex) | yes | yes |
| T3 Code, Logitech G HUB, Dia (default browser) | yes | yes |
| Steam | yes | yes |
| BetterTouchTool, Navi | yes | |
| Docker Desktop | | yes |
| Riot Client: League of Legends (+TFT), Valorant (NA) | | yes |
| Jagex Launcher (for Old School RuneScape) | | yes |

**Steam games:** Counter-Strike: Source, Counter-Strike 2, Phasmophobia, Rocket League,
MECCHA CHAMELEON, RuneScape: Dragonwilds, Halo: The Master Chief Collection, Valheim,
Aimlabs. Only Valheim runs on Mac.

**Claude Code skills:** [mattpocock/skills](https://github.com/mattpocock/skills)
(AI Hero), [t3dotgg/tstack](https://github.com/t3dotgg/tstack),
[heygen-com/hyperframes](https://github.com/heygen-com/hyperframes).

Codex desktop was merged into the ChatGPT desktop app in July 2026, so the ChatGPT app
is what gets installed.

## Add more

| To add | Edit |
|---|---|
| A Mac app | `mac/Brewfile` (find names with `brew search <name>`) |
| A Windows app | `windows/packages.txt` (find ids with `winget search <name>`) |
| A Steam game | `config/steam-games.txt` (app id is in the store URL) |
| A Claude skill repo | `config/skills.txt` |
| A Riot game | `$script:RiotPackages` in `windows/steps/games.ps1` |

## Layout

```
install.sh / install.ps1   one-line bootstraps (download repo, run setup)
config/                    lists shared by both platforms
mac/setup.sh               Mac steps, in order
mac/steps/*.sh             one file per area (homebrew, steam, apps, skills)
windows/setup.ps1          Windows steps, in order
windows/steps/*.ps1        one file per area (steam, games, apps)
```
