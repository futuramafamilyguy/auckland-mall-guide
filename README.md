# auckland-mall-guide

reference material for deploying containerised fullstack apps with nginx as a reverse proxy

this is intended for small personal projects and not large scale enterprise applications

this repo covers a few different options for container setup to show what's possible and to understand docker's networking mechanisms a little deeper
these options will have their own dedicated branch with the `main` branch being the recommended setup

### [host network access](https://github.com/futuramafamilyguy/auckland-mall-guide/tree/host-network){:target="blank"}

in this one, the server container communicates with the mongodb container via the host

- mongodb instance runs in its container on port 27017
- mongodb container makes port 27017 accessible to the host system through port publishing: `27017:27017` in `docker-compose.yml`
- communicating with the host on port 27017 will act as if you are communicating with the mongodb server directly
- this means that in production, if the host is publicly available at `mydomain.com`, then the mongodb container can be accessed via connection string `mongodb://mydomain.com:27017`
  - in production, `MONGO_URI=mongodb://mydomain:27017/auckland-mall-guide` env var should be added to the `server` servce in `docker-compose.yml`
- this connection string can be used by anything (eg. your server application or some database UI like mongodb compass)
- in a local setting where the host running the containers is not publicly available via a domain (eg. running it on a laptop connected to a home network), containers can access the host via the host's private IP
  - normally (depending on docker's network config) containers have their own internal virtual network managed by Docker isolated from the host's network so containers can communicate with each other via their private IPs but not devices connected to the host's network
  - there is a special case where containers are able to access the host via its private IP
  - once you find your host's private IP, you can verify it's reachable from the container by running `ping <host private ip>` inside the container
  - if it works, set env var `MONGO_URI=mongodb://<host private ip>:27017/auckland-mall-guide` in `docker-compose.yml`
  - if running docker on windows and macos, there is a `host.docker.internal` address that resolves to the host's private IP reachable by its containers

for a small personal standard fullstack app where every component typically resides on a single node, the downside of this approach is that communication between the nodes would need to go through the usual request process just to come back to the same machine, incurring unnecessary overhead (going through networking layers, OS's networking stack, DNS resolution, etc.)

setting port publishing to allow mongodb access via the host is suitable if you need to access the database from outside its host

- server resides on a different host
- sometimes you may want to monitor or updae your database using a UI like mongodb compass from your local machine without needing to ssh to your remote vm where everything is deployed. in this case publicly accessible mongodb would be handy as you can simply add the connection string to your UI
