---
layout: post
title: A year riding an Appaloosa
---

If you'd like to read the english version, please click [here](#english-version)

# Version française

Cela fait bientôt un an que je travaille avec Appaloosa, ce qui fait de cette fin d'année le moment parfait pour faire un bilan sur cette collaboration (tl;dr: Appaloosa, c'est vraiment de la balle).

Pour ceux qui ne nous connaissent pas, [Appaloosa](https://appaloosa-store.com) est une startup qui propose un store d'applications mobiles privé, simple et sécurisé pour les entreprises ou les développeurs qui souhaitent déployer en interne leurs applications sans les lourdeurs et la complexité des stores publiques (Google Play, iTunes, etc).

## Le bon

Début 2016, j'ai eu le plaisir de constater qu'Appaloosa était une entreprise saine, avec des pratiques saines et que mes collaborateurs étaient des personnes de bonne volonté et courageuses. Ma confiance a vite été acquise, et je pense que la réciproque est vraie aussi.

D'autre part, j'ai pu constater que:

* L'entreprise était composée à 100% de doers (notre General Manager n'hésite pas à mettre les doigts dans le CSS au besoin, et j'ai parfois un mal de chien à empêcher notre Product Manager, un ancien développeur, de tirer des feature branchs)
* Les valeurs proclamées (l'honnêteté, la bienveillance et l'excellence, inspiré des valeurs d'Octo Technology) ne sont pas des mots creux
* Les gens qui décident n'ont pas de problème d'ego, et sont demandeuses de retours sur les manières de faire et les jalons produits

Ces trois points font d'Appaloosa un environnement idéal pour un ingénieur qui aime travailler en se concentrant sur son produit plutôt que sur la politique d'entreprise !

2016 a été une année charnière pour Appaloosa, qui a changé d'échelle en embauchant un tech lead (votre serviteur) pour assister ses trois développeurs juniors. Sur l'année, l'équipe technique est passée de 3 à 8 personnes, et la vélocité (autant individuelle que collective) a augmenté, et tout ça en continuant de s'appuyer sur un cadre de travail plutôt Lean, et en gardant intact (j'espère) le fun que les gens avaient à travailler ensembles.

## La brute

Certains sujets ont été plutôt douloureux à résoudre ou faire avancer.

La plateforme avait initialement été démarrée en 2011, plus ou moins en sous marin, par des personnes dont le métier principal était le développement mobile, et a été officiellement industrialisée par une équipe réduite de développeur juniors trois ans plus tard. Le manque de temps et d'expérience a apporté son lot de code legacy et de dette technique, qu'il a fallu commencer à réduire assez rapidement après mon arrivée.

Nous avons collectivement mis en place les mesures suivantes pour renforcer la qualité de notre produit:

* Mise en place de linter pour l'analyse statique du code sur les pull requests (rubocop, executé par pronto)
* Simplification de la pipeline de gestion des pull requests (gitlab + phabricator + arcanist => github)
* Rédaction de guides de développement documentant les best practices et les antipatterns découverts dans le code
* Organisation de dojos et de micro ateliers autour de questions de sécurité et d'optimisation

Concernant les projets de fond permettant une meilleure scalabilité et maintenabilité:

* Refonte d'une partie de l'architecture en charge de la collection des statistiques en vue d'une meilleure scalabilité
* Etude et tests sur les nouveaux modèles Serverless d'AWS
* Démarrage du projet de nouvelle interface d'administration (Ember.js)
* Création d'outils de monitoring et chasse aux fuites mémoire et problèmes d'optimisation

A ce jour, l'équipe est clairement plus confiante dans sa plateforme, et nous avons développé une culture d'exigence qualitative en interne qui nous permet de délivrer des logiciels toujours plus robustes et efficaces.

Je suis fier de faire partie de cette équipe qui a eu le courage d'accepter de remettre beaucoup de choses en questions et qui produit des logiciels de qualité.

## Et le truand

Appaloosa recrute !

Nous cherchons des développeurs backend à l'aise avec le ruby pour renforcer notre équipe produit, et au moins un développeur iOS (swift) pour travailler sur notre store natif iOS.

Et si vous avez lu jusqu'ici, c'est que vous avez surement un fort intérêt pour le développement logiciel et l'impact des méthodes sur le résultat. Nous avons surement des choses à nous dire ! N'hésitez pas à m'envoyer un message à alexandre@appaloosa.io !

# English version


It's been almost a year since I'm working at Appaloosa, which make the end of this year a perfect time for drawing conclusions over that collaboration (tl;dr: Appaloosa rocks).

For those who do not know us, [Appaloosa](https://appaloosa-store.com) is a startup proposing a private, simple and secure app store, for the companies or the developers willing to internally deploy their applications without having to handle the cumbersome and complex public stores (Google Play, iTunes, ...).

## The good

At the beginning of 2016, I had the pleasure to see that Appaloosa was a clean company, with clean methods, and that my new colleagues were people showing good will and courage. I gave them my trust quite quickly, and I think that the inverse is true as well.

On another hand, I could see that:

* The company was composed only of doers (our General Manager is quite good at CSS when needed, and I have a hard time forbidding our Product Manager, which was also a developer, to create feature branches)
* The claimed values (honesty, goodwill and excellence, inspired by the values of Octo Technology) are not only empty words
* People who get to decide don't have ego issues, and are happy to collect feedbacks on the methods and works

Those three points make Appaloosa an ideal environment for a hard working engineer who prefer to focus on a project instead of his career !

2016 was a big year for Appaloosa, which took a step by hiring a technical lead (myself) to assist the already present junior developers. Over the last year, the technical team went from 3 to 8 people, and the velocity (of the individual and of the team) went up, while still relying on a Lean framework and still providing fun to the collaborators.

## The bad

Some specific issues were quite painful to solve or reduce.

The platform build was initially started in 2011, mostly undercover, by people whose job was iOS/Android development, and was officially released by a small team of junior developers three years later. The lack of time and expertise (over rails and API design) was a cause of legacy code creation and technical debt accumulation, that I decided to reduce after my onboarding.

We collectively achieved the following task to enhance the global quality of our product:

* Static code analysis over our pull requests (rubocop/pronto)
* Simplification of the pull request pipeline (gitlab + phabricator + arcanist => github)
* Development guidelines redaction, in order to document expected best practices and antipatterns to avoid
* Coding dojo and micro workshop over security and performance

Regarding the long running tasks we started to enhance the product scalability and maintainability:

* Statistics collection pipeline architecture rework to enhance scalability
* Study and tests over the new Serverless technologies at AWS
* Kickoff of our new administration UI development (Ember.js)
* Monitoring tools creation, and perf issues and memory bloat hunting

As of today, the team is clearly more confident in the platform, and we built a culture of quality exigence that allow us to ship more and more robust and efficient softwares.

I'm proud to be part of that team, which was courageous enough to reconsider a lot of things, and produce high quality software.

## And the ugly

Appaloosa is hiring !

We are looking for backend developers fluent in ruby to grow our product team, and also at least one iOS (swift) developer to work over our store iOS native app.

And if you are reading this, you have probably a string interest in software craftmanship and impact on methods over resulting software. We should probably talk together, sometime ! Don't hesitate to get in touch at alexandre@appaloosa.io !
