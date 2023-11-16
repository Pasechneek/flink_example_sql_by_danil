up:
	docker-compose up -d

1:
	cd /home/danil/Flink/flink-1.18.0 && ./bin/start-cluster.sh && ./bin/sql-client.sh

2:
	docker-compose exec postgres psql -h localhost -U postgres

3:
	docker-compose exec mysql mysql -uroot -p123456

down:
	docker-compose down
	cd /home/danil/Flink/flink-1.18.0 && ./bin/stop-cluster.sh

cleanup:
	docker-compose down --rmi all

fstop:
	cd /home/danil/Flink/flink-1.18.0 && ./bin/stop-cluster.sh

sqlserver:
	 docker-compose exec sqlserver sh