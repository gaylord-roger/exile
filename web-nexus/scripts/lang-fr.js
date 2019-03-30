Language.LCID = 1033;
Language.name = 'Français';
Language.shortDay = 'j';
Language.longDayNames=['Dimanche', 'Lundi', 'Mardi', 'Mercredi', 'Jeudi', 'Vendredi', 'Samedi'];
Language.longMonthNames=['Janvier', 'Février', 'Mars', 'Avril', 'Mai', 'Juin', 'Juillet', 'Août', 'Septembre', 'Octobre', 'Novembre', 'Décembre'];
Language.shortMonthNames=['Janv', 'Févr', 'Mars', 'Avril', 'Mai', 'Juin', 'Juil', 'Août', 'Sept', 'Oct', 'Nov', 'Déc'];

// strings
Object.extend(Language.strings, {
	'options.password_dont_match': 'Les mots de passe ne correspondent pas,\nveuillez vérifier votre nouveau mot de passe.',
	'options.password_invalid': 'Votre nouveau mot de passe doit être composé de 6 à 16 caractères.',
	'servers.description': 'Serveur: $srv<br/>',
	'servers.starttime': 'Date de début: $datetime',
	'servers.stoptime': 'Date de fin: $datetime',
	'stats.players': 'Joueurs: $players:n',
	'stats.online': 'En ligne: $players:n'
});