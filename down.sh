#!/bin/bash

docker-compose down
cd ~/Flink/flink-1.18.0 && ./bin/stop-cluster.sh