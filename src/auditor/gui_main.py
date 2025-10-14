"""PySide6 GUI for the environment auditor."""
from __future__ import annotations

import json
import logging
import os
import sys
from typing import Any, Dict, List, Optional

from PySide6.QtCore import Qt
from PySide6.QtGui import QIcon, QTextOption
from PySide6.QtWidgets import (
    QApplication,
    QFileDialog,
    QGroupBox,
    QHBoxLayout,
    QLabel,
    QMainWindow,
    QMessageBox,
    QPushButton,
    QCheckBox,
    QPlainTextEdit,
    QSplitter,
    QVBoxLayout,
    QWidget,
    QDialog,
)

from .auditor_core import AuditOptions, EnvironmentAuditor, build_markdown, build_powershell_script

logger = logging.getLogger(__name__)
MAX_PREVIEW_LINES = 800


class MarkdownDialog(QDialog):
    def __init__(self, parent: Optional[QWidget], content: str) -> None:
        super().__init__(parent)
        self.setWindowTitle("Reporte completo")
        self.resize(900, 700)
        layout = QVBoxLayout(self)
        viewer = QPlainTextEdit(self)
        viewer.setReadOnly(True)
        viewer.setPlainText(content)
        viewer.setWordWrapMode(QTextOption.NoWrap)
        layout.addWidget(viewer)


class MainWindow(QMainWindow):
    def __init__(self) -> None:
        super().__init__()
        self.setWindowTitle("Environment Auditor")
        self.resize(1100, 700)
        self.auditor = EnvironmentAuditor()
        self.latest_options = AuditOptions()
        self.latest_report: Optional[Dict[str, Any]] = None
        self._full_markdown: str = ""

        self._build_ui()
        self._run_audit()

    def _build_ui(self) -> None:
        central = QWidget(self)
        layout = QHBoxLayout(central)

        splitter = QSplitter(Qt.Horizontal, self)
        layout.addWidget(splitter)

        option_widget = QWidget(self)
        option_layout = QVBoxLayout(option_widget)

        section_group = QGroupBox("Sections", option_widget)
        section_layout = QVBoxLayout(section_group)

        self.chk_env = QCheckBox("Environment variables")
        self.chk_env.setChecked(True)
        self.chk_path = QCheckBox("PATH entries")
        self.chk_path.setChecked(True)
        self.chk_psmodule = QCheckBox("PSModulePath entries")
        self.chk_psmodule.setChecked(True)
        self.chk_custom = QCheckBox("Custom variables")
        self.chk_custom.setChecked(True)
        self.chk_diag = QCheckBox("Diagnostics")
        self.chk_diag.setChecked(True)

        for widget in (self.chk_env, self.chk_path, self.chk_psmodule, self.chk_custom, self.chk_diag):
            section_layout.addWidget(widget)

        section_layout.addStretch(1)
        option_layout.addWidget(section_group)

        button_group = QGroupBox("Actions", option_widget)
        button_layout = QVBoxLayout(button_group)

        self.btn_analyze = QPushButton("Analyze")
        self.btn_export_md = QPushButton("Export Markdown…")
        self.btn_export_json = QPushButton("Export JSON…")
        self.btn_export_ps = QPushButton("Export PowerShell Script…")

        self.btn_analyze.clicked.connect(self._run_audit)
        self.btn_export_md.clicked.connect(self._export_markdown)
        self.btn_export_json.clicked.connect(self._export_json)
        self.btn_export_ps.clicked.connect(self._export_powershell)

        for widget in (self.btn_analyze, self.btn_export_md, self.btn_export_json, self.btn_export_ps):
            button_layout.addWidget(widget)
        button_layout.addStretch(1)

        option_layout.addWidget(button_group)
        option_layout.addStretch(1)

        splitter.addWidget(option_widget)

        output_widget = QWidget(self)
        output_layout = QVBoxLayout(output_widget)

        self.summary_label = QLabel("Latest analysis summary will appear here.")
        self.summary_label.setAlignment(Qt.AlignLeft | Qt.AlignTop)
        output_layout.addWidget(self.summary_label)

        self.btn_view_full = QPushButton("Ver completo")
        self.btn_view_full.setEnabled(False)
        self.btn_view_full.clicked.connect(self._show_full_markdown)
        output_layout.addWidget(self.btn_view_full)

        self.output_area = QPlainTextEdit(self)
        self.output_area.setReadOnly(True)
        self.output_area.setWordWrapMode(QTextOption.NoWrap)

        output_layout.addWidget(self.output_area)

        splitter.addWidget(output_widget)
        splitter.setSizes([280, 820])

        self.setCentralWidget(central)

    def _collect_options(self) -> AuditOptions:
        return AuditOptions(
            include_env=self.chk_env.isChecked(),
            include_path=self.chk_path.isChecked(),
            include_psmodule=self.chk_psmodule.isChecked(),
            include_custom=self.chk_custom.isChecked(),
            include_diagnostics=self.chk_diag.isChecked(),
        )

    def _run_audit(self) -> None:
        options = self._collect_options()
        self.latest_options = options
        report = self.auditor.run(options)
        self.latest_report = report

        summary_lines: List[str] = [
            f"Generated: {report['generated_at']}",
            f"Environment variables: {report['summary'].get('environment_variable_count', 0)}",
            f"PATH entries: {report['summary'].get('path_entry_count', 0)}",
            f"PATH duplicates: {report['summary'].get('path_duplicate_count', 0)}",
            f"PATH missing targets: {report['summary'].get('path_missing_targets', 0)}",
            f"PATH access denied: {report['summary'].get('path_access_denied', 0)}",
            f"PSModulePath entries: {report['summary'].get('psmodule_count', 0)}",
            f"Custom variables: {report['summary'].get('custom_variable_count', 0)}",
        ]

        diag_counts = report["summary"].get("diagnostic_counts", {"error": 0, "warning": 0, "info": 0})
        summary_lines.append(
            f"Diagnostics → Errors:{diag_counts.get('error', 0)}  "
            f"Warnings:{diag_counts.get('warning', 0)}  "
            f"Info:{diag_counts.get('info', 0)}"
        )

        if options.include_diagnostics and report.get("diagnostics"):
            summary_lines.append("Diagnostics preview:")
            for item in report["diagnostics"][:10]:
                summary_lines.append(f" - {item['level'].upper()}: {item['message']}")
            if len(report["diagnostics"]) > 10:
                summary_lines.append(f"   … {len(report['diagnostics']) - 10} more")

        if options.include_path and report.get("path_entries"):
            missing = [entry for entry in report["path_entries"] if entry["status"] in {"missing", "access_denied"}]
            if missing:
                summary_lines.append(f"PATH issues: {len(missing)} entries with missing or denied targets")

        self.summary_label.setText("\n".join(summary_lines))

        markdown_full = build_markdown(report, options)
        self._full_markdown = markdown_full
        full_lines = markdown_full.splitlines()
        if len(full_lines) > MAX_PREVIEW_LINES:
            preview = "\n".join(full_lines[:MAX_PREVIEW_LINES]) + "\n...\n(Contenido truncado)"
            self.btn_view_full.setEnabled(True)
        else:
            preview = markdown_full
            self.btn_view_full.setEnabled(False)
        self.output_area.setPlainText(preview)

    def _ensure_report(self) -> bool:
        if not self.latest_report:
            QMessageBox.warning(self, "No data", "Please run an analysis first.")
            return False
        return True

    def _show_full_markdown(self) -> None:
        if not self._ensure_report():
            return
        dialog = MarkdownDialog(self, self._full_markdown)
        dialog.exec()

    def _export_markdown(self) -> None:
        if not self._ensure_report():
            return
        path, _ = QFileDialog.getSaveFileName(
            self,
            "Save Markdown Report",
            os.path.join(os.path.expanduser("~"), "Desktop", "env-report.md"),
            "Markdown (*.md)",
        )
        if not path:
            return
        content = build_markdown(self.latest_report, self.latest_options)
        try:
            with open(path, "w", encoding="utf-8") as fh:
                fh.write(content)
            QMessageBox.information(self, "Export complete", f"Markdown report saved to\n{path}")
            logger.info(json.dumps({"event": "export_markdown", "path": path}))
        except OSError as exc:
            QMessageBox.critical(self, "Error al guardar", str(exc))
            logger.error(json.dumps({"event": "export_markdown_failed", "path": path, "error": str(exc)}))

    def _export_json(self) -> None:
        if not self._ensure_report():
            return
        path, _ = QFileDialog.getSaveFileName(
            self,
            "Save JSON Report",
            os.path.join(os.path.expanduser("~"), "Desktop", "env-report.json"),
            "JSON (*.json)",
        )
        if not path:
            return
        try:
            with open(path, "w", encoding="utf-8") as fh:
                json.dump(self.latest_report, fh, indent=2)
            QMessageBox.information(self, "Export complete", f"JSON report saved to\n{path}")
            logger.info(json.dumps({"event": "export_json", "path": path}))
        except OSError as exc:
            QMessageBox.critical(self, "Error al guardar", str(exc))
            logger.error(json.dumps({"event": "export_json_failed", "path": path, "error": str(exc)}))

    def _export_powershell(self) -> None:
        path, _ = QFileDialog.getSaveFileName(
            self,
            "Save PowerShell Script",
            os.path.join(os.path.expanduser("~"), "Desktop", "env-auditor.psm1"),
            "PowerShell Module (*.psm1);;PowerShell Script (*.ps1)",
        )
        if not path:
            return
        script = build_powershell_script()
        try:
            with open(path, "w", encoding="utf-8") as fh:
                fh.write(script)
            QMessageBox.information(self, "Export complete", f"PowerShell script saved to\n{path}")
            logger.info(json.dumps({"event": "export_powershell", "path": path}))
        except OSError as exc:
            QMessageBox.critical(self, "Error al guardar", str(exc))
            logger.error(json.dumps({"event": "export_powershell_failed", "path": path, "error": str(exc)}))


def main() -> int:
    app = QApplication(sys.argv)
    window = MainWindow()
    icon_path = os.path.join(os.path.dirname(__file__), "icon.ico")
    if os.path.exists(icon_path):
        window.setWindowIcon(QIcon(icon_path))
    window.show()
    return app.exec()


if __name__ == "__main__":  # pragma: no cover - GUI entrypoint
    sys.exit(main())
