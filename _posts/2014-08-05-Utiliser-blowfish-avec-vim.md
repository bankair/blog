---
layout: post
title: Utiliser blowfish pour chiffrer ses fichiers avec vim
---

Si vous êtes en train de lire cette page, c'est que vous avez accès à internet (ou bien qu'en psychopathe a imprimé le contenu de ce blog, ce qui est à la fois hautement improbable et assez terrifiant).

Si vous avez accès à internet (je mets de coté la deuxième hypothèse qui me met légèrement mal à l'aise), ce que vous êtes aussi l'heureux propriétaire d'une jolie tripotée de couples login/password vous permettant de vous connecter à tous les services que vous utilisez (facebook, github, twitter, wikipédia, pinterest, etc etc).

Pour ne pas oublier ces couples login/password, j'ai été tenté de m'acheter un licence [1Password](https://agilebits.com/onepassword), mais le prix m'a rapidement découragé. J'en suis donc venu à utiliser une solutions combinant vim, blowfish et github.

# Agnah ? vim ? blowfish ?

Si ce titre vous parait ridicule, c'est que vous connaissez déjà vim et blowfish, et que vous n'avez pas besoin de ce paragraphe. Allez, zoup, filez donc au suivant.

Si vous êtes encore là, je vous explique en quelques mots: [vim](http://www.vim.org/) est mon éditeur de texte, blowfish est un [algorithme de chiffrement symétrique](http://fr.wikipedia.org/wiki/Blowfish). Le but de l'exercice est d'utiliser le chiffrement du dernier pour chiffrer des fichiers édités avec le premier.

# Configurer vim pour utiliser blowfish

Il est très simple d'utiliser le chiffrement avec vim lorsque le fichier est déjà ouvert:

    :X<entrée>

L'éditeur va alors vous demander une clef de chiffrement et sa confirmation. Le fichier sera chiffré lors de la sauvegarde (mais cela laisse encore quelques sujets ouverts, tels que les fichiers de swap, d'historique, etc).

A la prochaine ouverture du fichier, vim va vous réclamer la clef de chiffrement pour l'afficher en clair.

Il est aussi possible de préciser qu'on souhaite utiliser une clef en ligne de commande au lancement de vim:

    vim -x fichier_a_chiffrer.txt

L'inconvénient, c'est que dans les deux cas, les actions prises sur les fichiers peuvent être retrouvées dans:
1. Les backups,
2. Les fichiers de swap,
3. Le fichier viminfo,
4. Et probablement dans une tonne d'autres endroits qui m'échappent.

Pour résoudre ces potentielles failles de sécurité, j'ai créé un fichier **.vimencryptrc** :

{% highlight bash %}
set nobackup 
set noswapfile 
set nowritebackup 
set viminfo= 
set cm=blowfish
{% endhighlight %}

Je stocke ce fichier à la racine de mon compte utilisateur, et il est donc accessible via **$HOME/.vimencryptrc**

Vous noterez la dernière ligne, qui utilise blowfish comme crypt method (raccourci en cm).

Il suffit ensuite de l'utiliser la ligne suivante :

    vim -S $HOME/.vimencryptrc -x fichier_a_chiffrer.txt

qui précise que le fichier .vimencryptrc doit être chargé après le fichier de configuration par défaut, pour ouvrir un fichier que l'on souhaite chiffrer, ou que l'on a déjà chiffré.

En ce qui me concerne, j'ai ajouté un alias dans ma configuration bash:
{% highlight bash %}
alias vime="vim -S $HOME/.vimencryptrc -X "
{% endhighlight %}
Et je n'ai qu'à utiliser vime au lieu de vim pour préciser que je souhaite chiffrer un fichier:
{% highlight bash %}
vime fichier_a_chiffrer.txt
{% endhighlight %}


# Conclusion

J'édite mes fichiers chiffrés avec mon alias vime, dans un dépot privé github. Ainsi, je suis capable de retrouver mes mots de passe de partout, et sans autre outil qu'une vim, et avec versioning, s'il vous plait.

C'est pas la classe, ça ?

(Et c'est gratuit...)
