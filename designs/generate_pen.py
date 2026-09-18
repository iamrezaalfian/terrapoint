import json
import random
import string

def gen_id():
    return ''.join(random.choices(string.ascii_letters + string.digits, k=5))

def create_text(content, font_size=14, font_weight="normal", fill="#FFFFFF", font_family="$--font-body", text_align="left", name=None):
    return {
        "type": "text",
        "id": gen_id(),
        "name": name or content[:20],
        "fill": fill,
        "content": content,
        "fontFamily": font_family,
        "fontSize": font_size,
        "fontWeight": str(font_weight),
        "textAlign": text_align
    }

def create_frame(name, width="fill_container", height=None, layout="vertical", gap=0, padding=0, fill=None, stroke=None, stroke_width=0, corner_radius=0, justify="start", align="start", children=None, x=None, y=None):
    frame = {
        "type": "frame",
        "id": gen_id(),
        "name": name,
        "width": width,
        "layout": layout,
        "gap": gap,
        "padding": padding,
        "justifyContent": justify,
        "alignItems": align,
        "children": children or []
    }
    if height is not None:
        frame["height"] = height
    if fill:
        frame["fill"] = fill
    if stroke:
        frame["stroke"] = stroke
        frame["strokeWidth"] = stroke_width
    if corner_radius:
        frame["cornerRadius"] = corner_radius
    if x is not None:
        frame["x"] = x
    if y is not None:
        frame["y"] = y
    return frame

# ==============================================================================
# 7 SCREEN BUILDERS (100% MATCHING INDEX.HTML)
# ==============================================================================

# 1. INITIAL ACCOUNT LOGIN
def build_screen_initial_login(x_pos, is_dark=True):
    bg = "#0B0E17" if is_dark else "#FFFFFF"
    card_bg = "#131824" if is_dark else "#F8FAFC"
    border = "#1C2230" if is_dark else "#CBD5E1"
    fg = "#F8FAFC" if is_dark else "#0F172A"
    muted = "#7E8B9F" if is_dark else "#475569"
    btn_action = "#D97706"
    input_bg = "#131824" if is_dark else "#FFFFFF"
    theme_label = "Dark" if is_dark else "Light"

    return create_frame(
        name=f"1. Initial Login ({theme_label})",
        width=340,
        height=740,
        x=x_pos,
        y=0,
        fill=bg,
        stroke=border,
        stroke_width=2,
        corner_radius=28,
        padding=20,
        gap=16,
        justify="space_between",
        children=[
            create_frame(name="TopArea", width="fill_container", gap=14, children=[
                create_frame(name="LogoBar", width="fill_container", align="center", gap=6, children=[
                    create_frame(name="IconBox", width=48, height=48, corner_radius=12, fill=btn_action, justify="center", align="center", children=[
                        create_text("TP", font_size=18, font_weight="bold", fill="#FFFFFF", font_family="$--font-mono")
                    ]),
                    create_text("TERRAPOINT", font_size=18, font_weight="bold", fill=fg, font_family="$--font-heading"),
                    create_text("Mining Logistics & Hauling Compliance", font_size=11, fill=muted)
                ]),

                create_frame(name="FormCard", width="fill_container", fill=card_bg, stroke=border, stroke_width=1, corner_radius=16, padding=16, gap=12, children=[
                    create_text("MASUK AKUN PENGEMUDI", font_size=11, font_weight="bold", fill=muted, font_family="$--font-mono"),
                    
                    create_frame(name="InputGroup1", width="fill_container", gap=4, children=[
                        create_text("Nomor ID / NIK Driver", font_size=11, font_weight="bold", fill=fg),
                        create_frame(name="Field1", width="fill_container", height=46, fill=input_bg, stroke=border, stroke_width=1, corner_radius=8, padding=[0, 12], layout="horizontal", align="center", children=[
                            create_text("DRV-001", font_size=13, font_weight="600", fill=fg, font_family="$--font-mono")
                        ])
                    ]),

                    create_frame(name="InputGroup2", width="fill_container", gap=4, children=[
                        create_text("Kata Sandi Akun", font_size=11, font_weight="bold", fill=fg),
                        create_frame(name="Field2", width="fill_container", height=46, fill=input_bg, stroke=border, stroke_width=1, corner_radius=8, padding=[0, 12], layout="horizontal", justify="space_between", align="center", children=[
                            create_text("••••••••", font_size=16, font_weight="bold", fill=fg),
                            create_text("LIHAT", font_size=10, font_weight="bold", fill=muted, font_family="$--font-mono")
                        ])
                    ])
                ])
            ]),

            create_frame(name="BottomArea", width="fill_container", gap=10, children=[
                create_frame(name="BtnSubmit", width="fill_container", height=54, fill=btn_action, corner_radius=12, layout="horizontal", justify="center", align="center", children=[
                    create_text("MASUK KE SISTEM", font_size=14, font_weight="bold", fill="#FFFFFF", font_family="$--font-heading")
                ]),
                create_frame(name="FootText", width="fill_container", layout="horizontal", justify="center", children=[
                    create_text("Koneksi Camp Wi-Fi Terdeteksi", font_size=11, font_weight="600", fill=btn_action, font_family="$--font-mono")
                ])
            ])
        ]
    )

# 2. QUICK PIN UNLOCK
def build_screen_quick_pin(x_pos, is_dark=True):
    bg = "#0B0E17" if is_dark else "#FFFFFF"
    card_bg = "#131824" if is_dark else "#F8FAFC"
    border = "#1C2230" if is_dark else "#CBD5E1"
    fg = "#F8FAFC" if is_dark else "#0F172A"
    muted = "#7E8B9F" if is_dark else "#475569"
    key_bg = "#131824" if is_dark else "#F8FAFC"
    btn_action = "#D97706"
    theme_label = "Dark" if is_dark else "Light"

    keypad_rows = []
    keys = [
        ["1", "2", "3"],
        ["4", "5", "6"],
        ["7", "8", "9"],
        ["HAPUS", "0", "BUKA"]
    ]
    for row in keys:
        row_btns = []
        for k in row:
            btn_fill = key_bg
            txt_fill = fg
            if k == "HAPUS":
                btn_fill = "#7F1D1D" if is_dark else "#FEE2E2"
                txt_fill = "#FCA5A5" if is_dark else "#B91C1C"
            elif k == "BUKA":
                btn_fill = btn_action
                txt_fill = "#FFFFFF"
            
            btn = create_frame(
                name=f"Key_{k}",
                width="fill_container",
                height=52,
                layout="horizontal",
                justify="center",
                align="center",
                fill=btn_fill,
                stroke=border,
                stroke_width=1,
                corner_radius=10,
                children=[
                    create_text(k, font_size=15 if len(k) > 1 else 19, font_weight="bold", fill=txt_fill, font_family="$--font-mono")
                ]
            )
            row_btns.append(btn)
        
        keypad_rows.append(create_frame(
            name="KeyRow",
            width="fill_container",
            layout="horizontal",
            gap=8,
            children=row_btns
        ))

    pin_dots = create_frame(
        name="PINDots",
        width="fill_container",
        layout="horizontal",
        gap=10,
        justify="center",
        align="center",
        children=[
            create_frame(name="D1", width=14, height=14, corner_radius=7, fill=btn_action),
            create_frame(name="D2", width=14, height=14, corner_radius=7, fill=btn_action),
            create_frame(name="D3", width=14, height=14, corner_radius=7, fill=btn_action),
            create_frame(name="D4", width=14, height=14, corner_radius=7, fill=btn_action),
            create_frame(name="D5", width=14, height=14, corner_radius=7, fill=card_bg, stroke=border, stroke_width=1.5),
            create_frame(name="D6", width=14, height=14, corner_radius=7, fill=card_bg, stroke=border, stroke_width=1.5),
        ]
    )

    return create_frame(
        name=f"2. Quick PIN ({theme_label})",
        width=340,
        height=740,
        x=x_pos,
        y=0,
        fill=bg,
        stroke=border,
        stroke_width=2,
        corner_radius=28,
        padding=18,
        gap=12,
        justify="space_between",
        children=[
            create_frame(name="Header", width="fill_container", gap=6, align="center", children=[
                create_text("BUKA KUNCI CEPAT", font_size=10, font_weight="bold", fill=muted, font_family="$--font-mono"),
                create_frame(name="DriverBadge", padding=[6, 12], corner_radius=8, fill=card_bg, stroke=border, stroke_width=1, children=[
                    create_text("ID: DRV-001 (Ahmad Fauzi)", font_size=12, font_weight="bold", fill=fg, font_family="$--font-mono")
                ]),
                create_text("Masukkan 6-Digit PIN Shift", font_size=12, fill=muted)
            ]),

            pin_dots,
            create_frame(name="KeypadArea", width="fill_container", gap=8, children=keypad_rows),
            create_frame(name="Footer", width="fill_container", layout="horizontal", justify="center", children=[
                create_text("Otentikasi Offline Aktif", font_size=11, font_weight="600", fill=btn_action, font_family="$--font-mono")
            ])
        ]
    )

# 3. HOME OPERASIONAL (AUTO-DETECT)
def build_screen_home_autodetect(x_pos, is_dark=True):
    bg = "#0B0E17" if is_dark else "#FFFFFF"
    card_bg = "#131824" if is_dark else "#F8FAFC"
    card_active = "rgba(217, 119, 6, 0.12)" if is_dark else "#FFFBEB"
    border = "#1C2230" if is_dark else "#CBD5E1"
    border_active = "#D97706"
    fg = "#F8FAFC" if is_dark else "#0F172A"
    muted = "#7E8B9F" if is_dark else "#475569"
    btn_action = "#D97706"
    theme_label = "Dark" if is_dark else "Light"

    location_detected_card = create_frame(
        name="AutoDetectedLocationCard",
        width="fill_container",
        fill=card_active,
        stroke=border_active,
        stroke_width=1.5,
        corner_radius=14,
        padding=14,
        gap=6,
        children=[
            create_frame(name="TagRow", width="fill_container", layout="horizontal", justify="space_between", align="center", children=[
                create_text("LOKASI TERDETEKSI (GPS)", font_size=10, font_weight="bold", fill=btn_action, font_family="$--font-mono"),
                create_frame(name="Pill", padding=[2, 6], corner_radius=4, fill=btn_action, children=[
                    create_text("RADIUS <= 50M", font_size=9, font_weight="bold", fill="#FFFFFF", font_family="$--font-mono")
                ])
            ]),
            create_text("Loading Point Pit 3 Utara", font_size=15, font_weight="bold", fill=fg),
            create_frame(name="LocationMeta", width="fill_container", layout="horizontal", gap=12, children=[
                create_text("Jarak: 18m", font_size=11, font_weight="600", fill=fg, font_family="$--font-mono"),
                create_text("Akurasi: +/- 6.5m", font_size=11, fill=muted, font_family="$--font-mono")
            ])
        ]
    )

    sync_trigger_card = create_frame(
        name="SyncTriggerCard",
        width="fill_container",
        fill=card_bg,
        stroke=border,
        stroke_width=1,
        corner_radius=14,
        padding=12,
        gap=8,
        children=[
            create_frame(name="R1", width="fill_container", layout="horizontal", justify="space_between", align="center", children=[
                create_text("SINKRONISASI DATA", font_size=10, font_weight="bold", fill=muted, font_family="$--font-mono"),
                create_text("3 Ritase Tersimpan", font_size=11, font_weight="bold", fill=btn_action, font_family="$--font-mono")
            ]),
            create_frame(name="BtnQuickSync", width="fill_container", height=40, fill=card_bg, stroke=btn_action, stroke_width=1, corner_radius=8, layout="horizontal", justify="center", align="center", gap=6, children=[
                create_text("SINKRONKAN SEKARANG", font_size=12, font_weight="bold", fill=btn_action, font_family="$--font-heading")
            ])
        ]
    )

    btn_start_single = create_frame(
        name="BtnStartSingle",
        width="fill_container",
        height=58,
        fill=btn_action,
        corner_radius=14,
        layout="horizontal",
        justify="center",
        align="center",
        children=[
            create_text("AMBIL FOTO MUAT & MULAI", font_size=15, font_weight="bold", fill="#FFFFFF", font_family="$--font-heading")
        ]
    )

    return create_frame(
        name=f"3. Home Operational ({theme_label})",
        width=340,
        height=740,
        x=x_pos,
        y=0,
        fill=bg,
        stroke=border,
        stroke_width=2,
        corner_radius=28,
        padding=18,
        gap=12,
        justify="space_between",
        children=[
            create_frame(name="Top", width="fill_container", gap=10, children=[
                create_frame(name="Bar", width="fill_container", layout="horizontal", justify="space_between", align="center", children=[
                    create_text("TERRAPOINT", font_size=13, font_weight="bold", fill=fg),
                    create_frame(name="TagNet", padding=[2, 6], corner_radius=4, fill=card_active, stroke=btn_action, stroke_width=1, children=[
                        create_text("CAMP WI-FI", font_size=10, font_weight="bold", fill=btn_action, font_family="$--font-mono")
                    ])
                ]),
                create_frame(name="DriverInfo", width="fill_container", fill=card_bg, stroke=border, stroke_width=1, corner_radius=10, padding=10, layout="horizontal", justify="space_between", align="center", children=[
                    create_frame(name="T", gap=1, children=[
                        create_text("DRIVER AKTIF", font_size=9, font_weight="bold", fill=muted, font_family="$--font-mono"),
                        create_text("Ahmad Fauzi (DRV-001)", font_size=13, font_weight="bold", fill=fg)
                    ])
                ]),
                location_detected_card,
                sync_trigger_card
            ]),

            create_frame(name="Bottom", width="fill_container", gap=8, children=[
                btn_start_single,
                create_frame(name="Links", width="fill_container", layout="horizontal", justify="space_between", children=[
                    create_text("Perbarui GPS", font_size=11, font_weight="600", fill=muted, font_family="$--font-mono"),
                    create_text("Buka Antrean Detail", font_size=11, font_weight="bold", fill=btn_action, font_family="$--font-mono")
                ])
            ])
        ]
    )

# 4. DIRECT-CAPTURE CAMERA
def build_screen_camera(x_pos, is_dark=True):
    bg = "#000000" if is_dark else "#0F172A"
    card_bg = "#111827"
    border = "#374151"
    banner_bg = "#D97706"
    theme_label = "Dark" if is_dark else "Light"

    banner = create_frame(
        name="BannerValid",
        width="fill_container",
        fill=banner_bg,
        corner_radius=10,
        padding=10,
        layout="horizontal",
        align="center",
        gap=8,
        children=[
            create_frame(name="T", gap=2, children=[
                create_text("POSISI SESUAI (RADIUS <= 50M)", font_size=12, font_weight="bold", fill="#FFFFFF", font_family="$--font-heading"),
                create_text("Loading Point Pit 3 Utara", font_size=10, font_weight="600", fill="#FEF3C7")
            ])
        ]
    )

    reticle = create_frame(
        name="ReticleBox",
        width="fill_container",
        height=300,
        fill="#050B14",
        stroke=banner_bg,
        stroke_width=2,
        corner_radius=16,
        justify="center",
        align="center",
        gap=6,
        children=[
            create_text("[ AREA KAMERA LANGSUNG ]", font_size=13, font_weight="bold", fill="#94A3B8", font_family="$--font-mono"),
            create_frame(name="PillAcc", padding=[4, 8], corner_radius=6, fill="#0F172A", stroke="#334155", stroke_width=1, children=[
                create_text("Akurasi GPS: +/- 8.2m", font_size=10, font_weight="bold", fill=banner_bg, font_family="$--font-mono")
            ])
        ]
    )

    shutter = create_frame(
        name="ShutterBar",
        width="fill_container",
        layout="horizontal",
        justify="space_between",
        align="center",
        padding=[10, 16],
        fill=card_bg,
        stroke=border,
        stroke_width=1,
        corner_radius=16,
        children=[
            create_frame(name="BtnLamp", width=44, height=44, corner_radius=8, fill="#1F2937", justify="center", align="center", children=[
                create_text("SENTER", font_size=9, font_weight="bold", fill="#D1D5DB", font_family="$--font-mono")
            ]),
            create_frame(name="ShutterCircle", width=68, height=68, corner_radius=34, fill=banner_bg, stroke="#FFFFFF", stroke_width=3, justify="center", align="center", children=[
                create_text("FOTO", font_size=12, font_weight="bold", fill="#FFFFFF", font_family="$--font-heading")
            ]),
            create_frame(name="BtnFlip", width=44, height=44, corner_radius=8, fill="#1F2937", justify="center", align="center", children=[
                create_text("BATAL", font_size=9, font_weight="bold", fill="#D1D5DB", font_family="$--font-mono")
            ])
        ]
    )

    return create_frame(
        name=f"4. Viewfinder ({theme_label})",
        width=340,
        height=740,
        x=x_pos,
        y=0,
        fill=bg,
        stroke=border,
        stroke_width=2,
        corner_radius=28,
        padding=16,
        gap=12,
        justify="space_between",
        children=[
            banner,
            reticle,
            shutter
        ]
    )

# 5. PREVIEW FOTO + SWISS WATERMARK STAMP & RETAKE
def build_screen_preview(x_pos, is_dark=True):
    bg = "#05070B"
    card_bg = "#FFFFFF"
    border = "#1C2230"
    btn_action = "#D97706"
    theme_label = "Dark" if is_dark else "Light"

    watermark_box = create_frame(
        name="SwissWatermarkBox",
        width="fill_container",
        fill="#FFFFFF",
        corner_radius=14,
        padding=12,
        layout="horizontal",
        gap=10,
        align="center",
        children=[
            # Left Mini Map
            create_frame(name="MiniMap", width=70, height=80, corner_radius=8, fill="#F1F5F9", stroke="#CBD5E1", stroke_width=1, justify="center", align="center", children=[
                create_frame(name="Pin", width=12, height=12, corner_radius=6, fill="#DC2626", stroke="#FFFFFF", stroke_width=2),
                create_text("MAP 50M", font_size=8, font_weight="bold", fill="#334155", font_family="$--font-mono")
            ]),
            # Right Metadata
            create_frame(name="Metadata", gap=2, children=[
                create_frame(name="Hdr", width="fill_container", layout="horizontal", justify="space_between", children=[
                    create_text("START CHECKPOINT", font_size=9, font_weight="bold", fill=btn_action, font_family="$--font-mono"),
                    create_text("TERRAPOINT", font_size=8, fill="#64748B", font_family="$--font-mono")
                ]),
                create_text("08:05:22 WITA (18/09/2026)", font_size=11, font_weight="bold", fill="#DC2626", font_family="$--font-mono"),
                create_text("Loading Point Pit 3 Utara", font_size=11, font_weight="bold", fill="#0F172A"),
                create_text("Lat: -3.123456, Lng: 115.123456", font_size=9, fill="#475569", font_family="$--font-mono"),
                create_text("DRV-001 (Ahmad) • TSK-001", font_size=8, fill="#64748B", font_family="$--font-mono")
            ])
        ]
    )

    photo_area = create_frame(
        name="PhotoArea",
        width="fill_container",
        height=400,
        fill="#111827",
        stroke="#374151",
        stroke_width=1,
        corner_radius=18,
        padding=12,
        justify="end",
        children=[
            watermark_box
        ]
    )

    return create_frame(
        name=f"5. Preview Geotag ({theme_label})",
        width=340,
        height=740,
        x=x_pos,
        y=0,
        fill=bg,
        stroke=border,
        stroke_width=2,
        corner_radius=28,
        padding=18,
        gap=12,
        justify="space_between",
        children=[
            create_frame(name="Hdr", width="fill_container", layout="horizontal", justify="space_between", children=[
                create_text("Preview Bukti Foto", font_size=13, font_weight="bold", fill="#F8FAFC"),
                create_text("Tercatat", font_size=11, fill="#94A3B8", font_family="$--font-mono")
            ]),
            photo_area,
            create_frame(name="Actions", width="fill_container", gap=8, children=[
                create_frame(name="BtnUse", width="fill_container", height=54, fill=btn_action, corner_radius=12, layout="horizontal", justify="center", align="center", children=[
                    create_text("Gunakan Foto Ini (Mulai)", font_size=14, font_weight="bold", fill="#FFFFFF", font_family="$--font-heading")
                ]),
                create_frame(name="BtnRetake", width="fill_container", height=44, fill="#1E293B", corner_radius=10, layout="horizontal", justify="center", align="center", children=[
                    create_text("Foto Ulang (Retake)", font_size=12, font_weight="600", fill="#CBD5E1", font_family="$--font-mono")
                ])
            ])
        ]
    )

# 6. IN-PROGRESS HAULING (CLEAN STATUS)
def build_screen_tracking(x_pos, is_dark=True):
    bg = "#0B0E17" if is_dark else "#FFFFFF"
    card_bg = "#131824" if is_dark else "#F8FAFC"
    border = "#1C2230" if is_dark else "#CBD5E1"
    fg = "#F8FAFC" if is_dark else "#0F172A"
    muted = "#7E8B9F" if is_dark else "#475569"
    btn_action = "#D97706"
    theme_label = "Dark" if is_dark else "Light"

    return create_frame(
        name=f"6. Hauling Status ({theme_label})",
        width=340,
        height=740,
        x=x_pos,
        y=0,
        fill=bg,
        stroke=border,
        stroke_width=2,
        corner_radius=28,
        padding=18,
        gap=12,
        justify="space_between",
        children=[
            create_frame(name="TopArea", width="fill_container", gap=12, children=[
                create_frame(name="TopBar", width="fill_container", layout="horizontal", justify="space_between", align="center", children=[
                    create_text("RITASE BERJALAN", font_size=12, font_weight="bold", fill=fg),
                    create_frame(name="ActiveBadge", padding=[2, 6], corner_radius=4, fill="rgba(217, 119, 6, 0.15)", stroke=btn_action, stroke_width=1, children=[
                        create_text("SIAP HAULING", font_size=9, font_weight="bold", fill=btn_action, font_family="$--font-mono")
                    ])
                ]),
                create_frame(name="StatusCard", width="fill_container", fill=card_bg, stroke=border, stroke_width=1, corner_radius=14, padding=16, align="center", gap=6, children=[
                    create_text("PERJALANAN MENUJU TITIK BONGKAR", font_size=12, font_weight="bold", fill=btn_action, font_family="$--font-heading"),
                    create_text("Rute otomatis tercatat di latar belakang", font_size=11, fill=muted)
                ]),
                create_frame(name="RouteCard", width="fill_container", fill=card_bg, stroke=border, stroke_width=1, corner_radius=14, padding=14, gap=10, children=[
                    create_frame(name="A", gap=2, children=[
                        create_text("TITIK MUAT (AWAL)", font_size=9, font_weight="bold", fill=muted, font_family="$--font-mono"),
                        create_text("Loading Point Pit 3 Utara", font_size=13, font_weight="bold", fill=fg),
                        create_text("Foto Selesai • 08:05 WITA", font_size=11, font_weight="600", fill=btn_action, font_family="$--font-mono")
                    ]),
                    create_frame(name="B", gap=2, children=[
                        create_text("TITIK BONGKAR (TUJUAN)", font_size=9, font_weight="bold", fill=muted, font_family="$--font-mono"),
                        create_text("ROM Stockpile 1", font_size=13, font_weight="bold", fill=fg),
                        create_text("Ambil foto saat tiba di radius 50m", font_size=11, fill=muted, font_family="$--font-mono")
                    ])
                ])
            ]),

            create_frame(name="BottomArea", width="fill_container", gap=8, children=[
                create_frame(name="BtnBongkar", width="fill_container", height=58, fill=btn_action, corner_radius=14, layout="horizontal", justify="center", align="center", children=[
                    create_text("FOTO BONGKAR (SELESAI)", font_size=15, font_weight="bold", fill="#FFFFFF", font_family="$--font-heading")
                ]),
                create_frame(name="K3Note", width="fill_container", layout="horizontal", justify="center", children=[
                    create_text("Fokus menyetir & utamakan keselamatan K3", font_size=11, fill=muted, font_family="$--font-mono")
                ])
            ])
        ]
    )

# 7. SYNC QUEUE SCREEN (CLEAN HUMAN-FRIENDLY)
def build_screen_sync_queue(x_pos, is_dark=True):
    bg = "#0B0E17" if is_dark else "#FFFFFF"
    card_bg = "#131824" if is_dark else "#F8FAFC"
    border = "#1C2230" if is_dark else "#CBD5E1"
    fg = "#F8FAFC" if is_dark else "#0F172A"
    muted = "#7E8B9F" if is_dark else "#475569"
    btn_action = "#D97706"
    theme_label = "Dark" if is_dark else "Light"

    def make_item(t, m):
        return create_frame(
            name="Item",
            width="fill_container",
            fill=card_bg,
            stroke=border,
            stroke_width=1,
            corner_radius=10,
            padding=12,
            layout="horizontal",
            justify="space_between",
            align="center",
            children=[
                create_frame(name="Tx", gap=1, children=[
                    create_text(t, font_size=12, font_weight="bold", fill=fg),
                    create_text(m, font_size=10, fill=muted, font_family="$--font-mono")
                ]),
                create_text("Siap", font_size=11, font_weight="bold", fill=btn_action, font_family="$--font-mono")
            ]
        )

    return create_frame(
        name=f"7. Sync Queue ({theme_label})",
        width=340,
        height=740,
        x=x_pos,
        y=0,
        fill=bg,
        stroke=border,
        stroke_width=2,
        corner_radius=28,
        padding=18,
        gap=12,
        justify="space_between",
        children=[
            create_frame(name="TopArea", width="fill_container", gap=10, children=[
                create_frame(name="TopBar", width="fill_container", layout="horizontal", justify="space_between", align="center", children=[
                    create_text("ANTREAN SINKRONISASI", font_size=12, font_weight="bold", fill=fg),
                    create_frame(name="TagNet", padding=[2, 6], corner_radius=4, fill="rgba(217, 119, 6, 0.15)", stroke=btn_action, stroke_width=1, children=[
                        create_text("CAMP ONLINE", font_size=10, font_weight="bold", fill=btn_action, font_family="$--font-mono")
                    ])
                ]),
                create_frame(name="SumCard", width="fill_container", fill=card_bg, stroke=border, stroke_width=1, corner_radius=14, padding=12, gap=2, children=[
                    create_text("STATUS PENGIRIMAN", font_size=10, font_weight="bold", fill=muted, font_family="$--font-mono"),
                    create_text("3 Ritase Siap Dikirim ke Kantor", font_size=14, font_weight="bold", fill=fg)
                ]),
                make_item("Ritase 1: Pit 3 Utara ➔ ROM 1", "Muat 08:05 • Bongkar 08:35"),
                make_item("Ritase 2: Pit 3 Utara ➔ ROM 1", "Muat 09:10 • Bongkar 09:40"),
                make_item("Ritase 3: Pit 2 Barat ➔ ROM 2", "Muat 10:15 • Bongkar 10:48")
            ]),

            create_frame(name="BottomArea", width="fill_container", gap=8, children=[
                create_frame(name="Prog", width="fill_container", gap=4, children=[
                    create_frame(name="PText", width="fill_container", layout="horizontal", justify="space_between", children=[
                        create_text("Kemajuan Pengiriman", font_size=10, font_weight="bold", fill=muted, font_family="$--font-mono"),
                        create_text("66%", font_size=10, font_weight="bold", fill=btn_action, font_family="$--font-mono")
                    ]),
                    create_frame(name="BarBg", width="fill_container", height=6, corner_radius=3, fill=border, children=[
                        create_frame(name="BarFill", width=200, height=6, corner_radius=3, fill=btn_action)
                    ])
                ]),
                create_frame(name="BtnSyncAll", width="fill_container", height=58, fill=btn_action, corner_radius=14, layout="horizontal", justify="center", align="center", children=[
                    create_text("SINKRONKAN SEKARANG", font_size=14, font_weight="bold", fill="#FFFFFF", font_family="$--font-heading")
                ])
            ])
        ]
    )

# ==============================================================================
# MASTER CANVAS ASSEMBLY (7 SCREENS DARK + 7 SCREENS LIGHT)
# ==============================================================================
def main():
    spacing = 380

    # Dark Mode Set (7 Screens)
    d1 = build_screen_initial_login(0, is_dark=True)
    d2 = build_screen_quick_pin(spacing, is_dark=True)
    d3 = build_screen_home_autodetect(spacing * 2, is_dark=True)
    d4 = build_screen_camera(spacing * 3, is_dark=True)
    d5 = build_screen_preview(spacing * 4, is_dark=True)
    d6 = build_screen_tracking(spacing * 5, is_dark=True)
    d7 = build_screen_sync_queue(spacing * 6, is_dark=True)

    # Light Mode Set (7 Screens)
    l1 = build_screen_initial_login(spacing * 7, is_dark=False)
    l2 = build_screen_quick_pin(spacing * 8, is_dark=False)
    l3 = build_screen_home_autodetect(spacing * 9, is_dark=False)
    l4 = build_screen_camera(spacing * 10, is_dark=False)
    l5 = build_screen_preview(spacing * 11, is_dark=False)
    l6 = build_screen_tracking(spacing * 12, is_dark=False)
    l7 = build_screen_sync_queue(spacing * 13, is_dark=False)

    master_pen = {
        "version": "2.17",
        "children": [
            create_frame(
                name="TerraPoint Mining Safety Amber System (7 Complete Screens)",
                width=5600,
                height=840,
                x=0,
                y=0,
                fill="#06080D",
                padding=40,
                gap=30,
                layout="horizontal",
                children=[
                    d1, d2, d3, d4, d5, d6, d7,
                    l1, l2, l3, l4, l5, l6, l7
                ]
            )
        ],
        "variables": {
            "--background": {"type": "color", "value": "#0B0E17"},
            "--foreground": {"type": "color", "value": "#F8FAFC"},
            "--card": {"type": "color", "value": "#131824"},
            "--border": {"type": "color", "value": "#1C2230"},
            "--muted-foreground": {"type": "color", "value": "#7E8B9F"},
            "--primary-action": {"type": "color", "value": "#D97706"},
            "--accent-amber": {"type": "color", "value": "#D97706"},
            "--destructive": {"type": "color", "value": "#EF4444"},
            "--font-heading": {"type": "string", "value": "Plus Jakarta Sans"},
            "--font-body": {"type": "string", "value": "Plus Jakarta Sans"},
            "--font-mono": {"type": "string", "value": "JetBrains Mono"}
        },
        "fileToken": "terrapoint-mobile-7screens-complete-v7"
    }

    with open("designs/terrapoint_mobile_ui.pen", "w") as f:
        json.dump(master_pen, f, indent=2)
    
    print("Successfully generated complete 7-screen designs/terrapoint_mobile_ui.pen")

if __name__ == "__main__":
    main()
