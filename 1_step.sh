#!/bin/bash

docker-compose up -d
cd /home/danil/Flink/flink-1.18.0 && ./bin/start-cluster.sh && ./bin/sql-client.sh