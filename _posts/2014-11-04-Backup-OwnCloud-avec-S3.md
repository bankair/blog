---
layout: post
title: Backup OwnCloud sur Amazon S3
---

_tl;dr: Un script de backup pour ceux qui on installé leur [OwnCloud](http://owncloud.org/)._

Comme beaucoup d'entre vous, je suis passé par DropBox, Google Drive, et Ubuntu ONE. Finalement, la fermeture du service d'Ubuntu m'a décidé à passer à l'auto-hebergement.

J'ai donc installé un serveur OwnCloud sur mon serveur perso, et commencé à distribuer comme des cookies des comptes aux membres de ma famille.

Naturellement, comme les données n'étaient plus uniquement les miennes, j'ai envisagé une solution de backup, et j'ai choisi d'héberger mes backups directement sur S3, avec le script suivant (s3backup.sh):

{% highlight bash %}
#!/bin/sh
s3cmd sync --delete-removed /var/www/owncloud/data s3://$OC_BACKUP_BUCKET/data/
s3cmd sync --delete-removed /var/www/owncloud/config s3://$OC_BACKUP_BUCKET/config/
OWNCLOUD_BACKUP=owncloud-sqlbkp-`date +"%Y%m%d"`
# Caution: no space after -p option
mysqldump --lock-tables -h 127.0.0.1 -u $OC_SQL_USER -p$OC_SQL_PWD $OC_SQL_DB > $OWNCLOUD_BACKUP.bak
tar cvzf $OWNCLOUD_BACKUP.tgz $OWNCLOUD_BACKUP.bak
s3cmd put $OWNCLOUD_BACKUP.tgz s3://$OC_BACKUP_BUCKET/mysql/
rm $OWNCLOUD_BACKUP.tgz $OWNCLOUD_BACKUP.bak
{% endhighlight %}

Reste à configurer les variables d'environnement suivantes:

{% highlight bash %}
export OC_BACKUP_BUCKET="nom-du-bucket-de-sauvegarde"
export OC_SQL_DB="base-de-donnee-mysql-utilisee-par-owncloud"
export OC_SQL_USER="user-owncloud-dans-mysql"
export OC_SQL_PWD="mot-de-passe-du-user-owncloud-dans-mysql"
{% endhighlight %}

Ainsi que configurer une tâche cron quotidienne avec la commande:
{% highlight bash %}
crontab -e
{% endhighlight %}

Personellement, j'effectue mon backup tous les jours, à 2h du matin, avec la ligne suivante dans ma crontab:

>  0 2  *   *   *     /path/to/s3backup.sh

J'ajouterais probablement une politique d'historisation et de rétention des backups par la suite.
