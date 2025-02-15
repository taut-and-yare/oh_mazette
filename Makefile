watch:
	npx @tailwindcss/cli -i ./src/tailwind.css -o ./src/styles.css --watch

django:
	docker compose -f docker-compose.local.yml up django

migrations:
	docker compose -f docker-compose.local.yml run --rm django python manage.py makemigrations

migrate:
	docker compose -f docker-compose.local.yml run --rm django python manage.py migrate

test:
	docker compose -f docker-compose.local.yml run --rm django pytest -s

update:
	./update.sh
