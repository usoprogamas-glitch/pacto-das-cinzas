path = "scripts/dialogue_system.gd"
text = open(path, encoding="utf-8").read()
repl = {
    '"name": "Sobrevivente",': '"name": "Sobrevivente",\n\t\t"portrait": "dialog-portrait-valereDLCThroes",',
    '"name": "Mercador Errante",': '"name": "Mercador Errante",\n\t\t"portrait": "dialog-portrait-zaleDLCThroes",',
    '"name": "Refugiado do Castelo",': '"name": "Refugiado do Castelo",\n\t\t"portrait": "dialog-portrait-valereDLCThroes",',
    '"name": "Eremita dos Ventos",': '"name": "Eremita dos Ventos",\n\t\t"portrait": "dialog-portrait-Brugaves",',
    '"name": "Pescador Cego",': '"name": "Pescador Cego",\n\t\t"portrait": "dialog-portrait-Brugaves",',
    '"name": "Gnomo das Sombras",': '"name": "Gnomo das Sombras",\n\t\t"portrait": "dialog-portrait-zaleDLCThroes",',
    '"name": "Mensageiro Ferido",': '"name": "Mensageiro Ferido",\n\t\t"portrait": "dialog-portrait-Brugaves",',
}
n = 0
for old, new in repl.items():
    if old in text:
        text = text.replace(old, new, 1)
        n += 1
open(path, "w", encoding="utf-8", newline="").write(text)
print("portraits adicionados:", n)
