# Quartz Rsync Watch and Deploy
With this extremely handy name, I introduce to you a simple watcher, builder and deployer that uses [Quartz](https://quartz.jzhao.xyz/) to build static sites from your [Obsidian](https://obsidian.md/) vault and then deploys them to a remote server using `rsync`.

At the core it is a single docker service that runs a bash script to watch for changes in your vault and then builds and deploy them.

## Use Case
I created this tool, because I want to be able to publish my Obsidian notes from all of my devices without any hassle. Since I already have a server that serves as an always-on hub for my vaults that I sync with [Syncthing](https://syncthing.net/), I only need a tool to watch for changes and deploy them to my webserver. 
With this setup, whenever I edit a note on any of my devices, it gets:
    - synced to my server via Syncthing
    - detected by this tool watches
    - built into a html file by Quartz
    - deployed to my webserver.

## Usage
1. `git clone` this repository to your server.
2. Edit the `docker-compose.yml` file to your needs.
3. Edit the `.env` file to your needs.
4. Run `docker-compose up -d` to build and run the container in the background.

### Volumes:
Edit the docker-compose.yml file to your needs.
- Mount your Obsidian vault to `/quartz/content`
- Mount your deploy ssh key to `/root/.ssh/id_rsa`

### Environment Variables
- `RSYNC_TARGET`: The target to deploy to, for example `user@server:/path/to/deploy`
- `DEBOUNCE_TIME`: The time in seconds after the first change to wait before beginning the build. Default is 30 seconds. 

### Quartz Configuration
- Edit `quartz.config.ts` and `quartz.layout.ts` in `/quartz-config` to your needs. These will be mounted into the container and changes will be reflected in the next build. However, since the container is using its own watcher and not Quartz's (which does pick up changes to these files), you will have to trigger a build manually by editing any of your notes to see the changes.

## Limitations

### No know_hosts checking
The rsync command uses the `-o StrictHostKeyChecking=no` flag to bypass the known_hosts check. This can be a security risk and might enable MITM attacks. Please suggest a better way to handle this.

### Stupid Debouncing, no locking
Obsidian uses an auto-save feature, which saves the note almost on every keystroke. To throttle the build process, the watcher uses a simple ans stupid way of debouncing. After a first change is detected, it waits for `DEBOUNCE_TIME` seconds before it starts the build. Adjust this to your needs. This is a rather crude approach and I am sure it might come to problems, especially if you, like me are using Syncthing or similar to sync your vault.

### Stupid Check for Changes in the build folder
Sometimes you make changes to a draft or a note that is included from the build in other ways. In that case it is not necessary to deploy using rsync. Therefore, before and after each build, the script decides if it should deploy by checking the size of the `public` folder. If the size is the same, it assumes no changes were made and does not deploy. This might miss changes in edge cases. 





