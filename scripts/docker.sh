#!/bin/bash

docker stop mailwizz && docker rm mailwizz
docker build --rm=true --no-cache=true -t mailwizz .
docker run --name mailwizz -d -p 8080:80 twisted1919/mailwizz
docker exec -it mailwizz /root/mailwizz/scripts/setup.sh

