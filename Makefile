1:
	docker-compose up -d
	./start-cluster.sh && ./sql-client.sh

2:
	docker-compose exec postgres psql -h localhost -U postgres

3:
	docker-compose exec mysql mysql -uroot -p123456

down:
	docker-compose down
	./stop-cluster.sh

rmall:
	docker-compose down --rmi all

fstop:
	./stop-cluster.sh