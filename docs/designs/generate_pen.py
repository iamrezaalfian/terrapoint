import json
import random
import string

def gen_id():
    return ''.join(random.choices(string.ascii_letters + string.digits, k=5))

def create_text(content, font_size=14, font_weight="normal", fill="#FFFFFF", font_family="$--font-body", text_align="left", name=None, text_growth="fixed-width", width="fill_container", line_height=1.4):
    node = {
        "type": "text",
        "id": gen_id(),
        "name": name or content[:24],
        "fill": fill,
        "content": content,
        "fontFamily": font_family,
        "fontSize": font_size,
        "fontWeight": str(font_weight),
        "textAlign": text_align,
        "textGrowth": text_growth,
        "lineHeight": line_height
    }
    if width is not None:
        node["width"] = width
    return node

def create_badge_text(content, font_size=11, font_weight="bold", fill="#FFFFFF", font_family="$--font-mono", text_align="center"):
    return {
        "type": "text",
        "id": gen_id(),
        "name": content[:24],
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
# 7 SCREEN BUILDERS (NO TEXT OFFSIDE / OVERFLOW)
# ==============================================================================

# SCREEN 1: INITIAL LOGIN (ONLINE)
def build_screen_1_login(x_pos, is_dark=True):
    bg = "#0B0E17" if is_dark else "#FFFFFF"
    card_bg = "#131824" if is_dark else "#F8FAFC"
    border = "#1C2230" if is_dark else "#CBD5E1"
    fg = "#F8FAFC" if is_dark else "#0F172A"
    muted = "#7E8B9F" if is_dark else "#475569"
    amber = "#D97706"
    input_bg = "#131824" if is_dark else "#FFFFFF"
    theme_label = "Dark" if is_dark else "Light"

    return create_frame(
        name=f"1. Initial Login ({theme_label})",
        width=360,
        height=780,
        x=x_pos,
        y=0,
        fill=bg,
        stroke=border,
        stroke_width=2,
        corner_radius=32,
        padding=20,
        gap=16,
        justify="space_between",
        children=[
            create_frame(name="TopArea", width="fill_container", gap=16, children=[
                # Status Top
                create_frame(name="StatusTop", width="fill_container", layout="horizontal", justify="space_between", align="center", children=[
                    create_frame(name="OnlinePill", layout="horizontal", gap=6, align="center", children=[
                        create_frame(name="Dot", width=8, height=8, corner_radius=4, fill=amber),
                        create_badge_text("Online Setup", font_size=11, font_weight="bold", fill=amber, font_family="$--font-mono")
                    ]),
                    create_badge_text("v4.3", font_size=11, font_weight="600", fill=muted, font_family="$--font-mono")
                ]),

                # Logo & Heading
                create_frame(name="BrandArea", width="fill_container", gap=4, children=[
                    create_frame(name="LogoBox", width=48, height=48, corner_radius=14, fill=amber, justify="center", align="center", children=[
                        create_badge_text("TP", font_size=18, font_weight="bold", fill="#FFFFFF", font_family="$--font-mono")
                    ]),
                    create_text("Masuk TerraPoint", font_size=20, font_weight="bold", fill=fg, font_family="$--font-heading", width="fill_container"),
                    create_text("Hubungkan perangkat dengan akun pengemudi Anda saat berada di area camp.", font_size=12, fill=muted, width="fill_container", line_height=1.4)
                ]),

                # Form Card
                create_frame(name="FormCard", width="fill_container", fill=card_bg, stroke=border, stroke_width=1, corner_radius=18, padding=16, gap=14, children=[
                    create_frame(name="InputGroup1", width="fill_container", gap=6, children=[
                        create_text("Nomor ID Pengemudi", font_size=12, font_weight="600", fill=fg, width="fill_container"),
                        create_frame(name="Field1", width="fill_container", height=48, fill=input_bg, stroke=border, stroke_width=1, corner_radius=12, padding=[0, 14], layout="horizontal", align="center", children=[
                            create_badge_text("DRV-001", font_size=14, font_weight="bold", fill=fg, font_family="$--font-mono")
                        ])
                    ]),
                    create_frame(name="InputGroup2", width="fill_container", gap=6, children=[
                        create_text("Kata Sandi Akun", font_size=12, font_weight="600", fill=fg, width="fill_container"),
                        create_frame(name="Field2", width="fill_container", height=48, fill=input_bg, stroke=border, stroke_width=1, corner_radius=12, padding=[0, 14], layout="horizontal", justify="space_between", align="center", children=[
                            create_badge_text("••••••••", font_size=16, font_weight="bold", fill=fg, font_family="$--font-body"),
                            create_badge_text("LIHAT", font_size=10, font_weight="bold", fill=muted, font_family="$--font-mono")
                        ])
                    ]),
                    create_frame(name="RememberMe", width="fill_container", layout="horizontal", gap=8, align="center", children=[
                        create_frame(name="Check", width=16, height=16, corner_radius=4, fill=amber, justify="center", align="center", children=[
                            create_badge_text("✓", font_size=11, font_weight="bold", fill="#FFFFFF")
                        ]),
                        create_text("Simpan sesi login di perangkat ini", font_size=12, fill=muted, width="fill_container")
                    ])
                ])
            ]),

            # Bottom Action
            create_frame(name="BottomArea", width="fill_container", gap=10, children=[
                create_frame(name="BtnLogin", width="fill_container", height=54, fill=amber, corner_radius=14, layout="horizontal", justify="center", align="center", children=[
                    create_badge_text("Masuk ke Sistem", font_size=14, font_weight="bold", fill="#FFFFFF", font_family="$--font-heading")
                ]),
                create_frame(name="FootNote", width="fill_container", layout="horizontal", justify="center", children=[
                    create_text("Koneksi Camp Wi-Fi Terverifikasi", font_size=11, font_weight="600", fill=amber, font_family="$--font-mono", text_align="center", width="fill_container")
                ])
            ])
        ]
    )

# SCREEN 2: QUICK PIN UNLOCK (OFFLINE)
def build_screen_2_pin(x_pos, is_dark=True):
    bg = "#0B0E17" if is_dark else "#FFFFFF"
    card_bg = "#131824" if is_dark else "#F8FAFC"
    border = "#1C2230" if is_dark else "#CBD5E1"
    fg = "#F8FAFC" if is_dark else "#0F172A"
    muted = "#7E8B9F" if is_dark else "#475569"
    key_bg = "#131824" if is_dark else "#F8FAFC"
    amber = "#D97706"
    theme_label = "Dark" if is_dark else "Light"

    keypad_rows = []
    keys = [
        ["1", "2", "3"],
        ["4", "5", "6"],
        ["7", "8", "9"],
        ["Hapus", "0", "Buka"]
    ]
    for row in keys:
        row_btns = []
        for k in row:
            btn_fill = key_bg
            txt_fill = fg
            if k == "Hapus":
                btn_fill = key_bg
                txt_fill = "#F43F5E"
            elif k == "Buka":
                btn_fill = amber
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
                corner_radius=12,
                children=[
                    create_badge_text(k, font_size=15 if len(k) > 1 else 20, font_weight="bold", fill=txt_fill, font_family="$--font-mono")
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
        gap=12,
        justify="center",
        align="center",
        children=[
            create_frame(name="D1", width=14, height=14, corner_radius=7, fill=amber),
            create_frame(name="D2", width=14, height=14, corner_radius=7, fill=amber),
            create_frame(name="D3", width=14, height=14, corner_radius=7, fill=amber),
            create_frame(name="D4", width=14, height=14, corner_radius=7, fill=amber),
            create_frame(name="D5", width=14, height=14, corner_radius=7, fill=card_bg, stroke=border, stroke_width=1.5),
            create_frame(name="D6", width=14, height=14, corner_radius=7, fill=card_bg, stroke=border, stroke_width=1.5),
        ]
    )

    return create_frame(
        name=f"2. Quick PIN ({theme_label})",
        width=360,
        height=780,
        x=x_pos,
        y=0,
        fill=bg,
        stroke=border,
        stroke_width=2,
        corner_radius=32,
        padding=20,
        gap=14,
        justify="space_between",
        children=[
            # Top Status
            create_frame(name="StatusTop", width="fill_container", layout="horizontal", justify="space_between", align="center", children=[
                create_badge_text("08:00", font_size=11, font_weight="bold", fill=muted, font_family="$--font-mono"),
                create_badge_text("Offline Ready", font_size=11, font_weight="bold", fill=amber, font_family="$--font-mono")
            ]),

            # Driver Avatar & Name
            create_frame(name="DriverHeader", width="fill_container", align="center", gap=4, children=[
                create_frame(name="AvatarCircle", width=52, height=52, corner_radius=26, fill=card_bg, stroke=border, stroke_width=1.5, justify="center", align="center", children=[
                    create_badge_text("AF", font_size=16, font_weight="bold", fill=amber)
                ]),
                create_text("Ahmad Fauzi", font_size=17, font_weight="bold", fill=fg, font_family="$--font-heading", text_align="center", width="fill_container"),
                create_text("DRV-001", font_size=12, font_weight="bold", fill=muted, font_family="$--font-mono", text_align="center", width="fill_container"),
                create_text("Masukkan 6-Digit PIN Shift", font_size=12, fill=muted, text_align="center", width="fill_container")
            ]),

            # PIN Dots
            pin_dots,

            # Keypad
            create_frame(name="KeypadArea", width="fill_container", gap=8, children=keypad_rows),

            # Footer link
            create_frame(name="FooterLink", width="fill_container", layout="horizontal", justify="center", children=[
                create_text("Ganti Akun / Masuk Ulang", font_size=11, font_weight="600", fill=muted, font_family="$--font-mono", text_align="center", width="fill_container")
            ])
        ]
    )

# SCREEN 3: HOME AUTO-DETECT (OFFLINE)
def build_screen_3_home(x_pos, is_dark=True):
    bg = "#0B0E17" if is_dark else "#FFFFFF"
    card_bg = "#131824" if is_dark else "#F8FAFC"
    card_active = "rgba(217, 119, 6, 0.12)" if is_dark else "#FFFBEB"
    border = "#1C2230" if is_dark else "#CBD5E1"
    border_active = "#D97706"
    fg = "#F8FAFC" if is_dark else "#0F172A"
    muted = "#7E8B9F" if is_dark else "#475569"
    amber = "#D97706"
    theme_label = "Dark" if is_dark else "Light"

    location_card = create_frame(
        name="LocationCard",
        width="fill_container",
        fill=card_active,
        stroke=border_active,
        stroke_width=1.5,
        corner_radius=16,
        padding=16,
        gap=6,
        children=[
            create_frame(name="TagRow", width="fill_container", layout="horizontal", justify="space_between", align="center", children=[
                create_badge_text("LOKASI TERDETEKSI (GPS)", font_size=10, font_weight="bold", fill=amber, font_family="$--font-mono"),
                create_frame(name="Pill", padding=[2, 8], corner_radius=6, fill=amber, children=[
                    create_badge_text("Radius ≤ 50m", font_size=9, font_weight="bold", fill="#FFFFFF", font_family="$--font-mono")
                ])
            ]),
            create_text("Loading Point Pit 3 Utara", font_size=16, font_weight="bold", fill=fg, font_family="$--font-heading", width="fill_container"),
            create_frame(name="LocationMeta", width="fill_container", layout="horizontal", gap=14, children=[
                create_badge_text("Jarak: 18m", font_size=12, font_weight="600", fill=fg, font_family="$--font-mono"),
                create_badge_text("Akurasi: ± 6.5m", font_size=12, font_weight="normal", fill=muted, font_family="$--font-mono")
            ])
        ]
    )

    sync_card = create_frame(
        name="SyncCard",
        width="fill_container",
        fill=card_bg,
        stroke=border,
        stroke_width=1,
        corner_radius=16,
        padding=14,
        layout="horizontal",
        justify="space_between",
        align="center",
        children=[
            create_frame(name="SyncInfo", gap=2, children=[
                create_badge_text("ANTREAN SINKRONISASI", font_size=10, font_weight="bold", fill=muted, font_family="$--font-mono"),
                create_text("3 Ritase Tersimpan", font_size=13, font_weight="bold", fill=fg, width="fill_container")
            ]),
            create_frame(name="BtnQuickSync", padding=[8, 14], corner_radius=10, fill=card_bg, stroke=amber, stroke_width=1, children=[
                create_badge_text("Sync", font_size=12, font_weight="bold", fill=amber, font_family="$--font-mono")
            ])
        ]
    )

    btn_start = create_frame(
        name="BtnStartPhoto",
        width="fill_container",
        height=58,
        fill=amber,
        corner_radius=16,
        layout="horizontal",
        justify="center",
        align="center",
        gap=8,
        children=[
            create_badge_text("📷", font_size=16),
            create_badge_text("Ambil Foto Muat & Mulai", font_size=15, font_weight="bold", fill="#FFFFFF", font_family="$--font-heading")
        ]
    )

    return create_frame(
        name=f"3. Home Auto-Detect ({theme_label})",
        width=360,
        height=780,
        x=x_pos,
        y=0,
        fill=bg,
        stroke=border,
        stroke_width=2,
        corner_radius=32,
        padding=20,
        gap=14,
        justify="space_between",
        children=[
            create_frame(name="Top", width="fill_container", gap=12, children=[
                # Bar
                create_frame(name="TopBar", width="fill_container", layout="horizontal", justify="space_between", align="center", children=[
                    create_badge_text("TERRAPOINT", font_size=14, font_weight="bold", fill=fg, font_family="$--font-heading"),
                    create_frame(name="GpsBadge", layout="horizontal", gap=6, align="center", children=[
                        create_frame(name="GpsDot", width=6, height=6, corner_radius=3, fill=amber),
                        create_badge_text("GPS Siap", font_size=11, font_weight="bold", fill=amber, font_family="$--font-mono")
                    ])
                ]),
                # Driver Row
                create_frame(name="DriverRow", width="fill_container", layout="horizontal", justify="space_between", align="center", padding=[6, 0], children=[
                    create_frame(name="DrvTxt", gap=1, children=[
                        create_badge_text("PENGEMUDI AKTIF", font_size=9, font_weight="bold", fill=muted, font_family="$--font-mono"),
                        create_text("Ahmad Fauzi (DRV-001)", font_size=13, font_weight="bold", fill=fg, width="fill_container")
                    ]),
                    create_frame(name="ShiftPill", padding=[3, 8], corner_radius=6, fill=card_active, stroke=amber, stroke_width=1, children=[
                        create_badge_text("Shift 1", font_size=10, font_weight="bold", fill=amber, font_family="$--font-mono")
                    ])
                ]),
                location_card,
                sync_card
            ]),

            create_frame(name="Bottom", width="fill_container", gap=6, children=[
                btn_start,
                create_frame(name="Foot", width="fill_container", layout="horizontal", justify="center", children=[
                    create_text("Foto awal otomatis memulai ritase", font_size=11, fill=muted, font_family="$--font-mono", text_align="center", width="fill_container")
                ])
            ])
        ]
    )

# SCREEN 4: DIRECT-CAPTURE CAMERA VIEWFINDER (OFFLINE)
def build_screen_4_camera(x_pos, is_dark=True):
    bg = "#000000" if is_dark else "#0F172A"
    card_bg = "#111827"
    border = "#374151"
    amber = "#D97706"
    theme_label = "Dark" if is_dark else "Light"

    banner = create_frame(
        name="BannerValid",
        width="fill_container",
        fill=amber,
        corner_radius=10,
        padding=[8, 12],
        layout="horizontal",
        justify="space_between",
        align="center",
        children=[
            create_badge_text("Posisi Sesuai (≤ 50m)", font_size=12, font_weight="bold", fill="#FFFFFF", font_family="$--font-heading"),
            create_badge_text("± 8.2m", font_size=11, font_weight="bold", fill="#FEF3C7", font_family="$--font-mono")
        ]
    )

    reticle = create_frame(
        name="ReticleBox",
        width="fill_container",
        height=320,
        fill="#050B14",
        stroke=amber,
        stroke_width=2,
        corner_radius=18,
        justify="center",
        align="center",
        gap=8,
        children=[
            create_badge_text("[ AREA KAMERA LANGSUNG ]", font_size=13, font_weight="bold", fill="#94A3B8", font_family="$--font-mono"),
            create_badge_text("Bidik Bak Muatan Truk", font_size=11, font_weight="normal", fill="#CBD5E1", font_family="$--font-mono"),
            create_frame(name="LocLabel", padding=[4, 10], corner_radius=6, fill="#0F172A", stroke="#334155", stroke_width=1, children=[
                create_badge_text("Loading Point Pit 3 Utara", font_size=11, font_weight="bold", fill=amber, font_family="$--font-mono")
            ])
        ]
    )

    shutter_bar = create_frame(
        name="ShutterBar",
        width="fill_container",
        layout="horizontal",
        justify="space_between",
        align="center",
        padding=[12, 18],
        fill=card_bg,
        stroke=border,
        stroke_width=1,
        corner_radius=20,
        children=[
            create_frame(name="BtnLamp", width=46, height=46, corner_radius=12, fill="#1F2937", justify="center", align="center", children=[
                create_badge_text("⚡", font_size=18)
            ]),
            create_frame(name="ShutterCircle", width=68, height=68, corner_radius=34, fill=amber, stroke="#FFFFFF", stroke_width=4, justify="center", align="center", children=[
                create_badge_text("FOTO", font_size=12, font_weight="bold", fill="#FFFFFF", font_family="$--font-heading")
            ]),
            create_frame(name="BtnCancel", width=46, height=46, corner_radius=12, fill="#1F2937", justify="center", align="center", children=[
                create_badge_text("✕", font_size=16, font_weight="bold", fill="#D1D5DB")
            ])
        ]
    )

    return create_frame(
        name=f"4. Camera Viewfinder ({theme_label})",
        width=360,
        height=780,
        x=x_pos,
        y=0,
        fill=bg,
        stroke=border,
        stroke_width=2,
        corner_radius=32,
        padding=16,
        gap=12,
        justify="space_between",
        children=[
            banner,
            reticle,
            shutter_bar
        ]
    )

# SCREEN 5: GEOTAG PREVIEW WITH SWISS WATERMARK & RETAKE (OFFLINE)
def build_screen_5_preview(x_pos, is_dark=True):
    bg = "#05070B"
    border = "#1C2230"
    amber = "#D97706"
    theme_label = "Dark" if is_dark else "Light"

    swiss_watermark_box = create_frame(
        name="SwissWatermarkStampCard",
        width="fill_container",
        fill="#FFFFFF",
        corner_radius=14,
        padding=10,
        layout="horizontal",
        gap=8,
        align="center",
        children=[
            # Left Mini Map Inset Snapshot
            create_frame(name="MiniMapInset", width=68, height=78, corner_radius=8, fill="#F1F5F9", stroke="#CBD5E1", stroke_width=1, justify="center", align="center", gap=2, children=[
                create_frame(name="GpsPin", width=12, height=12, corner_radius=6, fill="#DC2626", stroke="#FFFFFF", stroke_width=2),
                create_badge_text("50M RADIUS", font_size=7, font_weight="bold", fill="#334155", font_family="$--font-mono")
            ]),
            # Right Surveyor Metadata
            create_frame(name="SurveyorMetadata", width="fill_container", gap=2, children=[
                create_frame(name="HdrRow", width="fill_container", layout="horizontal", justify="space_between", children=[
                    create_badge_text("START CHECKPOINT", font_size=9, font_weight="bold", fill=amber, font_family="$--font-mono"),
                    create_badge_text("TERRAPOINT", font_size=8, font_weight="normal", fill="#64748B", font_family="$--font-mono")
                ]),
                create_badge_text("08:05:22 WITA (18/09/2026)", font_size=10, font_weight="bold", fill="#DC2626", font_family="$--font-mono"),
                create_text("Loading Point Pit 3 Utara", font_size=11, font_weight="bold", fill="#0F172A", width="fill_container"),
                create_badge_text("Lat: -3.123456, Lng: 115.123456", font_size=9, font_weight="normal", fill="#475569", font_family="$--font-mono"),
                create_badge_text("Akurasi: ±8.2m | Alt: 142m MSL", font_size=8, font_weight="normal", fill="#64748B", font_family="$--font-mono"),
                create_badge_text("DRV-001 (Ahmad) • TSK-001", font_size=8, font_weight="normal", fill="#64748B", font_family="$--font-mono")
            ])
        ]
    )

    photo_container = create_frame(
        name="PhotoContainerWithWatermark",
        width="fill_container",
        height=420,
        fill="#111827",
        stroke="#374151",
        stroke_width=1,
        corner_radius=20,
        padding=10,
        justify="end",
        children=[
            swiss_watermark_box
        ]
    )

    return create_frame(
        name=f"5. Geotag Preview & Retake ({theme_label})",
        width=360,
        height=780,
        x=x_pos,
        y=0,
        fill=bg,
        stroke=border,
        stroke_width=2,
        corner_radius=32,
        padding=18,
        gap=12,
        justify="space_between",
        children=[
            # Header
            create_frame(name="PreviewHdr", width="fill_container", layout="horizontal", justify="space_between", align="center", children=[
                create_badge_text("Preview Bukti Foto", font_size=13, font_weight="bold", fill="#F8FAFC", font_family="$--font-heading"),
                create_badge_text("Tercatat", font_size=11, font_weight="bold", fill=amber, font_family="$--font-mono")
            ]),

            photo_container,

            # Dual Actions: Gunakan vs Retake
            create_frame(name="Actions", width="fill_container", gap=8, children=[
                create_frame(name="BtnUsePhoto", width="fill_container", height=54, fill=amber, corner_radius=14, layout="horizontal", justify="center", align="center", children=[
                    create_badge_text("Gunakan Foto Ini (Mulai)", font_size=14, font_weight="bold", fill="#FFFFFF", font_family="$--font-heading")
                ]),
                create_frame(name="BtnRetake", width="fill_container", height=44, fill="#1E293B", stroke="#334155", stroke_width=1, corner_radius=12, layout="horizontal", justify="center", align="center", children=[
                    create_badge_text("Foto Ulang (Retake)", font_size=12, font_weight="600", fill="#CBD5E1", font_family="$--font-mono")
                ])
            ])
        ]
    )

# SCREEN 6: HAULING ACTIVE STATUS (OFFLINE)
def build_screen_6_tracking(x_pos, is_dark=True):
    bg = "#0B0E17" if is_dark else "#FFFFFF"
    card_bg = "#131824" if is_dark else "#F8FAFC"
    border = "#1C2230" if is_dark else "#CBD5E1"
    fg = "#F8FAFC" if is_dark else "#0F172A"
    muted = "#7E8B9F" if is_dark else "#475569"
    amber = "#D97706"
    theme_label = "Dark" if is_dark else "Light"

    return create_frame(
        name=f"6. Hauling Active Status ({theme_label})",
        width=360,
        height=780,
        x=x_pos,
        y=0,
        fill=bg,
        stroke=border,
        stroke_width=2,
        corner_radius=32,
        padding=20,
        gap=14,
        justify="space_between",
        children=[
            create_frame(name="TopArea", width="fill_container", gap=14, children=[
                # Top status
                create_frame(name="TopBar", width="fill_container", layout="horizontal", justify="space_between", align="center", children=[
                    create_badge_text("RITASE BERJALAN", font_size=13, font_weight="bold", fill=fg, font_family="$--font-heading"),
                    create_frame(name="ActiveBadge", padding=[3, 8], corner_radius=6, fill="rgba(217, 119, 6, 0.15)", stroke=amber, stroke_width=1, children=[
                        create_badge_text("SIAP HAULING", font_size=10, font_weight="bold", fill=amber, font_family="$--font-mono")
                    ])
                ]),
                # Simplified status card (K3 Driver Focus)
                create_frame(name="StatusCard", width="fill_container", fill=card_bg, stroke=border, stroke_width=1, corner_radius=16, padding=18, align="center", gap=6, children=[
                    create_frame(name="TruckIcon", width=44, height=44, corner_radius=22, fill="rgba(217, 119, 6, 0.15)", justify="center", align="center", children=[
                        create_badge_text("🚛", font_size=20)
                    ]),
                    create_text("PERJALANAN MENUJU TITIK BONGKAR", font_size=12, font_weight="bold", fill=amber, font_family="$--font-heading", text_align="center", width="fill_container"),
                    create_text("Rute hauling otomatis tercatat di latar belakang dan terpantau oleh Dispatcher di dashboard.", font_size=11, fill=muted, text_align="center", width="fill_container", line_height=1.4)
                ]),
                # Checkpoint Info
                create_frame(name="CheckpointCard", width="fill_container", fill=card_bg, stroke=border, stroke_width=1, corner_radius=16, padding=16, gap=12, children=[
                    create_frame(name="A", width="fill_container", gap=2, children=[
                        create_badge_text("TITIK MUAT (AWAL)", font_size=9, font_weight="bold", fill=muted, font_family="$--font-mono"),
                        create_text("Loading Point Pit 3 Utara", font_size=13, font_weight="bold", fill=fg, width="fill_container"),
                        create_badge_text("Foto Selesai • 08:05 WITA", font_size=11, font_weight="600", fill=amber, font_family="$--font-mono")
                    ]),
                    create_frame(name="B", width="fill_container", gap=2, children=[
                        create_badge_text("TITIK BONGKAR (TUJUAN)", font_size=9, font_weight="bold", fill=muted, font_family="$--font-mono"),
                        create_text("ROM Stockpile 1", font_size=13, font_weight="bold", fill=fg, width="fill_container"),
                        create_badge_text("Ambil foto saat tiba di radius 50m", font_size=11, font_weight="normal", fill=muted, font_family="$--font-mono")
                    ])
                ])
            ]),

            # Bottom Button: Foto Bongkar
            create_frame(name="BottomArea", width="fill_container", gap=8, children=[
                create_frame(name="BtnBongkar", width="fill_container", height=58, fill=amber, corner_radius=16, layout="horizontal", justify="center", align="center", children=[
                    create_badge_text("Foto Bongkar (Selesai)", font_size=15, font_weight="bold", fill="#FFFFFF", font_family="$--font-heading")
                ]),
                create_frame(name="K3Note", width="fill_container", layout="horizontal", justify="center", children=[
                    create_text("Fokus menyetir • Utamakan keselamatan K3", font_size=11, fill=muted, font_family="$--font-mono", text_align="center", width="fill_container")
                ])
            ])
        ]
    )

# SCREEN 7: CAMP SYNC QUEUE (ONLINE)
def build_screen_7_sync(x_pos, is_dark=True):
    bg = "#0B0E17" if is_dark else "#FFFFFF"
    card_bg = "#131824" if is_dark else "#F8FAFC"
    border = "#1C2230" if is_dark else "#CBD5E1"
    fg = "#F8FAFC" if is_dark else "#0F172A"
    muted = "#7E8B9F" if is_dark else "#475569"
    amber = "#D97706"
    theme_label = "Dark" if is_dark else "Light"

    def make_task_row(title, time_sub):
        return create_frame(
            name="TaskRow",
            width="fill_container",
            fill=card_bg,
            stroke=border,
            stroke_width=1,
            corner_radius=12,
            padding=14,
            layout="horizontal",
            justify="space_between",
            align="center",
            children=[
                create_frame(name="T", gap=2, children=[
                    create_text(title, font_size=13, font_weight="bold", fill=fg, width="fill_container"),
                    create_badge_text(time_sub, font_size=11, font_weight="normal", fill=muted, font_family="$--font-mono")
                ]),
                create_badge_text("Siap", font_size=12, font_weight="bold", fill=amber, font_family="$--font-mono")
            ]
        )

    return create_frame(
        name=f"7. Sync Queue ({theme_label})",
        width=360,
        height=780,
        x=x_pos,
        y=0,
        fill=bg,
        stroke=border,
        stroke_width=2,
        corner_radius=32,
        padding=20,
        gap=14,
        justify="space_between",
        children=[
            create_frame(name="TopArea", width="fill_container", gap=12, children=[
                # Top Bar
                create_frame(name="TopBar", width="fill_container", layout="horizontal", justify="space_between", align="center", children=[
                    create_badge_text("ANTREAN SINKRONISASI", font_size=13, font_weight="bold", fill=fg, font_family="$--font-heading"),
                    create_frame(name="OnlinePill", padding=[3, 8], corner_radius=6, fill="rgba(217, 119, 6, 0.15)", stroke=amber, stroke_width=1, children=[
                        create_badge_text("CAMP ONLINE", font_size=10, font_weight="bold", fill=amber, font_family="$--font-mono")
                    ])
                ]),
                # Clean summary card
                create_frame(name="SummaryCard", width="fill_container", fill=card_bg, stroke=border, stroke_width=1, corner_radius=16, padding=16, gap=2, children=[
                    create_badge_text("STATUS PENGIRIMAN", font_size=10, font_weight="bold", fill=muted, font_family="$--font-mono"),
                    create_text("3 Ritase Siap Dikirim ke Kantor", font_size=15, font_weight="bold", fill=fg, width="fill_container")
                ]),
                make_task_row("Ritase 1: Pit 3 Utara ➔ ROM 1", "Muat 08:05 • Bongkar 08:35"),
                make_task_row("Ritase 2: Pit 3 Utara ➔ ROM 1", "Muat 09:10 • Bongkar 09:40"),
                make_task_row("Ritase 3: Pit 2 Barat ➔ ROM 2", "Muat 10:15 • Bongkar 10:48")
            ]),

            # Bottom Upload Button
            create_frame(name="BottomArea", width="fill_container", gap=10, children=[
                create_frame(name="ProgRow", width="fill_container", gap=4, children=[
                    create_frame(name="ProgText", width="fill_container", layout="horizontal", justify="space_between", children=[
                        create_badge_text("Kemajuan Pengiriman", font_size=11, font_weight="bold", fill=muted, font_family="$--font-mono"),
                        create_badge_text("66%", font_size=11, font_weight="bold", fill=amber, font_family="$--font-mono")
                    ]),
                    create_frame(name="BarBg", width="fill_container", height=6, corner_radius=3, fill=border, children=[
                        create_frame(name="BarFill", width=220, height=6, corner_radius=3, fill=amber)
                    ])
                ]),
                create_frame(name="BtnSync", width="fill_container", height=58, fill=amber, corner_radius=16, layout="horizontal", justify="center", align="center", children=[
                    create_badge_text("Sinkronkan Sekarang", font_size=15, font_weight="bold", fill="#FFFFFF", font_family="$--font-heading")
                ])
            ])
        ]
    )

# ==============================================================================
# MASTER CANVAS ASSEMBLY (14 EXACT FRAMES)
# ==============================================================================
def main():
    spacing = 400

    # Dark Mode Set (7 Complete Screens)
    d1 = build_screen_1_login(0, is_dark=True)
    d2 = build_screen_2_pin(spacing, is_dark=True)
    d3 = build_screen_3_home(spacing * 2, is_dark=True)
    d4 = build_screen_4_camera(spacing * 3, is_dark=True)
    d5 = build_screen_5_preview(spacing * 4, is_dark=True)
    d6 = build_screen_6_tracking(spacing * 5, is_dark=True)
    d7 = build_screen_7_sync(spacing * 6, is_dark=True)

    # Light Mode Set (7 Complete Screens)
    l1 = build_screen_1_login(spacing * 7, is_dark=False)
    l2 = build_screen_2_pin(spacing * 8, is_dark=False)
    l3 = build_screen_3_home(spacing * 9, is_dark=False)
    l4 = build_screen_4_camera(spacing * 10, is_dark=False)
    l5 = build_screen_5_preview(spacing * 11, is_dark=False)
    l6 = build_screen_6_tracking(spacing * 12, is_dark=False)
    l7 = build_screen_7_sync(spacing * 13, is_dark=False)

    master_pen = {
        "version": "2.17",
        "children": [
            create_frame(
                name="TerraPoint Mining Safety Amber System (14 Complete Frames)",
                width=5800,
                height=880,
                x=0,
                y=0,
                fill="#06080D",
                padding=40,
                gap=40,
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
        "fileToken": "terrapoint-mobile-14frames-exact-v8"
    }

    with open("designs/terrapoint_mobile_ui.pen", "w") as f:
        json.dump(master_pen, f, indent=2)
    
    print("Successfully regenerated 1:1 exact designs/terrapoint_mobile_ui.pen with textGrowth constraints")

if __name__ == "__main__":
    main()
