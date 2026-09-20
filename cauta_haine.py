import os
import sys
import json

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
DB_PATH = os.path.join(SCRIPT_DIR, "resources", "[Wave]", "clothing_db.json")

COMP_NAMES = {
    11: "Top (Geaca / Hanorac / Haina)",
    8:  "Tricou (Undershirt)",
    9:  "Vesta Antiglont (Body Armor)",
    4:  "Pantaloni (Legs)",
    6:  "Pantofi (Shoes)",
    7:  "Accesorii / Lant (Necklace)",
    1:  "Masca (Mask)",
    3:  "Brate / Maini (Torso)",
    10: "Decals (Insigne)"
}

def load_db():
    if not os.path.exists(DB_PATH):
        print(f"[EROARE] Nu s-a gasit baza de date: {DB_PATH}")
        sys.exit(1)
    with open(DB_PATH, "r", encoding="utf-8") as f:
        return json.load(f)

def search_text(db, query):
    query = query.lower().strip()
    print(f"\n========================================================")
    print(f" Rezultate cautare dupa cuvant: '{query}'")
    print(f"========================================================")
    matches = 0
    for gender in ["male", "female"]:
        for comp_id, items in db.get(gender, {}).items():
            for item in items:
                model_match = query in item["model"].lower()
                matched_tex = [t for t in item.get("textures", []) if query in t.lower()]
                if model_match or matched_tex:
                    matches += 1
                    comp_name = COMP_NAMES.get(int(comp_id), f"Componenta {comp_id}")
                    print(f"\n[{matches}] Sex: {gender.upper()} | {comp_name}")
                    print(f"    • Model 3D (.ydd): {item['model']}")
                    print(f"    • Pack:            {item['pack']}")
                    print(f"    • Cale:            {item['path']}")
                    if matched_tex:
                        print(f"    • Texturi potrivite: {', '.join(matched_tex)}")
                    else:
                        print(f"    • Texturi ({len(item.get('textures', []))} variante): {', '.join(item.get('textures', [])[:5])}")
                    if matches >= 30:
                        print("\n... au fost gasite prea multe rezultate, afisez primele 30.")
                        return

    for gender_prop in ["male_props", "female_props"]:
        for prop_id, items in db.get(gender_prop, {}).items():
            for item in items:
                model_match = query in item["model"].lower()
                matched_tex = [t for t in item.get("textures", []) if query in t.lower()]
                if model_match or matched_tex:
                    matches += 1
                    print(f"\n[{matches}] Prop {prop_id} ({gender_prop})")
                    print(f"    • Model 3D (.ydd): {item['model']}")
                    print(f"    • Pack:            {item['pack']}")
                    print(f"    • Cale:            {item['path']}")
                    if matched_tex:
                        print(f"    • Texturi potrivite: {', '.join(matched_tex)}")

    if matches == 0:
        print(f"Niciun model sau textura gasita care sa contina '{query}'.")
    print(f"========================================================\n")

def search_index(db, gender, comp_id, addon_index, texture_index=0):
    gender = gender.lower()
    comp_str = str(comp_id)
    items = db.get(gender, {}).get(comp_str, [])
    if not items:
        print(f"[EROARE] Nu exista haine addon pentru componenta {comp_id} ({gender}).")
        return

    if addon_index < 1 or addon_index > len(items):
        print(f"[EROARE] Indexul addon {addon_index} este invalid. Exista intre 1 si {len(items)} haine addon pentru componenta {comp_id}.")
        return

    item = items[addon_index - 1]
    textures = item.get("textures", [])
    tex_name = textures[texture_index] if (0 <= texture_index < len(textures)) else (textures[0] if textures else "Lipsa .ytd")

    print(f"\n========================================================")
    print(f" DETALII HAINA GASITA:")
    print(f"========================================================")
    print(f"• Categorie:       {COMP_NAMES.get(int(comp_id), f'Componenta {comp_id}')}")
    print(f"• Model 3D (.ydd): {item['model']}")
    print(f"• Textura (.ytd):  {tex_name}")
    print(f"• Pack:            {item['pack']}")
    print(f"• Cale folder:     {item['path']}")
    print(f"• Toate texturile acestui model ({len(textures)} variante):")
    for idx, t in enumerate(textures):
        print(f"    [{idx}] {t}")
    print(f"========================================================\n")

def main():
    db = load_db()

    if len(sys.argv) > 1:
        arg = sys.argv[1]
        if arg.isdigit() and len(sys.argv) >= 3:
            comp_id = int(sys.argv[1])
            addon_index = int(sys.argv[2])
            tex_index = int(sys.argv[3]) if len(sys.argv) >= 4 else 0
            gender = sys.argv[4] if len(sys.argv) >= 5 else "male"
            search_index(db, gender, comp_id, addon_index, tex_index)
        else:
            search_text(db, " ".join(sys.argv[1:]))
        return

    while True:
        print("\n=== CAUTARE HAINE & TEXTURI WAVE ===")
        print("1. Cauta dupa cuvant / nume logo / server")
        print("2. Cauta dupa componenta si index addon")
        print("3. Iesire")
        choice = input("Alege optiunea (1/2/3): ").strip()

        if choice == "1":
            q = input("Introdu textul / numele de pe logo: ").strip()
            if q:
                search_text(db, q)
        elif choice == "2":
            g = input("Sex (male/female, default male): ").strip() or "male"
            c = input("ID componenta (ex: 11 pt Geaca, 8 pt Tricou, 9 pt Vesta, 4 pt Pantaloni): ").strip()
            idx = input("Index haina addon (1, 2, 3...): ").strip()
            tex = input("Index textura (0, 1, 2... default 0): ").strip() or "0"
            if c.isdigit() and idx.isdigit() and tex.isdigit():
                search_index(db, g, int(c), int(idx), int(tex))
            else:
                print("[EROARE] Trebuie sa introduci numere valide.")
        elif choice == "3":
            break

if __name__ == "__main__":
    main()
