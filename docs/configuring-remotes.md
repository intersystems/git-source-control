# Configuring Remotes

This guide covers how to configure and interact with remote repositories in Embedded Git using the settings page.

## Prerequisites

- Git and Embedded Git installed on the server
- A remote repository (e.g., GitHub, GitLab, Bitbucket)
- Access to the Embedded Git settings page on the instance: https://hostname:port/prefix/isc/studio/usertemplates/gitsourcecontrol/gitprojectsettings.csp

## Option 1: Configuring SSH authentication with a personal SSH key

This option is best for individual development environments using any remote that supports SSH authentication.

1. Enter a filename in the SSH Private Key File input of the Embedded Git settings form. Save the form.
2. Click the "File not found - generate a new key pair?" button. Save the form.
3. Copy the value of the "Public key" input on the settings page.
4. Add the public key to the SSH keys for your individual user on the Git remote. For example in GitHub: https://github.com/settings/ssh/new
5. In your Git remote, copy the link to clone the repository via SSH.
6. In Embedded Git settings, click the "Clone" button and paste the SSH repository URL into the confirmation dialog.

## Option 2: Configuring SSH authentication with a GitHub deploy key

This option is best for shared development environments using GitHub.

Follow the steps for Option 1, but in step 4, instead of adding the public key to your individual user's SSH keys, add it as a deploy key to the repository (repository settings > Deploy keys > Add deploy key). Check "Allow write access".

## Option 3: Configuring HTTPS authentication with a personal access token

This option is best for individual development environments using GitHub where SSH access to the remote is not permitted from the development server.

1. In the GitHub repository, go to Settings > Developer Settings > Personal Access Tokens > Tokens (classic) > Generate new token (classic)
2. Give the new token scope "repo". Click "Generate Token"
3. Copy the token - it looks like ghp_abunchoflettersandnumbers
4. In the Embedded Git settings page, click the "Clone" button. Include the personal access token in the remote URL like this: https://my-github-username:ghp_abunchoflettersandnumbers@github.com/org/repo.git

## Option 4: Configuring HTTPS authentication with a project access token

This option is best for shared development environments using GitLab where SSH access to the remote is not permitted from the development server.
1. In GitLab, go to repository settings > Access Tokens > Add new token
2. Give the token permissions to read and write the repository.
3. Copy the token and save it somewhere secure.
4. In the Embedded Git settings page, click the "Clone" button. Include the project access token in the URL like this: https://git:pastetokenhere@my-gitlab-tenant.example.com/org/repo.git

## Frequently Asked Questions

### How do I verify that my remote connection is working?

After configuring your remote, refresh the Embedded Git settings page. The "Remote Repository" input should display the remote URL with a "Connection successful" message underneath. If you see an error message instead, review your authentication settings.

### If multiple developers are pushing changes with the same deploy key or access token, will they all look like they came from the same user?

In the git repository history, each commit will still be attributed to the individual user who made the commit.

### My firewall blocks outgoing traffic on port 22. Can I still use SSH authentication?

For GitHub specifically, you may be able to enable SSH connections over HTTPS following this guide: https://docs.github.com/en/authentication/troubleshooting-ssh/using-ssh-over-the-https-port. That involves making some changes to an SSH config file. To force Embedded Git to use a specific config file, edit the "Path to SSH Config File" input on the Embedded Git settings page.