import os
import google.generativeai as genai
from github import Github

# --- CONFIG ---
MODEL_NAME = 'gemini-3-pro-preview' 

api_key = os.environ.get('GEMINI_API_KEY')
if not api_key:
    print("❌ Kein API Key gefunden!")
    exit(1)

genai.configure(api_key=api_key)

g = Github(os.environ['GITHUB_TOKEN'])
repo = g.get_repo(os.environ['REPO_NAME'])
pr = repo.get_pull(int(os.environ['PR_NUMBER']))

# --- 1. ANTI-SPAM: Alte Bot-Kommentare löschen ---
print("🧹 Suche nach alten Bot-Kommentaren...")
try:
    for comment in pr.get_issue_comments():
        if "🤖 Gemini Review" in comment.body:
            comment.delete()
            print(f"   Alten Kommentar {comment.id} gelöscht.")
except Exception as e:
    print(f"⚠️ Konnte Kommentare nicht löschen (Berechtigung?): {e}")

# --- 2. DIFF LADEN & FILTERN ---
diff_text = ''
files_analyzed = []
has_test_files = False
# Erweiterte Ignore-Liste für weniger Token-Verbrauch
ignored_ext = ['.json', '.md', '.svg', '.png', '.lock', '.yml', '.yaml', '.css', '.scss']

for file in pr.get_files():
    # Ignoriere gelöschte Dateien oder unwichtige Formate
    if file.status == "removed" or any(file.filename.endswith(ext) for ext in ignored_ext):
        continue
    
    if file.patch:
        files_analyzed.append(file.filename)
        diff_text += f'\n\n--- DATEI: {file.filename} ---\n{file.patch}\n'
        
        if "test" in file.filename.lower() or "spec" in file.filename.lower():
            has_test_files = True

if not diff_text:
    print("✅ Keine review-relevanten Änderungen (Code) gefunden.")
    exit(0)

# --- 3. PROMPT ---
# Optimierter Prompt für Gemini 3 Context
prompt = f'''
Du bist ein strenger Senior Code Reviewer für das Projekt 'mealtrack'.

KONTEXT:
- Dateien: {', '.join(files_analyzed)}
- Tests im PR enthalten? {"JA ✅" if has_test_files else "NEIN ❌ (Kritisch prüfen!)"}

AUFGABE:
1. Suche nach Bugs, Sicherheitslücken und Clean Code Verstößen.
2. PRÜFE TESTS: Wenn neue Logik ohne Tests kommt -> Schreibe **⚠️ TESTS FEHLEN**.
3. PRÜFE ARCHITEKTUR (Feature-First): Neuer Code muss feature-basiert sein (lib/features/...). Warne, wenn Business-Logik/Widgets global statt im Feature liegen.
4. SPRACHE: Kommentare/Namen müssen Englisch sein.
5. STIL: Keine unnötigen Einleitungen.

ANTWORT FORMAT (Markdown):
### 🛡️ Review Zusammenfassung
(Urteil & Status)

### 🏗️ Architecture & Feature-First
(Prüfe Feature-First Einhaltung. Liegen Dateien in lib/features/...?)

### 🐛 Bugs & Anmerkungen
(Kritische Fehler)

### 🧪 Fehlende Tests & Szenarien
(Analysiere konkret: Was fehlt? Happy Path? Edge Cases?)

CODE DIFF:
{diff_text[:300000]}
'''
# Gemini 3 hat großes Context Window, habe Limit auf 300k erhöht

# --- 4. KI ANFRAGE ---
try:
    print(f"🚀 Sende Anfrage an {MODEL_NAME}...")
    model = genai.GenerativeModel(MODEL_NAME)
    
    generation_config = {
        "temperature": 0.0,         # Volle Strenge
        "top_p": 0.95,              # Stabile Wortwahl
        "max_output_tokens": 65536  # Genug Platz für lange Reviews
    }
    
    response = model.generate_content(prompt, generation_config=generation_config)
    review_body = response.text
except Exception as e:
    review_body = f"❌ **KI-Fehler:** {str(e)}"
    print(review_body)

# --- 5. POSTEN ---
header = f'## 🤖 Gemini Review ({MODEL_NAME})\n'
pr.create_issue_comment(header + review_body)
print("✅ Review gepostet!")
