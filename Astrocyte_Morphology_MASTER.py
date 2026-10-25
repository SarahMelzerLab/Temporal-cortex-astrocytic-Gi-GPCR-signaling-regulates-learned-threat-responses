"""Portable 3-D Z-cylinder astrocyte-morphology workflow.

Run this file with Python, then select the raw TIFF folder and analysis-output
folder. The only quantitative endpoint is the number of detected Lck-GFP
process centerlines crossing each soma-centred cylindrical radius.

Keep these three Python files together:
  Astrocyte_Morphology_MASTER.py
  astrocyte_current_processes.py
  astrocyte_background_segmentation.py
"""
import argparse
from datetime import datetime, timezone
import hashlib
import json
import math
import os
from pathlib import Path
import re
import subprocess
import sys
import tempfile
import time

import numpy as np
import pandas as pd
from scipy import ndimage as ndi
from scipy.stats import levene, mannwhitneyu, shapiro, ttest_ind
from skimage import filters, morphology
import tifffile


CODE_DIR = Path(__file__).resolve().parent
MAIN_SCRIPT_NAME = Path(__file__).name
# This lab installation is the preferred validated environment. Another user
# can edit this one value or set ASTROCYTE_ANALYSIS_PYTHON. If the executable
# does not exist, the script simply continues with the current interpreter.
DEFAULT_ANALYSIS_PYTHON = r"C:\astrocyte_analysis\python.exe"
RELAUNCH_ENV_FLAG = "ASTROCYTE_ANALYSIS_RELAUNCHED"
CONFIG_NAME = "workflow_config.json"
FILES = None
ANALYSIS_ROOT = None
SETTINGS_DIR = None
ZCYLINDER_DIR = None
CACHE_DIR = None
NAPARI_DIR = None
VERSION = "zcylinder_intersections_z10_xy30_v1"
XY_UM = 0.08198898723923402
Z_HALF_PLANES = 10
MAX_RADIUS_UM = 30.0
RADIUS_STEP_UM = 1.0
_QT_APP = None

if str(CODE_DIR) not in sys.path:
    sys.path.insert(0, str(CODE_DIR))

from astrocyte_background_segmentation import robust_background_by_z
from astrocyte_current_processes import DEFAULT_FIBER_DETECTOR, segment_processes


# Bump this token only when preprocessing math changes. It is folded into the
# cache signature below so older masks cannot be silently reused by new code.
PREPROCESSING_VERSION = "gfp_gaussian015_background3_robust_z_v1"
SHELL_HALF_WIDTH_XY_PIXELS = 1.5
CACHE_SIGNATURE_VERSION = (
    f"{VERSION}|detector={DEFAULT_FIBER_DETECTOR}"
    f"|preprocess={PREPROCESSING_VERSION}|xy={XY_UM:.17g}"
    f"|zhalf={Z_HALF_PLANES}|rmax={MAX_RADIUS_UM:g}"
    f"|rstep={RADIUS_STEP_UM:g}|shell={SHELL_HALF_WIDTH_XY_PIXELS:g}px"
)


# ---------------------------------------------------------------------------
# Small persistence and path helpers
# ---------------------------------------------------------------------------

def relaunch_in_preferred_python():
    """Run this script to completion in the validated interpreter.

    Spyder commonly supplies its own Python and Qt environment variables to
    child processes.  Remove those variables and put the validated environment
    first on ``PATH`` so Napari loads the matching Qt libraries.  The parent
    process waits for the complete workflow, so it cannot report success while
    the actual analysis has silently exited.
    """
    configured = os.environ.get(
        "ASTROCYTE_ANALYSIS_PYTHON", DEFAULT_ANALYSIS_PYTHON).strip()
    if not configured or os.environ.get(RELAUNCH_ENV_FLAG) == "1":
        return False
    preferred = Path(configured).expanduser()
    if not preferred.is_file():
        print(
            f"Preferred analysis interpreter was not found: {preferred}\n"
            f"Continuing with: {sys.executable}", flush=True)
        return False
    try:
        already_using_preferred = os.path.samefile(preferred, sys.executable)
    except OSError:
        already_using_preferred = (
            str(preferred.resolve()).casefold() ==
            str(Path(sys.executable).resolve()).casefold())
    if already_using_preferred:
        return False
    environment = os.environ.copy()
    for variable in (
            "PYTHONHOME", "PYTHONPATH", "PYTHONEXECUTABLE",
            "QT_API", "QT_PLUGIN_PATH", "QT_QPA_PLATFORM_PLUGIN_PATH",
            "QML2_IMPORT_PATH", "VIRTUAL_ENV", "MPLBACKEND"):
        environment.pop(variable, None)
    for variable in tuple(environment):
        if variable.startswith("SPYDER_") or variable.startswith("PYDEVD_"):
            environment.pop(variable, None)

    preferred_root = preferred.parent.resolve()
    current_roots = []
    for candidate in (sys.prefix, os.environ.get("CONDA_PREFIX", "")):
        if not candidate:
            continue
        try:
            candidate_path = Path(candidate).resolve()
        except OSError:
            continue
        if candidate_path != preferred_root:
            current_roots.append(candidate_path)

    kept_path_entries = []
    for entry in environment.get("PATH", "").split(os.pathsep):
        if not entry:
            continue
        try:
            resolved_entry = Path(entry).resolve()
            from_current_environment = any(
                resolved_entry == root or root in resolved_entry.parents
                for root in current_roots)
        except OSError:
            from_current_environment = False
        if not from_current_environment:
            kept_path_entries.append(entry)

    preferred_path_entries = [
        preferred_root,
        preferred_root / "Scripts",
        preferred_root / "Library" / "bin",
    ]
    environment["PATH"] = os.pathsep.join(
        [str(path) for path in preferred_path_entries if path.exists()] +
        kept_path_entries)
    environment["CONDA_PREFIX"] = str(preferred_root)
    environment["CONDA_DEFAULT_ENV"] = str(preferred_root)
    environment["PYTHONUNBUFFERED"] = "1"
    environment[RELAUNCH_ENV_FLAG] = "1"
    print(
        "Running the complete analysis with the validated interpreter:\n"
        f"  {preferred}\n"
        "Keep this Spyder console open. It will report when the analysis "
        "window closes.", flush=True)
    process = subprocess.Popen(
        [str(preferred), str(Path(__file__).resolve()), *sys.argv[1:]],
        env=environment,
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT,
        text=True,
        bufsize=1,
        errors="replace")
    if process.stdout is not None:
        for output_line in process.stdout:
            print(output_line, end="", flush=True)
    return_code = process.wait()
    if return_code == 0:
        print(
            "The complete analysis finished normally in the validated "
            "interpreter.", flush=True)
    else:
        print(
            "The analysis process stopped before completing "
            f"(Windows exit code {return_code}).\n"
            "Any Python error from the validated process is shown above.",
            flush=True)
    return True

def utc_now():
    return datetime.now(timezone.utc).isoformat()


def _json_safe(value):
    if isinstance(value, np.ndarray):
        return [_json_safe(item) for item in value.tolist()]
    if isinstance(value, np.generic):
        return _json_safe(value.item())
    if isinstance(value, float) and not math.isfinite(value):
        return None
    if isinstance(value, dict):
        return {str(key): _json_safe(item) for key, item in value.items()}
    if isinstance(value, (list, tuple)):
        return [_json_safe(item) for item in value]
    return value


def _replace_with_network_retry(temporary, destination):
    """Atomically replace a file despite brief Windows/SMB sharing locks."""
    retry_delays = (0.1, 0.2, 0.4, 0.8, 1.6, 3.2, 3.2, 3.2)
    for attempt in range(len(retry_delays) + 1):
        try:
            os.replace(temporary, destination)
            return
        except PermissionError as error:
            if (getattr(error, "winerror", None) not in (5, 32, 33) or
                    attempt == len(retry_delays)):
                raise
            if attempt == 0:
                print(
                    "Waiting for a temporary Windows/network file lock: "
                    f"{Path(destination).name}", flush=True)
            time.sleep(retry_delays[attempt])


def atomic_json(path, value):
    """Write JSON atomically, including on Windows network shares."""
    path = Path(path); path.parent.mkdir(parents=True, exist_ok=True)
    payload = json.dumps(_json_safe(value), indent=2, allow_nan=False)
    temporary = None
    try:
        with tempfile.NamedTemporaryFile(
                mode="w", encoding="utf-8", newline="\n", delete=False,
                dir=path.parent, prefix=f".{path.name}.", suffix=".tmp") as handle:
            handle.write(payload)
            handle.flush()
            os.fsync(handle.fileno())
            temporary = Path(handle.name)
        _replace_with_network_retry(temporary, path)
    except Exception:
        if temporary is not None:
            try:
                temporary.unlink(missing_ok=True)
            except OSError:
                pass
        raise


def _relative_path(path, anchor):
    """Return a relocatable path, or ``None`` when Windows drives differ."""
    try:
        return os.path.relpath(Path(path).resolve(), Path(anchor).resolve())
    except ValueError:
        return None


def _resolve_saved_path(value, anchor):
    """Resolve a saved relative path while accepting older absolute configs."""
    if not value:
        return None
    path = Path(value)
    return path.resolve() if path.is_absolute() else (Path(anchor) / path).resolve()


def _manifest_for_storage(manifest):
    """Strip machine-specific locations from the canonical settings record."""
    stored = _json_safe(manifest)
    stored["input_folder"] = _relative_path(FILES, ANALYSIS_ROOT)
    stored["analysis_root"] = "."
    for row in stored.get("stacks", []):
        row["path"] = Path(row["path"]).name
    return stored


def configure_session(input_folder, analysis_folder):
    """Bind this process to user-selected raw and output folders."""
    global FILES, ANALYSIS_ROOT, SETTINGS_DIR, ZCYLINDER_DIR
    global CACHE_DIR, NAPARI_DIR
    FILES = Path(input_folder).resolve()
    ANALYSIS_ROOT = Path(analysis_folder).resolve()
    SETTINGS_DIR = ANALYSIS_ROOT / "Saved_settings"
    ZCYLINDER_DIR = ANALYSIS_ROOT / "ZCylinder_Analysis"
    CACHE_DIR = ANALYSIS_ROOT / "_analysis_cache"
    NAPARI_DIR = ZCYLINDER_DIR / "napari_launcher"
    for folder in (SETTINGS_DIR, ZCYLINDER_DIR / "single_cells",
                   ZCYLINDER_DIR / "group_analysis", CACHE_DIR, NAPARI_DIR):
        folder.mkdir(parents=True, exist_ok=True)
    save_workflow_config(FILES)


def save_workflow_config(input_folder):
    """Save only relocatable locations; launchers prompt if raw data moved."""
    SETTINGS_DIR.mkdir(parents=True, exist_ok=True)
    atomic_json(SETTINGS_DIR / CONFIG_NAME, {
        "workflow_version": VERSION,
        "input_folder_relative_to_analysis": _relative_path(
            input_folder, ANALYSIS_ROOT),
        "analysis_folder": ".",
        "note": "The main launcher asks for raw and analysis folders at each normal start."
    })


def choose_session_folders():
    """Ask for both folders at each normal launch, as requested."""
    from qtpy.QtWidgets import QFileDialog, QMessageBox
    raw = QFileDialog.getExistingDirectory(
        None, "1 of 2: Select the RAW TIFF folder", str(CODE_DIR))
    if not raw:
        return False
    raw_path = Path(raw)
    if not any(raw_path.glob("*.tif")) and not any(raw_path.glob("*.tiff")):
        QMessageBox.warning(None, "No TIFF files", "The selected raw folder contains no .tif or .tiff files.")
        return False
    output = QFileDialog.getExistingDirectory(
        None, "2 of 2: Select the ANALYSIS OUTPUT folder", str(CODE_DIR))
    if not output:
        return False
    configure_session(raw_path, output)
    return True


# ---------------------------------------------------------------------------
# GUI lifecycle
# ---------------------------------------------------------------------------

def ensure_qt():
    global _QT_APP
    from qtpy.QtWidgets import QApplication
    _QT_APP = QApplication.instance() or QApplication(sys.argv)
    return _QT_APP


def wait_viewer(viewer):
    """Wait for one Napari window across old and new Napari event APIs."""
    from qtpy.QtCore import QEventLoop, QTimer
    app = ensure_qt()
    previous = app.quitOnLastWindowClosed()
    window = viewer.window._qt_window
    loop = QEventLoop()
    timer = QTimer()
    def check_closed():
        try:
            visible = window.isVisible()
        except RuntimeError:
            visible = False
        if not visible:
            loop.quit()
    app.setQuitOnLastWindowClosed(False)
    try:
        timer.timeout.connect(check_closed)
        timer.start(50)
        loop.exec()
    finally:
        timer.stop()
        app.setQuitOnLastWindowClosed(previous)


def filename_info(path):
    path = Path(path)
    match = re.match(r"(SMEL\d+)_(\d+)_(R\d+C\d+[LR])", path.stem, re.I)
    zmatch = re.search(r"(?:^|_)z(\d{3})(?:_|\.|$)", path.stem, re.I)
    if not match or not zmatch:
        raise ValueError(f"Unrecognized publication filename: {path.name}")
    z_step = int(zmatch.group(1)) / 100.0
    return {"mouse_id": match.group(1).upper(),
            "mouse_number": int(match.group(1)[4:]),
            "section_id": f"{match.group(2)}_{match.group(3).upper()}",
            "stack_id": f"{match.group(1).upper()}_{match.group(2)}_{match.group(3).upper()}",
            "z_step_um": z_step}


# ---------------------------------------------------------------------------
# Raw-stack validation and saved-setting discovery
# ---------------------------------------------------------------------------

def inspect_tiff(path):
    path = Path(path).resolve(); stat = path.stat(); info = filename_info(path)
    with tifffile.TiffFile(path) as handle:
        series = handle.series[0]
        if series.axes != "ZCYX" or len(series.shape) != 4 or series.shape[1] != 4:
            raise ValueError(f"Expected one ZCYX four-channel stack; got {series.axes} {series.shape}")
        if info["z_step_um"] != 0.35:
            raise ValueError(f"Z-cylinder analysis requires z035; found {info['z_step_um']} um")
        shape = [int(value) for value in series.shape]
        dtype = str(np.dtype(series.dtype))
        imagej = dict(handle.imagej_metadata or {})
        embedded = imagej.get("spacing")
        if embedded is not None and not np.isclose(float(embedded), .35, atol=1e-6):
            raise ValueError("Filename and embedded Z spacing disagree")
    data = tifffile.memmap(path, mode="r")
    fingerprint = hashlib.sha256()
    for z in (0, shape[0] // 2, shape[0] - 1):
        for channel in range(4):
            plane = np.asarray(data[z, channel])
            # Force TIFF decoding here so a damaged plane fails during intake.
            _ = float(plane.max())
            sample = np.ascontiguousarray(plane[::32, ::32])
            fingerprint.update(np.asarray([z, channel], dtype=np.int32).tobytes())
            fingerprint.update(sample.tobytes())
    if getattr(data, "_mmap", None) is not None:
        data._mmap.close()
    return {**info, "path": str(path), "size_bytes": stat.st_size,
            "mtime_ns": stat.st_mtime_ns, "shape_zcyx": shape,
            "dtype": dtype, "sample_fingerprint": fingerprint.hexdigest(),
            "compatibility": "ZCYX_4ch_z035_OK"}


def _same_source(old, new):
    if old.get("sample_fingerprint") and new.get("sample_fingerprint"):
        return all(old.get(key) == new.get(key) for key in
                   ("size_bytes", "shape_zcyx", "dtype", "sample_fingerprint"))
    return all(old.get(key) == new.get(key) for key in
               ("size_bytes", "mtime_ns", "shape_zcyx"))


def _portable_move_match(old, new):
    """Fallback used only for a manifest the user explicitly imports."""
    return all(old.get(key) == new.get(key) for key in
               ("size_bytes", "shape_zcyx")) and (
                   not old.get("dtype") or old.get("dtype") == new.get("dtype"))


def _load_import_manifest():
    """Offer one explicit, non-destructive import when this output is new."""
    from qtpy.QtWidgets import QFileDialog, QMessageBox
    answer = QMessageBox.question(
        None, "Reuse prior saved settings?",
        "This analysis-output folder has no saved Z-cylinder settings yet. "
        "Would you like to import soma centers and GFP sensitivities from a prior manifest.json?",
        QMessageBox.Yes | QMessageBox.No, QMessageBox.No)
    if answer != QMessageBox.Yes:
        return None, None
    selected, _ = QFileDialog.getOpenFileName(
        None, "Select the prior manifest.json", str(CODE_DIR), "JSON (*.json)")
    if not selected:
        return None, None
    path = Path(selected).resolve()
    try:
        payload = json.loads(path.read_text(encoding="utf-8"))
    except (OSError, ValueError, TypeError) as error:
        QMessageBox.warning(None, "Could not import settings", str(error))
        return None, None
    if not isinstance(payload.get("stacks"), list):
        QMessageBox.warning(None, "Could not import settings",
                            "The selected JSON does not contain a stacks list.")
        return None, None
    return payload, path


def _read_cohort_workbook(path):
    """Read the assignment workbook with Python's standard library only."""
    import zipfile
    import xml.etree.ElementTree as ET

    spreadsheet_ns = "http://schemas.openxmlformats.org/spreadsheetml/2006/main"
    with zipfile.ZipFile(path, "r") as archive:
        shared_strings = []
        if "xl/sharedStrings.xml" in archive.namelist():
            shared_root = ET.fromstring(archive.read("xl/sharedStrings.xml"))
            for item in shared_root.findall(f"{{{spreadsheet_ns}}}si"):
                shared_strings.append("".join(
                    node.text or "" for node in item.iter(
                        f"{{{spreadsheet_ns}}}t")))
        sheet_root = ET.fromstring(archive.read("xl/worksheets/sheet1.xml"))

    def column_index(reference):
        letters = re.match(r"[A-Z]+", reference.upper()).group(0)
        result = 0
        for letter in letters:
            result = result * 26 + ord(letter) - 64
        return result - 1

    records = []
    for row in sheet_root.findall(
            f".//{{{spreadsheet_ns}}}sheetData/{{{spreadsheet_ns}}}row"):
        values = {}
        for cell in row.findall(f"{{{spreadsheet_ns}}}c"):
            index = column_index(cell.attrib.get("r", "A1"))
            cell_type = cell.attrib.get("t", "")
            if cell_type == "inlineStr":
                value = "".join(node.text or "" for node in cell.iter(
                    f"{{{spreadsheet_ns}}}t"))
            else:
                value_node = cell.find(f"{{{spreadsheet_ns}}}v")
                value = "" if value_node is None else value_node.text or ""
                if cell_type == "s" and value:
                    value = shared_strings[int(value)]
                elif cell_type == "b":
                    value = "True" if value == "1" else "False"
            values[index] = value
        if values:
            width = max(values) + 1
            records.append([values.get(index, "") for index in range(width)])
    if not records:
        return pd.DataFrame()
    width = max(len(row) for row in records)
    records = [row + [""] * (width - len(row)) for row in records]
    return pd.DataFrame(records[1:], columns=records[0]).fillna("")


def _write_cohort_workbook(table, path):
    """Write a small native XLSX without external Excel libraries."""
    import zipfile
    from xml.sax.saxutils import escape

    table = table.fillna("").astype(str)
    matrix = [list(table.columns)] + table.values.tolist()

    def cell(reference, value, style=0):
        style_attr = f' s="{style}"' if style else ""
        safe = escape(str(value), {'"': '&quot;'})
        return (f'<c r="{reference}" t="inlineStr"{style_attr}>'
                f'<is><t xml:space="preserve">{safe}</t></is></c>')

    columns = "ABCD"
    row_xml = []
    for row_number, values in enumerate(matrix, start=1):
        cells = []
        for column_number, value in enumerate(values):
            style = 1 if row_number == 1 else (2 if column_number in (1, 2) else 0)
            cells.append(cell(f"{columns[column_number]}{row_number}", value, style))
        row_xml.append(f'<row r="{row_number}">{"".join(cells)}</row>')
    last_row = len(matrix)
    worksheet_xml = f'''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<worksheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main">
<sheetViews><sheetView workbookViewId="0"><pane ySplit="1" topLeftCell="A2" activePane="bottomLeft" state="frozen"/><selection pane="bottomLeft" activeCell="A2" sqref="A2"/></sheetView></sheetViews>
<sheetFormatPr defaultRowHeight="15"/>
<cols><col min="1" max="1" width="17" customWidth="1"/><col min="2" max="2" width="15" customWidth="1"/><col min="3" max="3" width="22" customWidth="1"/><col min="4" max="4" width="58" customWidth="1"/></cols>
<sheetData>{''.join(row_xml)}</sheetData>
<autoFilter ref="A1:D{last_row}"/>
</worksheet>'''
    styles_xml = '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<styleSheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main">
<fonts count="2"><font><sz val="10"/><name val="Arial"/></font><font><b/><color rgb="FFFFFFFF"/><sz val="10"/><name val="Arial"/></font></fonts>
<fills count="4"><fill><patternFill patternType="none"/></fill><fill><patternFill patternType="gray125"/></fill><fill><patternFill patternType="solid"><fgColor rgb="FF1F4E78"/><bgColor indexed="64"/></patternFill></fill><fill><patternFill patternType="solid"><fgColor rgb="FFFFF2CC"/><bgColor indexed="64"/></patternFill></fill></fills>
<borders count="1"><border><left/><right/><top/><bottom/><diagonal/></border></borders>
<cellStyleXfs count="1"><xf numFmtId="0" fontId="0" fillId="0" borderId="0"/></cellStyleXfs>
<cellXfs count="3"><xf numFmtId="0" fontId="0" fillId="0" borderId="0" xfId="0"/><xf numFmtId="0" fontId="1" fillId="2" borderId="0" xfId="0" applyFont="1" applyFill="1" applyAlignment="1"><alignment horizontal="center" vertical="center"/></xf><xf numFmtId="0" fontId="0" fillId="3" borderId="0" xfId="0" applyFill="1"/></cellXfs>
<cellStyles count="1"><cellStyle name="Normal" xfId="0" builtinId="0"/></cellStyles><dxfs count="0"/><tableStyles count="0" defaultTableStyle="TableStyleMedium2" defaultPivotStyle="PivotStyleLight16"/>
</styleSheet>'''
    content_types = '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types"><Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/><Default Extension="xml" ContentType="application/xml"/><Override PartName="/xl/workbook.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.sheet.main+xml"/><Override PartName="/xl/worksheets/sheet1.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.worksheet+xml"/><Override PartName="/xl/styles.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.styles+xml"/></Types>'''
    root_rels = '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships"><Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="xl/workbook.xml"/></Relationships>'''
    workbook_xml = '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<workbook xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main" xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships"><sheets><sheet name="Cohort assignments" sheetId="1" r:id="rId1"/></sheets></workbook>'''
    workbook_rels = '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships"><Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/worksheet" Target="worksheets/sheet1.xml"/><Relationship Id="rId2" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/styles" Target="styles.xml"/></Relationships>'''
    path.parent.mkdir(parents=True, exist_ok=True)
    temporary = path.with_suffix(".xlsx.tmp")
    with zipfile.ZipFile(temporary, "w", zipfile.ZIP_DEFLATED) as archive:
        archive.writestr("[Content_Types].xml", content_types)
        archive.writestr("_rels/.rels", root_rels)
        archive.writestr("xl/workbook.xml", workbook_xml)
        archive.writestr("xl/_rels/workbook.xml.rels", workbook_rels)
        archive.writestr("xl/styles.xml", styles_xml)
        archive.writestr("xl/worksheets/sheet1.xml", worksheet_xml)
    temporary.replace(path)


def ensure_cohort_assignments(rows):
    """Create or validate the native Excel condition-assignment table."""
    path = ANALYSIS_ROOT / "cohort_assignments.xlsx"
    animal_ids = sorted({row["mouse_id"] for row in rows})
    if path.is_file():
        table = _read_cohort_workbook(path)
    else:
        table = None
    if table is not None:
        required = {"Animal_ID", "Condition"}
        if not required.issubset(table.columns):
            raise ValueError(
                f"{path.name} must contain Animal_ID and Condition columns.")
        table["Animal_ID"] = table["Animal_ID"].str.strip().str.upper()
        if table["Animal_ID"].duplicated().any():
            duplicate = table.loc[table["Animal_ID"].duplicated(), "Animal_ID"].iloc[0]
            raise ValueError(f"Duplicate Animal_ID in {path.name}: {duplicate}")
        missing = [animal for animal in animal_ids
                   if animal not in set(table["Animal_ID"])]
        if missing:
            additions = pd.DataFrame({
                "Animal_ID": missing, "Condition": "Unassigned",
                "Assignment_is_mock": "False",
                "Notes": "New animal: assign Saline or CNO before final inference."})
            table = pd.concat([table, additions], ignore_index=True)
    else:
        table = pd.DataFrame({
            "Animal_ID": animal_ids,
            "Condition": ["Saline"] * len(animal_ids),
            "Assignment_is_mock": ["True"] * len(animal_ids),
            "Notes": ["Initial mock assignment; verify before biological comparison."] * len(animal_ids)})
    for optional in ("Assignment_is_mock", "Notes"):
        if optional not in table.columns:
            table[optional] = ""
    normalized = table["Condition"].str.strip().str.lower().map(
        {"saline": "Saline", "cno": "CNO", "unassigned": "Unassigned", "": "Unassigned"})
    bad = table.loc[normalized.isna(), ["Animal_ID", "Condition"]]
    if not bad.empty:
        raise ValueError(
            "Condition must be Saline, CNO, or Unassigned. Invalid row: " +
            bad.iloc[0].to_dict().__repr__())
    table["Condition"] = normalized
    table = table[["Animal_ID", "Condition", "Assignment_is_mock", "Notes"]]
    table = table.sort_values("Animal_ID").reset_index(drop=True)
    _write_cohort_workbook(table, path)
    mapping = dict(zip(table["Animal_ID"], table["Condition"]))
    for row in rows:
        row["condition"] = mapping.get(row["mouse_id"], "Unassigned")
    return table


def discover_manifest(import_manifest_path=None, allow_import_prompt=True):
    if FILES is None or ANALYSIS_ROOT is None:
        raise RuntimeError("Select the raw TIFF and analysis-output folders first.")
    SETTINGS_DIR.mkdir(parents=True, exist_ok=True)
    manifest_path = SETTINGS_DIR / "manifest.json"
    imported_path = None
    if manifest_path.is_file():
        previous = json.loads(manifest_path.read_text(encoding="utf-8"))
    elif import_manifest_path:
        imported_path = Path(import_manifest_path).resolve()
        previous = json.loads(imported_path.read_text(encoding="utf-8"))
    elif allow_import_prompt:
        imported, imported_path = _load_import_manifest()
        previous = imported or {"stacks": []}
    else:
        previous = {"stacks": []}
    old_by_id = {row["stack_id"]: row for row in previous.get("stacks", [])}
    paths = sorted([*FILES.glob("*.tif"), *FILES.glob("*.tiff")],
                   key=lambda item: item.name.lower())
    rows, errors = [], []
    for path in paths:
        try:
            row = inspect_tiff(path)
        except ValueError as error:
            if "requires z035" not in str(error):
                errors.append({"File": path.name, "Error": str(error)})
            continue
        old = old_by_id.get(row["stack_id"])
        # A fingerprint disagreement means the pixels changed. The weaker
        # size/shape fallback is reserved for explicitly imported old
        # manifests that predate fingerprints.
        old_has_fingerprint = bool(old and old.get("sample_fingerprint"))
        matched = bool(old and (
            _same_source(old, row) or
            (imported_path and not old_has_fingerprint and
             _portable_move_match(old, row))))
        if matched:
            for key in ("soma_global_zyx", "soma_saved_utc", "soma_source",
                        "fiber_sensitivity", "threshold_saved_utc",
                        "threshold_source"):
                if key in old:
                    row[key] = old[key]
            if (row.get("soma_source") and
                    row.get("soma_source") not in
                    {"manual_zcylinder", "reused_manual_soma"}):
                row["soma_source"] = "reused_manual_soma"
            if (row.get("threshold_source") and
                    row.get("threshold_source") not in
                    {"manual_zcylinder", "reused_manual_gfp_sensitivity"}):
                row["threshold_source"] = "reused_manual_gfp_sensitivity"
            row["settings_match"] = (
                "content_fingerprint" if _same_source(old, row)
                else "explicit_import_same_id_size_shape")
        else:
            row.update(soma_global_zyx=None, fiber_sensitivity=None)
        rows.append(row)
    if errors:
        pd.DataFrame(errors).to_csv(SETTINGS_DIR / "INCOMPATIBLE_FILES.csv", index=False)
    if not rows:
        raise ValueError("No compatible z035 TIFFs were found.")
    ids = [row["stack_id"] for row in rows]
    if len(ids) != len(set(ids)):
        raise ValueError("Duplicate stack identifiers found; resolve filenames before analysis.")
    ensure_cohort_assignments(rows)
    manifest = {"version": VERSION, "updated_utc": utc_now(),
                "input_folder": str(FILES), "analysis_root": str(ANALYSIS_ROOT),
                "analysis": "3-D Z cylinder: selected soma +/-10 optical planes; 30-um maximum XY radius; fiber-centerline intersections only",
                "mcherry_territory_used": False,
                "imported_settings_from": "prior_saved_settings_manifest" if imported_path else None,
                "stacks": rows}
    save_manifest(manifest)
    return manifest


def save_manifest(manifest):
    """Persist settings without embedding this computer's absolute paths."""
    manifest["updated_utc"] = utc_now()
    SETTINGS_DIR.mkdir(parents=True, exist_ok=True)
    atomic_json(SETTINGS_DIR / "manifest.json", _manifest_for_storage(manifest))
    pd.DataFrame([{"Stack_ID": row["stack_id"], "Mouse_ID": row["mouse_id"],
                   "Section_ID": row["section_id"], "Z_planes": row["shape_zcyx"][0],
                   "Soma_ZYX": row.get("soma_global_zyx"),
                   "Soma_source": row.get("soma_source"),
                   "GFP_sensitivity": row.get("fiber_sensitivity"),
                   "Threshold_source": row.get("threshold_source"),
                   "Source_TIFF": Path(row["path"]).name}
                  for row in manifest["stacks"]]).to_csv(
        SETTINGS_DIR / "STACK_STATUS.csv", index=False)
    # Old cached summaries may predate portable paths. Rewriting metadata does
    # not touch masks, centerlines, crossings, or figures.
    for row in manifest["stacks"]:
        summary_path = cell_folder(row["stack_id"]) / "analysis_summary.json"
        if not summary_path.is_file():
            continue
        try:
            summary = json.loads(summary_path.read_text(encoding="utf-8"))
        except (OSError, ValueError, TypeError):
            continue
        source_name = Path(row["path"]).name
        if summary.get("source") != source_name:
            summary["source"] = source_name
            atomic_json(summary_path, summary)
    export_saved_settings(manifest)


def export_saved_settings(manifest):
    """Write simple portable mirrors; manifest.json remains canonical."""
    soma_rows, threshold_rows = [], []
    for row in manifest.get("stacks", []):
        center = row.get("soma_global_zyx")
        soma_rows.append({"Stack_ID": row["stack_id"],
                          "Soma_Z": center[0] if center else np.nan,
                          "Soma_Y": center[1] if center else np.nan,
                          "Soma_X": center[2] if center else np.nan,
                          "Soma_source": row.get("soma_source", ""),
                          "TIFF_size_bytes": row["size_bytes"],
                          "TIFF_mtime_ns": row["mtime_ns"]})
        threshold_rows.append({"Stack_ID": row["stack_id"],
                               "GFP_sensitivity": row.get("fiber_sensitivity", np.nan),
                               "Threshold_source": row.get("threshold_source", ""),
                               "TIFF_size_bytes": row["size_bytes"],
                               "TIFF_mtime_ns": row["mtime_ns"]})
    pd.DataFrame(soma_rows).to_csv(SETTINGS_DIR / "SAVED_SOMA_CENTERS.csv", index=False)
    pd.DataFrame(threshold_rows).to_csv(
        SETTINGS_DIR / "SAVED_GFP_SENSITIVITIES.csv", index=False)
    progress_rows=[]
    for row in manifest.get("stacks", []):
        center=row.get("soma_global_zyx")
        if center is None:
            full_z="Pending soma selection"
            complete_radius=np.nan
        else:
            geo=geometry(row)
            full_z=geo["full_z21"]
            complete_radius=geo["complete_radius_um"]
        progress_rows.append({
            "Stack_ID":row["stack_id"], "Z_planes":row["shape_zcyx"][0],
            "Structurally_compatible":row["compatibility"],
            "Stack_can_contain_21_planes":row["shape_zcyx"][0] >= 21,
            "Selected_soma_has_full_plus_minus_10":full_z,
            "Complete_XY_radius_um":complete_radius,
            "Soma_saved":center is not None,
            "GFP_sensitivity_saved":row.get("fiber_sensitivity") is not None,
            "Current_analysis_complete":analysis_is_current(row)})
    pd.DataFrame(progress_rows).to_csv(
        SETTINGS_DIR / "COMPATIBILITY_AND_PROGRESS.csv", index=False)
    (SETTINGS_DIR / "DO_NOT_DELETE_SETTINGS.txt").write_text(
        "Keep this entire Saved_settings folder. manifest.json is the canonical record "
        "that lets the workflow reuse soma centers and GFP sensitivities. The CSV "
        "files are readable mirrors for inspection.\n", encoding="utf-8")


def choose_item(title, prompt, labels, preferred=0):
    from qtpy.QtWidgets import QInputDialog
    selected, accepted = QInputDialog.getItem(
        None, title, prompt, labels, preferred, False)
    return selected if accepted else None


def choose_row(rows, title):
    labels = [f"{row['stack_id']} | {Path(row['path']).name}" for row in rows]
    selected = choose_item(title, "Choose one image stack:", labels)
    return rows[labels.index(selected)] if selected else None


# ---------------------------------------------------------------------------
# Soma selection and GFP detector review
# ---------------------------------------------------------------------------

def _unit(volume):
    sample = np.asarray(volume[::max(1, volume.shape[0] // 20), ::8, ::8], np.float32)
    low, high = np.percentile(sample, [1, 99.8])
    return np.clip((np.asarray(volume, np.float32) - low) /
                   max(float(high - low), 1.0), 0, 1)


def _identity_rgb(dapi, sox9):
    d, s = _unit(dapi), _unit(sox9)
    rgb = np.zeros((*d.shape, 3), np.float32)
    rgb[..., 0] = s; rgb[..., 1] = .08 * s; rgb[..., 2] = np.maximum(d, s)
    return rgb


def _high_contrast_limits(volume):
    """Return robust display-only limits without changing the source intensities."""
    z_stride = max(1, int(volume.shape[0]) // 24)
    sample = np.asarray(volume[::z_stride, ::4, ::4], dtype=np.float32)
    finite = sample[np.isfinite(sample)]
    if finite.size == 0:
        return 0.0, 1.0
    low, high = np.percentile(finite, (40.0, 99.7))
    if not np.isfinite(low):
        low = 0.0
    if not np.isfinite(high) or high <= low:
        high = low + 1.0
    return float(low), float(high)


def select_soma(row):
    import napari
    from qtpy.QtWidgets import QLabel, QMessageBox, QPushButton, QVBoxLayout, QWidget
    data = tifffile.memmap(row["path"], mode="r")
    spacing = (row["z_step_um"], XY_UM, XY_UM)
    viewer = napari.Viewer(ndisplay=2, title=row["stack_id"] + " — select one soma")
    viewer.add_image(data[:, 1], name="Raw GFP", scale=spacing, colormap="gray",
                     blending="additive", visible=True)
    viewer.add_image(_identity_rgb(data[:, 0], data[:, 2]),
                     name="DAPI blue + SOX9 magenta", rgb=True, scale=spacing,
                     blending="additive", visible=True)
    mcherry_limits = _high_contrast_limits(data[:, 3])
    mcherry = viewer.add_image(
        data[:, 3], name="High-contrast mCherry — DISPLAY ONLY; NOT analyzed",
        scale=spacing, colormap="red", blending="additive", visible=False,
        opacity=.85, contrast_limits=mcherry_limits, gamma=.55)
    points = viewer.add_points(name="SELECT EXACTLY ONE SOMA", ndim=3, scale=spacing,
                               size=45, face_color="yellow", border_color="black",
                               out_of_slice_display=True)
    state = {"saved": False, "center": None}
    controls = QWidget(); layout = QVBoxLayout(controls)
    text = QLabel(
        "Scroll to the soma plane. Click the Place/reposition button, then click "
        "the soma center once. High-contrast mCherry is identity context only and "
        "never defines the analysis region.")
    text.setWordWrap(True); layout.addWidget(text)
    status = QLabel("Ready to place one soma point.")
    status.setWordWrap(True); layout.addWidget(status)
    place = QPushButton("1. Place/reposition soma center"); layout.addWidget(place)
    toggle_mcherry = QPushButton("Show high-contrast mCherry"); layout.addWidget(toggle_mcherry)
    clear = QPushButton("Clear soma point"); layout.addWidget(clear)
    save = QPushButton("Save this soma center"); layout.addWidget(save)
    cancel = QPushButton("Pause without changing the saved center"); layout.addWidget(cancel)
    viewer.window.add_dock_widget(controls, area="right", name="Z-cylinder soma selection")

    def activate_placement(clear_existing=True):
        if clear_existing and len(points.data):
            points.data = np.empty((0, 3), dtype=float)
        viewer.layers.selection.active = points
        points.mode = "add"
        status.setText("Placement active: click once on the center of the soma.")

    def clear_point():
        points.data = np.empty((0, 3), dtype=float)
        activate_placement(clear_existing=False)

    def toggle_mcherry_visibility():
        mcherry.visible = not bool(mcherry.visible)
        toggle_mcherry.setText(
            "Hide high-contrast mCherry" if mcherry.visible
            else "Show high-contrast mCherry")

    def save_point():
        if len(points.data) != 1:
            QMessageBox.warning(
                None, "One soma required",
                "Click 'Place/reposition soma center', then click exactly once on the soma.")
            return
        center = np.rint(points.data[0]).astype(int)
        full_z = center[0] >= Z_HALF_PLANES and center[0] + Z_HALF_PLANES < data.shape[0]
        if not full_z:
            answer = QMessageBox.question(
                None, "Incomplete Z-cylinder depth",
                "This soma does not have 10 acquired planes both above and below. "
                "The Z-cylinder result will be saved as unavailable (NaN). Save anyway?",
                QMessageBox.Yes | QMessageBox.No, QMessageBox.No)
            if answer != QMessageBox.Yes: return
        state.update(saved=True, center=center.tolist()); viewer.close()

    place.clicked.connect(lambda checked=False: activate_placement())
    toggle_mcherry.clicked.connect(lambda checked=False: toggle_mcherry_visibility())
    clear.clicked.connect(lambda checked=False: clear_point())
    save.clicked.connect(lambda checked=False: save_point())
    cancel.clicked.connect(lambda checked=False: viewer.close())
    activate_placement(clear_existing=False)
    viewer.reset_view(); wait_viewer(viewer)
    if getattr(data, "_mmap", None) is not None: data._mmap.close()
    return state["center"] if state["saved"] else None


def geometry(row):
    """Define the soma-centred ±10-plane crop and complete XY radius."""
    center = np.asarray(row["soma_global_zyx"], int)
    shape = np.asarray(row["shape_zcyx"])[[0, 2, 3]]
    distances = [center[1] * XY_UM, (shape[1] - 1 - center[1]) * XY_UM,
                 center[2] * XY_UM, (shape[2] - 1 - center[2]) * XY_UM]
    complete_radius = min(MAX_RADIUS_UM, float(np.floor(min(distances))))
    if complete_radius < 1:
        raise ValueError(f"{row['stack_id']}: soma is too close to an XY edge.")
    context = min(float(min(distances)), complete_radius + 1.0)
    pixels = int(math.ceil(context / XY_UM))
    y0, y1 = max(0, center[1]-pixels), min(shape[1], center[1]+pixels+1)
    x0, x1 = max(0, center[2]-pixels), min(shape[2], center[2]+pixels+1)
    z0, z1 = max(0, center[0]-Z_HALF_PLANES), min(shape[0], center[0]+Z_HALF_PLANES+1)
    origin = np.asarray([z0, y0, x0]); local = center-origin
    return {"bounds": [[z0,z1],[y0,y1],[x0,x1]], "origin": origin.tolist(),
            "local_center": local.tolist(), "complete_radius_um": complete_radius,
            "processing_radius_um": context,
            "full_z21": bool(
                z0 == center[0] - Z_HALF_PLANES and
                z1 == center[0] + Z_HALF_PLANES + 1),
            "captured_z_planes": int(z1-z0)}


def load_crop(row):
    geo = geometry(row); bounds = geo["bounds"]
    data = tifffile.memmap(row["path"], mode="r")
    z, y, x = (slice(*item) for item in bounds)
    raw = np.asarray(data[z, :, y, x]).copy()
    if getattr(data, "_mmap", None) is not None: data._mmap.close()
    return raw, geo


def normalize_gfp(gfp, center, spacing):
    sigma = tuple(.15 / value for value in spacing)
    processed = ndi.gaussian_filter(gfp, sigma=sigma, mode="nearest", output=np.float32)
    background = ndi.gaussian_filter(
        gfp, sigma=tuple(3.0/value for value in spacing), mode="nearest",
        truncate=3.0, output=np.float32)
    processed -= background; del background
    config = {"xy_sample_stride": 4, "soma_xy_exclusion_radius_um": 12.0,
              "sample_upper_percentile": 99.5, "sigma_floor_intensity": .5,
              "z_smoothing_um": 1.0}
    median, sigma_z, record = robust_background_by_z(
        processed, center, spacing, config, ndi, np)
    normalized = np.empty_like(processed)
    for z in range(len(processed)):
        normalized[z] = (processed[z]-median[z])/sigma_z[z]
    return normalized, record


def plane_detect(normalized, territory, sensitivity):
    """Fast 2-D threshold preview; final measurements use segment_processes."""
    image = np.clip(np.asarray(normalized, np.float32), 0, 8)
    sato = filters.sato(image, sigmas=(1,2,3), black_ridges=False)
    meij = filters.meijering(image, sigmas=(1,2,3), black_ridges=False)
    local_sigma = max(2.0, 1.5 / XY_UM)
    meij = np.maximum(meij-ndi.gaussian_filter(meij, local_sigma, mode="nearest"), 0)
    effective = float(np.clip(sensitivity, 0, 100))
    low_q, high_q = 20+.55*effective, 70+.20*effective
    floor, strong_floor = .10+.009*effective, .75+.010*effective
    output_mask = np.zeros_like(territory, bool)
    output_skeleton = np.zeros_like(territory, bool)
    for ridge in (sato, meij):
        reference = territory & (image >= .1) & (ridge > 0)
        if not reference.any(): continue
        weak = territory & (image >= floor) & (ridge >= np.percentile(ridge[reference], low_q))
        strong = territory & (image >= strong_floor) & (ridge >= np.percentile(ridge[reference], high_q))
        labels, _ = ndi.label(weak, structure=np.ones((3,3), bool))
        seeded = np.unique(labels[strong]); seeded = seeded[seeded > 0]
        kept = np.isin(labels, seeded) if seeded.size else np.zeros_like(weak)
        kept = morphology.remove_small_objects(kept, max_size=4, connectivity=2)
        output_mask |= kept; output_skeleton |= morphology.skeletonize(kept)
    return output_mask & territory, output_skeleton & territory


def detection_inputs(row):
    raw, geo = load_crop(row); center = np.asarray(geo["local_center"], int)
    spacing = np.asarray([row["z_step_um"], XY_UM, XY_UM])
    normalized, background = normalize_gfp(raw[:,1], center, spacing)
    yy, xx = np.indices(raw.shape[2:])
    distance = np.sqrt(((yy-center[1])*XY_UM)**2+((xx-center[2])*XY_UM)**2)
    processing_disk = distance <= geo["processing_radius_um"]
    territory = np.broadcast_to(processing_disk, normalized.shape).copy()
    valid = np.logical_or.reduce([raw[:,channel] != 0 for channel in range(4)])
    return raw, geo, center, spacing, normalized, distance, territory, valid, background


def review_threshold(row, initial=50):
    import napari
    from qtpy.QtCore import Qt
    from qtpy.QtWidgets import QLabel, QPushButton, QSlider, QVBoxLayout, QWidget
    (raw, geo, center, spacing, normalized, distance, territory,
     valid, _) = detection_inputs(row)
    z = int(center[0]); state = {"saved": False, "stage": "plane", "value": int(initial)}
    viewer = napari.Viewer(ndisplay=2, title=row["stack_id"]+" — GFP threshold only")
    viewer.add_image(raw[:,1], name="Raw GFP", scale=spacing, colormap="gray",
                     blending="additive")
    radius_line = np.abs(distance-geo["complete_radius_um"]) <= XY_UM*1.5
    viewer.add_image(np.broadcast_to(radius_line, raw.shape[0:1]+raw.shape[2:]).copy(),
                     name=f"Complete XY radius {geo['complete_radius_um']:g} um",
                     scale=spacing, colormap="yellow", blending="additive", opacity=.8)
    fibers = viewer.add_image(np.zeros_like(raw[:,1],np.uint8), name="Detected fibers — cyan",
                              scale=spacing, colormap="cyan", blending="additive",
                              contrast_limits=(0,1))
    viewer.add_points([center], name="Selected soma", scale=spacing, size=45,
                      face_color="yellow", border_color="black", out_of_slice_display=True)
    controls=QWidget(); layout=QVBoxLayout(controls)
    instruction=QLabel(); instruction.setWordWrap(True); layout.addWidget(instruction)
    status=QLabel(); status.setWordWrap(True); layout.addWidget(status)
    slider=QSlider(Qt.Horizontal); slider.setRange(0,100); slider.setValue(int(initial)); layout.addWidget(slider)
    accept=QPushButton("1. Accept soma-plane threshold; build Z +/-10"); layout.addWidget(accept)
    confirm=QPushButton("2. Confirm through Z and save sensitivity"); layout.addWidget(confirm)
    back=QPushButton("Back to soma-plane slider"); layout.addWidget(back)
    cancel=QPushButton("Pause without changing sensitivity"); layout.addWidget(cancel)
    viewer.window.add_dock_widget(controls, area="right", name="Z-cylinder GFP threshold")
    def update_controls():
        plane=state["stage"]=="plane"; slider.setVisible(plane); accept.setVisible(plane)
        confirm.setVisible(not plane); back.setVisible(not plane)
        instruction.setText(("Move LEFT for more fibers and RIGHT for fewer. Cyan should follow thin raw GFP, not diffuse background."
                             if plane else "Scroll through all acquired planes. Confirm only if cyan follows raw GFP without filling the field."))
    def update_plane(value=None):
        viewer.dims.set_current_step(0,z); state["value"]=int(slider.value())
        mask, skeleton=plane_detect(normalized[z],territory[z],state["value"])
        shown=np.zeros_like(raw[:,1],np.uint8); shown[z]=ndi.maximum_filter(skeleton.astype(np.uint8),size=3)
        fibers.data=shown; fraction=100*float(mask[territory[z]].mean())
        status.setText(f"Sensitivity {state['value']} | soma-plane GFP-positive pixels {fraction:.1f}%")
    def build_z():
        _, skeleton, _ = segment_processes(
            normalized, territory, spacing, state["value"])
        skeleton &= valid
        state.update(stage="z")
        fibers.data=(ndi.maximum_filter(skeleton.astype(np.uint8),size=(1,3,3))>0).astype(np.uint8)
        status.setText(f"Sensitivity {state['value']} | captured {geo['captured_z_planes']} planes | full +/-10: {geo['full_z21']}")
        update_controls()
    def back_plane(): state.update(stage="plane"); update_plane(); update_controls()
    def save(): state.update(saved=True); viewer.close()
    slider.valueChanged.connect(update_plane); accept.clicked.connect(lambda checked=False:build_z())
    back.clicked.connect(lambda checked=False:back_plane()); confirm.clicked.connect(lambda checked=False:save())
    cancel.clicked.connect(lambda checked=False:viewer.close())
    update_plane(); update_controls(); viewer.dims.set_current_step(0,z); viewer.reset_view(); wait_viewer(viewer)
    return state["value"] if state["saved"] else None


def radial_crossings(skeleton, valid, distance, max_radius, full_z=True):
    """Count connected fiber-centerline intersections at each XY radius."""
    crossings=[]
    for radius in np.arange(1,MAX_RADIUS_UM+1,RADIUS_STEP_UM):
        complete=bool(radius <= max_radius and full_z)
        shell=np.abs(distance-radius)<=XY_UM*SHELL_HALF_WIDTH_XY_PIXELS
        hits=skeleton & valid & shell[None]
        count=int(ndi.label(hits,structure=np.ones((3,3,3),bool))[1]) if complete else np.nan
        crossings.append(count)
    return crossings


# ---------------------------------------------------------------------------
# Per-cell quantification and review artifacts
# ---------------------------------------------------------------------------

def cell_folder(stack_id):
    """Private cache folder; public cell outputs stay flat and easy to browse."""
    return CACHE_DIR / stack_id


def zcylinder_cell_stem(stack_id):
    return ZCYLINDER_DIR / "single_cells" / f"{stack_id}_ZCylinder"


def expected_cell_artifacts(row):
    """Files that must exist before one cell is considered complete."""
    stack_id = row["stack_id"]
    folder = cell_folder(stack_id)
    stem = zcylinder_cell_stem(stack_id)
    return (
        folder / "analysis_summary.json",
        folder / "analysis_masks.npz",
        stem.with_suffix(".csv"),
        stem.with_suffix(".png"),
        stem.with_suffix(".svg"),
        NAPARI_DIR / f"{stack_id}_OPEN_NAPARI.cmd",
    )


def analysis_signature(row):
    """Return the exact inputs that make a saved result reusable."""
    return {"version":CACHE_SIGNATURE_VERSION,
            "source":{key:row.get(key) for key in
                      ("size_bytes", "shape_zcyx", "dtype", "sample_fingerprint")},
            "soma":row.get("soma_global_zyx"),
            "sensitivity":row.get("fiber_sensitivity")}


def analysis_is_current(row):
    summary_path = cell_folder(row["stack_id"]) / "analysis_summary.json"
    if not summary_path.is_file():
        return False
    try:
        saved = json.loads(summary_path.read_text(encoding="utf-8"))
    except (OSError, ValueError, TypeError):
        return False
    return (saved.get("status") == "complete" and
            saved.get("analysis_signature") == analysis_signature(row) and
            all(path.is_file() for path in expected_cell_artifacts(row)))


def analyze_cell(row, force=False):
    folder=cell_folder(row["stack_id"]); folder.mkdir(parents=True,exist_ok=True)
    signature=analysis_signature(row)
    summary_path=folder/"analysis_summary.json"
    if not force and analysis_is_current(row):
        return json.loads(summary_path.read_text(encoding="utf-8"))
    raw,geo,center,spacing,normalized,distance,territory,valid,background=detection_inputs(row)
    sensitivity=int(row["fiber_sensitivity"])
    zc_mask,zc_skeleton,qc=segment_processes(normalized,territory,spacing,sensitivity)
    zc_mask &= valid; zc_skeleton &= valid
    crossings=radial_crossings(zc_skeleton,valid,distance,
                               geo["complete_radius_um"],geo["full_z21"])
    radii=np.arange(
        int(RADIUS_STEP_UM), int(MAX_RADIUS_UM) + 1, int(RADIUS_STEP_UM))
    common={"Stack_ID":row["stack_id"], "Animal_ID":row["mouse_id"],
            "Condition":row.get("condition","Unassigned")}
    result=pd.DataFrame({**common, "Radius_um":radii,
                         "Fiber_centerline_intersections":crossings,
                         "Complete_XY":radii<=geo["complete_radius_um"],
                         "Complete_Z_plus_minus_10":geo["full_z21"]})
    result.to_csv(zcylinder_cell_stem(row["stack_id"]).with_suffix(".csv"),index=False)
    np.savez_compressed(folder/"analysis_masks.npz",
                        zcylinder_mask=zc_mask.astype(np.uint8),
                        zcylinder_skeleton=zc_skeleton.astype(np.uint8),
                        valid=valid.astype(np.uint8),distance_um=distance.astype(np.float32))
    summary={"version":VERSION,"status":"complete","stack_id":row["stack_id"],
             "source":Path(row["path"]).name,
             "analysis_signature":signature,"soma_global_zyx":row["soma_global_zyx"],
             "fiber_sensitivity":sensitivity,"spacing_zyx_um":spacing.tolist(),"geometry":geo,
             "crop_bounds_global_zyx":geo["bounds"],
             "z_half_planes":Z_HALF_PLANES,"zcylinder_eligible":geo["full_z21"],
             "mcherry_used":False,"background":background,"process_qc":qc,"completed_utc":utc_now()}
    render_zcylinder_cell(row,raw,center,result,zc_skeleton)
    write_napari_launcher(row)
    # Mark complete only after every numerical and review artifact exists.
    atomic_json(summary_path,summary)
    return summary


def _save_figure(fig, stem):
    fig.savefig(stem.with_suffix(".png"),dpi=190)
    fig.savefig(stem.with_suffix(".svg"))
    fig.clear()


def render_zcylinder_cell(row,raw,center,result,skeleton):
    import matplotlib; matplotlib.use("Agg")
    from matplotlib.backends.backend_agg import FigureCanvasAgg
    from matplotlib.figure import Figure
    from matplotlib.colors import ListedColormap
    fig=Figure(figsize=(11,5),layout="constrained"); FigureCanvasAgg(fig); axes=fig.subplots(1,2)
    projection=np.max(raw[:,1],axis=0); axes[0].imshow(projection,cmap="gray")
    shown=np.max(skeleton,axis=0)>0
    axes[0].imshow(np.ma.masked_where(~shown,shown),cmap=ListedColormap(["cyan"]),alpha=.95)
    axes[0].scatter(center[2],center[1],c="yellow",s=35,edgecolor="black")
    axes[0].set_title("Z ±10 max projection + cyan fibers")
    axes[1].plot(result.Radius_um,result.Fiber_centerline_intersections,color="teal",lw=2)
    axes[1].axvspan(15,20,color="#f2c14e",alpha=.18)
    axes[1].set(xlabel="XY radius (µm)",ylabel="Fiber-centerline intersections",
                title="3-D radial intersections")
    for axis in axes: axis.grid(alpha=.15)
    eligibility="full 21 planes" if bool(result.Complete_Z_plus_minus_10.iloc[0]) else "incomplete Z — result is NaN"
    fig.suptitle(f"{row['stack_id']} — 3-D Z-cylinder analysis | {eligibility} | {row.get('condition','Unassigned')}")
    _save_figure(fig,zcylinder_cell_stem(row["stack_id"]))


def write_napari_launcher(row):
    """Write a location-independent Windows convenience launcher.

    Users may set ASTROCYTE_ANALYSIS_PYTHON to a Python executable. Otherwise
    the active ``python`` on PATH is used. ASTROCYTE_ANALYSIS_PROGRAM can
    override the master script location if code and results are moved apart.
    """
    launcher=NAPARI_DIR/f"{row['stack_id']}_OPEN_NAPARI.cmd"
    program_relative = _relative_path(CODE_DIR / MAIN_SCRIPT_NAME, NAPARI_DIR)
    default_program = ""
    if program_relative is not None:
        default_program = (
            f'if not defined PROGRAM set "PROGRAM=%~dp0'
            f'{program_relative.replace("/", chr(92))}"\n')
    content=("@echo off\n"
             "set \"PROGRAM=%ASTROCYTE_ANALYSIS_PROGRAM%\"\n"
             f"{default_program}"
             "if not exist \"%PROGRAM%\" (\n"
             "  echo Cannot locate Astrocyte_Morphology_MASTER.py.\n"
             "  echo Move code and results together or set ASTROCYTE_ANALYSIS_PROGRAM.\n"
             "  pause\n"
             "  exit /b 1\n"
             ")\n"
             "if defined ASTROCYTE_ANALYSIS_PYTHON (\n"
             f"  \"%ASTROCYTE_ANALYSIS_PYTHON%\" \"%PROGRAM%\" --open-review \"{row['stack_id']}\" "
             "--analysis-root \"%~dp0..\\..\"\n"
             ") else (\n"
             f"  python \"%PROGRAM%\" --open-review \"{row['stack_id']}\" "
             "--analysis-root \"%~dp0..\\..\"\n"
             ")\n"
             "if errorlevel 1 pause\n")
    launcher.write_text(content,encoding="utf-8")


def completed_rows(manifest):
    return [row for row in manifest["stacks"] if analysis_is_current(row)]


def _summary_curve(combined, value):
    """Return descriptive per-radius source data used by the group figure."""
    group=combined.groupby(["Condition","Radius_um"])[value]
    table=group.agg(n_cells="count",Mean="mean",Median="median",Q1=lambda x:x.quantile(.25),Q3=lambda x:x.quantile(.75),SD="std").reset_index()
    table["SEM"]=table.SD/np.sqrt(table.n_cells)
    shapiro_w=[]; shapiro_p=[]; recommendations=[]
    for _,row in table.iterrows():
        values=combined.loc[(combined.Condition==row.Condition)&
                            (combined.Radius_um==row.Radius_um),value].dropna().to_numpy(float)
        if 3 <= len(values) <= 5000 and np.ptp(values) > 0:
            result=shapiro(values); shapiro_w.append(float(result.statistic)); shapiro_p.append(float(result.pvalue))
            recommendations.append("Mean_SEM" if result.pvalue >= .05 else "Median_IQR")
        else:
            shapiro_w.append(np.nan); shapiro_p.append(np.nan); recommendations.append("Insufficient_n_or_no_variance")
    table["Shapiro_W"]=shapiro_w; table["Shapiro_p"]=shapiro_p
    table["Recommended_summary"]=recommendations
    return table


def rebuild_group(manifest):
    rows=completed_rows(manifest)
    if not rows: return
    frames=[]
    for row in rows:
        sid=row["stack_id"]
        cell_csv=zcylinder_cell_stem(sid).with_suffix(".csv")
        frame=pd.read_csv(cell_csv)
        condition=row.get("condition","Unassigned")
        old_conditions=set(frame["Condition"].dropna().astype(str))
        label_changed=old_conditions != {str(condition)}
        frame["Animal_ID"]=row["mouse_id"]
        frame["Condition"]=condition
        if label_changed:
            # Unblinding changes labels only. Refresh the per-cell table and
            # QC title from saved masks without repeating fiber detection.
            frame.to_csv(cell_csv,index=False)
            raw,geo=load_crop(row)
            center=np.asarray(geo["local_center"],int)
            with np.load(cell_folder(sid)/"analysis_masks.npz") as saved:
                skeleton=saved["zcylinder_skeleton"].astype(bool)
            render_zcylinder_cell(row,raw,center,frame,skeleton)
        frames.append(frame)
    group_dir=ZCYLINDER_DIR/"group_analysis"
    combined=pd.concat(frames,ignore_index=True)
    combined.to_csv(group_dir/"ZCylinder_individual_cells.csv",index=False)
    summary=_summary_curve(combined,"Fiber_centerline_intersections")
    summary.to_csv(group_dir/"ZCylinder_intersections_summary.csv",index=False)
    render_group_intersections(
        combined,summary,group_dir/"GROUP_ZCYLINDER_INTERSECTIONS")
    run_unblinded_comparison(
        combined,"Fiber_centerline_intersections",
        group_dir/"GROUP_ZCYLINDER_15_20UM_COMPARISON")
    write_condition_sample_sizes(rows)


# ---------------------------------------------------------------------------
# Group plots, assumption checks, statistics, and source-data export
# ---------------------------------------------------------------------------

def render_group_intersections(combined,summary,stem):
    import matplotlib; matplotlib.use("Agg")
    from matplotlib.backends.backend_agg import FigureCanvasAgg
    from matplotlib.figure import Figure
    fig=Figure(figsize=(9,6),layout="constrained"); FigureCanvasAgg(fig); axis=fig.subplots()
    colors={"Saline":"#1f77b4","CNO":"#d62728","Unassigned":"#777777"}
    for condition, _ in combined.groupby("Condition"):
        color=colors.get(condition,"#777777")
        s=summary.loc[summary.Condition==condition]
        x=s.Radius_um.to_numpy(float);mean=s.Mean.to_numpy(float);sem=s.SEM.fillna(0).to_numpy(float)
        axis.plot(x,mean,color=color,lw=2,label=f"{condition} cell mean ± SEM")
        axis.fill_between(x,mean-sem,mean+sem,color=color,alpha=.16)
    axis.axvspan(15,20,color="#f2c14e",alpha=.18,label="15–20 µm follow-up window")
    axis.set(title="3-D Z-cylinder radial intersections",
             xlabel="XY radius from selected soma (µm)",
             ylabel="Lck-GFP process centerline crossings (count)")
    axis.grid(alpha=.2);axis.legend(fontsize=8)
    fig.suptitle("Cell-level group mean ± SEM\nMissing radii or incomplete depth are NaN, never zero")
    _save_figure(fig,stem)


def _normality_p(values):
    values=np.asarray(values,float)
    if 3 <= len(values) <= 5000 and np.ptp(values)>0:
        return float(shapiro(values).pvalue)
    return np.nan


def _comparison_test(per_cell):
    saline=per_cell.loc[per_cell.Condition=="Saline","Cell_value"].dropna().to_numpy(float)
    cno=per_cell.loc[per_cell.Condition=="CNO","Cell_value"].dropna().to_numpy(float)
    record={"Saline_n_cells":len(saline),"CNO_n_cells":len(cno),
            "Saline_N_animals":per_cell.loc[per_cell.Condition=="Saline","Animal_ID"].nunique(),
            "CNO_N_animals":per_cell.loc[per_cell.Condition=="CNO","Animal_ID"].nunique(),
            "Saline_Shapiro_p":_normality_p(saline),"CNO_Shapiro_p":_normality_p(cno),
            "Levene_p":np.nan,"Test":"Insufficient cells",
            "Statistic":np.nan,"p_value":np.nan,"Summary":"Not tested"}
    if len(saline)<2 or len(cno)<2:
        return record
    record["Levene_p"]=float(levene(saline,cno,center="median").pvalue)
    normal=(np.isfinite(record["Saline_Shapiro_p"]) and
            np.isfinite(record["CNO_Shapiro_p"]) and
            record["Saline_Shapiro_p"]>=.05 and record["CNO_Shapiro_p"]>=.05)
    if normal and record["Levene_p"]>=.05:
        result=ttest_ind(saline,cno,equal_var=True)
        record.update(Test="Student independent-samples t-test",
                      Statistic=float(result.statistic),p_value=float(result.pvalue),
                      Summary="Cell mean ± SEM")
    elif normal:
        result=ttest_ind(saline,cno,equal_var=False)
        record.update(Test="Welch independent-samples t-test",
                      Statistic=float(result.statistic),p_value=float(result.pvalue),
                      Summary="Cell mean ± SEM")
    else:
        result=mannwhitneyu(saline,cno,alternative="two-sided",method="auto")
        record.update(Test="Mann–Whitney U test",
                      Statistic=float(result.statistic),p_value=float(result.pvalue),
                      Summary="Cell median and IQR")
    return record


def _p_stars(value):
    if not np.isfinite(value): return "not tested"
    if value<.0001:return "****"
    if value<.001:return "***"
    if value<.01:return "**"
    if value<.05:return "*"
    return "ns"


def _ascii_export_frame(frame):
    """Return an export copy whose text is safe in any CSV/Excel locale."""
    replacements = str.maketrans({
        "±": "+/-", "µ": "u", "μ": "u", "–": "-", "—": "-",
        "−": "-", " ": " ",
    })

    def clean(value):
        if not isinstance(value, str):
            return value
        value = value.translate(replacements)
        return value.encode("ascii", "ignore").decode("ascii")

    result = frame.copy()
    for column in result.select_dtypes(include=["object", "string"]).columns:
        result[column] = result[column].map(clean)
    return result


def _write_source_data_workbook(per_cell, statistics, path):
    """Write a formatted, multi-sheet XLSX using only the standard library."""
    import zipfile
    from xml.sax.saxutils import escape

    dictionary = pd.DataFrame([
        ("Per-cell values", "Stack_ID", "Unique confocal-stack/cell identifier"),
        ("Per-cell values", "Animal_ID", "Animal identifier parsed from Stack_ID"),
        ("Per-cell values", "Condition", "Treatment group from cohort_assignments.xlsx"),
        ("Per-cell values", "Cell_value", "Mean centerline-crossing count across available radii from 15 through 20 um"),
        ("Per-cell values", "Radii_averaged", "Radial interval used for the per-cell value"),
        ("Statistics", "Saline_n_cells", "Number of Saline cells included in the comparison"),
        ("Statistics", "CNO_n_cells", "Number of CNO cells included in the comparison"),
        ("Statistics", "Saline_N_animals", "Number of Saline animals represented"),
        ("Statistics", "CNO_N_animals", "Number of CNO animals represented"),
        ("Statistics", "Saline_Shapiro_p", "Shapiro-Wilk normality-test p value for Saline cell values"),
        ("Statistics", "CNO_Shapiro_p", "Shapiro-Wilk normality-test p value for CNO cell values"),
        ("Statistics", "Levene_p", "Median-centered Levene variance-test p value"),
        ("Statistics", "Test", "Two-group statistical test selected from the assumption checks"),
        ("Statistics", "Statistic", "Test statistic"),
        ("Statistics", "p_value", "Two-sided comparison p value"),
        ("Statistics", "Summary", "Summary convention used in the corresponding plot"),
        ("Statistics", "Analysis", "Analysis geometry"),
        ("Statistics", "Outcome", "Measured outcome"),
        ("Statistics", "Window_um", "Inclusive radial interval summarized for each cell"),
        ("Statistics", "Inferential_unit", "Independent unit used by the statistical test"),
        ("Statistics", "Animal_ID_role", "How animal identity is reported in this comparison"),
    ], columns=["Sheet", "Field", "Definition"])
    sheets = [
        ("Per-cell values", _ascii_export_frame(per_cell)),
        ("Statistics", _ascii_export_frame(statistics)),
        ("Data dictionary", dictionary),
    ]

    def column_name(index):
        name = ""
        while index:
            index, remainder = divmod(index - 1, 26)
            name = chr(65 + remainder) + name
        return name

    def cell_xml(reference, value, style=0):
        style_attr = f' s="{style}"' if style else ""
        if value is None or (not isinstance(value, str) and pd.isna(value)):
            return f'<c r="{reference}"{style_attr}/>'
        if isinstance(value, (bool, np.bool_)):
            return f'<c r="{reference}" t="b"{style_attr}><v>{int(value)}</v></c>'
        if isinstance(value, (int, float, np.integer, np.floating)):
            number = float(value)
            if math.isfinite(number):
                text = str(int(number)) if number.is_integer() else repr(number)
                return f'<c r="{reference}"{style_attr}><v>{text}</v></c>'
            return f'<c r="{reference}"{style_attr}/>'
        safe = escape(str(value), {'"': '&quot;'})
        return (f'<c r="{reference}" t="inlineStr"{style_attr}>'
                f'<is><t xml:space="preserve">{safe}</t></is></c>')

    worksheet_xml = []
    for _, frame in sheets:
        frame = frame.reset_index(drop=True)
        matrix = [list(frame.columns)] + frame.values.tolist()
        rows = []
        for row_number, values in enumerate(matrix, start=1):
            cells = [cell_xml(f"{column_name(column_number)}{row_number}", value,
                              1 if row_number == 1 else 0)
                     for column_number, value in enumerate(values, start=1)]
            rows.append(f'<row r="{row_number}">{"".join(cells)}</row>')
        widths = []
        for column_number, column in enumerate(frame.columns, start=1):
            values = [str(column), *["" if pd.isna(value) else str(value)
                                     for value in frame[column].tolist()]]
            width = min(max(max(map(len, values)) + 2, 10), 70)
            widths.append(
                f'<col min="{column_number}" max="{column_number}" '
                f'width="{width}" customWidth="1"/>')
        last_column = column_name(max(len(frame.columns), 1))
        last_row = max(len(matrix), 1)
        worksheet_xml.append(
            '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
            '<worksheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main">'
            '<sheetViews><sheetView workbookViewId="0"><pane ySplit="1" topLeftCell="A2" '
            'activePane="bottomLeft" state="frozen"/><selection pane="bottomLeft" '
            'activeCell="A2" sqref="A2"/></sheetView></sheetViews>'
            '<sheetFormatPr defaultRowHeight="15"/>'
            f'<cols>{"".join(widths)}</cols><sheetData>{"".join(rows)}</sheetData>'
            f'<autoFilter ref="A1:{last_column}{last_row}"/></worksheet>')

    sheet_entries = "".join(
        f'<sheet name="{escape(name, {chr(34): "&quot;"})}" sheetId="{index}" r:id="rId{index}"/>'
        for index, (name, _) in enumerate(sheets, start=1))
    relationships = "".join(
        f'<Relationship Id="rId{index}" '
        'Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/worksheet" '
        f'Target="worksheets/sheet{index}.xml"/>'
        for index in range(1, len(sheets) + 1))
    styles_id = len(sheets) + 1
    worksheet_overrides = "".join(
        f'<Override PartName="/xl/worksheets/sheet{index}.xml" '
        'ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.worksheet+xml"/>'
        for index in range(1, len(sheets) + 1))
    workbook_xml = (
        '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
        '<workbook xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main" '
        'xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships">'
        f'<sheets>{sheet_entries}</sheets></workbook>')
    workbook_rels = (
        '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
        '<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">'
        f'{relationships}<Relationship Id="rId{styles_id}" '
        'Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/styles" '
        'Target="styles.xml"/></Relationships>')
    styles_xml = '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<styleSheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main">
<fonts count="2"><font><sz val="10"/><name val="Arial"/></font><font><b/><color rgb="FFFFFFFF"/><sz val="10"/><name val="Arial"/></font></fonts>
<fills count="3"><fill><patternFill patternType="none"/></fill><fill><patternFill patternType="gray125"/></fill><fill><patternFill patternType="solid"><fgColor rgb="FF1F4E78"/><bgColor indexed="64"/></patternFill></fill></fills>
<borders count="1"><border><left/><right/><top/><bottom/><diagonal/></border></borders>
<cellStyleXfs count="1"><xf numFmtId="0" fontId="0" fillId="0" borderId="0"/></cellStyleXfs>
<cellXfs count="2"><xf numFmtId="0" fontId="0" fillId="0" borderId="0" xfId="0"/><xf numFmtId="0" fontId="1" fillId="2" borderId="0" xfId="0" applyFont="1" applyFill="1" applyAlignment="1"><alignment horizontal="center" vertical="center"/></xf></cellXfs>
<cellStyles count="1"><cellStyle name="Normal" xfId="0" builtinId="0"/></cellStyles><dxfs count="0"/><tableStyles count="0" defaultTableStyle="TableStyleMedium2" defaultPivotStyle="PivotStyleLight16"/>
</styleSheet>'''
    content_types = (
        '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
        '<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">'
        '<Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>'
        '<Default Extension="xml" ContentType="application/xml"/>'
        '<Override PartName="/xl/workbook.xml" '
        'ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.sheet.main+xml"/>'
        f'{worksheet_overrides}<Override PartName="/xl/styles.xml" '
        'ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.styles+xml"/>'
        '</Types>')
    root_rels = (
        '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
        '<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">'
        '<Relationship Id="rId1" '
        'Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" '
        'Target="xl/workbook.xml"/></Relationships>')

    path = Path(path)
    path.parent.mkdir(parents=True, exist_ok=True)
    temporary = path.with_suffix(".xlsx.tmp")
    try:
        with zipfile.ZipFile(temporary, "w", zipfile.ZIP_DEFLATED) as archive:
            archive.writestr("[Content_Types].xml", content_types)
            archive.writestr("_rels/.rels", root_rels)
            archive.writestr("xl/workbook.xml", workbook_xml)
            archive.writestr("xl/_rels/workbook.xml.rels", workbook_rels)
            archive.writestr("xl/styles.xml", styles_xml)
            for index, xml in enumerate(worksheet_xml, start=1):
                archive.writestr(f"xl/worksheets/sheet{index}.xml", xml)
        temporary.replace(path)
    except Exception:
        temporary.unlink(missing_ok=True)
        raise


def run_unblinded_comparison(combined,value,stem):
    """Compare cell-level 15–20 µm means, with animal N reported separately."""
    window=combined.loc[combined.Radius_um.between(15,20)&combined[value].notna()].copy()
    per_cell=(window.groupby(["Stack_ID","Animal_ID","Condition"],as_index=False)[value]
              .mean().rename(columns={value:"Cell_value"}))
    per_cell["Radii_averaged"]="15-20 um inclusive; available radii only"
    stats=_comparison_test(per_cell)
    stats.update(Analysis="3-D Z-cylinder",Outcome=value,Window_um="15-20 um inclusive",
                 Inferential_unit="cell",Animal_ID_role="N reported only; not averaged for test")
    per_cell_export = _ascii_export_frame(per_cell)
    stats_export = _ascii_export_frame(pd.DataFrame([stats]))
    per_cell_export.to_csv(stem.with_name(stem.name+"_per_cell.csv"),index=False)
    stats_export.to_csv(stem.with_name(stem.name+"_statistics.csv"),index=False)
    workbook_path = stem.with_name(stem.name+"_source_data.xlsx")
    try:
        _write_source_data_workbook(per_cell_export, stats_export, workbook_path)
    except Exception as exc:
        print(f"WARNING: Source-data workbook was not written ({type(exc).__name__}: {exc}). "
              "The ASCII-only CSV files were saved successfully.")
    render_unblinded_dotplot(per_cell,stats,stem)


def render_unblinded_dotplot(per_cell,stats,stem):
    import matplotlib;matplotlib.use("Agg")
    from matplotlib.backends.backend_agg import FigureCanvasAgg
    from matplotlib.figure import Figure
    from matplotlib.patches import Rectangle
    fig=Figure(figsize=(7,6),layout="constrained");FigureCanvasAgg(fig);axis=fig.subplots()
    colors={"Saline":"#1f77b4","CNO":"#d62728"};rng=np.random.default_rng(20261022)
    for x,condition in enumerate(("Saline","CNO")):
        cells=per_cell.loc[per_cell.Condition==condition,"Cell_value"].to_numpy(float)
        if len(cells):
            axis.scatter(x+rng.uniform(-.12,.12,len(cells)),cells,s=30,alpha=.48,
                         color=colors[condition])
            if stats["Summary"]=="Cell mean ± SEM":
                center=float(np.mean(cells));spread=float(np.std(cells,ddof=1)/np.sqrt(len(cells))) if len(cells)>1 else 0
                low,high=center-spread,center+spread
            else:
                center=float(np.median(cells));low,high=np.quantile(cells,[.25,.75]) if len(cells)>1 else (center,center)
            axis.add_patch(Rectangle((x-.22,low),.44,max(high-low,np.finfo(float).eps),
                                     facecolor=colors[condition],alpha=.18,edgecolor=colors[condition]))
            axis.hlines(center,x-.22,x+.22,color=colors[condition],lw=3,zorder=5)
    finite=per_cell.Cell_value.to_numpy(float)
    if len(finite):
        ymin,ymax=float(np.nanmin(finite)),float(np.nanmax(finite));span=max(ymax-ymin,1.0)
        bracket=ymax+.12*span
        axis.plot([0,0,1,1],[bracket-.02*span,bracket,bracket,bracket-.02*span],color="black",lw=1.2)
        p=stats["p_value"]
        label=(f"{stats['Test']}\np={p:.3g} ({_p_stars(p)})" if np.isfinite(p)
               else stats["Test"])
        axis.text(.5,bracket+.025*span,label,ha="center",va="bottom",fontsize=9)
        axis.set_ylim(ymin-.1*span,bracket+.25*span)
    cell_counts=per_cell.groupby("Condition").size().to_dict()
    animal_counts=per_cell.groupby("Condition").Animal_ID.nunique().to_dict()
    axis.set_xticks([0,1],[f"Saline\nn={cell_counts.get('Saline',0)} cells; N={animal_counts.get('Saline',0)} animals",
                          f"CNO\nn={cell_counts.get('CNO',0)} cells; N={animal_counts.get('CNO',0)} animals"])
    axis.set_ylabel("Mean fiber-centerline intersections across 15–20 µm")
    axis.set_title("3-D Z-cylinder post-unblinding comparison\nStatistical test uses individual cells")
    axis.grid(axis="y",alpha=.2)
    _save_figure(fig,stem)


def write_condition_sample_sizes(rows):
    records=[]
    conditions=sorted({"Saline","CNO"}|{row.get("condition","Unassigned") for row in rows})
    for condition in conditions:
        eligible=[row for row in rows if row.get("condition","Unassigned")==condition
                  and geometry(row)["full_z21"]]
        records.append({"Analysis":"3-D Z-cylinder intersections","Condition":condition,
                        "n_cells":len(eligible),
                        "N_animals":len({row["mouse_id"] for row in eligible})})
    pd.DataFrame(records).to_csv(ANALYSIS_ROOT/"condition_sample_sizes.csv",index=False)


# ---------------------------------------------------------------------------
# Saved-result viewer and interactive workflow orchestration
# ---------------------------------------------------------------------------

def open_review(row):
    import napari
    from qtpy.QtWidgets import QLabel,QPushButton,QVBoxLayout,QWidget
    folder=cell_folder(row["stack_id"])
    saved=np.load(folder/"analysis_masks.npz")
    raw,geo=load_crop(row); center=np.asarray(geo["local_center"]); spacing=np.asarray([row["z_step_um"],XY_UM,XY_UM])
    viewer=napari.Viewer(ndisplay=2,title=row["stack_id"]+" — 3-D Z-cylinder saved review")
    raw_layer=viewer.add_image(raw[:,1],name="Raw GFP",scale=spacing,colormap="gray",blending="additive")
    viewer.add_image(_identity_rgb(raw[:,0],raw[:,2]),name="DAPI blue + SOX9 magenta",rgb=True,scale=spacing,visible=False)
    fiber_layer=viewer.add_image(
        ndi.maximum_filter(saved["zcylinder_skeleton"],size=(1,5,5)),
        name="Detected fiber centerlines — cyan",scale=spacing,colormap="cyan",
        blending="additive",visible=True,contrast_limits=(0,1))
    center_layer=viewer.add_points([center],name="Selected soma center",scale=spacing,size=45,face_color="yellow",border_color="black",out_of_slice_display=True)
    controls=QWidget(); layout=QVBoxLayout(controls)
    text=QLabel(
        f"The analysis uses 10 optical planes above and below the selected soma and "
        f"extends to a complete XY radius of {geo['complete_radius_um']:g} µm. "
        "Scroll through Z to compare cyan detected centerlines with raw gray GFP. "
        "The only quantitative output is the number of centerline intersections at each XY radius.")
    text.setWordWrap(True); layout.addWidget(text)
    plane=QPushButton("2-D plane view (scroll through Z)")
    volume=QPushButton("Rotatable 3-D detected centerlines (display only)")
    layout.addWidget(plane);layout.addWidget(volume)

    def show_plane():
        viewer.dims.ndisplay=2;fiber_layer.visible=True;raw_layer.visible=True
        center_layer.visible=True
        viewer.dims.set_current_step(0,int(center[0]));viewer.reset_view()
    def show_volume():
        viewer.dims.ndisplay=3;raw_layer.visible=False
        center_layer.visible=False
        fiber_layer.visible=True
        viewer.reset_view()
    plane.clicked.connect(lambda checked=False:show_plane())
    volume.clicked.connect(lambda checked=False:show_volume())
    viewer.window.add_dock_widget(controls,area="right",name="Z-cylinder views")
    show_plane();wait_viewer(viewer)


def ensure_centers(manifest, rows, reselect_all=False):
    for index,row in enumerate(rows,1):
        if row.get("soma_global_zyx") is not None and not reselect_all: continue
        print(f"SOMA {index}/{len(rows)}: {row['stack_id']}",flush=True)
        center=select_soma(row)
        if center is None: save_manifest(manifest); return False
        row.update(soma_global_zyx=center,soma_source="manual_zcylinder",soma_saved_utc=utc_now(),fiber_sensitivity=None)
        save_manifest(manifest)
    return True


def ensure_thresholds(manifest, rows, rereview_all=False):
    for index,row in enumerate(rows,1):
        if row.get("fiber_sensitivity") is not None and not rereview_all: continue
        print(f"GFP THRESHOLD {index}/{len(rows)}: {row['stack_id']}",flush=True)
        value=review_threshold(row,int(row.get("fiber_sensitivity") or 50))
        if value is None: save_manifest(manifest); return False
        row.update(fiber_sensitivity=int(value),threshold_source="manual_zcylinder",threshold_saved_utc=utc_now())
        save_manifest(manifest)
    return True


def analyze_rows(manifest,rows,force=False):
    for index,row in enumerate(rows,1):
        if row.get("soma_global_zyx") is None or row.get("fiber_sensitivity") is None: continue
        print(f"ANALYZE {index}/{len(rows)}: {row['stack_id']}",flush=True); analyze_cell(row,force=force)
    rebuild_group(manifest); save_manifest(manifest)


def single_reanalyze(manifest):
    row=choose_row(manifest["stacks"],"Single-cell reanalysis")
    if row is None:return
    soma_choice=choose_item("Soma center","How should the soma be handled?",["Reuse saved soma if available","Select/reselect soma"],0)
    if soma_choice is None:return
    if not ensure_centers(manifest,[row],reselect_all=soma_choice.startswith("Select")):return
    threshold_choice=choose_item("GFP sensitivity","How should GFP sensitivity be handled?",["Reuse saved sensitivity if available","Review/review again"],0)
    if threshold_choice is None:return
    if not ensure_thresholds(manifest,[row],rereview_all=threshold_choice.startswith("Review")):return
    analyze_rows(manifest,[row],force=True);open_review(row)


def inspect_finished(manifest,title,repeat=False):
    rows=completed_rows(manifest)
    if not rows:
        from qtpy.QtWidgets import QMessageBox
        QMessageBox.information(None,title,"No completed Z-cylinder cells are available yet.");return
    while True:
        row=choose_row(rows,title)
        if row is None:
            return
        open_review(row)
        if not repeat:
            return


def group_resume(manifest):
    soma_choice=choose_item("Group soma centers","Reuse all matching saved centers and select only missing ones?",["Reuse saved; select missing only","Reselect every soma","Cancel"],0)
    if soma_choice is None or soma_choice=="Cancel":return
    if not ensure_centers(manifest,manifest["stacks"],reselect_all=soma_choice.startswith("Reselect")):return
    threshold_choice=choose_item("Group GFP sensitivities","Reuse saved GFP sensitivities and review only missing ones?",["Reuse saved; review missing only","Review every GFP sensitivity","Cancel"],0)
    if threshold_choice is None or threshold_choice=="Cancel":return
    if not ensure_thresholds(manifest,manifest["stacks"],rereview_all=threshold_choice.startswith("Review every")):return
    analyze_rows(manifest,manifest["stacks"],force=False)
    from qtpy.QtWidgets import QMessageBox
    QMessageBox.information(None,"Z-cylinder group complete",f"Saved under:\n{ANALYSIS_ROOT}")


def rebuild_after_unblinding(manifest):
    """Refresh Saline/CNO labels and rebuild statistics without redetecting fibers."""
    ensure_cohort_assignments(manifest["stacks"])
    save_manifest(manifest)
    rebuild_group(manifest)
    from qtpy.QtWidgets import QMessageBox
    QMessageBox.information(
        None,"Post-unblinding analysis rebuilt",
        "The condition curves, 15–20 µm comparisons, and n/N table were rebuilt "
        "from cohort_assignments.xlsx. No soma or GFP detection was rerun.")


def run(input_folder=None, output_folder=None):
    """Start an interactive analysis, optionally with folders from the CLI."""
    ensure_qt()
    if input_folder is not None or output_folder is not None:
        if input_folder is None or output_folder is None:
            raise ValueError("Provide both --input-folder and --output-folder.")
        configure_session(input_folder, output_folder)
    elif not choose_session_folders():
        print("Workflow cancelled before any analysis folders were changed.",flush=True)
        return
    manifest=discover_manifest()
    scope=choose_item("3-D Z-cylinder analysis","Choose an analysis scope:",
                      ["Single cell","Group analysis"],1)
    if scope=="Single cell":
        action=choose_item("Single cell","Choose what to do:",
                           ["Analyze/reanalyze one cell","Inspect one completed cell"],0)
        if action=="Analyze/reanalyze one cell": single_reanalyze(manifest)
        elif action=="Inspect one completed cell": inspect_finished(
            manifest,"Inspect completed single cell")
    elif scope=="Group analysis":
        action=choose_item("Group analysis","Choose what to do:",[
            "Resume analysis — reuse saved settings and complete missing cells",
            "Rebuild Saline/CNO follow-up only — after unblinding",
            "Inspect completed cells only"],0)
        if action and action.startswith("Resume analysis"): group_resume(manifest)
        elif action and action.startswith("Rebuild Saline/CNO"): rebuild_after_unblinding(manifest)
        elif action=="Inspect completed cells only": inspect_finished(
            manifest,"Inspect completed group cells — Cancel when finished",repeat=True)
    else:
        print("Workflow cancelled. Saved work is unchanged.",flush=True)


def run_saved_review(stack_id, analysis_root, raw_folder=None):
    """Entry point used by the per-cell launchers."""
    ensure_qt()
    root=Path(analysis_root).resolve()
    config_path=root/"Saved_settings"/CONFIG_NAME
    configured_raw=Path(raw_folder).resolve() if raw_folder else None
    if configured_raw is None and config_path.is_file():
        try:
            config=json.loads(config_path.read_text(encoding="utf-8"))
            saved_path=config.get("input_folder_relative_to_analysis")
            if saved_path is None:
                # Compatibility with settings saved before portable paths.
                saved_path=config.get("input_folder")
            configured_raw=_resolve_saved_path(saved_path,root)
        except (OSError,ValueError,KeyError,TypeError):
            configured_raw=None
    if configured_raw is None or not configured_raw.is_dir():
        from qtpy.QtWidgets import QFileDialog
        selected=QFileDialog.getExistingDirectory(
            None,"Locate the RAW TIFF folder for this saved analysis",str(root))
        if not selected:
            return
        configured_raw=Path(selected)
    configure_session(configured_raw,root)
    manifest=discover_manifest(allow_import_prompt=False)
    row=next((item for item in manifest["stacks"] if item["stack_id"]==stack_id),None)
    if row is None:
        raise ValueError(f"{stack_id} was not found in the selected raw TIFF folder.")
    if not analysis_is_current(row):
        from qtpy.QtWidgets import QMessageBox
        QMessageBox.warning(None,"Saved review is not current",
                            "This cell must be analyzed with its current soma and GFP settings before review.")
        return
    open_review(row)


def main():
    if relaunch_in_preferred_python():
        return
    parser=argparse.ArgumentParser(description="Portable 3-D Z-cylinder astrocyte analysis")
    parser.add_argument("--open-review",metavar="STACK_ID")
    parser.add_argument("--analysis-root")
    parser.add_argument("--raw-folder")
    parser.add_argument("--input-folder",help="Raw TIFF folder; otherwise choose it in the GUI")
    parser.add_argument("--output-folder",help="Analysis-output folder; otherwise choose it in the GUI")
    args=parser.parse_args()
    if args.open_review:
        if not args.analysis_root:
            parser.error("--open-review requires --analysis-root")
        run_saved_review(args.open_review,args.analysis_root,args.raw_folder)
    else:
        run(args.input_folder,args.output_folder)


if __name__=="__main__":main()
