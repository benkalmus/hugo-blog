ENV_FILE = "$(CURDIR)/.env"

source:
	@. $(ENV_FILE) && echo "VAR2 is $$PASSWORD"

run:
	hugo server -D

build: 
	hugo 

#TODO CI/CD or Docker
push: build 
	tar -czf blog.tar.gz public/*
	rsync -ra --progress blog.tar.gz portfolio-website-aws:~/ 	
	@. $(ENV_FILE) && ssh portfolio-website-aws "echo $$PASSWORD | sudo -S bash /home/benkalmus/deploy-blog.sh"

