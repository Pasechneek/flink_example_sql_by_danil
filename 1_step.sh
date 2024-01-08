#!/bin/bash

docker-compose up -d
./start-cluster.sh && ./sql-client.sh