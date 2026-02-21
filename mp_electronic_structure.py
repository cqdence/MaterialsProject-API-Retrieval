import traceback
import os
import pandas as pd
from mp_api.client import MPRester
from emmet.core.electronic_structure import BSPathType
from emmet.core.summary import HasProps
import argparse

EXPORTS_DIR = "Exports"


def fetch_and_export_electronic_structure(api_key, material_id, path_type_str="latimer_munro"):
    os.makedirs(EXPORTS_DIR, exist_ok=True)

    with MPRester(api_key) as mpr:
        print(f"\n{'='*60}")
        print(f"  Material: {material_id}  |  path_type: {path_type_str}")
        print(f"{'='*60}\n")

        try:
            path_type = BSPathType(path_type_str.lower())
        except ValueError:
            print(f"  Unknown path_type '{path_type_str}', falling back to latimer_munro")
            print(f"  Valid options: {[pt.value for pt in BSPathType]}")
            path_type = BSPathType.latimer_munro

        # ── Band Structure ────────────────────────────────────────────
        bs = None

        # Method 1: current API (works for most modern mp- IDs)
        print("[1] Fetching band structure via material ID...")
        try:
            bs = mpr.get_bandstructure_by_material_id(material_id, path_type=path_type)
            if bs:
                print(f"    OK  (method: material_id, path_type={path_type.value})")
        except Exception:
            pass

        # Method 2: direct task-based S3 fetch (works for legacy task IDs)
        if bs is None:
            print("    Not found via material ID.")
            print("[2] Trying direct task-based fetch (legacy ID support)...")
            try:
                bs = mpr.materials.electronic_structure_bandstructure.get_bandstructure_from_task_id(material_id)
                if bs:
                    print(f"    OK  (method: task_id S3 fetch)")
            except Exception as e:
                print(f"    Failed: {e}")

        if bs is None:
            print("    No band structure found by any method.")

        # ── DOS ───────────────────────────────────────────────────────
        dos = None

        print("[3] Fetching DOS via material ID...")
        try:
            dos = mpr.get_dos_by_material_id(material_id)
            if dos:
                print(f"    OK  (method: material_id)")
        except Exception:
            pass

        # If DOS not found (common for legacy IDs), find the stable
        # equivalent in the new API and use its DOS
        if dos is None and bs is not None:
            print("    Not found via material ID.")
            print("[4] Looking for equivalent material in new API for DOS...")
            try:
                formula = bs.structure.composition.reduced_formula
                candidates = mpr.materials.summary.search(
                    formula=formula,
                    has_props=[HasProps.dos],
                    fields=["material_id", "energy_above_hull", "symmetry"]
                )
                if candidates:
                    best = min(candidates, key=lambda x: getattr(x, "energy_above_hull", 999))
                    sg = getattr(getattr(best, "symmetry", None), "symbol", "?")
                    print(f"    Using {best.material_id} ({formula}, {sg}, "
                          f"e_above_hull={best.energy_above_hull:.4f} eV) for DOS")
                    dos = mpr.get_dos_by_material_id(str(best.material_id))
                    if dos:
                        print(f"    OK")
                else:
                    print(f"    No {formula} materials with DOS found in new API")
            except Exception as e:
                print(f"    Failed: {e}")
                traceback.print_exc()

        if dos is None:
            print("    No DOS found by any method.")

        # ── Export Band Structure ─────────────────────────────────────
        print(f"\n[5] Exporting band structure...")
        if bs is not None:
            try:
                bs_pmg = bs.to_pymatgen() if hasattr(bs, "to_pymatgen") else bs

                distances = bs_pmg.distance
                labels = [k.label if k.label else "" for k in bs_pmg.kpoints]

                data_frames = []
                for spin, energy_matrix in bs_pmg.bands.items():
                    spin_label = "SpinUp" if spin.value == 1 else "SpinDown"
                    df_spin = pd.DataFrame(energy_matrix.T)
                    df_spin.columns = [f"Band_{i+1}_{spin_label}" for i in range(df_spin.shape[1])]
                    data_frames.append(df_spin)

                df_bs = pd.concat(data_frames, axis=1)
                df_bs.insert(0, "Distance", distances)
                df_bs.insert(1, "Label", labels)

                bs_filename = os.path.join(EXPORTS_DIR, f"{material_id}_{path_type_str}_bandstructure.csv")
                df_bs.to_csv(bs_filename, index=False)
                print(f"    Saved -> {bs_filename}  "
                      f"({len(df_bs)} kpoints, {len(data_frames[0].columns)} bands)")
            except Exception as e:
                print(f"    Export failed: {e}")
                traceback.print_exc()
        else:
            print("    SKIPPED (no data)")

        # ── Export DOS ────────────────────────────────────────────────
        print(f"\n[6] Exporting DOS...")
        if dos is not None:
            try:
                dos_pmg = dos.to_pymatgen() if hasattr(dos, "to_pymatgen") else dos

                dos_dict = {"Energy": dos_pmg.energies}
                for spin, density_vals in dos_pmg.densities.items():
                    spin_label = "SpinUp" if spin.value == 1 else "SpinDown"
                    dos_dict[f"Density_{spin_label}"] = density_vals

                df_dos = pd.DataFrame(dos_dict)
                dos_filename = os.path.join(EXPORTS_DIR, f"{material_id}_dos.csv")
                df_dos.to_csv(dos_filename, index=False)
                print(f"    Saved -> {dos_filename}  ({len(df_dos)} energy points)")
            except Exception as e:
                print(f"    Export failed: {e}")
                traceback.print_exc()
        else:
            print("    SKIPPED (no data)")

        print(f"\n{'='*60}\n  Done.\n{'='*60}\n")


if __name__ == "__main__":
    parser = argparse.ArgumentParser(
        description="Export Materials Project electronic structure to CSV"
    )
    parser.add_argument("--api_key", required=True, help="Materials Project API key")
    parser.add_argument("--mp_id", required=True, help="Material ID (e.g. mp-149) or legacy task ID")
    parser.add_argument(
        "--path_type", default="latimer_munro",
        help="K-path convention: latimer_munro, setyawan_curtarolo, or hinuma"
    )
    args = parser.parse_args()
    fetch_and_export_electronic_structure(args.api_key, args.mp_id, args.path_type)
