# Quartz Rsync Watch and Deploy
With this extremely handy name, I introduce to you a simple watcher, builder and deployer that uses [Quartz](https://quartz.jzhao.xyz/) to build static sites from your [Obsidian](https://obsidian.md/) vault and deploys them to a remote server using `rsync`.

At it's core this is a single docker service that runs a bash script to watch for changes in your mounted vault and builds and deploy html pages when it detects them.

## Use Case
I want to be able to publish my Obsidian notes from all of my devices without any hassle. Since I already use [Syncthing](https://syncthing.net/) to keep my vaults in sync between devices and I have a server as an always-on hub for them, this tool is all I needed to fully automise the deployment of my notes.
With this setup, whenever I edit a note on any of my devices, it gets:

    - synced to my server via Syncthing,
    - detected by this watcher,
    - built into a html file by Quartz,
    - and deployed to my webserver with rsync.

## Usage
1. `git clone` this repository to your server.
2. Edit the `docker-compose.yml` file to your needs.
3. Edit the `.env` file to your needs.
4. Run `docker-compose up -d` to build and run the container in the background.

### Volumes:
To edit the docker-compose.yml file to your needs:
- Mount your Obsidian vault to `/quartz/content`
- Mount your deploy ssh key to `/root/.ssh/id_rsa`

### Environment Variables
Then set the following environment variables in the `.env` file:
- `RSYNC_TARGET`: The target to deploy to, for example `user@server:/path/to/deploy`
- `DEBOUNCE_TIME`: The time in seconds after the first change to wait before beginning the build. Default is 30 seconds. 

### Quartz Configuration
The Quartz configuration files `quartz.config.ts` and `quartz.layout.ts` are included in the `/quartz-config` folder and are mounted into the container. 
However, since this container is using inotify and only watches for changes in the `/quartz/content` directory and not Quartz's builder which does pick up changes to the configuration files, you will have to trigger a build manually by editing any of your notes.

## Limitations

### No know_hosts checking
The rsync command uses the `-o StrictHostKeyChecking=no` flag to bypass the known_hosts check. This can be a security risk and might enable MITM attacks. Please suggest a better way to handle this.

### Stupid Debouncing, no locking
Obsidian uses an auto-save feature, which saves the note on almost every keystroke. To throttle the build process, the watcher uses a simple and stupid way of debouncing. After a first change is detected, it waits for `DEBOUNCE_TIME` seconds before it starts the build. Adjust this to your needs (e.g. the average time you edit a note before making a break). This is a rather crude approach and I am sure it might come to file locking problems, especially if you, like me, are using Syncthing or similar to sync your vault.

### Stupid Check for Changes in the build folder
Sometimes you make changes to a `draft` note or a note that is excluded from the build in other ways. In that case it is not necessary to deploy using rsync. Therefore, before and after each build, the script decides if it should deploy by checking the size of the `public` folder. If the size stayed the same, it assumes no changes were made and does not deploy. This might miss changes in edge cases. 





