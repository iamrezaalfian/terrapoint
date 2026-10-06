import os
import sys
from reportlab.lib.pagesizes import A4
from reportlab.lib import colors
from reportlab.lib.styles import getSampleStyleSheet, ParagraphStyle
from reportlab.platypus import (
    SimpleDocTemplate, Paragraph, Spacer, Table, TableStyle, Image, PageBreak, HRFlowable
)
from reportlab.pdfgen import canvas

ASSETS_DIR = 'D:/Produktivitas/terrapoint/docs/flow-assets'
PDF_OUTPUT = 'D:/Produktivitas/terrapoint/docs/TerraPoint_Master_Application_Flow_Documentation.pdf'

# A4 width = 595.27 pt, height = 841.89 pt
# With 40pt margins, printable width is 515.27 pt, printable height is 745 pt
PRINTABLE_WIDTH = 515.27

class NumberedCanvas(canvas.Canvas):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)
        self._saved_page_states = []

    def showPage(self):
        self._saved_page_states.append(dict(self.__dict__))
        self._startPage()

    def save(self):
        num_pages = len(self._saved_page_states)
        for state in self._saved_page_states:
            self.__dict__.update(state)
            self.draw_page_decorations(num_pages)
            super().showPage()
        super().save()

    def draw_page_decorations(self, page_count):
        if self._pageNumber == 1:
            return  # Skip cover page

        self.saveState()
        self.setFont("Helvetica-Bold", 8)
        self.setFillColor(colors.HexColor("#D97706"))
        self.drawString(40, 808, "TERRAPOINT MINING PLATFORM")

        self.setFont("Helvetica", 8)
        self.setFillColor(colors.HexColor("#64748B"))
        self.drawString(180, 808, "— Master Application Flow Documentation")

        self.setStrokeColor(colors.HexColor("#CBD5E1"))
        self.setLineWidth(0.6)
        self.line(40, 800, 555, 800)

        # Footer
        self.line(40, 38, 555, 38)
        self.setFont("Helvetica", 8)
        self.setFillColor(colors.HexColor("#64748B"))
        self.drawString(40, 26, "Sektor Sulawesi Morowali • Versi 2.4 Production Ready")
        self.drawRightString(555, 26, f"Halaman {self._pageNumber} dari {page_count}")
        self.restoreState()

def build_pdf():
    doc = SimpleDocTemplate(
        PDF_OUTPUT,
        pagesize=A4,
        leftMargin=40,
        rightMargin=40,
        topMargin=50,
        bottomMargin=46
    )

    c_amber = colors.HexColor("#D97706")
    c_dark = colors.HexColor("#0F172A")
    c_slate = colors.HexColor("#334155")
    c_muted = colors.HexColor("#64748B")
    c_bg_head = colors.HexColor("#0F172A")

    title_style = ParagraphStyle('CoverTitle', fontName='Helvetica-Bold', fontSize=22, leading=26, textColor=c_dark)
    subtitle_style = ParagraphStyle('CoverSubtitle', fontName='Helvetica-Bold', fontSize=11, leading=14, textColor=c_amber)
    h1_style = ParagraphStyle('SectionH1', fontName='Helvetica-Bold', fontSize=14, leading=17, textColor=c_dark, spaceBefore=4, spaceAfter=6)
    h2_style = ParagraphStyle('SectionH2', fontName='Helvetica-Bold', fontSize=10, leading=13, textColor=c_amber, spaceBefore=4, spaceAfter=2)
    body_style = ParagraphStyle('BodyTextCustom', fontName='Helvetica', fontSize=8.5, leading=11.5, textColor=c_slate)
    tbl_header_style = ParagraphStyle('TblHead', fontName='Helvetica-Bold', fontSize=7.5, leading=9.5, textColor=colors.white)
    tbl_cell_style = ParagraphStyle('TblCell', fontName='Helvetica', fontSize=7.5, leading=9.5, textColor=c_slate)
    tbl_cell_bold = ParagraphStyle('TblCellBold', fontName='Helvetica-Bold', fontSize=7.5, leading=9.5, textColor=c_dark)

    story = []

    # ==========================================
    # COVER PAGE
    # ==========================================
    story.append(Spacer(1, 30))
    story.append(Paragraph("TERRAPOINT PLATFORM", subtitle_style))
    story.append(Spacer(1, 4))
    story.append(Paragraph("Master Application Flow & Operations Documentation", title_style))
    story.append(Spacer(1, 6))
    story.append(HRFlowable(width="100%", thickness=2, color=c_amber, spaceBefore=2, spaceAfter=12))

    meta_text = """
    <b>Sektor Operasional:</b> Mining Logistics & Heavy Equipment Fleet Compliance (Sulawesi Morowali)<br/>
    <b>Cakupan Platform:</b> Mobile Client App (Flutter 3.47+ Offline-First) & Web Dashboard Command Center (PWA)<br/>
    <b>Status Sistem:</b> Production Ready (v2.4)
    """
    story.append(Paragraph(meta_text, body_style))
    story.append(Spacer(1, 14))

    # Executive Summary Card
    summary_box = [
        [Paragraph("<b>RINGKASAN EKSEKUTIF ALUR OPERASIONAL</b>", ParagraphStyle('BHeader', fontName='Helvetica-Bold', fontSize=9.5, textColor=colors.white))],
        [Paragraph("""
        TerraPoint adalah sistem audit kepatuhan rute hauling dan verifikasi bukti visual operasional tambang berbasis <i>offline-first</i>. Sistem ini mengeliminasi kesalahan input pengemudi melalui <b>Zero-Click GPS Auto-Detection</b> (radius 50m geofence), kamera <i>direct-capture</i> tanpa galeri, <i>canvas burn-in watermark</i> permanen pada piksel foto, serta pelacakan telemetri latar belakang senyap (K3 silent mode). Seluruh aktivitas lapangan terpantau secara real-time di Web Command Center Head Mine Dispatcher.
        """, ParagraphStyle('BText', fontName='Helvetica', fontSize=8.5, leading=12.5, textColor=c_dark))]
    ]
    t_sum = Table(summary_box, colWidths=[PRINTABLE_WIDTH])
    t_sum.setStyle(TableStyle([
        ('BACKGROUND', (0, 0), (0, 0), c_amber),
        ('BACKGROUND', (0, 1), (0, 1), colors.HexColor("#FEF3C7")),
        ('PADDING', (0, 0), (-1, -1), 8),
        ('BOX', (0, 0), (-1, -1), 1, c_amber),
    ]))
    story.append(t_sum)
    story.append(Spacer(1, 16))

    # ==========================================
    # SECTION 1: MATRIKS ALUR LINTAS PLATFORM
    # ==========================================
    story.append(Paragraph("1. Matriks Alur Lintas Platform (Cross-Platform Flow Matrix)", h1_style))
    story.append(Paragraph("Tabel transisi alur operasional antara aplikasi mobile pengemudi di pit dan web command center pengawas:", body_style))
    story.append(Spacer(1, 6))

    raw_matrix = [
        ["ID", "Platform", "Layar / Modul", "Koneksi", "Pemicu Pengguna", "Hasil Mutasi State"],
        ["MOB-01", "Mobile", "Layar 1: Login", "Online", "Input NIK & Password di Camp", "Sesi driver & PIN hash disimpan di SQLite lokal."],
        ["MOB-02", "Mobile", "Layar 2: PIN Unlock", "Offline", "Input 6-digit PIN pada keypad", "Verifikasi lokal -> Buka shift kerja mandiri."],
        ["MOB-03", "Mobile", "Layar 3: Beranda", "Offline", "GPS mendeteksi Pit <= 50m", "Tombol 'Ambil Foto Muat & Mulai' aktif."],
        ["MOB-04", "Mobile", "Layar 4: Viewfinder", "Offline", "Tekan shutter kamera 68dp", "Jepret foto bak truk via CameraX direct-capture."],
        ["MOB-05", "Mobile", "Layar 5: Preview", "Offline", "Tekan 'Gunakan Foto Ini'", "Burn-in watermark ke piksel -> Task IN_PROGRESS."],
        ["MOB-06", "Mobile", "Layar 6: Hauling", "Offline", "Perjalanan Pit ke ROM Smelter", "Background tracking senyap (v >= 3 km/jam)."],
        ["MOB-07", "Mobile", "Layar 7: Sync Queue", "Online", "Kembali ke Camp & tekan Sync", "Upload WebP ke R2 & Supabase (status SYNCED)."],
        ["WEB-01", "Web PWA", "Peta Armada Live", "Online", "Klik truk / toggle layer satelit", "Render rute polyline & HUD telemetri live."],
        ["WEB-02", "Web PWA", "Log Ritase", "Online", "Cari Task ID / Ekspor CSV", "Tabel audit kepatuhan & modal foto surveyor."],
        ["WEB-03", "Web PWA", "Master Geofence", "Online", "Geser slider radius (20-100m)", "Simpan titik checkpoint tambang & toleransi."],
        ["WEB-04", "Web PWA", "Manajemen Armada", "Online", "Filter armada (Hauling/Standby)", "Inspeksi muatan tonase, BBM %, dan odometer."],
        ["WEB-05", "Web PWA", "Admin Login", "Online", "Input Username & Password", "Akses eksklusif Head Mine Dispatcher."]
    ]

    wrapped_matrix = []
    for r_idx, row in enumerate(raw_matrix):
        row_cells = []
        for c_idx, cell_text in enumerate(row):
            if r_idx == 0:
                row_cells.append(Paragraph(cell_text, tbl_header_style))
            else:
                st = tbl_cell_bold if c_idx in [0, 1, 2] else tbl_cell_style
                row_cells.append(Paragraph(cell_text, st))
        wrapped_matrix.append(row_cells)

    # Exact col widths fitting within PRINTABLE_WIDTH (515.27pt)
    t_mat = Table(wrapped_matrix, colWidths=[38, 42, 92, 42, 136, 165])
    t_mat.setStyle(TableStyle([
        ('BACKGROUND', (0, 0), (-1, 0), c_bg_head),
        ('GRID', (0, 0), (-1, -1), 0.5, colors.HexColor("#CBD5E1")),
        ('ROWBACKGROUNDS', (0, 1), (-1, -1), [colors.white, colors.HexColor("#F8FAFC")]),
        ('PADDING', (0, 0), (-1, -1), 3),
        ('VALIGN', (0, 0), (-1, -1), 'TOP'),
    ]))
    story.append(t_mat)
    story.append(PageBreak())

    # ==========================================
    # SECTION 2: ALUR MOBILE CLIENT (7 LAYAR LENGKAP)
    # ==========================================
    story.append(Paragraph("2. Alur Mobile Client App (7 Layar Lengkap)", h1_style))
    story.append(Paragraph("Aplikasi mobile pengemudi beroperasi 100% offline di area tambang dengan tombol kontras tinggi:", body_style))
    story.append(Spacer(1, 6))

    # Mobile Screen Builder: 150pt x 320pt (aspect ratio 0.47)
    def build_mobile_screen_cell(img_filename, screen_title, screen_desc):
        img_p = os.path.join(ASSETS_DIR, img_filename)
        cell_content = []
        if os.path.exists(img_p):
            cell_content.append(Image(img_p, width=150, height=320))
            cell_content.append(Spacer(1, 4))
        cell_content.append(Paragraph(f"<b>{screen_title}</b>", h2_style))
        cell_content.append(Paragraph(screen_desc, body_style))
        return cell_content

    # Mobile Page 1: Screen 1 & Screen 2
    c1 = build_mobile_screen_cell(
        'mobile-01-login.png',
        "Layar 1: Login Akun Awal (Online)",
        "Autentikasi awal driver di camp saat ada sinyal Wi-Fi. Mengunduh master titik pit ke SQLite lokal."
    )
    c2 = build_mobile_screen_cell(
        'mobile-02-pin.png',
        "Layar 2: Quick PIN Unlock (Offline)",
        "Keypad angka 6-digit besar (56x56dp) untuk membuka shift kerja mandiri di lapangan tanpa internet."
    )
    t_m_page1 = Table([[c1, c2]], colWidths=[PRINTABLE_WIDTH/2, PRINTABLE_WIDTH/2])
    t_m_page1.setStyle(TableStyle([('VALIGN', (0, 0), (-1, -1), 'TOP'), ('ALIGN', (0, 0), (-1, -1), 'CENTER'), ('PADDING', (0, 0), (-1, -1), 4)]))
    story.append(t_m_page1)
    story.append(PageBreak())

    # Mobile Page 2: Screen 3 & Screen 4
    c3 = build_mobile_screen_cell(
        'mobile-03-home.png',
        "Layar 3: Beranda Auto-Detect (Offline)",
        "Sensor GPS otomatis mendeteksi Pit Bahodopi (<=50m). Tombol 'AMBIL FOTO MUAT & MULAI' otomatis aktif."
    )
    c4 = build_mobile_screen_cell(
        'mobile-04-viewfinder.png',
        "Layar 4: Viewfinder 50m Interlock",
        "Direct-capture camera tanpa akses galeri. Shutter 68dp terkunci otomatis jika berada di luar radius 50m."
    )
    t_m_page2 = Table([[c3, c4]], colWidths=[PRINTABLE_WIDTH/2, PRINTABLE_WIDTH/2])
    t_m_page2.setStyle(TableStyle([('VALIGN', (0, 0), (-1, -1), 'TOP'), ('ALIGN', (0, 0), (-1, -1), 'CENTER'), ('PADDING', (0, 0), (-1, -1), 4)]))
    story.append(t_m_page2)
    story.append(PageBreak())

    # Mobile Page 3: Screen 5 & Screen 6
    c5 = build_mobile_screen_cell(
        'mobile-05-watermark.png',
        "Layar 5: Preview + Watermark Surveyor",
        "Kotak putih stamp permanen di sudut bawah foto: peta mini kontur 50m, jam merah presisi WITA, koordinat, dan akurasi."
    )
    c6 = build_mobile_screen_cell(
        'mobile-06-hauling.png',
        "Layar 6: Status Hauling Aktif (K3 Mode)",
        "Layar tenang bebas distraksi visual radar di kabin. Tracking koordinat berjalan senyap di background service."
    )
    t_m_page3 = Table([[c5, c6]], colWidths=[PRINTABLE_WIDTH/2, PRINTABLE_WIDTH/2])
    t_m_page3.setStyle(TableStyle([('VALIGN', (0, 0), (-1, -1), 'TOP'), ('ALIGN', (0, 0), (-1, -1), 'CENTER'), ('PADDING', (0, 0), (-1, -1), 4)]))
    story.append(t_m_page3)
    story.append(PageBreak())

    # Mobile Page 4: Screen 7 (Sync Queue)
    c7_img = [Image(os.path.join(ASSETS_DIR, 'mobile-07-sync.png'), width=150, height=320)] if os.path.exists(os.path.join(ASSETS_DIR, 'mobile-07-sync.png')) else [Paragraph("[Gambar]", body_style)]
    c7_text = [
        Paragraph("<b>Layar 7: Antrean Sinkronisasi Mandiri (Online)</b>", h2_style),
        Spacer(1, 6),
        Paragraph("""
        <b>Fungsi & Fitur Utama:</b><br/>
        • Menampilkan daftar ritase selesai dalam bahasa ramah driver tanpa istilah teknis yang membingungkan.<br/>
        • Driver menekan tombol amber tunggal <b>'SINKRONKAN SEKARANG'</b> saat kembali ke area camp yang memiliki koneksi Wi-Fi stabil.<br/>
        • Aplikasi mengunggah foto WebP ke Cloudflare R2 dan mengirim data ritase ke Supabase cloud.<br/>
        • <b>Retensi Permanen:</b> Seluruh foto bukti tetap tersimpan pada memori internal HP driver untuk kebutuhan audit regulasi inspektur tambang.
        """, body_style)
    ]
    t_m_page4 = Table([[c7_img, c7_text]], colWidths=[170, PRINTABLE_WIDTH - 170])
    t_m_page4.setStyle(TableStyle([('VALIGN', (0, 0), (-1, -1), 'TOP'), ('ALIGN', (0, 0), (0, -1), 'CENTER'), ('PADDING', (0, 0), (-1, -1), 6)]))
    story.append(t_m_page4)
    story.append(PageBreak())

    # ==========================================
    # SECTION 3: ALUR WEB DASHBOARD COMMAND CENTER (1 SCREEN PER PAGE)
    # ==========================================
    story.append(Paragraph("3. Alur Web Dashboard Admin Command Center", h1_style))
    story.append(Paragraph("Portal pengawasan terpadu Head Mine Dispatcher & Superadmin untuk monitoring rute hauling nikel Morowali:", body_style))
    story.append(Spacer(1, 6))

    # Web Screen Builder: Full-width 500pt x 312.5pt (aspect ratio 1.60)
    def add_web_screen_page(img_filename, title, desc):
        items = []
        items.append(Paragraph(f"<b>{title}</b>", h2_style))
        items.append(Spacer(1, 4))
        img_p = os.path.join(ASSETS_DIR, img_filename)
        if os.path.exists(img_p):
            items.append(Image(img_p, width=500, height=312.5))
            items.append(Spacer(1, 6))
        items.append(Paragraph(desc, body_style))
        return items

    # Web Page 1: Satellite Map & Haul Roads
    story.extend(add_web_screen_page(
        'web-01-satellite-map.png',
        "Halaman 1: Peta Satelit Topografi & Koridor Hauling Morowali",
        "<b>Fitur Utama:</b> Citra satelit resolusi tinggi Esri World Imagery menampilkan kontur pit tambang nikel Bahodopi dan Teluk Morowali. Garis rute hauling berkelok (turunan pit switchback RL +180m hingga Pelabuhan Smelter) dan marker armada bergerak real-time."
    ))
    story.append(PageBreak())

    # Web Page 2: Telemetry HUD Inspector
    story.extend(add_web_screen_page(
        'web-02-telemetry-hud.png',
        "Halaman 1: Inspektor Telemetri Truk Live (HUD Drawer)",
        "<b>Fitur Utama:</b> Klik pada marker truk (misal DT-104) memunculkan panel cockpit: muatan sensor 45.2 Ton (Saprolite Ni 1.85%), kecepatan GPS 33.8 km/h, BBM 81% (19.2 L/h), suhu mesin 89°C, tekanan ban 114 PSI, dan elevasi +85m RL."
    ))
    story.append(PageBreak())

    # Web Page 3: Trip Logs Table
    story.extend(add_web_screen_page(
        'web-03-trip-logs.png',
        "Halaman 2: Log Ritase & Audit Kepatuhan (Ekspor CSV)",
        "<b>Fitur Utama:</b> Pencarian instan Task ID/Driver, filter status (Selesai, In Progress), filter grade bijih (Saprolite/Limonite), berat bruto/netto, dan tombol ekspor data rekapitulasi ke berkas CSV."
    ))
    story.append(PageBreak())

    # Web Page 4: Evidence Modal
    story.extend(add_web_screen_page(
        'web-04-evidence-modal.png',
        "Halaman 2: Modal Verifikasi Bukti Foto & Audit Haversine",
        "<b>Fitur Utama:</b> Menampilkan perbandingan foto muat dan foto bongkar dengan watermark surveyor stamp serta audit kalkulasi deviasi jarak GPS terhadap batas toleransi 50m (misal: deviasi ±6.2m dan ±7.8m terverifikasi valid)."
    ))
    story.append(PageBreak())

    # Web Page 5: Master Geofence Checkpoints
    story.extend(add_web_screen_page(
        'web-05-geofence.png',
        "Halaman 3: Master Geofence Checkpoints & Slider Radius",
        "<b>Fitur Utama:</b> Daftar checkpoint tambang (Pit Bahodopi North +185 RL, Pit Keuno West +120 RL, ROM Smelter Port 1). Dilengkapi form tambah checkpoint dengan slider toleransi radius 20m hingga 100m."
    ))
    story.append(PageBreak())

    # Web Page 6: Fleet Management
    story.extend(add_web_screen_page(
        'web-06-fleet.png',
        "Halaman 4: Manajemen Armada Truk Nikel Morowali",
        "<b>Fitur Utama:</b> Grid kartu status unit armada (DT-101 s/d DT-115), tipe kendaraan Scania/Volvo/Mercedes, odometer, level bahan bakar %, dan status siklus hauling aktif."
    ))
    story.append(PageBreak())

    # Web Page 7: Admin Login
    story.extend(add_web_screen_page(
        'web-07-login.png',
        "Laman Login Mandiri Khusus Admin (Better Auth Powered)",
        "<b>Fitur Utama:</b> Laman login mandiri fullscreen khusus Head Mine Dispatcher & Superadmin dengan kredensial resmi (admin.morowali@terrapoint.mine) dan proteksi enterprise identity."
    ))

    doc.build(story, canvasmaker=NumberedCanvas)
    print(f"Cleaned PDF compiled successfully: {PDF_OUTPUT}")

if __name__ == "__main__":
    build_pdf()
