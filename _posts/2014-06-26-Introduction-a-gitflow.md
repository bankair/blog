---
layout: post
title: Introduction à gitflow
---

Pour le consultant de SSII que j'étais avant, git était pour moi comme le cinéma scandinave: Si quelqu'un m'en parlait, je hochait la tête en souriant, en esperant qu'il parte rapidement (ou qu'un piano lui tombe dessus si jamais il venait à me poser des questions).

Néanmoins, depuis, j'ai eu l'occasion de découvrir un peu mieux l'outil, et d'apprendre à l'apprécier.

# Rappel sur git

Pour mémoire, git est un outil de contrôle de version décentralisé.

Contrairement aux outils de type CVS ou subversion, pour lesquels il existe un serveur de référence à partir duquel tous les clients tirent une copie du repo, chaque copie de repo git est un repo lui même.

D'autre part, la séparation en trois zones (Working directory, staging area, et Git directory) permet de travailler et d'effectuer plusieurs commits en mode offline, sans se synchroniser avec un serveur de référence.

Dans la pratique, en général, on utilise un serveur que l'on choisit comme référence (par exemple, un repo sur github ou bitbucket), on travaille sur des copies locales, et tout le monde se synchronise régulièrement avec le serveur.

# Le problème de la collaboration et de la synchronisation

Seul, on peut soumettre des commits à n'importe quelle fréquence sans réellement affecter negativement la livraison du produit sur lequel on travaille.

A plusieurs, en revanche, la question de savoir quand et quoi livrer se pose très vite.

Imaginons par exemple qu'Alice et Bob travaillent sur la branche master de leur projet commun et envoient quotidiennement leurs commits :

1. Rien n'a encore été développé, il n'y a donc rien à livrer au début du projet
2. Alice démarre la feature A. **On ne peut pas livrer, A est incomplète**.
3. Bob démarre la feature B. **On ne peut pas livrer, ni A, ni B ne sont complètes**.
4. Bob finit B. **On ne peut toujours pas livrer, A est encore incomplète**.
5. Bob démarre la feature C. **On ne peut pas livrer, ni A, ni C ne sont complètes**.
4. Alice finit A. **On ne peut toujours pas livrer, C est encore incomplète**.
5. Alice démarre la feature D. **On ne peut pas livrer, ni D, ni C ne sont complètes**.
6. Etc...

On peut imaginer aisément que ce genre de deadlock peut durer très longtemps. Lorsque j'ai commencé à travailler, nous avions des "code freeze" qui permettaient de finir les features encore en cours de développement sans en démarrer de nouvelles.

Cette solution est assez peu efficace, car elle oblige à immobiliser une partie de l'équipe de développement pour arriver à synchroniser les livraisons de feature.

La réponse de premier niveau, rendue possible par la facilité de création de branch et de merge de git, fut [la feature branch](http://martinfowler.com/bliki/FeatureBranch.html). Le principe de base consister à tirer une nouvelle branche depuis master à chaque nouveau développement, et à n'appliquer le contenu de cette branche dans master uniquement une fois le développement terminé.

Ainsi, le travail d'Alice et Bob aurait été le suivant:

1. Rien n'a encore été développé, il n'y a donc rien à livrer au début du projet
2. Alice démarre la feature A dans sa feature branch feature/A. Il n'y a rien à livrer sur master.
3. Bob démarre la feature B dans sa feature branch feature/B. Il n'y a rien à livrer sur master.
4. Bob finit B et merge sa branche feature/B dans master. **On peut livrer master, avec la feature B**.
5. Bob démarre la feature C dans sa feature branch feature/C. **On peut livrer master, avec la feature B**.
4. Alice finit A et merge sa branche feature/A dans master. **On peut livrer master, avec les features B et A**.
5. Alice démarre la feature D. **On peut livrer master, avec les features B et A**.
6. Etc...

Tout cela est très bien, on peut désormais livrer les features dès qu'elles sont terminées, tout le monde est heureux, et va à la plage parce qu'il est bien joli.

Et tout le monde s'amuse bien.

A la plage.

* * *

J'en entends qui, dans le fond, crachottent des gros mots. Bug toi même. Hotfix ta mère. Moi aussi, je peux être grossier.

Rabat-joie, va.

* * *

J'en conviens, la feature branch ne règle pas tout. Il nous reste encore à savoir comment (de manière non-exhaustive):

* Traiter les bugs
* Gérer les hotfixes
* Livrer
* Tagger les versions livrées pour référence
* ...

# gitflow

Et soudain est apparu, sur son fidèle destrier, [Vincent Driessen](http://nvie.com/) et son [successful Git branching model](http://nvie.com/posts/a-successful-git-branching-model/):

![gitflow](http://nvie.com/img/2009/12/Screen-shot-2009-12-24-at-11.32.03.png "Gitflow")

Ce modèle de développement s'appuie sur deux branches principales:

* master: le mirroir de la production. Ce qui se trouve dans cette branche est la dernière version livrée de votre logiciel.
* develop: la branche sur laquelle tous les développeurs vont répercuter leur feature branchs. C'est la version en cours de développement de votre logiciel.

On peut résumer comme suit: On développe sur develop, et on livre ce qu'il y a dans master.

On peut découper les opérations de ce workflow comme suit:

* Nouveau développement / bugfix
* Packaging d'une version
* Livraison
* Hotfix

## Détails des opérations

### Nouveau développement / Bugfix

Imaginons que Alice doive développer la feature A:

* Alice checkout la branche develop et la met à jour: git checkout develop && git pull
* Alice tire une nouvelle branche pour sa feature: git checkout -b feature/A
* Alice développe sa feature
* Alice commit: git add featureA.c && git commit -m 'feature A'
* Alice répercute le contenu de sa feature branch dans develop: git checkout develop && git merge feature/A

### Packaging d'une version

Bob va devoir packager la dernière version (1.3) de l'application:

* Bob checkout la branche develop: git checkout develop && git pull
* Bob tire une nouvelle branche pour la release 1.3: git checkout -b release/1.3
* Alice et Bob se lancent dans une session de QA endiablée
* Un bug sauvage est trouvé
* Bob corrige le bug
* Bob commit: git add bugfix.c && git commit -m 'bug fix'
* Bob reporte le commit sur develop: git checkout develop && git merge release/1.3 && git checkout release/1.3

Si jamais plusieurs personnes travaillent sur les bugfix de la version, il est plus simple que tout le monde travaille sur la branche de release, et qu'une personne reporte toutes les corrections sur develop à la fin:

{% highlight bash %}
git checkout release/1.3
git pull
git checkout develop
git pull
git merge release/1.3
{% endhighlight %}

### Livraison

Ma partie préférée (attention, c'est hautement complexe):

{% highlight bash %}
git checkout release/1.3
git pull
git checkout master
git pull
git merge release/1.3
git tag -a 1.3 -m '2014-06-26 Release 1.3'
git push
{% endhighlight %}

### Hotfix

Cela se passe exactement comme pour une feature, sauf qu'on tire la branche de master, et qu'on la répercute sur master **ET** develop:

* Alice checkout la branche master et la met à jour: git checkout master && git pull
* Alice tire une nouvelle branche pour son hotfix: git checkout -b hotfix/X
* Alice corrige le bug
* Alice commit: git add hotfixX.c && git commit -m 'hotfix X'
* Alice répercute le contenu de sa branch de hotfix dans develop et master:
{% highlight bash %}
git checkout master
git pull
git merge hotfix/X
git push
git checkout develop
git pull
git tag -a 1.3.1 -m '2014-06-26 Hotfix X'
git push
{% endhighlight %}

Ne reste plus qu'à relivrer le contenu de master en production.

## Et ça marche ?

Plutôt pas mal !

### Avantages / Inconvénients

Les avantages sont multiples:

* Plus de code freeze
* historique git très propre si les feature branch sont rebasées sur develop
* Modèle de tagging propre
* Méthodologie résumable à quelques concepts simples et forts (on developpe dans develop, et on livre dans master)
* Eprouvé
* Et j'en oublie

Quant aux inconvénients:

* Pas mal d'actions inutiles pour les projets mono-développeur
* Il faut être particulièrement rigoureux sur la gestion des hotfix, sous peine d'écraser un hotfix à la livraison suivante si il n'a pas été reporté sur develop (vécu)
* Un développeur ne jouant pas le jeu de la feature branch peut pousser le packageur à faire le grand écart à coups de cherry-pick pour préparer sa release branch. Et ça, c'est très pénible.

### Les outils

sourcetree vient de base avec des fonctionalités inspirées de git flow (cf gros bouton git flow) qui permettent de créer des feature branchs, etc.

Sinon, l'auteur de la méthode a créé un set [d'extentions git](https://github.com/nvie/gitflow)

Et tout cela est très hautement scriptable. Nous livrons simultanément cinq applications à chaque déploiement, dont deux sont soumises à la méthodologie gitflow. Auparavant, une mise en production pouvait facilement durer deux jours.

J'ai pris sur moi de développer un script de déploiement qui assure toute la partie packaging/backup/livraison, et cela nous prend désormais moins de deux heures, et nous avons monté notre fréquence de déploiement de une fois toutes les deux semaines à deux fois par semaine.

En conclusion, si vous êtes au moins deux sur votre projet, tenter git flow ne vous coutera pas grand chose, et pourrait vous faciliter grandement la vie.
