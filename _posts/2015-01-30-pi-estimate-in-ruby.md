---
layout: post
title: Estimation de Pi en ruby multithread
---

_AKA j'ai envie de parler de la gem parallel_

Aujourd'hui, j'avais envie de jouer avec la gem [parallel](https://github.com/grosser/parallel), qui permet d'effectuer des traitements en parallèle sur des collections sans se soucier de gérer l'ordonnancement de ses threads.

Un problème qui se prête plutôt bien à une mise en parallèle est l'estimation de Pi par la méthode Monte Carlo.

# Estimation de Pi

La [méthode Monte Carlo d'estimation de Pi](http://fr.wikipedia.org/wiki/M%C3%A9thode_de_Monte-Carlo#D.C3.A9termination_de_la_valeur_de_.CF.80_.28pi.29)  utilise le calcul de l'aire d'un cercle pour estimer une approximation de Pi par tâtonnement statistique.

En bref, on trace un cercle de rayon 1 dans un carré de coté 1, on tire aléatoirement un grand nombre de points à l'intérieur du carré, et on fait le rapport entre le nombre de points dans le cercle et à l'extérieur du cercle, multiplié par 4.

Pour calculer le nombre de points à l'intérieur du cercle, on peut utiliser la méthode suivante:

{% highlight ruby %}
def est_circle_hits(n)
  result = 0
  n.times { result += 1 if ((rand ** 2) + (rand ** 2) < 1) }
  result
end
{% endhighlight %}

Si l'on veut tester notre méthode de suite, en tentant de projeter 60 millions de points aléatoirement sur notre carré, on peut utiliser:

{% highlight ruby %}
hits = est_circle_hits(60_000_000)
puts 4.0 * hits.to_f / 60_000_000
{% endhighlight %}

Ce qui nous donne:

{% highlight bash %}
$ time ruby pi_estimate.rb
3.1413710666666668

real  0m15.516s
user  0m15.477s
sys   0m0.031s
{% endhighlight %}

# Comment la gem parallel peut-elle nous aider ?

La raison pour laquelle cet algorithme se prête particulièrement bien à une mise en parallèle est que les résultats des différentes itérations ne sont pas interdépendants (contrairement à une suite de Fibonacci, ou il faut utiliser les valeurs des itération n-1 et n-2 pour calculer la valeur de l'itération n).

Avec parallel, on peut, au choix:

* paralléliser un appel à la méthode map de ruby avec Parallel.map
* effectuer en parallèle des opérations sur chaque élément d'une collection avec Parallel.each

Dans notre cas, on peut essayer, par exemple, de découper en 6 tranches de 10 millions de projections de points nos 60 millions de tentatives:

{% highlight ruby %}
  require 'parallel'
  hits = Parallel.map((1..6).to_a) { est_circle_hits(10_000_000) }.reduce(:+)
{% endhighlight %}

Ici, on traite en parallèle six tranches de 10 millions de projection de points, et on additionne ensuite les six résultats (le nombre de points à l'intérieur du cercle pour chacune de ces six tranches de projections).

Le résultat parle par lui même:
{% highlight bash %}
$ time ruby pi_estimate.rb
3.1413846666666667

real  0m4.322s
user  0m24.559s
sys   0m0.058s
{% endhighlight %}

On peut noter que le temps total d'exécution est tombé de 15.51 secondes à 4.32 secondes (mais que le temps user est lui monté de 15.47 secondes à 24.55 secondes, ce qui s'explique par le temps utilisé en plus pour gérer l'ordonnancement).

# Conclusion
La gem parallel est un moyen rapide et efficace de facilement paralléliser des traitements en ruby. Néanmoins, suite à quelques essais avec des collègues, il est apparu que la gem pouvait poser des problèmes avec certaines ressources.

Avec rails, par exemple, pour pouvoir traiter en parallèle des opérations nécessitant un accès à une ressource active record, il est nécessaire de forcer une réouverture de connexion à la base:

{% highlight ruby %}
  # People and Country are active record models
  # That code delete all people whose country starts by 'C'
  Parallel.each(Country) do |country|
    # Lifesaver !
    ActiveRecord::Base.connection.reconnect!
    People.where(country: country.id).delete_all if country =~ /^C/
  end
{% endhighlight %}

Ce qui en fait un formidable outil pour mettre en place rapidement des traitements d'opérations en parallèle lorsqu'on ne fait rien de particulier avec des ressources partagées.

