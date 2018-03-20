# ws-docker
The Docker Image used for Local Dev &amp; CircleCI too


## Local Development Usage
### Install Docker
[Download Source and Install Guide](https://store.docker.com/editions/community/docker-ce-desktop-mac)

Make sure no other processes are using port 80; i.e., localhost:80 should return nothing.

### Setup Local DNS
Use [Gas Mask](https://github.com/2ndalpha/gasmask) on Mac with similar entries:

```
127.0.0.1 local.domain1.com
127.0.0.1 local.domain2.com
```

### Organize your repos
Your github repos should be in this directory format:

```
./domain1.com/local
./domain2.com/local
```

The .git folder should be in local. You can checkout new projects with a `git clone https://github.com/owner/repo-name local`
As such, http://local.domain1.com/wp-admin should be a viable link.


### Environment Variables
Since CircleCI uses this same-ish Docker image, the same env-vars need setup locally.
This doesn't need to happen for every project, just rename the webserver.sample file to webserver.env
and fill out the appropriate info.


### Docker Cleanup
If you're running out of disk space: `docker system prune -a`

Note: that will be needed more often if you use `docker stop` and `docker run` a lot.

Hint: just start containers that are stopped instead of running new containers.

## FMI:
[Docker Cheatsheet](https://docs.docker.com/get-started/part2/#recap-and-cheat-sheet-optional)


