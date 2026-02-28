NAME = inception

COMPOSE = docker compose -f srcs/docker-compose.yml
DATA_DIR = /home/sykawai/data
SECRETS = db_password db_root_password wp_admin_password wp_user_password

all: up

init:
	mkdir -p $(DATA_DIR)/mariadb $(DATA_DIR)/wordpress
	@for s in $(SECRETS); do \
		cp -n secrets/$$s.txt.example secrets/$$s.txt; \
	done

up: init
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
