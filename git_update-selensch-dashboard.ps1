Set-Location C:\Scripts\vcode\selensch-dashboard
# 1. Erstmal schauen, was sich geändert hat (optional, aber gut zur Kontrolle)
git status

# 2. Alle neuen und geänderten Dateien für den Upload vormerken ("stagen")
git add .

# 3. Die Änderungen "verpacken" und beschriften (Commit)
# WICHTIG: Schreibe in die Gänsefüßchen kurz rein, was du gemacht hast.
git commit -m "Update: Dashboard auf PS7 optimiert und Tools-Tab hinzugefügt"

# 4. Alles zum Server (GitHub/GitLab/Azure DevOps) hochladen
git push
