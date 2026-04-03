# ansible-webservers — Claude context

## What this repo does

Ansible playbooks to configure nginx on a Digital Ocean server (`nginx-proxy-nyc2-01`, `159.203.152.22`, Ubuntu 20.04). Manages virtual hosts, SSL, firewall rules, and site content deployment.

## Key files

- `playbooks/nginx.yml` — installs nginx, ssl-cert, ufw; configures firewall
- `playbooks/sites.yml` — deploys virtual host configs and site content
- `playbooks/templates/nginx/virtual-host.conf.j2` — virtual host template (see SSL modes below)
- `playbooks/templates/nginx/sites-available/default` — catch-all returning 404 using snakeoil cert
- `inventory/host_vars/nginx-proxy-nyc2-01.yml` — production site list
- `inventory/host_vars/local-docker.yml` — dev site list
- `inventory/group_vars/webservers.yml` — `www_data` (sites with deployable content)

## SSL modes

Three modes are controlled per-site via flags in inventory:

| Mode | Flags | Nginx behaviour |
|---|---|---|
| HTTP only | _(none)_ | Serves HTTP, no redirect |
| Cloudflare proxy | `https_redirect: true` | Redirects only when `X-Forwarded-Proto: http` — avoids redirect loops with Cloudflare |
| nginx terminates SSL | `ssl: true` | Unconditional HTTP→HTTPS redirect + `listen 443 ssl` block with Let's Encrypt cert at `/etc/letsencrypt/live/{{ item.name }}/` |

## Site types

**`placeholders`** — virtual host config + placeholder `index.html` from `index.html.j2`. No content repo.

**`www_data`** — virtual host config + content deployed from either:
- A GitHub repo (`repo_url`, `repo_user`, `repo_name`, `www_folder`) — cloned to `/tmp/www_data/` on the control machine then copied up
- A local path (`local_path`) — copied directly; clone step is skipped

**`sites_enabled`** — controls which `sites-available` configs get symlinked into `sites-enabled`. Must include every site that should be active, plus `default` and `reverse-proxy`.

## Adding a new site

1. Add to `placeholders` or `www_data` in `nginx-proxy-nyc2-01.yml` (or `webservers.yml` for all environments)
2. Add to `sites_enabled` in `nginx-proxy-nyc2-01.yml`
3. Set `https_redirect: true` if proxied via Cloudflare, `ssl: true` if nginx terminates SSL (requires a cert at `/etc/letsencrypt/live/<domain>/`)
4. Dry run: `ansible-playbook -vv -l production playbooks/sites.yml --check`
5. Deploy: `ansible-playbook -vv -l production playbooks/sites.yml`

## Local dev environment

The Docker container is the ansible target (not the control node). See README for full setup. The container runs SSH on port 2222 and nginx on port 8080.

```bash
# Start container (keep running in separate terminal)
./scripts/start-container.sh

# Run against dev
ansible-playbook -l dev playbooks/nginx.yml
ansible-playbook -vv -l dev playbooks/sites.yml
```

Requires `~/.ssh/id_ansible` keypair — generate with:
```bash
ssh-keygen -t ed25519 -f ~/.ssh/id_ansible -N ''
```

## Known constraints

- **UFW on Docker**: `Enable UFW` task has `when: "'production' in group_names"` — UFW enablement is skipped in dev because it disrupts SSH inside the container
- **python3-apt**: Required in the container for `--check` mode to work with the `package` module
- **snakeoil cert**: `ssl-cert` package must be installed (handled by `nginx.yml`) for the `default` catch-all HTTPS block to load
- **www_data `local_path`**: Uses `{{ playbook_dir }}/../../www/<domain>` — assumes the `www` repo is checked out as a sibling of `ansible-webservers` under `Projects/`
- **UFW `Enable UFW` task**: Only runs in production — `when: "'production' in group_names"`