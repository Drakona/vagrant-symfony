# path to composer
BACK_PACKAGE_MANAGER=./composer.phar

# flags for composer
BACK_PACKAGE_MANAGER_FLAGS=-o

# path to yarn
FRONT_PACKAGE_MANAGER=yarn

# path to gulp
ASSETS_BUILDER=gulp

# Symfony command
SYMFONY_CONSOLE=php bin/console

# flags to assets:install
ASSETS_FLAGS=--symlink

# flags to assets:install
ENV=dev

# Paths
# Cache folders (essentially for LiipImagine)
ASSETS_CACHE_FOLDER=web/media/cache/*
# Upload Path
UPLOAD_PATH=web/uploads

# Source pour la documentation du Makefile : http://marmelab.com/blog/2016/02/29/auto-documented-makefile.html
.DEFAULT_GOAL := help

#
#
# Commandes principales
#
#
setup: vm.init vm.ssh.install ## Crée la VM et installe le projet à l'intérieur

install: packages.init db.init build ## Installe le projet et toutes ses dépendances, puis les assets et la base de données

update: packages.update db.update build ## Met à jour le projet, sa base de données et ses assets

upgrade: packages.upgrade db.update build ## Met à jour le projet, sa base de données, ses assets et les versions des librairies front ET back

build: assets.build ## Met à jour les assets. Supporte le paramètre env (dev ou prod)

run: build assets.watch ## Met à jour les assets et surveille leur modification. Supporte le paramètre env (dev ou prod)

start: vm.start ## Lance la machine virtuelle, s'y connecte en SSH et lance la commande run

lint: assets.lint ## Vérifie les coding standards des différents fichiers du projet (sass, js, twig, php, yaml)

clean: assets.clean build ## clean tous les assets et les build à nouveau

sitemap: sitemap.dump ## Construit les fichiers de sitemap

help:
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-9s\033[0m %s\n", $$1, $$2}'

#
#
# Sous-commandes
#
#

#
# Initialise les package managers et lance l'installation des composants (front et back)
#
packages.init: packages.back.init packages.front.init

#
# Met à jour les package managers et install les composants (front et back)
#
packages.update: packages.back.update packages.front.update

#
# Met à jour les package managers et met à jour les composants (front et back)
#
packages.upgrade: packages.back.selfupdate packages.back.upgrade packages.front.upgrade

#
# Initialise le package manager pour php / code serveur
#
packages.back.selfinit: assets.back.init
	curl -s http://getcomposer.org/installer | php

#
# Met à jour le package manager pour php / code serveur
#
packages.back.selfupdate: assets.back.selfupdate
	$(BACK_PACKAGE_MANAGER) self-update

#
# Initialise les composants pour php / code serveur
#
packages.back.init: packages.back.selfinit
	$(BACK_PACKAGE_MANAGER) install $(BACK_PACKAGE_MANAGER_FLAGS)

#
# Met à jour les composants pour php / code serveur
#
packages.back.update:
	$(BACK_PACKAGE_MANAGER) install $(BACK_PACKAGE_MANAGER_FLAGS)

#
# Met à jour les composants pour php / code serveur
#
packages.back.upgrade: packages.back.selfupdate
	$(BACK_PACKAGE_MANAGER) update $(BACK_PACKAGE_MANAGER_FLAGS)

#
# Initialise les composants pour le front (js / sass / css)
#
packages.front.init:
	$(FRONT_PACKAGE_MANAGER) install --force

#
# Installe les composants pour le front (js / sass / css)
#
packages.front.update: packages.front.init

#
# Met à jour les composants pour le front (js / sass / css)
#
packages.front.upgrade:
	$(FRONT_PACKAGE_MANAGER) upgrade

#
# Lance les linters pour les assets (front et back)
#
assets.lint: assets.back.lint assets.front.lint

#
# Construit les assets (fichiers css, js et images finales) les assets (front et back)
#
assets.build: assets.back.build assets.front.build

#
# Supprime les fichiers temporaires, en vue d'être reconstruits (front et back)
#
assets.clean: assets.back.clean assets.front.clean

#
# Supprime les fichiers temporaires, en vue d'être reconstruits (front et back)
#
assets.watch: assets.front.watch

#
# Supprime les fichiers temporaires, en vue d'être reconstruits (front)
#
assets.front.clean:
	$(ASSETS_BUILDER) clean --env=$(ENV)

#
# Lance les linters pour les assets (front)
#
assets.front.lint:
	$(ASSETS_BUILDER) lint --env=$(ENV)

#
# Lance le build (compilation des assets) pour les assets (front)
#
assets.front.build:
	$(ASSETS_BUILDER) --$(ENV)

#
# Lance le suivi de modifications des assets (front)
#
assets.front.watch: assets.front.build
	$(ASSETS_BUILDER) watch --$(ENV)

#
# Supprime les fichiers temporaires, en vue d'être reconstruits (back)
#
assets.back.clean:
	rm -rf $(ASSETS_CACHE_FOLDER)
	$(SYMFONY_CONSOLE) cache:clear --env=$(ENV)

#
# Lance les linters pour les assets (vues et configs) (back)
#
assets.back.lint:
	$(SYMFONY_CONSOLE) lint:twig app --env=$(ENV)
	$(SYMFONY_CONSOLE) lint:twig src --env=$(ENV)
	$(SYMFONY_CONSOLE) lint:yaml app --env=$(ENV)
	$(SYMFONY_CONSOLE) lint:yaml src --env=$(ENV)

#
# Télécharge les commandes nécessaires pour les assets
#
assets.back.init:
	wget http://cs.sensiolabs.org/download/php-cs-fixer-v2.phar -O php-cs-fixer.phar

#
# Met à jour les commandes nécessaires pour les assets
#
assets.back.selfupdate:
	php php-cs-fixer.phar self-update

#
# Corrige les problèmes de coding standards
#
assets.back.fix:
	php php-cs-fixer.phar fix src/

#
# Construit les assets (back)
#
assets.back.build:
	$(SYMFONY_CONSOLE) assets:install $(ASSETS_FLAGS) --env=$(ENV)
	$(SYMFONY_CONSOLE) fos:js-routing:dump --target=web/bundles/fosjsrouting/js/routes.js --env=$(ENV)

#
# Exporte les traductions pour le js
#
translations.dump:
	$(SYMFONY_CONSOLE) bazinga:js-translation:dump web/bundles/bazingajstranslation/js/ --env=$(env)

#
# Initialise la base de données
#
db.init: db.create db.migrations.migrate db.elastica.populate

#
# Met à jour la base de données
#
db.update: db.migrations.migrate db.elastica.populate

#
# Met à jour de manière forcée le schema de base de données (à éviter)
#
db.schema.update:
	$(SYMFONY_CONSOLE) doctrine:schema:update --force --env=$(ENV)

#
# Lance les migrations (met à jour la base de données)
#
db.migrations.migrate:
	$(SYMFONY_CONSOLE) doctrine:migrations:migrate --allow-no-migration --no-interaction --env=$(ENV)

#
# Génère un fichier de migration contenant les différences
# de schéma avec la base précédente
#
db.migrations.diff:
	$(SYMFONY_CONSOLE) doctrine:migrations:diff --env=$(ENV)

#
# Crée la base de données et les tables
#
db.create:
	$(SYMFONY_CONSOLE) doctrine:database:create --if-not-exists --env=$(ENV)

#
# Supprime la base de données
#
db.drop:
	$(SYMFONY_CONSOLE) doctrine:schema:drop --force --env=$(ENV)
	$(SYMFONY_CONSOLE) doctrine:database:drop --force --env=$(ENV)

#
# Met à jour l'index elasticsearch
# (synchronise avec la base de données)
#
db.elastica.populate:
	$(SYMFONY_CONSOLE) fos:elastica:populate --env=$(ENV)

#
# Crée les fichiers de sitemaps
#
sitemap.dump:
	$(SYMFONY_CONSOLE) presta:sitemap:dump --gzip --env=$(ENV)

#
# Déploie sur le serveur de demo
#
deploy.demo:
	cap demo deploy

#
# Déploie sur le serveur de prod
#
deploy.prod:
	cap prod deploy



################################################################################
#                                                                              #
#                                   VM Commands                                #
#                                                                              #
################################################################################

#
# Init your VM
#
vm.init: vm.init.plugins vm.run vm.init.provision

#
# Run ansible to install vagrant content
#
vm.init.provision:
	vagrant provision

#
# Install necessary plugins
#
vm.init.plugins:
	vagrant plugin install landrush
	vagrant plugin install vagrant-vbguest

#
# Update project from host
#
vm.ssh.update:
	vagrant ssh -- "cd /vagrant && make update"

#
# Install project from host
#
vm.ssh.install:
	vagrant ssh -- "cd /vagrant && make install"

#
# Start your VM
#
vm.start: vm.run vm.connect

#
# Start vagrant (and skip provisionning)
#
vm.run:
	vagrant up --no-provision

#
# Connect via ssh to the vagrant
#
vm.connect:
	vagrant ssh
