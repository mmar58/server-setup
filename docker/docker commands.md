Here we are listing all the important commands of the docker, which are essential in everyday usage.

## Installing Docker on Ubuntu

To install Docker on Ubuntu, run the following commands:

1. Update the `apt` package index and install required packages:
```bash
sudo apt-get update
sudo apt-get install ca-certificates curl gnupg
```

2. Add Docker's official GPG key:
```bash
sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
sudo chmod a+r /etc/apt/keyrings/docker.gpg
```

3. Set up the repository:
```bash
echo \
  "deb [arch="$(dpkg --print-architecture)" signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  "$(. /etc/os-release && echo "$VERSION_CODENAME")" stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
```

4. Install Docker Engine and related plugins:
```bash
sudo apt-get update
sudo apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
```

## Running Docker without root privileges (sudo)

By default, the `docker` command can only be run by the root user or by a user in the `docker` group. To use Docker without needing to prefix commands with `sudo`:

1. Create the `docker` group (it may already exist):
```bash
sudo groupadd docker
```

2. Add your current user to the `docker` group:
```bash
sudo usermod -aG docker $USER
```

3. Apply the new group membership (or log out and log back in):
```bash
newgrp docker
```

4. Verify that you can run `docker` commands without `sudo`:
```bash
docker run hello-world
```

## Setting Docker to always run (Start on Boot)

To ensure the Docker service starts automatically whenever your Linux server boots up, use `systemctl`:

```bash
sudo systemctl enable docker.service
sudo systemctl enable containerd.service
```

If you need to start it immediately in your current session without rebooting:
```bash
sudo systemctl start docker.service
```

## Important Commands for Regular Usage

### Checking Docker container stats
You can run:
```bash 
docker stats 
```
to get a live, real-time feed of exactly how much CPU, memory, and network I/O each specific container is using.

### Checking each container logs
You can pull logs from any container using a single, unified command:
```bash
docker logs <container_name>
```
making debugging much more logical and efficient.
To continuously follow the logs (like `tail -f`), add the `-f` flag:
```bash
docker logs -f <container_name>
```

### Listing Containers
To see currently running containers:
```bash
docker ps
```
To see all containers (including stopped ones):
```bash
docker ps -a
```

### Starting, Stopping, and Restarting Containers
To start a stopped container:
```bash
docker start <container_name_or_id>
```
To stop a running container gracefully:
```bash
docker stop <container_name_or_id>
```
To restart a running container:
```bash
docker restart <container_name_or_id>
```

### Removing Containers and Images
To remove a stopped container:
```bash
docker rm <container_name_or_id>
```
To remove a Docker image:
```bash
docker rmi <image_name_or_id>
```
To clean up unused space (removes all stopped containers, unused networks, dangling images, and build cache):
```bash
docker system prune
```

### Executing Commands Inside a Container
To run an interactive bash shell inside a running container (useful for inspecting the inside of a container):
```bash
docker exec -it <container_name_or_id> /bin/bash
```
*(Tip: If `/bin/bash` is not available, try `/bin/sh` instead).*