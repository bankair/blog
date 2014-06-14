---
layout: post
title: Docteur Jekyll et Mister Wordpress
---

# Le flippant Mister Wordpress et son hypermnésie décorative

J'ai fait une expérience enrichissante : j'ai essayé de monter une plateforme wordpress avec un environnement de développement et un environnement de production, avec pour objectif de permettre à notre designer de tenter des modifications en local, dans son environnement de développement, et de pouvoir ensuite les pousser sur l'environnement de production.

Ça n'a pas du tout marché.

À cette occasion, j'ai découvert que Wordpress :

* gardait des chemins en dur dans sa base de donnée (sympa pour les changements d'adresse...)
* gardait du css en dur dans sa base de donnée (ça parait WTF au début, mais quand on y pense, si on veut permettre la customisation des pages, il faut bien les stocker quelque part...)

Résultat: Impossible de maintenir plusieurs environnements sans une mécanique complexe (modifier les références absolues, sérialiser et de-sérialiser la base de donnée).

# Le bon Docteur Jekyll

Pour ceux qui connaissent déjà le moteur de blog [Jekyll](http://jekyllrb.com/), je n'ai probablement pas besoin de tenter de vous le faire aimer. Pour les autres, je vous tartine avec plaisir une petite introduction sur le sujet.

## Jekyll, un generateur de site statique

Contrairement à Wordpress, Jekyll n'est pas un moteur de blog s'appuyant sur une base de donnée.

Avec Wordpress, les étapes pour installer le moteur et bloguer avec sont les suivantes:

1. Récupérer la [dernière archive de wordpress](http://fr.wordpress.org/txt-download/)
2. Installer mysql sur le serveur et créer une base de donnée
3. Installer Apache avec le support PHP
4. Décompresser l'archive sur le serveur web et modifier la configuration pour pointer sur la base mysql
5. Finir la configuration du serveur via ./wp-admin/install.php
6. Bloguer en éditant directement les articles dans l'interface d'admin du blog

Avec Jekyll:

1. Installer rbenv, ruby et la gem jekyll
2. Créer un blog : jekyll new blog
3. Ajouter des articles dans le répertoire blog/\_posts/
4. Générer le site statique avec 'jekyll build' dans le répertoire titre-du-nouveau-site.
5. Héberger le contenu du répertoire blog/\_site sur le serveur web

L'inconvénient est qu'il faut répéter les étapes 3, 4 et 5 (3 et 4, en ce qui me concerne. Je vous explique cela plus bas) à chaque fois qu'on souhaite ajouter ou modifier des articles.

Les avantages de Jekyll sont multiples:

* Site statique (et donc cachable), rendu plus rapide
* Un site Jekyll est versionable facilement (d'où son utilisation pour les blogs de github)
* On peut maintenir autant d'environnement que l'on veut et faire des tests sans affecter la 'production'

## Un workflow sexy et léger pour Jekyll

On vient de le voir, un des inconvénients de Jekyll est sont processus de publication qui ne permet pas, de base, de publier facilement de nouveaux articles.

Pour remédier à cet inconvénient, j'ai commencé par jeter un un oeil sur [capistrano](http://capistranorb.com). Et ensuite, je me suis rappelé que je souhaitais héberger un blog perso sur une dedibox, et pas une web app haute disponibilité avec quatre environnements de QA et des milliers d'utilisateurs.

### Le set up

La mise en place de mes deux environnements de blog s'est faite comme suit:
<a name="setup_overview"></a>

1. Création d'un blog jekyll en local
2. Création d'un repo github avec le contenu du blog
3. Clonage du repo sur le serveur
4. Génération du site sur le serveur avec 'jekyll build'
5. Installation de nginx sur le serveur et mise à jour de la configuration pour faire pointer le serveur sur le répertoire \_site du blog
6. Création d'un script sh qui effectue récupère la dernière version du blog depuis github, et qui génére le site statique (à executer sur le serveur)
7. Création d'un script sh qui pousse version locale du site sur github, qui se connecte en ssh sur le serveur et execute le script précédent.

Je vous détaille tout cela à [la fin de cet article](#setup_details).

### La publication

Aujourd'hui, mon processus de publication d'article est le suivant:

1. Je rédige un brouillon en local
2. Lorsque je suis satisfait, je déplace mon brouillon dans les articles, et je commit mes changements
3. Je lance le script de déploiement qui va pousser les changement vers github, déclencher une récupération et une reconstruction du site sur ma dedibox.

Dans un shell, sur mon poste de travail, cela se traduit par:

{% highlight bash %}
git mv ./_drafts/super-article.md ./_posts/2014-06-13-super-article.md
git add ./_posts/2014-06-13-super-article.md
git commit -m 'Publication du super article'
./push_to_prod.sh
{% endhighlight %}

Une mise à jour cosmétique ou l'ajout d'un thème se passe exactement de la même manière (commit + script de push au serveur), sans aucun downtime. Et cerise sur le gateau: Je peux tout tester en local avant de faire n'importe quoi avec mon site publié (hein, wordpress, t'entends ?).

* * *

### Le détail du set up
<a name="setup_details"></a>
Voici le détail processus de set up d'un blog jekyll tel que décrit [plus haut](#setup_overview).

#### 1. Création d'un site avec jekyll

Opération difficilement simplifiable:
{% highlight bash %}
jekyll new nom-du-site
{% endhighlight %}

En imaginant que je souhaite que mon site s'appelle blog, je vais taper:

{% highlight bash %}
jekyll new blog
{% endhighlight %}

Jekyll va aller créer tout ce qui va bien dans un répertoire appellé blog. Je vous invite à jeter un oeil à [la documentation officielle](http://jekyllrb.com/docs/structure/) pour plus de détails sur le contenu de ce répertoire.

#### 2. Création d'un repo github avec le contenu du blog

Pour commencer, je vais créer un repo sur mon compte [github](https://github.com), que je vais appeller 'blog'.
Ensuite, je vais dans le répertoire blog que j'ai créé en local quelques minutes plus tôt, et je fais ce qui suit:

{% highlight bash %}
# Initialisation d'un repo git dans le répertoire blog
git init .
# Ajout de tout le contenu du répertoire blog
git add .
# Premier commit
git commit -m 'initial commit'
# Ajout de mon repo github distant
git remote add origin https://github.com/mon-login-github/blog.git
# On pousse tout sur le repo distant
git push -u origin master
{% endhighlight %}

#### 3. Clonage du repo sur le serveur

{% highlight bash %}
ssh user@server
git clone https://github.com/mon-login-github/blog.git
{% endhighlight %}

#### 4. Génération du site sur le serveur avec 'jekyll build'

Pour générer le site une première fois sur le server:
{% highlight bash %}
ssh user@server
cd blog
jekyll build
{% endhighlight %}

Ainsi, une première version de mon site va exister dans le répertoire /home/user/blog/\_site, sur le serveur.

Pour générer le site en local sur mon poste, pendant que je travaille sur mes brouillons, j'utilise plutôt:

{% highlight bash %}
jekyll serve --drafts --watch
{% endhighlight %}

La commande serve effectue un build du site, et lance un serveur web sur le port 4000, ce qui permet de consulter son site eh allant sur _http://localhost:4000_.

L'option _--drafts_ permet d'afficher les brouillons du répertoire blog/\_drafts comme des articles publiés (pratique pour travailler dessus et jeter un oeil au rendu).

Quand à l'option _--watch_, elle lance une regeneration du site à chaque fois qu'un fichier est modifié (et du coup, pas besoin de tuer et relancer le serveur web local pour faire des tests).

#### 5. Installation de nginx sur le serveur et mise à jour de la configuration pour faire pointer le serveur sur le répertoire \_site du blog

L'étape suivante consiste à rendre disponible en ligne le site généré dans *~/blog/\_site*.

Mon serveur est une Debian, donc l'installation de nginx se fera d'un rapide coup de :

{% highlight bash %}
sudo apt-get install nginx
{% endhighlight %}

Une fois l'installation terminée, j'édite le fichier de configuration /etc/nginx/site-available/default, et j'y mets ce qui suit:

    server {
      root /home/user/blog/_site;
      index index.html index.htm;
      location / {
        try_files $uri $uri/ /index.html;
      }
      location /doc/ {
        alias /usr/share/doc/;
        autoindex on;
        allow 127.0.0.1;
        allow ::1;
        deny all;
      }
    }

On lance le server nginx:

    sudo /etc/init.d/nginx start

Et le site est ainsi disponible en ligne.

#### 6. Création d'un script sh qui effectue récupère la dernière version du blog depuis github, et qui génére le site statique (à executer sur le serveur)

J'ai souhaité éviter de devoir déployer à la main à chaque fois la dernière version du blog. Pour cela, j'ai écrit un script shell très simple que j'ai ajouté au repo:

{% highlight bash %}
    if git pull; then
      if bundle install; then
        if jekyll build; then
          echo "Deployment complete"
        else
          echo "Failed to build blog files"
        fi
      else
        echo "Failed to install bundle"
      fi
    else
      echo "Failed to Pull last sources"
    fi
{% endhighlight %}

J'ai placé ce script dans le répertoire ~/blog/ de mon server. Une fois ceci fait, si tout se passe bien, c'est la dernière fois que vous mettrez vos gros doigts sur le serveur.

Vous noterez que mon script utilise [bundler](http://bundler.io/), qu'il vous faudra aussi installer sur le server (ainsi que ruby, si il n'y est pas déjà).

#### 7. Création d'un script sh qui pousse version locale du site sur github, qui se connecte en ssh sur le serveur et execute le script précédent.

Je suis, comme beaucoup, assez flemmard. J'ai donc créé un micro script shell pour pousser les modifications locales sur mon compte github et les déployer sur mon server distant:

{% highlight bash %}
    git push
    ssh -t dedibox 'cd blog; bash ./pull_and_build.sh'
{% endhighlight %}

# Conclusion, pour les plus assidus

J'espère que ma prose vous aura apporté quelque chose, et vous aura évité de tomber dans les pièges dans lesquels je suis moi même tombé. Surtout n'hésitez pas à me contacter via twitter ou email en cas de remarque ou question.
