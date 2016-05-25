---
layout: post
title: Utiliser Ihasa pour bricoler un load balancer distribué en ruby
---

# I has a bucket !

> ".- ..- / ... . -.-. --- ..- .-. ... --..-- / .. .-.. / ..-. .- .. - / . -. -.-. --- .-. . / -.. . ... / -... .-.. .- --. ..- . ... / -. ..- .-.. .-.. . ..."

Il y a quelques jours, coincé au lit à cause d'un lumbago, j'ai dévelopé [Ihasa](https://github.com/bankair/ihasa), une implémentation de l'algorithme du [Token Bucket](https://en.wikipedia.org/wiki/Token_bucket) ([page française](https://fr.wikipedia.org/wiki/Seau_%C3%A0_jetons)) qui mélange Ruby, lua et Redis.

L'algo Token Bucket est extrêmement simple (et efficace):

*Variables:*

* R: Le nombre de requêtes que je souhaite laisser passer par seconde, en moyenne (rate)
* B: Le nombre de requêtes que je souhaite laisser passer en rafale (burst)

Déroulement grossier de l'algorithme:

* Je commence avec R jetons dans mon seau
* Avant de vérifier si je dispose d'un jeton ou pas, je calcule le minimum entre B et le nombre de jetons que j'ai gagné depuis le dernier tirage de jeton, ce qui représente la quantité de jetons dont je dispose au moment d'un requête
* Si la quantité de jetons dont je dispose dépasse 1, je laisse la requête passer
* A chaque fois qu'une requête passe, je retire un jeton

On peut très facilement le mettre en place en ruby, sans Redis, mais cela impliquerait que la limite ne serait respectée que pour le processus courant (et non plus globalement).

J'aurais aussi pu choisir de stocker uniquement la quantité courante de jetons et le timestamp de la dernière requête dans redis, mais cela laisse de la place à des problèmes de concurrence.

J'ai donc choisi de stocker la configuration (rate et burst), la quantité de jetons (allowance) et l'heure de la dernière requête, et d'exécuter directement le code de l'algorithme de Token Bucket en lua, dans l'instance redis, ce qui élimine un paquet de soucis de concurrence.

Certains diront que l'instance redis devient un goulet d'étranglement, et dans l'arrière plan, on entendra Salvatore s'étrangler, mais de rire.

# Un load balancer en ruby ? Et pourquoi pas un marteau en mousse ?

Imaginons que j'ai envie de faire suivre des requêtes GET à un ensemble de machines, et que j'ai un parc hétérogène (des petites machines qui se trainent, et des grosses machines qui cavalent comme des folles).

Tout d'abord, je vais modéliser une API, qui va encapsuler un nombre de requêtes autorisées par secondes et un hôte:

{% highlight ruby %}
require 'net/http'
require 'ihasa'

Api = Struct.new(:uri_or_host, :rate) do
  def bucket
    @bucket ||= Ihasa.bucket(rate: rate, burst: 2 * rate, prefix: uri_or_host)
  end

  def forward
    bucket.accept? ? yield(Net::HTTP.get(uri_or_host, '/')) : false
  end
end
{% endhighlight %}

Ici, vous pouvez noter deux choses:
* La méthode d'instance bucket, qui construit l'objet bucket quand on en a besoin, et qui configure le burst au double du rate.
* La méthode forward, qui yield ET retourne le contenu de l'API encapsulée si il reste un jeton dans le seau, ou retourne juste `false` dans le cas contraire.

Ensuite, nous sommes en mesure de créer plusieurs instance d'Api:

{% highlight ruby %}
apis = [
  Api.new('www.perdu.com', 5),
  Api.new('www.perdus.com', 10)
]
{% endhighlight %}

Ici, on a décidé d'autoriser 5 requêtes par seconde sur [perdu.com](http://www.perdu.com), et 10 requêtes par seconde sur [perdus.com](http://www.perdus.com), posant les fondations d'un système indiscutablement indispensable.

Et pour finir, on créé une app Rack:

{% highlight ruby %}
require 'rack'

app = proc do |_env|
  response = [403, {'Content-Type' => 'text/plain'}, ["Request limit violated\n"]]
  apis.sort_by! { rand }.find do |api|
    api.forward { |body| response = [200, {'Content-Type' => 'text/html'}, [body]] }
  end
  response
end

Rack::Handler::WEBrick.run app
{% endhighlight %}

Cette application mélange les apis au hasard (pour éviter de requêter systématiquement les mêmes), et les parcourt jusqu'à en trouver une qui dispose encore d'un jeton libre.

Si aucun jeton n'est trouvé sur la liste des APIs, on répond avec une erreur 403.

Nous voici désormais avec un load balancer sur perdu.com/perdus.com. L'utilité de cet exemple est fort discutable, mais on imagine aisément un paquet d'applications intéressantes (fallback à plusieurs niveaux, provision automatique de nouvelles APIs quand on commence à se trouver à cours de token, etc.).

Durant mes tests, l'overhead du load balancing s'est averé relativement négligeable (tellement négligeable que je n'ai pas réussi à le mesurer avec précision, même avec un serveur aussi lent que WEBrick), ce qui me laisse à penser qu'il y a encore plein de choses à expérimenter autour de tout ça, et j'espère vous avoir inspirer à essayer des choses avec Ihasa vous aussi !
