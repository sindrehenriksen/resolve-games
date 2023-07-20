flutter build web --dart-define=RG_ENV=dev
firebase use rgdev
firebase deploy --only hosting
