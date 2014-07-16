---
layout: post
title: Ruby et la décoration
---

_Où le développeur se découvre une âme artiste..._

# Le pattern Décorateur

D'après [Wikipédia](http://fr.wikipedia.org/wiki/D%C3%A9corateur_(patron_de_conception)):

>Un décorateur permet d'attacher dynamiquement de nouvelles responsabilités à un objet. Les décorateurs offrent une alternative assez souple à l'héritage pour composer de nouvelles fonctionnalités.

Concrètement, mettre en place un pattern décorateur consiste à encapsuler une classe cible dans le décorateur, et à surcharger un comportement spécifique.

Ruby propose de base une manière élégante de répondre à ce genre de besoin (la classe [SimpleDelegator](http://www.ruby-doc.org/stdlib-1.9.3/libdoc/delegate/rdoc/Delegator.html)), mais nous verrons qu'il est aussi possible de modifier plus ou moins dynamiquement et sans modifier le code client de ma classe cible.

# SimpleDelegator

Imaginons que nous ayons le même souci que celui présenté dans la page Wikipédia:

Nous savons qu'une voiture a un prix:

{% highlight ruby %}
class Voiture
  def prix
    @prix
  end
end
{% endhighlight %}

Et nous savons qu'une voiture de la marque Citron vaut 250 € (et qu'elle fait 'Honk !'):

{% highlight ruby %}
class Citron < Voiture
  def initialize
    @prix = 250.0
  end
  def Klaxonne
    puts 'Honk !'
  end
end
citron = Citron.new
puts('%d €' % citron.prix) # Affiche '250 €'
{% endhighlight %}

Comment modéliser de manière non intrusive l'ajout d'options à mon véhicule pour pouvoir calculer le nouveau prix ?

## Première implémentation des options

Tout d'abord, nous allons d'abord inclure le fichier delegate:

{% highlight ruby %}
require 'delegate'
{% endhighlight %}

Ensuite, nous allons déclarer une classe DiscoDecorator, qui ajoute au prix total de la voiture le prix d'un mini boule à facettes (soit 3.50 €):

{% highlight ruby %}
class DiscoDecorator < SimpleDelegator
  def prix
    __getobj__.prix + 3.5
  end
end
{% endhighlight %}

Dans cette class, nous avons juste écrit la méthode prix, qui appelle prix sur l'objet décoré, et le retourne ajouté de 3.50 €.

Il y a deux choses importantes à savoir sur la classe SimpleDelegator:

1. Il faut l'initialiser avec l'objet à décorer. Toutes les méthodes non-surchargées seront appellées sur cet objet.
2. La méthode **\_\_getobj\_\_** renvoie l'objet décoré.

Ajoutons aussi une classe MoumoutteDecorator, avec une moumoutte de volant à la modique somme de 15 €:

{% highlight ruby %}
class MoumoutteDecorator < SimpleDelegator
  def prix
    __getobj__.prix + 15
  end
end
{% endhighlight %}

On peu ainsi composer à l'envie une Citron avec option disco (notez le passage de citron au constructeur du décorateur):

{% highlight ruby %}
disco_citron = DiscoDecorator.new(citron)
puts('%.2f €' % disco_citron.prix) # Affiche 253.50 €
{% endhighlight %}

Une citron avec une moumoutte de volant:

{% highlight ruby %}
moumoutte_citron = MoumoutteDecorator.new(citron)
puts('%.2f €' % moumoutte_citron.prix) # Affiche 265.00 €
{% endhighlight %}

Ou bien les deux en encapsulant un décorateur dans un autre décorateur:

{% highlight ruby %}
disco_moumoutte_citron = DiscoDecorator.new(moumoutte_citron)
puts('%.2f €' % disco_moumoutte_citron.prix) # Affiche 268.50 €
{% endhighlight %}

Et bien entendu, l'objet décoré garde toutes ses autres fonctions intactes:

{% highlight ruby %}
disco_moumoutte_citron.klaxonne # Affiche 'Honk !'
{% endhighlight %}

## Implémentation générique des options

On peu aussi imaginer créer une classe générique OptionDecorator, qui va hériter de SimpleDelegator:

{% highlight ruby %}
class OptionDecorator < SimpleDelegator
  def initialize(prix, objet)
    @prix = prix
    super(objet)
  end
  def prix
    __getobj__.prix + @prix
  end
end
{% endhighlight %}

Ainsi, l'ajout d'option se ferait à la volée, sans nul besoin d'écrire une classe à chaque fois:

{% highlight ruby %}
climatisation_citron = OptionDecorator.new(105, citron)
puts('%.2f €' % climatisation_citron.prix) # Affiche 355.00 €
{% endhighlight %}

La décoration est un concept simple et puissant qui peut permettre d'enrichir le comportement d'une classe sans en altérer la mécanique interne.

Voici un exemple un peu plus velu:

{% highlight ruby %}
class DetailedOptionDecorator < SimpleDelegator
  def initialize(nom, prix, objet)
    @nom = nom
    @prix = prix
    super(objet)
  end
  def prix
    __getobj__.prix.tap do |total|
      # Affichage du prix de la voiture sans options
      puts '  % 7.2f €' % total unless __getobj__.kind_of? SimpleDelegator
      # Affichage du prix de l'option courante
      puts '+ % 7.2f € (%s)' % [@prix, @nom]
      # Calcul du total
    end + @prix
  end
end
{% endhighlight %}

Ici, on a créé un decorateur paramètrable, dont le constructeur attends un nom d'option, un prix, et l'objet décoré.

On peut l'utiliser pour décorer une citron avec plusieurs options:

{% highlight ruby %}
citron_decorator = {
  Moumoutte: 15,
  Clim: 105,
  Disco: 3.5
}.inject(citron) do |voiture, option|
  DetailedOptionDecorator.new(option[0], option[1], voiture)
end
{% endhighlight %}

Ici, dans la boucle de l'inject, on encapsule la citron dans trois DetailedOptionDecorator. Ensuite, il ne reste plus qu'à appeller prix et afficher son résultat:

{% highlight ruby %}
puts 'Prix toutes options comprises:'
total = citron_decorator.prix
puts '=' * 23
puts '  % 7.2f €' % total
{% endhighlight %}

Ce code va afficher un détail et le prix total de la voiture avec moumoutte, climatisation et boule disco:
 

    Prix toutes options comprises:
        250.00 €
     +   15.00 € (Moumoutte)
     +  105.00 € (Clim)
     +    3.50 € (Disco)
     =======================
        373.50 €

Et notre voiture décorée fait toujours 'Honk !':
{% highlight ruby %}
citron_decorator.klaxonne # affiche toujours 'Honk !'
{% endhighlight %}

# L'approche introspective

L'inconvénient de l'utilisation de SimpleDelegator, c'est que les appels internes au fonctionnement de la classe de la fonction décorée ne passent pas par le décorateur.

Si l'on reprend notre classe voiture pour lui ajouter une méthode tva (qui va renvoyer 20% du prix de la voiture:

{% highlight ruby %}
class Voiture
  def prix
    @prix
  end
  def tva
    0.2 * prix
  end
end
{% endhighlight %}

Une voiture décorée renverra la même tva que la voiture non décorée:

{% highlight ruby %}
# Calcul de tva:
puts '% 7.2f €' % citron.tva            # Affiche 50.00 €
puts '% 7.2f €' % citron_decorator.tva  # Affiche 50.00 € aussi... echec !
{% endhighlight %}

## Le remplacement de méthode à la volée

En revanche, il est possible de d'envisager un remplacement à la volée d'une méthode par une méthode dite 'singleton' (une méthode qui n'existe que pour la méta-classe de l'instance de l'objet sur laquelle on l'ajoute), mais les inconvénients sont multiples:

* On modifie l'instance de l'objet qu'on souhaite décorer, ce qui viole le principe d'enrichissement non-intrusif du décorateur.
* On ne peut pas décorer deux fois la même instance, sous peine de se manger un 'stack too deep'.

Pour la blague, voici un exemple d'implémentation:

{% highlight ruby %}
def decorate(obj, symbol, &block)
  obj.define_singleton_method((symbol.to_s + '_prev').to_sym, obj.method(symbol))
  obj.define_singleton_method(symbol, &block)
end

citron1 = Citron.new
citron2 = Citron.new

decorate(citron1, :prix) { 35 + prix_prev }

puts '% 7.2f €' % citron1.prix # Affiche 285.00 €
puts '% 7.2f €' % citron2.prix # Affiche 250.00 €
puts '% 7.2f €' % citron1.tva # Affiche 57.00 €
puts '% 7.2f €' % citron2.tva # Affiche 50.00 €
{% endhighlight %}

## Module + Extend + Super decorator = Joy

[Dan Croak](https://twitter.com/croaky) a fait quelques recherches sur le sujet dans un article interessant intitulé [Evaluating Alternative Decorator Implementations In Ruby](http://robots.thoughtbot.com/evaluating-alternative-decorator-implementations-in).

Une des méthodes qui a attiré mon attention est celle qu'il intitule 'Module + Extend + Super decorator'.

Cette fois, les décorateurs sont des modules qui surchargent la fonction à décorer:

{% highlight ruby %}
module Moumoutte
  def prix
    super + 15
  end
end

module Disco
  def prix
    super + 3.5
  end
end
{% endhighlight %}
Et il suffit d'étendre l'objet avec le module qu'on souhaite utiliser comme décorateur:
{% highlight ruby %}
citron = Citron.new
puts '% 7.2f €' % citron.prix # Affiche 250.00 €
puts '% 7.2f €' % citron.tva # Affiche 50.00 €

citron.extend(Disco)
puts '% 7.2f €' % citron.prix # Affiche 253.50 €
puts '% 7.2f €' % citron.tva # Affiche 50.70 €

citron.extend(Moumoutte)
puts '% 7.2f €' % citron.prix # Affiche 268.50 €
puts '% 7.2f €' % citron.tva # Affiche 53.70 €
{% endhighlight %}

Les avantages de cette méthode sont relativement évidents (lisibilité, délégation effectuée en profondeur, etc), mais elle est affublée d'un inconvénient majeur: il est impossible d'appliquer deux fois le même décorateur (sauf à user de sombres magouilles que je n'étalerais en aucun ca ici...).

# Conclusion

Ce petit article est loin d'avoir fait le tour du sujet de l'implémentation du pattern décorateur en ruby. J'espère néanmoins qu'il aura eu le mérite de faire découvrir quelque chose à certains d'entre vous.

Pour les plus curieux, il est possible de télécharger le [fichier ruby qui a servi à l'élaboration de cet article.](http://polymerisation-des-concepts.fr/citron.rb).

N'hésitez pas à me pinger sur [twitter](https://twitter.com/bankair) en cas de question ou remarques.
