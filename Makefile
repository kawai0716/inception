NAME = inception

COMPOSE = docker compose -f srcs/docker-compose.yml
DATA_DIR = /home/sykawai/data

all: up

up:
	mkdir -p $(DATA_DIR)/mariadb $(DATA_DIR)/wordpress
	$(COMPOSE) up --build -d

down:
	$(COMPOSE) down

clean:
	$(COMPOSE) down -v

fclean: clean
	$(COMPOSE) down -v --rmi all --remove-orphans

re: fclean up

ps:
	$(COMPOSE) ps
