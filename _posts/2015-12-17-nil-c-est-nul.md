---
layout: post
title: nil, c'est nul !
---

# Nil n'est méchant volontairement
_(Socrate. Ou presque.)_

Si Aristote faisait du ruby, il aurait très certainement dit quelque chose de ce genre:

> "La nature a horreur du nil."

Vous l'avez sûrement déjà compris, malin comme vous êtes, bande de petits strudels: cet article va parler de l'usage de la valeur nil en Ruby.

# Petits rappels

Histoire que tout le monde soit sur la même page, nil est une valeur spéciale de Ruby. Il s'agit de la seule instance de la classe NilClass:

{% highlight ruby %}
  nil.class
  # => NilClass
  nil.inspect
  # => "nil"
  nil.nil?
  # => true
{% endhighlight %}

La valeur nil ne peut pas être clonée (singleton oblige):

{% highlight ruby %}
  nil.clone
  # => raise a TypeError: can't clone NilClass
{% endhighlight %}

Et c'est aussi la seule valeur (autre que false) qui s'évalue comme "fausse":

{% highlight ruby %}
  if nil
    puts 'Universe breached'
  else
    puts 'nil is the only other false value'
  end
  # => print 'nil is the only other false value'
{% endhighlight %}

# La possibilité du nil
_(Michel Hashbecq)_

On peut retrouver cette valeur spéciale dans un certain nombre de contextes:

{% highlight ruby %}
  # C'est la valeur d'une variable d'instance pas encore affectée:
  defined?(@foobar)
  # => nil
  @foobar
  # => nil
  @foobar = 2
  # => 2
  @foobar
  # => 2
  defined?(@foobar)
  # => "instance-variable"

  # C'est la valeur par défaut renvoyée par Hash#[] si
  # la clef n'existe pas:
  hash = { a: 1, b: 2 }
  hash[:b]
  # => 2
  hash[:c]
  # => nil

  # C'est aussi la valeur de retour des méthodes qui affichent
  # des chaînes de caractère (puts, print, warn, etc.):
  puts 'foobar'
  # => nil (but prints foobar on the standard output)

  # C'est aussi la valeur retournée par une clause if non déclenchée
  # en l'absence de clause else:
  if false
    puts 'Universe breach'
  end
  # => nil (and prints nothing)

  # C'est la valeur retournée lorsqu'on tente un first ou last sur un
  # Array vide:
  [].first
  # => nil
  [].last
  # => nil

  # Et, enfin, c'est la valeur retournée par un appel à
  # ActiveRecord::FinderMethods#find_by lorsqu'il n'y a pas de ligne
  # correspondante en base:
  Country.find_by(owner: 'Old men')
  # => nil (because there is no country for old men)
{% endhighlight %}

Cette liste n'est pas exhaustive, mais elle donne une certaine idée du nombre de situations dans lesquelles on peut se retrouver à manipuler du nil.

# Le problème avec nil

Le problème qu'on rencontre, avec nil, c'est qu'à partir du moment où l'on commence à en manipuler, on doit s'attendre à en avoir partout. Et donc tester la nullité de toute valeur. Ce qui donne très vite du code pénible à lire ou avec des exceptions levées à des endroits qui n'ont rien à voir avec la cause réelle de l'exception.

## La gestion de nil entache la lisibilité

Prenons l'exemple du code suivant, qui fait assez peu de choses: il récupère un owner depuis un hash de mapping `owner_id<=>owner`, récupère le pays associé, et l'affiche sur la sortie standard après l'avoir décoré au besoin:

{% highlight ruby %}
  OWNERS = {
    1 => 'Candy',
    2 => 'old men',
    3 => 'Narnia'
  }

  def print_country(owner_id, decorator = nil)
    warn 'Starting country printing process'
    owner = OWNERS[owner_id]
    unless owner.nil?
      country = Country.find_by(owner: owner)
      unless country.nil? || country.name.nil?
        if decorator.nil?
          puts decorator.process(country.name)
        else
          puts country.name
        end
      end
    end
    warn 'End of country printing process'
  end

  class UpperCaser
    def process(str)
      str.upcase
    end
  end

  # Print the name of Candy's country, upper cased
  print_country(1, UpperCaser.new)
{% endhighlight %}

Ce code, qui fonctionnellement fait assez peu de choses, est criblé de tests de nullité, ce qui rend sa lisibilité assez pénible. Il est cependant assez facile de le rendre plus lisible, et plus facile à maintenir.

### La gestion de l'owner, et le warning final

Ici, on note qu'au lieu d'interrompre le l'exécution de la méthode avec un return, le développeur a utilisé un bloc if qui ne s'exécute que si owner n'est pas nil, dans l'objectif de conserver l'affichage du warning final en sortie de méthode.

{% highlight ruby %}
  OWNERS = {
    1 => 'Candy',
    2 => 'old men',
    3 => 'Narnia'
  }

  def print_owner(owner_id)
    warn 'Starting country printing process'
    owner = OWNERS[owner_id]
    unless owner.nil?
      puts owner
    end
    warn 'End of country printing process'
  end

  # Print the name of Candy
  print_owner 1
  # Print nothing (appart from the warnings)
  print_owner 13
{% endhighlight %}

Nous avons plusieurs solutions pour gérer cela de manière plus lisibles. En premier lieu, j'ai souvent tendance à utiliser Hash#fetch plutôt que Hash#[], pour gérer les valeurs par défaut de manière explicite (sauf si j'ai décidé de définir une valeur par défaut pour Hash#[] lors de la création du hash).


#### La version avec un bloc ensure

Ici, on utilise deux astuces:

1. On utilise Hash#fetch en lui passant un bloc qui ne contient que l'instruction return, qui va sortir de la méthode si on ne trouve pas d'owner id associé.
2. On place le dernier warn dans le block ensure de la méthode. Ce bloc sera exécuté quoi qu'il arrive, une fois la méthode terminée (nota: ça ne change pas la valeur de retour de la méthode).

{% highlight ruby %}
  def print_owner(owner_id)
    warn 'Starting country printing process'
    puts(OWNERS.fetch(owner_id) { return })
  ensure
    warn 'End of country printing process'
  end
{% endhighlight %}

#### La version avec séparation des responsabilités d'affichage des warning et de l'owner

Ici, on décide simplement de donner la responsabilité de l'affichage de l'owner à une méthode print_owner_implementation, et la méthode print_owner ne s'occupe que de décorer l'appel de l'implémentation avec les warnings.

{% highlight ruby %}
  def print_owner_implementation(owner_id)
    puts(OWNERS.fetch(owner_id) { return })
  end

  def print_owner(owner_id)
    warn 'Starting country printing process'
    print_owner_implementation owner_id
    warn 'End of country printing process'
  end
{% endhighlight %}

#### La version avec une couche d'abstraction supplémentaire et un "null object":

On peut aussi décider de déporter la responsabilité de l'affichage du nom dans un autre objet.

Ici, j'utilise une structure Owner, qui contient un nom, et qui a la responsabilité de l'afficher lorsqu'on appelle la méthode Owner#print.

Pour faire bonne mesure, et gérer le cas où je n'ai pas d'owner associé à un id, j'ai aussi ajouté une class NullOwner, qui implémente une méthode NullOwner.print, qui ne fait rien du tout. Cette classe est utilisée comme un objet neutre.

{% highlight ruby %}
  Owner = Struct.new(:name) { def print; puts name; end }

  OWNERS = {
    1 => Owner.new('Candy'),
    2 => Owner.new('old men'),
    3 => Owner.new('Narnia')
  }
  
  # NullOwner.print ne fait rien
  class NullOwner; def self.print; end end

  def print_owner(owner_id)
    warn 'Starting country printing process'
    OWNERS.fetch(owner_id, NullOwner).print
    warn 'End of country printing process'
  end
{% endhighlight %}

### La gestion des paramètres optionnels

Une des choses que j'adore avec Ruby est la richesse des possibilités offertes concernant la gestion des paramètres de méthode.

Malheureusement, souvent, on peut croiser du code qui ressemble à ce qui suit:

{% highlight ruby %}
  def print_name(name, repeat = nil)
    if repeat == nil
      puts name
    else
      repeat.times { puts name }
    end
  end
{% endhighlight %}

Ce qui est plutôt dangereux en terme de contrôle de flux. Pour ce bout de code, appeler `print_owner('bob')` et `print_owner('bob', nil)` revient absolument au même. Et comme nil est assez souvent utilisé comme valeur de retour lorsqu'un méthode n'a pas de résultat ni d'effets de bord, on peut se retrouver à faire juste n'importe quoi.

Je vais donc répéter une chose que je radote assez régulièrement:

# N'utilisez pas nil comme une information.

## Jamais.

### (bordel)

La raison pour cela est simple. Imaginons que j'ai deux listes (théoriquement de la même taille) contenant, l'une des prénoms, et l'autre, le nombre de fois que je veux les afficher. Pour ce faire, je vais utiliser la méthode `print_name` de la manière suivante:

{% highlight ruby %}
  name_list.zip(repeat_list).each { |n, r| print_name(n, r) }
{% endhighlight %}

C'est élégant, cela fait le job en tenant sur une ligne, mais que se passe-t-il si il y a une inconsistance au niveau des données ?

{% highlight ruby %}
  name_list = %w(alice bob)
  # => ["alice", "bob"]
  repeat_list = [2]
  # => [2]
  zipped_list = name_list.zip(repeat_list)
  # => [["alice", 2], ["bob", nil]]
  zipped_list.each { |n, r| print_name(n, r) }
  # Affiche:
  #   alice
  #   alice
  #   bob
{% endhighlight %}

Dans l'exemple précédent, on constate que le fait que notre repeat_list était trop courte n'a posé aucun problème, car Array#zip a juste comblé la valeur manquante par... nil !

Du coup, notre fonction a considéré qu'elle pouvait afficher "bob" une fois, alors que idéalement, elle aurait du jeter une exception.

Ce n'est pas très grave dans le cadre de ma méthode print_name qui affiche juste une chaîne, mais imaginez le potentiel de catastrophe si on parle de système financier ou autre production critique...

Si vraiment vous devez utiliser une paramètre optionnel, avec une valeur neutre, et que vous ne souhaitez pas sortir la responsabilité de l'action dans un objet externe, il vous est possible d'utiliser un symbole qui vous servira de valeur neutre. Sur les grosses bases de code, pour éviter les collisions de symbole, j'ai tendance à utiliser une constante contenant un symbole suffixé d'un md5sum de l'heure pour m'assurer de son unicité (si tout le monde commence à balader et manipuler du `:none` partout, on en revient vite au même problème qu'avec nil).

{% highlight ruby %}
  NO_REPEAT = :none_3863273382bb7fa0cf68f1e41bb8c788
  def print_name(name, repeat = NO_REPEAT)
    if repeat = NO_REPEAT
      puts name
    else
      repeat.times { puts name }
    end
  end
{% endhighlight %}

Maintenant, si j'essaye encore le bout de code sensé afficher les noms d'alice et bob, il va afficher deux fois alice, puis jeter une exception pour bob (NoMethodError: undefined method 'times' for nil:NilClass), ce qui est déjà plus cohérent.


D'autre part, il y a une chose à savoir avec les paramètres optionnels: vous pouvez utiliser n'importe quoi comme valeur par défaut.

{% highlight ruby %}
  # On peut utiliser un appel de méthode d'instance:
  def default_name() 'alice' end
  def print_name(name = default_name)
    puts name
  end

  # Ou même d'autre paramètres:
  def register(name, login = name)
    # ...
  end

  # Voir encore des expressions:
  def add(a, b, result = a + b)
    result
  end
{% endhighlight %}

Du coup, c'est bien plus rigolo de jouer avec que de manipuler du nil.

### Et la memoization ?

Un raccourci assez pratiqué en ruby consiste à memoizer certaines valeurs calculées de la manière qui suit:

{% highlight ruby %}
  def slow_method
    # ...
  end

  def cached_value
    @cached_value ||= slow_method
  end
{% endhighlight %}

Inconvénient de ce bidule: si votre méthode slow_method retourne nil, et bien votre valeur est recalculée à chaque fois.

Une implémentation un tantinet plus safe serait:

{% highlight ruby %}
  def cached_value
    defined?(@cached_value) ? @cached_value : (@cached_value = slow_method)
  end
{% endhighlight %}

Explication avec un coup d'irb:

{% highlight ruby %}
  defined?(@foobar)
  # => nil
  @foobar
  # => nil
  @foobar = nil
  # => nil
  defined?(@foobar)
  # => "instance-variable"
  @foobar
  # => nil
{% endhighlight %}

Affecter nil à une variable d'instance la définit à la volée, alors que son évaluation renvoie toujours nil.

# Conclusion

Du coup, il est tout à fait possible de se débarrasser de ces disgracieux `.nil?` qui émaillent le code du début:

{% highlight ruby %}
  OWNERS = {
    1 => 'Candy',
    2 => 'old men',
    3 => 'Narnia'
  }

  def print_country_impl(owner_id, decorator)
    owner = OWNERS.fetch(owner_id) { return }
    country = Country.find_by(owner: owner) or return
    # Ici, pas le choix
    return if country.name.nil?
    puts decorator.process(country.name)
  end

  def print_country(owner_id, decorator = NullDecorator)
    warn 'Starting country printing process'
    print_country_impl(owner_id, decorator)
    warn 'End of country printing process'
  end

  class NullDecorator
    def self.process(str) str end
  end

  class UpperCaser
    def self.process(str) str.upcase end
  end

  # Print the name of Candy's country, upper cased
  print_country(1, UpperCaser)
{% endhighlight %}

Il existe encore plein d'autres moyens pour éviter d'avoir à gérer la nullité de vos valeurs manipulées, mais j'espère que ces quelques conseils permettront à certains d'entre vous d'éviter de s'arracher les cheveux sur des bug cryptiques causés par un nil vicieusement planqué au fin fond de votre code.

Les principes généraux que j'aime bien essayer de partager:

1. nil n'est pas une information.
2. nil est une absence d'information.
3. Utiliser une valeur neutre autre que nil permet de faire la différence entre un contexte normal et anormal d'utilisation d'une méthode.
4. Les NullObjects (allez lire [Much ado about naught](http://devblog.avdi.org/introduction-to-much-ado-about-naught/) si ce n'est pas déjà fait) sont vos amis.
