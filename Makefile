tailwind_build:
	npx @tailwindcss/cli -i ./oh_mazette/static/css/tailwind.css -o ./oh_mazette/static/css/styles.css  --minify

push: tailwind_build
	@git status -s  # Show changed files
	@read -p "Enter commit message (leave blank to cancel): " msg; \
	if [ -z "$$msg" ]; then \
		echo "Commit canceled."; \
	else \
		git add . && git commit -m "$$msg" && git push; \
	fi

django:
	docker compose -f docker-compose.local.yml up django

dev:
	unbuffer npx tailwindcss -i ./oh_mazette/static/css/tailwind.css -o ./oh_mazette/static/css/styles.css --watch | awk '{print "\033[1;32m[Tailwind]\033[0m", $$0}' & \
	unbuffer docker compose -f docker-compose.local.yml up django | awk '{print "\033[1;34m[Django]\033[0m", $$0}' & \
	trap 'pkill -P $$' EXIT  # Kill all background processes when exiting
	wait

build:
	docker compose -f docker-compose.local.yml build

migrations:
	docker compose -f docker-compose.local.yml run --rm django python manage.py makemigrations

migrate:
	docker compose -f docker-compose.local.yml run --rm django python manage.py migrate

manage: # e.g. make manage cmd="migrate"
	docker compose -f docker-compose.local.yml run --rm django python manage.py $(cmd)

test:
	docker compose -f docker-compose.local.yml run --rm django pytest -s

update:
	./update.sh
