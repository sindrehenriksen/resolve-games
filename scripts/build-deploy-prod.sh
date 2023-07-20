flutter build web --dart-define=RG_ENV=prod
firebase use rg
firebase deploy --only hosting
