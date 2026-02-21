# Materials Project Electronic Structure Exporter

Pulls band structure and density of states (DOS) data from the [Materials Project](https://next-gen.materialsproject.org) and saves them as CSV files you can open and graph in Excel.

---

## First time setup

Open a terminal, run the command

```bash
cd ~/Downloads && git clone https://github.com/cqdence/MaterialsProject-API-Retrieval/
```

cd into the **`MaterialsProject-API-Retrieval/`** folder directory (`cd MaterialsProject-API-Retrieval/`), and run:

```bash
bash setup.sh
```

The script will automatically check for and install anything that's missing:
- **Xcode Command Line Tools** (built-in Mac dev tools — a pop-up will appear, just click Install)
- **Homebrew** (Mac package manager)
- **Python 3.9+**
- **All required Python packages**

You only need to do this once.

---

## Exporting data

Every time you want to pull data, run:

```bash
bash run.sh
```

It will ask you:
1. Your **API key** (found at [next-gen.materialsproject.org/api](https://next-gen.materialsproject.org/api) after logging in — it will offer to save it so you only type it once)
2. The **material ID(s)** you want — found on the material's page on the website, looks like `mp-149`. You can enter multiple separated by spaces.
3. The **k-path convention** (just press Enter to use the default)

Your files will appear in the **`Exports/`** folder.

---

## Output files

| File | Contents |
|---|---|
| `Exports/mp-XXXXX_latimer_munro_bandstructure.csv` | Band structure — k-point distance, high-symmetry labels, one column per band |
| `Exports/mp-XXXXX_dos.csv` | Density of states — energy and density columns |

Both open directly in Excel and are ready to plot.

---

## K-path options

| # | Value | Convention |
|---|---|---|
| 1 | `latimer_munro` | Latimer-Munro (default) |
| 2 | `setyawan_curtarolo` | Setyawan-Curtarolo |
| 3 | `hinuma` | Hinuma et al. |

---

## Notes

- Some older material IDs are legacy entries no longer in the new API. The script handles this automatically — it fetches the band structure from archived data and finds the closest stable equivalent for the DOS.
- Your saved API key is stored in `.api_key` (local only, never uploaded to GitHub).
