---
layout: post
title: Décoration dynamique en ruby
---

_tl;dr: Jouons avec un peu d'instrospection pour décorer de manière dynamique n'importe quel objet._

# SimpleDelegator, c'est bien mais...

Pour rappel, la class [SimpleDelegator de ruby](http://polymerisation-des-concepts.fr/2014/07/16/Ruby-et-decoration/) est bien pratique pour modifier de manière non intrusive le comportement d'une classe:
{% highlight ruby %}
#! ruby
class FooBar
  def bar() puts "Bar" end
end

require 'delegate'
class FooBarDelegator < SimpleDelegator
  def bar
    puts "Calling #{__getobj__.class}.bar"
    __getobj__.bar
  end
end

foo = FooBarDelegator.new(FooBar.new)

foo.bar # Should print: 'Calling Foo.bar' and then 'Bar'
{% endhighlight %}

Bien qu'assez pratique si l'on ne souhaite surcharger que quelques méthodes d'une classe, cette approche est assez vite contraignante si on veut décorer toutes les méthodes d'une class qui en a beaucoup (ou dont on ne connait pas le nombre).

**Use case:**
_Je souhaite tracer toute le chemin d'execution d'un appel de n'importe quelle méthode d'une classe._

# method_missing est ton ami !
Les objets de type SimpleDelegator héritent directement de la class Delegator, qui utilise le méchanisme de méta-programmation inhérent à ruby pour forwarder tous les appels de fonctions non-surchargés à l'instance décorée.

Une des méthodes utilisées est method_missing:

{% highlight ruby %}
    # prototype de method_missing:
    def method_missing(name, *args, &block)
{% endhighlight %}

Cette méthode d'instance est appellée à chaque fois qu'une instance reçoitun appel de méthode pour lequel il n'existe pas de définition.

Ses paramètres sont:

* name : Le nom/symbole de la méthode appellée
* args : Une liste d'arguments passés à l'appel de méthode
* block : Un block à transmettre à la méthode

Par exemple, si j'appelle foo.bar(42), et que l'instance foo n'a pas de méthode bar, c'est sa méthode method_missing qui va être appellée avec les arguments suivants:

* name : :bar
* args : [42]
* block : pas de block

On peut donc profiter de cette méthode pour, par exemple, afficher tous les appels de méthode d'instance:


{% highlight ruby %}
#! ruby
  class Foo
    def foo() 'foo' end
  end

  class Bar
    def make_foo
      Foo.new
    end
    def foobar
      make_foo.foo.inspect + 'bar'
    end
    def foobarize(e)
      "foo:#{e.inspect}:bar"
    end
  end

  require 'delegate'

  class Spy < SimpleDelegator
    def method_missing(name, *args, &block)
      parameters = args.map(&:inspect).join ', '
      puts "Calling #{__getobj__.class}.#{name}(#{parameters})"
      super
    end
  end

  watched_bar = Spy.new(Bar.new)
  puts watched_bar.foobar
  puts watched_bar.foobarize(nil)
{% endhighlight %}

Ce bout de code va afficher:

    Calling Bar.foobar()
    foobar
    Calling Bar.foobarize(nil)
    foo:nil:bar

Les points à noter sont les suivants:

* L'appel à Bar.make_foo, dans la méthode Bar.foobar n'est pas affiché, car il s'execute sur self (l'instance de Bar) et pas sur l'instance de Spy. En revanche, watched_bar.make_foo déclencherait l'affichage de 'Calling Bar.make_foo()'.
* Le mot clef **super** sans arguments appellent la méthode de la classe parente de Spy (SimpleDelegator) avec les arguments intacts de l'appel initial.


# Un peu de propagation ?

On peut très bien imaginer remplacer **super** par **Spy.new(super)**, pour propager la surveillance aux résultats des méthodes appellées. Mais, watched_bar.make_foo.foo afficherait:

    Calling Bar.make_foo()
    Calling Foo.foo()
    Calling String.to_ary()
    Calling String.to_s()
    #<Spy:0x007f87790aa7f0>

On remarquera qu'à la place de l'attendu 'foo', on a un cryptique '#<Spy:0x007f87790aa7f0>', qui s'explique par le fait que la méthode Object.to_s retourne une chaine composée du nom de la class de l'instance courante (Spy) suivi de son identifiant:

> Returns a string representing obj. The default to_s prints the object’s
> class and an encoding of the object id. As a special case, the top-level
> object that is the initial execution context of Ruby programs returns
> “main.”

On peut aisément résoudre ce problème en ajoutant juste une fonction 'passe-plat' à Spy, qui va juste faire suivre l'appel de to_s à l'object sous-jacent:

{% highlight ruby %}
  def to_s() __getobj__.to_s end
{% endhighlight %}

# Mais pour quoi faire tout ça ?

On peut imaginer bon nombre d'applications pour ce type de pattern, mais comme on ne peut que partiellement maitriser la propagation de la décoration (les appels de méthodes effectués depuis un autre appel de méthode de l'instance ne sont pas décorés), j'ai tendance à privilégier les utilisations non fonctionnelles:

* Reverse-engineering : La première fois que j'ai vu quelqu'un utiliser une forme de ce pattern, il s'agissait d'effectuer du reverse engineering pour comprendre comment était utilisée une librairie dynamique par une application dont nous n'avions pas le code source (ni la documentation, bien entendu, c'est pour les faibles, comme les tests unitaires). Le développeur en charge de cette étude ne s'est pas démonté, a récupéré toutes les signatures de méthode de la dll, et a créé une dll à l'interface identique, mais qui enregistrait chaque appel de fonction dans un fichier avant de le faire suivre à la dll d'origine. On peut facilement imaginer faire la même chose avec un Spy (comme je le montre un peu plus bas).
* Monitoring & debugging : Avec la même technique, on peut aussi extraire des métriques d'une application ou la raison d'un crash.

La seule règle à respecter est de ne pas changer les valeurs de retour des méthodes d'instance inspectées, car, comme précisé plus haut (oui, j'insiste lourdement, mais c'est pour ton bien) **on ne maitrise pas les sous appels de méthode d'instance**.

# Un dernier exemple concret pour la route ?

Imaginons qu'on ai le code suivant:

{% highlight ruby %}
#! ruby
class Foo
  def foo() 'foo' end
  def self.init() @instance = Foo.new end
  def self.instance() @instance end
end

class Bar
  def fetch() Foo end
end

puts Bar.new.fetch.instance.foo
{% endhighlight %}

Toi, rubyiste à l'oeil aguerri, tu as déjà remarqué plusieurs erreurs de conception ('un simplet-gleton ?'), de flow ('nan, mais elle est où, l'initialization ?') et de contrôle d'erreur ('un raise si nil, ça t'arracherait le postrulum ?'). En ce qui me concerne, je suis plutôt flemmard, ces derniers temps, alors je vais juste l'executer:

    ruby test.rb
    test.rb:12:in `<main>': undefined method `foo' for nil:NilClass (NoMethodError)

Ah. (Notez l'incroyable talent d'acteur)

Créons une class Spy avec propagation !

{% highlight ruby %}

require 'delegate'

class Spy < SimpleDelegator
  def initialize(obj, propagate:true, depth:2)
    @propagate = propagate
    @depth = depth
    super(obj)
  end
  def to_s() __getobj__.to_s end
  def method_missing(name, *args, &block)
    parameters = args.map(&:inspect).join ', '
    puts(('  '*@depth)+"=> Calling #{__getobj__.inspect}.#{name}(#{parameters})")
    result = super
    puts(('  '*@depth)+" = #{result.inspect} (#{result.class.to_s})")
    if @propagate
      result = Spy.new(result, propagate:true, depth:@depth+2) 
    end
    result
  end
end

def watch(obj, propagate = true)
  Spy.new(obj, propagate:true)
end
{% endhighlight %}

Et tant qu'on y est, une petite méthode pour faire plus joli:

{% highlight ruby %}
def watch(obj, propagate = true)
  Spy.new(obj, propagate:true)
end
{% endhighlight %}

Et ensuite, je vais changer:

{% highlight ruby %}
puts Bar.new.fetch.foo.foo
{% endhighlight %}

en:

{% highlight ruby %}
puts watch(Bar.new).fetch.foo.foo
{% endhighlight %}

Et cette fois ci, la sortie de mon script est:

        => Calling #<Bar:0x007fb61b8af8f8>.fetch()
         = Foo (Class)
            => Calling Foo.foo()
             = nil (NilClass)
                => Calling nil.foo()
    test.rb:24:in `method_missing'            => Calling nil.inspect()
                 = "nil" (String)
    : undefined method `foo' for nil:Spy (NoMethodError)
      from test.rb:37:in `<main>'

On en déduit que Foo.foo() a renvoyé nil au lieu d'une instance de la classe Foo. Nous avions donc oublié d'appeller Foo.init. On ajoute Foo.init devant notre appel à fetch:

{% highlight ruby %}
Foo.init
puts watch(Bar.new).fetch.foo.foo
{% endhighlight %}

Et cette fois ci, la sortie du script est:

        => Calling #<Bar:0x007fe5a98ab808>.fetch()
         = Foo (Class)
            => Calling Foo.foo()
             = #<Foo:0x007fe5a98ab830> (Foo)
                => Calling #<Foo:0x007fe5a98ab830>.foo()
                 = "foo" (String)
                    => Calling "foo".to_ary()
    foo

Et hop.
