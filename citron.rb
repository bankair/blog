class Voiture
  def prix
    @prix
  end
end

class Citron < Voiture
  def initialize
    @prix = 250.0
  end
  def klaxonne
    puts 'Honk !'
  end
end

citron = Citron.new
puts('%.2f €' % citron.prix) # affiche 250.00 €

require 'delegate'

class DiscoDecorator < SimpleDelegator
  def prix
    __getobj__.prix + 3.5
  end
end

class MoumoutteDecorator < SimpleDelegator
  def prix
    __getobj__.prix + 15
  end
end

disco_citron = DiscoDecorator.new(citron)
puts('%.2f €' % disco_citron.prix) # Affiche 253.50 €
moumoutte_citron = MoumoutteDecorator.new(citron)
puts('%.2f €' % moumoutte_citron.prix) # Affiche 265.00 €

disco_moumoutte_citron = DiscoDecorator.new(moumoutte_citron)
puts('%.2f €' % disco_moumoutte_citron.prix) # Affiche 268.50 €

disco_moumoutte_citron.klaxonne

puts '#' * 178

class OptionDecorator < SimpleDelegator
  def initialize(prix, objet)
    @prix = prix
    super(objet)
  end
  def prix
    __getobj__.prix + @prix
  end
end

climatisation_citron = OptionDecorator.new(105, citron)
puts('%.2f €' % climatisation_citron.prix) # Affiche 355.00 €

puts '#' * 178

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

citron_decorator = { Moumoutte: 15, Clim: 105, Disco: 3.5 }.inject(citron) do |voiture, option|
  DetailedOptionDecorator.new(option[0], option[1], voiture)
end
puts 'Prix toutes options comprises:'
total = citron_decorator.prix
puts '=' * 23
puts '  % 7.2f €' % total

citron_decorator.klaxonne # affiche toujours 'Honk !'

class Voiture
  def prix
    @prix
  end
  def tva
    0.2 * prix
  end
end

puts '% 7.2f €' % citron.tva # Affiche 50.00 €
puts '% 7.2f €' % citron_decorator.tva # Affiche 50.00 €

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

citron = Citron.new
puts '% 7.2f €' % citron.prix # Affiche 250.00 €
puts '% 7.2f €' % citron.tva # Affiche 50.00 €
citron.extend(Disco)

puts '% 7.2f €' % citron.prix # Affiche 253.50 €
puts '% 7.2f €' % citron.tva # Affiche 50.70 €
citron.extend(Moumoutte)

puts '% 7.2f €' % citron.prix # Affiche 268.50 €
puts '% 7.2f €' % citron.tva # Affiche 53.70 €
