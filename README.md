# auckland-mall-guide

reference material for deploying containerised fullstack apps with nginx as a reverse proxy

this is intended for small personal projects and not large scale enterprise applications

this repo covers a few different options for container setup to show what's possible and to understand docker's networking mechanisms a little deeper.
these options will have their own dedicated branch with the `main` branch being the recommended setup

<hr>

### [host network access](https://github.com/futuramafamilyguy/auckland-mall-guide/tree/host-network)

server container communicates with mongodb container via the host

this means, instead of relying on docker's internal networking, the mongodb container is exposed via the host. the container can be configured so that requests that arrive at a specific port on the host will be forwarded to a specific port in the container. because clients target the host ip (eg. server applicaion's connection string), it would appear from the outside that the mongodb instance is running directly on the host

not suitable for small fullstack apps where every component typically reside on a single node. the downside of this approach is that the server container communicates with the mongodb container by targeting the host's published IP or hostname, which triggers the full external networking process, including DNS resolution and routing through the host's networking stack, just to route back to the same machine. incurs a lot of unnecessary overhead and latency compared to using docker's internal networking as containers are able to communicate without leaving the virtual network

suitable if:

- server resides on a separate host from the database
- need to access certain containers from outside the host (eg. app is running on a remote vm and you want to query and update the databse without having to ssh into the vm)

<br>

setup:

- mongodb instance runs in its container on its default port of 27017
- mongodb container makes port 27017 accessible to the host system through port publishing: `27017:27017` in `docker-compose.yml`
- communicating with the host on port 27017 will be as if you are communicating with the mongodb server directly

**prod**

- if the host is publicly available at `mydomain.com`, then the mongodb container can be accessed via connection string `mongodb://mydomain.com:27017`
- `MONGO_URI=mongodb://mydomain:27017/auckland-mall-guide` env var should be added to the `server` servce in `docker-compose.yml`
  - this is the connection string the server will use when communicating with mongodb

**local environment**

- if running locally (eg. running it on a laptop connected to a home network), server container can access the host (and turn mongodb container) using the host's private IP
- by default (depending on Docker's network configuration), containers are connected to an internal virtual network managed by docker, which is isolated from the host's private network, allowing containers to communicate with each other using their private IPs
  - isolation means containers cannot directly interact with devices on the host's network unless explicitly configured to do so but there is a special case where containers are able to access the host via its private IP in its own network
- once you find your host's private IP, you can verify it's reachable from the container by running `ping <host private ip>` inside the container
- if it works, set env var `MONGO_URI=mongodb://<host private ip>:27017/auckland-mall-guide` in `docker-compose.yml`
- if running docker on windows and macos, there is a `host.docker.internal` address that resolves to the host's private IP reachable by its containers
