ENV_FILE = "$(CURDIR)/.env"

run:
	hugo server -D

build: 
	hugo 

#TODO CI/CD or Docker
push: build 
	rm blog.tar.gz
	tar -czf blog.tar.gz public/*
	rsync -ra --progress blog.tar.gz portfolio-website-aws:~/ 	
	@. $(ENV_FILE) && ssh portfolio-website-aws "echo $$PASSWORD | sudo -S bash /home/benkalmus/deploy-blog.sh"

clean:
	hugo --cleanDestinationDir
	rm -rf public
