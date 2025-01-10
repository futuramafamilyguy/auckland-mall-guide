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

- if running locally (eg. on a laptop connected to a home network), server container can access the host (and in turn mongodb container) using the host's private IP
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
- should mention that in `docker-compose.yml`, `VITE_API_URL` is declared as a build arg instead of an env var
  - is because vite requires all env vars to be available during build time. once the app has been built, it can't retroactively read env vars on the host (in our case the client container) it's running on
  - declaring `VITE_API_URL` as env var in `docker-compose.yml` will simply set the `VITE_API_URL` env var in the resulting container _after_ react app has been built so it does nothing
  - declaring `VITE_API_URL` as build arg instead will pass it to docker's temporary build environment used to run instructions in the Dockerfile and set it as an env var in the temporary environment (`ARG VITE_API_URL` and `ENV VITE_API_URL=$VITE_API_URL` in the Dockerfile) which can be accessed by vite during build time

**prod**

- client depends on `VITE_API_URL` env var so set it to `http://mydomain.com:3000/api/malls` (server container which is accessible via host's port 3000)
- client itself will be accessible at `http://mydomain.com:3001`

**local environment**

- client depends on `VITE_API_URL` env var so set it to `http://localhost:3000/api/malls`
- client itself will be accessible at `http://localhost:3001`

**localhost vs private IP**

this is for local environment only

- in host network access, where the database is exposed to the host network using port publishing, the server container communicates with it using the host's private IP (ie. `mongodb://<host private ip>:27017/auckland-mall-guide`)
- in split network access, where server and client containers are exposed to the host network using port publishing, the client container communicates with the server using localhost with the corresponding port (ie. `http://localhost:3000/api/malls`)
- wtf.jpeg
- how come one uses localhost and the other private IP
- it's kinda been explained already in the intro section for split network access but i'll do it here in more detail
- it can be a bit confusing but key is to think about where the request is coming from and where it's going to

- **server -> database: private IP**
  - server app runs on container A port 3000
  - database runs on container B port 27107
  - the server app itself sends requests to the database using its container's (container A) networking stack
  - if server communicates with database using localhost (ie. `mongodb://localhost:27017/auckland-mall-guide`), then the request will be routed back to the same container (container A) port 27107 **<----- here is the answer**
  - nothing will happen because only the server app is running on container A and nothing is listening on port 27107 **<----- here is the answer**
  - the databse runs on a separate container (cotnainer B) so the request must leave container A which is why localhost doesn't work here
  - database is exposed to the host network so in order to locate container B, need to locate the host which we can do so via the host's private IP using the corresponding port set up in port publishing (more details on this explained in the host network access section)
- **client -> server: localhost**
  - server app runs on container A port 3000
  - client app (service that serves webpages) runs on container B port 3000
  - both client and server containers have port publishing set up (server: `3000:3000`, client: `3001:3000`)
  - means server is accessible at `http://localhost:3000` from host machine and client is accessible at `http://localhost:3001` from host machine even though both apps listen on port 3000 within their respective containers
  - to get react pages, make request to client container (which runs an app that serves webpages) by calling `http://localhost:3001` from the browser or like curl or something
  - this works because the host from which the client container is accessible at `http://localhost:3001` is the same host from which the browser makes the request
  - request flow looks like this:
    - **type http://localhost:3001 in browser**
    - **browser sends request to its host's networking stack**
    - **networking stack realises it's localhost and sends the request back to itself**
    - **host receives a request to port 3001**
    - **requests to port 3001 are forwarded to client container's port 3000 thanks to port publishing**
    - **app inside client container returns the webpages**
    - **browser renders resulting webpage**
  - now when react page is loaded in the browser, it sends a request to server container by calling `http://localhost:3000`
  - this also works because it is not the client container that makes this request, it is the react app which runs in the browser inside the host so any requests that it sends to localhost goes through the host's networking stack which means requests will be routed back to the same host, going through the same flow as above (except that it targets port 3000 instead of 3001)

**bridge network vs custom network**

this section just goes into some stuff docker compose abstracts away from us (if you use default configuration like this project)

- there are two types of docker internal network: default bridge network or user-defined custom networks
- can think of these internal networks as a way to group all your containers together so that they can communicate with each other while keeping them isolated collectively
- all the examples so far use custom networks because we're using docker compose and all containers declared in a docker compose yml have a default compose network set up
- when you have started all the containers using docker compose, you can run `docker network ls` for all networks among which you should see two: `bridge` (default bridge network) and `auckland-mall-guide_default` (default docker compose network. if you have another docker compose yml and run it you will see another `<app name>_default` network)
- run `docker network inspect auckland-mall-guide_default` and you will see under `"Containers"` field all containers that are part of the network which should be the client, server, and mongodb containers
- here's what happens if you're not using docker compose for container management:
  - any containers you create manually using docker with default network configuration will be under the default bridge network (run `docker network inspect bridge` and you will see the container you just started)
  - let's say i want to create all my containers (client, server, mongodb) manually:
    - create mongodb: `docker run -d --name mongodb -v $(pwd)/data:/data/db -v $(pwd)/mongodb/scripts:/docker-entrypoint-initdb.d mongo:latest`
    - before i create server container, here's an issue with using the default bridge network
    - while all containers part of the bridge network can communicate with each other, they can only refer to each other by their private IPs
    - if i attempt to create server container using the mongodb container name like so: `docker run -d --name server -p 3000:3000 -e MONGO_URI=mongodb://mongodb:27017/auckland-mall-guide server-image`, it will fail to resolve the name and return `getaddrinfo ENOTFOUND mongodb`
    - to create server properly, connection string for mongodb must refer to its private IP
    - to get private IP, run `docker inspect mongodb` which you can find under `"NetworkSettings"` > `"Network"` > `"bridge"` > `"IPAddress"`
    - now can create server using private IP for mongodb connection string like so `docker run -d --name server -p 3000:3000 -e MONGO_URI=mongodb://<said private IP>/auckland-mall-guide server-image`
    - annoying AF
    - using custom network is way more convenient because containers can address each other via their container name or service name (the latter in the case of using docker compose) so not only is it more readable you also don't have to go through the process of detecting containers' IP addresses (addressii?) within the bridge network
    - to bypass this, you can create a custom network and then bind all containers you create to it like so:
      - create custom network using docker: `docker network create -d bridge my-custom-network`
      - create mongodb and bind to network: `docker run -d --name mongodb --network my-custom-network -v $(pwd)/data:/data/db -v $(pwd)/mongodb/scripts:/docker-entrypoint-initdb.d mongo:latest`
      - can now create server with mongodb name for connection string as long as it's also bound to the same network: `docker run -d --name server --network my-custom-network  -p 3000:3000 -e MONGO_URI=mongodb://mongodb:27017/auckland-mall-guide server-image`
    - you can see this already working when using docker compose without any additional network configuration in the setup section under split network access where server container's env var for mongodb connection string is `mongodb://mongodb:27017/auckland-mall-guide` (ie. uses service name and not private IP)
      - works because server and mongodb containers are created via docker compose and therefore both containers are on the default custom network created by docker compose (**not** the bridge network)
- it can still be beneficial to declare custom networks in docker compose yml instead of relying on its default one because you can group containers together and place them in separate networks to disable communication between certain containers while allowing them to communicate with other containers

<hr>

### [split network with reverse proxy](https://github.com/futuramafamilyguy/auckland-mall-guide/tree/nginx-split)

same set up as split network but with nginx set up as a reverse proxy

this means client and server are still accessible via host network just with nginx (also accessible via host network). this set up is not recommended at all since the purpose of a reverse proxy is to prevent direct communication between users and your apps (client and server in this case) so having a reverse proxy _and_ publicly available client and server containers defeats its purpose. just thought i'd do a section here to explain how nginx works so the next section on the recommended set up for reverse proxy won't as bloated with info

only going to do local environment since this isn't recommended anyway

client and server still accessible at `http://localhost:3001` and `http://localhost:3000` respectively. this is not great as mentioned in the previous section, but a necessary evil because users need something publicly available for them to interact with. nginx is meant to server as a single point of entry for users into the system so no matter what, nginx must be publicly accessible

**what ports should nginx be accessible at?**

first thing to understand is that in a typical fullstack web app, users (via the browser) make requests to fetch the client pages and when they interact with them, the client pages would send requests to the backend server (also via the browser). because both requests are made from external sources, this is why the server must be publicly accessible as well. before, it was easy targeting each container because they listened on different ports in the host but now that all requests go through nginx first, need a different way to differentiate the requests. common practice in production would be for client requests to target `domain.com` and server requests `api.domain.com`. both need to be set up to point to the host IP using DNS records. this means the reverse proxy would be listening on default ports like port 80 for http (which is why there are no ports specified) which is a good practice since these are user-facing. both requests would arrive at the same host on port 80 and nginx would be configured to route requests to their respective containers (based on the presence of `api` subdomain). in our case, because we're running this locally, we can only use `localhost` which means we can't use subdomains (not easily anyway). for the next best option, we will use default port 80 for client and port 8080 for server container since users don't directly call the server, their browser does so behind the scenes. so need to expose two ports for nginx: 80 (request flow: browser -> `http://localhost` -> client container) and 8080 (request flow: browser -> `http://localhost:8080` -> server container)

**how to configure nginx?**

in a nutshell, using nginx's config file `*.conf` you specify which ports nginx should listen on and the url the request should be forwarded to given the port (`proxy_pass`). in our case, want to intercept requests that arrive at port 80 and forward them to client container and requests that arrive at port 8080 which should be forwarded to server container. client and server containers are both accessible using `localhost` of the host, but the problem with targeting `localhost` in nginx config is that when nginx forwards requests, those requests are sent from the nginx container and because it's `localhost`, the request would be looped back into the nginx container. what it should do is after requests are forwarded by nginx, they leave the nginx container, go back to the host which is then sent to the client and server containers that are running on the host.

now that are are targeting host from within the nginx container, then we should set the forward-url as the host's private IP which was discussed earlier. once the forwarded request arrives at the host, it needs to be sent to the client or server container which is accessible using the port set up during port publishing. so the nginx config should be: bind port 80 to `http://<private ip of host>:3001` and binding port 8080 to `http://<private ip of host>:3000`

once the config file has been created, simpl copy the config file from your local machine into the running nginx container using: `sudo docker cp <path on local machine to config file>/default.conf <nginx container name>:/etc/nginx/conf.d/` and then reload nginx with the updated config in the container by running `sudo docker exec <nginx container name> nginx -s reload`

this is the manual step you would take but in the actual setup using docker compose, this step is done slightly differently because we want to use env var in the config file for client and server urls to avoid committing the host's private IP to source control. instead of `default.config` file we use `default.template` file. the content should be indentical except that in the template file, all values that need to be read from env vars are replaced with `${ENV_VAR}`. this is unusable on its own but there's a `start.sh` script that uses `envsubst` to substitute all instances of env var templates in `default.template` with their actual values loaded from the host (ie. the output script when run against the template file would be the exact content of the template file except any instances of `${ENV_VAR}` would be replaced with the actual value set to `ENV_VAR` in the host machine). the output is then written to `default.config` in the expected location for nginx config inside the container. the `default.config` file is always generated using `default.template` and `start.sh` so it doesn't need to be committed to source control

**setup**

- set `MONGO_URI` env var to `mongodb://mongodb:27017/auckland-mall-guide`
- set up `3000:3000` port publishing for server container so it is accessible on the host at `http://localhost:3000`
- set up `3001:3000` port publishing for client container so it is accessible on the host at `http://localhost:3001`
- configure port 8080 in `nginx/default.template` to forward requests to `${SERVER_URL}`
  - set `SERVER_URL` env var to `http://<private IP of host>:3000`
- configure port 80 in `nginx/default.template` to forward requests to `${CLIENT_URL}`
  - set `CLIENT_URL` env var to `http://<private IP of host>:3001`
- set up `8080:8080` and `80:80` port publishing for nginx container so it is accessible on the host at `http://localhost:8080`and `http://localhost`
  - `http://localhost:8080` gets forwarded to server container at `${SERVER_URL}`: `http://<private IP of host>:3000`
  - `http://localhost` gets forwarded to client container at `${CLIENT_URL}`: `http://<private IP of host>:3001`
- copy `default.template` and `start.sh` so they can be used inside nginx container for configuration using volumes
- set `VITE_API_URL` env var to `http://localhost:8080/api/malls`
  - this env var is used by the client pages to make requests to server container
  - can either be set to `http://localhost:8080/api/malls` or `http://localhost:3000/api/malls`
  - 3000 is accessible because of port publishing on host for server container
  - 8080 also works because `http://localhost:8080` targets the nginx container and 8080 will reroute the request to `http://localhost:3000`
  - bit pointless because the request takes a detour to nginx instead of straight to the server but it demonstrates the what nginx allows you to do

with all this set up, can access the whole app by typing `http://localhost` in the browser (`http://localhost:3001` also works for the same reason as the last few bullet points above)
