# Exile
Dans ce guide, nous allons installer Exile sur une nouvelle installation Windows serveur. Vous aurez votre propre serveur pour tester et jouer en local.

# Préparation
Commencez par récupérer le repository sur le serveur web. Vous pouvez le faire de 2 manières :
* Depuis le bouton vert "Clone or download" de Github, vous téléchargerez un zip de la dernière version
* Avec [git](https://git-scm.com/) avec la commande `git clone https://github.com/gaylord-roger/exile.git C:/Exile`

Pour la suite de la procédure d'installation, on considèrera que vous avez tout récupéré dans C:\Exile

## Serveur SMTP (optionnel)
Vous avez besoin d'un relais pour envoyer les emails d'inscriptions, modification de mot de passe oublié, et les notifications du jeu.  
Vous pouvez utiliser le relais SMTP de votre FAI, installer un hMailServer, postfix ou tout autre serveur mail.  
Configurez votre serveur mail dans le fichier "C:\Exile\web-nexus\lib\Email.asp"

## Postgresql
Installez la dernière version de postgresql (v11) depuis https://www.postgresql.org/

Laissez toutes les options d'installation cochées puis finissez l'installation.

StackBuilder va se lancer, installez les pilotes pgsqlODBC (32 bits) : nous avons besoin des pilotes ODBC 32 bits pour nous connecter à postgresql depuis ASP et les scripts de mise à jour.

Alternative : vous pouvez installer postgresql sur une installation linux, vous devrez cependant installer les pilotes pgsqlODBC sur le serveur web et modifier toutes les entrées référençant le serveur par le nom ou l'adresse IP de votre postgresql

## COM+
Le site et les scripts nécessitent l'installation d'objets COM+ 32bits gérant les templates et les combats.

Installez les objets COM+ en exécutant `c:\Exile\libs\reg.bat`. Des boites de dialogue Windows apparaîtront, cliquez sur ok.

# Base de données
Pour restaurer la base de données, exécutez la commande `"C:\Program Files\PostgreSQL\11\bin\psql" -h localhost -p 5432 -U postgres -f "C:\exile\db\exile.sql"`

Lancez PGAdmin (l'administration de postgresql), connectez-vous à votre serveur puis lancez l'outil de requête.
Nous allons modifier le mot de passe du compte "Admin" et créer un compte "Test", entrez la commande suivante :
```
 SET search_path TO exile_nexus;
 UPDATE exile_nexus.users SET password = exile_nexus.sp_account_hashpassword('demo') WHERE id = 5
 SELECT sp_account_create('test', 'testpass', 'test@exile', 1036, '0.0.0.0')
```
Modifiez "demo" par le mot de passe que vous souhaitez pour l'administrateur et "testpass" par le mot de passe pour le compte de test puis exécutez la commande.

Créez ensuite une galaxie avec la requête suivante :
```
SET search_path TO exile_s03,static;
SELECT admin_create_galaxies(1,1);
```

# ODBC
Ouvrez le fichier "C:\Exile\db\odbc.reg" et modifiez le mot de passe "demo" (2 occurrences) par le mot de passe de votre serveur postgresql, enregistrez puis fusionnez les données dans votre base de registre (exécutez le fichier).

Cela enregistre les DSN système exile_nexus et exile_s03

# IIS
Installez le rôle Web serveur + le service de rôle ASP, vous pouvez suivre ce guide : https://docs.microsoft.com/fr-fr/iis/application-frameworks/running-classic-asp-applications-on-iis-7-and-iis-8/classic-asp-not-installed-by-default-on-iis

Lancez la console IIS `C:\Windows\System32\inetsrv\inetmgr.exe`

Supprimez le site déjà existant par défaut

Créez 2 nouveaux sites web :
 - "www.monexile.lan" avec comme chemin physique "C:\Exile\web-nexus"
 - "s03.monexile.lan" avec comme chemin physique "C:\Exile\web-game" et "s03.monexile.lan" comme nom d'hote
 
Allez dans la page des pools d'application puis modifiez les paramètres avancés suivant dans chaque pool correspondant aux sites créés précédemment : 
 - .NET CLR version : no managed code
 - Enable 32-Bits Applications : true
 - Managed Pipeline Mode : classic
 
Ouvrez le site "www.monexile.lan", allez dans la fonctionnalité "ASP" puis modifiez la ligne Script Language de "VBScript" à "JScript", Apply

Pour chaque site, allez dans la fonctionnalité "ASP" puis modifiez la ligne "Debugging Properties/Send Errors To Browser" à True, Apply


# DNS local
Ouvrez le fichier "C:\Windows\System32\drivers\etc\hosts" en tant qu'administrateur et ajoutez ces 2 lignes à la fin :
 - 127.0.0.1	www.monexile.lan
 - 127.0.0.1	s03.monexile.lan

Pour accéder à votre serveur depuis une autre machine sur votre réseau local, ouvrez le fichier hosts de la machine et remplacez "127.0.0.1" par l'adresse IP de votre serveur web. Vous devrez également ouvrir le port 80 du parefeu sur le serveur web.

A partir de ce moment, vous pouvez vous connecter à votre serveur sur http://www.monexile.lan


# Jobs
Ouvrez les taches planifiées de Windows `%windir%\system32\taskschd.msc /s` et importez les fichiers .xml présents dans "C:\Exile\jobs".

Sur chaque tâche importée, dans la page "General", cochez "Run whether user is logged in or not"

# Https
Dans IIS, sur chaque site, ajoutez les liaisons https.

Ouvrez le port 443 dans le parefeu si besoin.

Dans la base de données exile, modifiez l'entrée de l'univers dans exile_nexus.universes et spécifiez le schéma https:// dans le champ "url"

Dans "C:\Exile\web-game\lib\config.asp", modifiez urlNexus pour pointer sur l'url en https

