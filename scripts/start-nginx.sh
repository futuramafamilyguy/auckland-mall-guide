envsubst '${SERVER_URL} ${CLIENT_URL}' < /etc/nginx/conf.d/default.template > /etc/nginx/conf.d/default.conf
nginx -g 'daemon off;'
