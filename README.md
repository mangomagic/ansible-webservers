# ansible-webservers

Ansible playbooks for configuring nginx on a Digital Ocean server (`nginx-proxy-nyc2-01`).

## Inventory

| Group | Host | Target |
|---|---|---|
| `dev` | `local-docker` | 127.0.0.1:2222 (local Docker container) |
| `production` | `nginx-proxy-nyc2-01` | 159.203.152.22 (Digital Ocean) |

## Playbooks

| Playbook | Description |
|---|---|
| `playbooks/nginx.yml` | Install and configure nginx |
| `playbooks/sites.yml` | Deploy virtual hosts and site content |
| `playbooks/php.yml` | Install PHP-FPM and extensions |
| `playbooks/mysql.yml` | Install and configure MySQL, create databases and users |

## Local Development Setup

The dev environment runs nginx inside a Docker container, which Ansible targets over SSH (port 2222).

### Prerequisites

- Docker
- Ansible (`brew install ansible`)
- An SSH keypair at `~/.ssh/id_ansible` (matches `private_key_file` in `ansible.cfg`)

Generate the key if needed:

```bash
ssh-keygen -t ed25519 -f ~/.ssh/id_ansible -N ''
```

### Start the container

```bash
./scripts/start-container.sh
```

This builds the `nginx-environment` Docker image and starts it with:

| Host port | Container port | Purpose |
|---|---|---|
| `2222` | `22` | SSH (Ansible) |
| `8080` | `80` | HTTP |
| `8443` | `443` | HTTPS |

Your `~/.ssh/id_ansible.pub` is mounted into the container so Ansible can connect as the `mangomagic` user. To use a different key:

```bash
SSH_PUB_KEY=~/.ssh/other_key.pub ./scripts/start-container.sh
```

### Run playbooks against dev

With the container running, in a separate terminal:

```bash
# Install and configure nginx
ansible-playbook -l dev playbooks/nginx.yml

# Deploy sites
ansible-playbook -vv -l dev playbooks/sites.yml
```

Check nginx is up: <http://localhost:8080>

## Usage

### Install/configure nginx

```bash
# Dev
ansible-playbook -l dev playbooks/nginx.yml

# Production
ansible-playbook -l production playbooks/nginx.yml
```

### Deploy sites

```bash
# Dev
ansible-playbook -vv -l dev playbooks/sites.yml

# Production — dry run first
ansible-playbook -vv -l production playbooks/sites.yml --check
ansible-playbook -vv -l production playbooks/sites.yml

# Deploy a single site
ansible-playbook -vv -l production playbooks/sites.yml -e site=somethingthai.com
```

Sites that use vault credentials (e.g. LWT database config) require `--ask-vault-pass`:

```bash
ansible-playbook -vv -l production playbooks/sites.yml -e site=sti.mangomagic.co.uk --ask-vault-pass
```

### PHP

Ubuntu 20.04 ships PHP 7.4. The version is set via `php_version` in `inventory/group_vars/webservers.yml`.

```bash
# Dev
ansible-playbook -l dev playbooks/php.yml

# Production
ansible-playbook -l production playbooks/php.yml
```

To enable PHP for a site, add `php: true` to its entry in `inventory/group_vars/webservers.yml`:

```yaml
www_data:
  - name: mysite.com
    php: true
    local_path: "..."
```

Then redeploy the site to update the virtual host config:

```bash
ansible-playbook -vv -l production playbooks/sites.yml -e site=mysite.com
```

### MySQL

Set passwords in `inventory/group_vars/vault.yml` then encrypt it:

```bash
ansible-vault encrypt inventory/group_vars/vault.yml
```

```bash
# Dev
ansible-playbook -l dev playbooks/mysql.yml --ask-vault-pass

# Production — dry run first
ansible-playbook -l production playbooks/mysql.yml --ask-vault-pass --check
ansible-playbook -l production playbooks/mysql.yml --ask-vault-pass
```

Add databases to `inventory/group_vars/webservers.yml`:

```yaml
mysql_databases:
  - db: myapp
    user: myapp
    password: "{{ vault_mysql_myapp_password }}"
```

Then add the corresponding `vault_mysql_myapp_password` to `vault.yml` before re-encrypting.

**Note**: make sure the `community.mysql` collection is installed:

```bash
ansible-galaxy collection install community.mysql
```

### Useful flags

```bash
# Start from a specific task
ansible-playbook -vv -l production playbooks/sites.yml --start-at-task='Copy www data to webserver'

# Retry failed hosts only
ansible-playbook -vv -l production playbooks/sites.yml --limit @~/.ansible_retries/sites.retry

# Increase verbosity
ansible-playbook -vvv -l production playbooks/sites.yml --check
```
