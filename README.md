# Quartz Rsync Watch and Deploy
With this extremely handy name, I introduce to you a simple watcher, builder and deployer that uses [Quartz](https://quartz.jzhao.xyz/) to build static sites from your [Obsidian](https://obsidian.md/) vault and then deploys them to a remote server using `rsync`.

At the core it is a single docker service that runs a bash script to watch for changes in your vault and then builds and deploy them.

## Usage
### Quartz Configuration
- Edit `quartz.config.ts` and `quartz.layout.ts` in `/quartz-config` to your needs. These will be mounted into the container and changes will be reflected in the next build. However, since the container is using its own watcher and not Quartz's (which does pick up changes to these files), you will have to trigger a build manually by editing any of your notes to see the changes.

### Volumes:
Edit the docker-compose.yml file to your needs.
- Mount your Obsidian vault to `/quartz/content`
- Mount your deploy ssh key to `/root/.ssh/id_rsa`

### Environment Variables
- `RSYNC_TARGET`: The target to deploy to, for example `user@server:/path/to/deploy`
- `DEBOUNCE_TIME`: The time in seconds after the first change to wait before beginning the build. Default is 30 seconds. 

### Build and Run
- Run `docker-compose up -d` to build and run the container in the background. By default it will restart unless stopped manually.


## Use Case
I created this tool, because I wanted to be able to publish my Obsidian notes from all of my devices without any hassle. I already had a server set up and was syncing my vaults with [Syncthing](https://syncthing.net/), so I only neede a tool to watch for changes and deploy them to my webserver. 
So now I can:
- Write a note on any of my devices -> Syncthing syncs it to my server -> This tool watches for changes and initiates a build with Quartz -> Deploys the build to my webserver.
