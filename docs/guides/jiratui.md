# JiraTUI

TUI client for Atlassian Jira, themed with Catppuccin Mocha.

## Quick start

Launch the TUI:

```sh
jiratui ui
```

Or from the Zellij launcher (`Alt l` > `jiratui ui`).

## Configuration

Config lives at `~/.config/jiratui/config.yaml` (stow-managed from `stow/jiratui/`).

The stowed config sets the theme and search defaults. You need to add your Jira API credentials before first use.

### API credentials

Edit the config and uncomment/fill in:

```yaml
jira_api_username: 'you@example.com'
jira_api_token: 'your-api-token'
jira_api_base_url: 'https://your-instance.atlassian.net'
jira_base_url: 'https://your-instance.atlassian.net'
```

Generate an API token at [id.atlassian.com/manage-profile/security/api-tokens](https://id.atlassian.com/manage-profile/security/api-tokens).

For Jira Data Center (on-premises), add:

```yaml
cloud: False
```

### Optional settings

```yaml
# Pre-select your user in dropdowns
jira_account_id: 'your-account-id'

# Default project (avoids picking one each time)
default_project_key_or_id: 'MY-PROJECT'

# Saved JQL queries
pre_defined_jql_expressions:
  1:
    label: "Current sprint"
    expression: 'sprint in openSprints()'
  2:
    label: "My open issues"
    expression: 'assignee = currentUser() AND resolution = Unresolved'

# Auto-run a saved JQL query on startup
jql_expression_id_for_work_items_search: 1

# Custom status colors
styling:
  work_item_status_colors:
    closed: green
    development: blue
    blocked: '#FF0000'
    in_review: yellow
```

## CLI commands

JiraTUI also has a non-interactive CLI for scripting:

```sh
# Search issues in a project
jiratui issues search --project-key PROJ

# Search a specific issue
jiratui issues search --key PROJ-123

# List comments on an issue
jiratui comments list --key PROJ-123

# Search users
jiratui users search --query "jane"

# Show config file location
jiratui config

# List available themes
jiratui themes
```

## Theme

The stowed config uses the built-in `catppuccin-mocha` theme. Override per-session with:

```sh
jiratui ui --theme nord
```

## Troubleshooting

**"Unable to find the config file"**
- Make sure the stow package is applied: `(cd stow && stow --target="$HOME" --restow jiratui)`

**Authentication errors**
- Verify your API token is valid and has the right scopes
- For cloud instances, use your email as `jira_api_username`
- For data center, use your Jira username and set `cloud: False`

**API version mismatch**
- Cloud defaults to API v3; if you get errors, try adding `jira_api_version: 2`
- Data center automatically uses the correct version
