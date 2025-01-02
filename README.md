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

<hr>

### [split network access](https://github.com/futuramafamilyguy/auckland-mall-guide/tree/split-network)

client and server are exposed via the host network while database access is kept within the internal docker network

this setup aims to use docker's internal networking wherever possible to adhere to "least privilege". server communicates with the database internally but the client and server are exposed to the public. exposing the client is obvious as it serves as the "entrypoint" to the web app (ie. users interact with the webpage which in turn make calls to the server). the reason the server also needs to be exposed is that the client container does not run the react app itself but instead a service that serves webpages to the user's browser. and so what ends up making requests to the server is not the client container (which resides on the same host and can communicate with the server internally) but the user node or browser which is why the server also needs a public entrypoint. you can think of eposing the server container as a necessary evil here. maybe a [lesser evil](https://allenmaygibson.com/blog/geralt-takes-idioms-literally)?

suitable if:

- ceebs setting up a reverse proxy

<br>

setup:

- no need to set up port publishing for mongodb because server will communicate with it via docker's internal network
- server depends on `MONGO_URI` env var so set it to `mongodb://mongodb:27017/auckland-mall-guide` (this will be the same for both prod and local)
- server needs to be publicly accessible so set up port publishing `3000:3000` (server app listens on 3000 within the container and will receive requests sent to port 3000 of the host)
- client needs to be publicly accessible so set up port publishing `3001:3000` (serve-webpage service listens on 3000 within the client container so there is no conflict with the server app listening on 3000 in the server container but the host port must be different to avoid conflicts)

**prod**

- client depends on `VITE_API_URL` env var so set it to `http://mydomain.com:3000/api/malls` (server container which is accessible via host's port 3000)
- client itself will be accessible at `http://mydomain.com:3001`

**local environment**

- client depends on `VITE_API_URL` env var so set it to `http://localhost:3000/api/malls`
- client itself will be accessible at `http://localhost:3001`
