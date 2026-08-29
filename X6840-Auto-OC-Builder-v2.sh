#!/usr/bin/env bash
set -euo pipefail

# ============================================================
# X6840 Auto CPU OverClock Builder
# Target : Infinix Smart 20 / X6840
# Method : Modify CPU OPP tables inside vendor_boot DTB
# ============================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

INPUT="$SCRIPT_DIR/vendor_boot.img"

if [ ! -f "$INPUT" ]; then
    echo "[ERROR] vendor_boot.img tidak ditemukan."
    echo "Letakkan vendor_boot.img di:"
    echo "  $SCRIPT_DIR"
    exit 1
fi

# Nilai konfigurasi awal.
MHZ=""
ADD_HZ=""
CHANGE_VOLTAGE="n"
LITTLE_VOLTAGE=""
BIG_VOLTAGE=""

# Support tools beside this repo or in the tools-backup repo.
if [ -d "$SCRIPT_DIR/tools" ]; then
    TOOLS="$SCRIPT_DIR/tools"
elif [ -d "$HOME/x6840-tools-backup/tools" ]; then
    TOOLS="$HOME/x6840-tools-backup/tools"
elif [ -d "$HOME/repack-tools-backup/tools" ]; then
    TOOLS="$HOME/repack-tools-backup/tools"
else
    echo "[ERROR] X6840 tools directory not found."
    exit 1
fi

MKBOOTIMG="$TOOLS/mkbootimg/mkbootimg.py"
UNPACK="$TOOLS/mkbootimg/unpack_bootimg.py"
MKDTIMG="$TOOLS/libufdt/utils/src/mkdtboimg.py"
FDTGET="$TOOLS/dtc/fdtget"
FDTPUT="$TOOLS/dtc/fdtput"
AVBTOOL="$TOOLS/avb/avbtool.py"

for f in "$MKBOOTIMG" "$UNPACK" "$MKDTIMG" "$FDTGET" "$FDTPUT" "$AVBTOOL"; do
    if [ ! -e "$f" ]; then
        echo "[ERROR] Missing tool: $f"
        exit 1
    fi
done

BASE="$(basename "$INPUT" .img)"
WORK="$(mktemp -d)"
OUT_DIR="$SCRIPT_DIR/output"
mkdir -p "$OUT_DIR"

cleanup() {
    rm -rf "$WORK"
}
trap cleanup EXIT

echo "================================================"
echo " X6840 PEMBUAT CPU OVERCLOCK OTOMATIS"
echo " Pembuat   : Rizky X Loli"
echo " Target    : Infinix Smart 20 (X6840)"
echo " Metode    : Modifikasi CPU OPP pada Device Tree vendor_boot"
echo "================================================"
echo "Berkas     : $INPUT"
echo

echo "[1/8] Membaca informasi AVB bawaan..."

AVB_INFO="$WORK/avb.txt"
python3 "$AVBTOOL" info_image --image "$INPUT" > "$AVB_INFO"

PARTITION_NAME="$(awk '/Partition Name:/ {print $3; exit}' "$AVB_INFO")"
ORIGINAL_SIZE="$(awk '/Original image size:/ {print $4; exit}' "$AVB_INFO")"
IMAGE_SIZE="$(awk '/^Image size:/ {print $3; exit}' "$AVB_INFO")"
SALT="$(awk '/^[[:space:]]*Salt:/ {print $2; exit}' "$AVB_INFO")"

if [ -z "${PARTITION_NAME:-}" ]; then
    PARTITION_NAME="$(awk '/Partition Name:/ {print $3; exit}' "$AVB_INFO")"
fi

if [ "$PARTITION_NAME" != "vendor_boot" ]; then
    echo "[ERROR] Input is not an AVB vendor_boot image."
    exit 1
fi

if [ -z "${IMAGE_SIZE:-}" ] || [ -z "${ORIGINAL_SIZE:-}" ] || [ -z "${SALT:-}" ]; then
    echo "[ERROR] Could not read required AVB parameters."
    exit 1
fi

PROP_LINE="$(grep -m1 "Prop: com.android.build.vendor_boot.fingerprint" "$AVB_INFO" || true)"
PROP_VALUE="$(printf '%s\n' "$PROP_LINE" | sed -n "s/.* -> '\(.*\)'/\1/p")"

echo "      Ukuran partisi : $IMAGE_SIZE"
echo "      Ukuran payload   : $ORIGINAL_SIZE"

echo "[2/8] Mengekstrak vendor_boot..."

mkdir -p "$WORK/unpack"
python3 "$UNPACK" \
    --boot_img "$INPUT" \
    --out "$WORK/unpack" \
    --format=mkbootimg > "$WORK/mkbootimg_args.txt"

if [ ! -f "$WORK/unpack/dtb" ]; then
    echo "[ERROR] DTB container not found."
    exit 1
fi

echo "[3/8] Membaca tabel DT Android..."

python3 "$MKDTIMG" dump "$WORK/unpack/dtb" > "$WORK/dtinfo.txt"

DT_COUNT="$(awk '/dt_entry_count/ {print $3; exit}' "$WORK/dtinfo.txt")"
DT_OFFSET="$(awk '/dt_offset/ {print $3; exit}' "$WORK/dtinfo.txt")"
DT_SIZE="$(awk '/dt_size/ {print $3; exit}' "$WORK/dtinfo.txt")"
PAGE_SIZE="$(awk '/page_size/ {print $3; exit}' "$WORK/dtinfo.txt")"
DT_VERSION="$(awk '/^[[:space:]]*version[[:space:]]*=/ {print $3; exit}' "$WORK/dtinfo.txt")"

if [ "$DT_COUNT" != "1" ]; then
    echo "[ERROR] Expected exactly one DT entry, found: $DT_COUNT"
    exit 1
fi

dd if="$WORK/unpack/dtb" \
   of="$WORK/mt6768.dtb" \
   bs=1 skip="$DT_OFFSET" count="$DT_SIZE" \
   status=none

cp "$WORK/mt6768.dtb" "$WORK/mt6768_oc.dtb"

echo "[4/8] Konfigurasi CPU OPP..."

# Pastikan kedua tabel tersedia.
for table in opp_table0 opp_table1; do
    if ! "$FDTGET" -l "$WORK/mt6768_oc.dtb" "/$table" >/dev/null 2>&1; then
        echo "[ERROR] /$table tidak ditemukan."
        exit 1
    fi
done

NODE="opp15"

# ------------------------------------------------------------
# Baca nilai stock dari DTB.
# ------------------------------------------------------------
LITTLE_HZ_HEX="$("$FDTGET" -t x "$WORK/mt6768.dtb" \
    "/opp_table0/$NODE" opp-hz | awk '{print $2}')"

BIG_HZ_HEX="$("$FDTGET" -t x "$WORK/mt6768.dtb" \
    "/opp_table1/$NODE" opp-hz | awk '{print $2}')"

LITTLE_VOLTAGE_STOCK="$("$FDTGET" -t u "$WORK/mt6768.dtb" \
    "/opp_table0/$NODE" opp-microvolt)"

BIG_VOLTAGE_STOCK="$("$FDTGET" -t u "$WORK/mt6768.dtb" \
    "/opp_table1/$NODE" opp-microvolt)"

if [ -z "$LITTLE_HZ_HEX" ] || [ -z "$BIG_HZ_HEX" ]; then
    echo "[ERROR] Tidak dapat membaca opp-hz stock."
    exit 1
fi

if [ -z "$LITTLE_VOLTAGE_STOCK" ] || [ -z "$BIG_VOLTAGE_STOCK" ]; then
    echo "[ERROR] Tidak dapat membaca opp-microvolt stock."
    exit 1
fi

LITTLE_HZ=$((16#$LITTLE_HZ_HEX))
BIG_HZ=$((16#$BIG_HZ_HEX))

LITTLE_STOCK_MHZ=$((LITTLE_HZ / 1000000))
BIG_STOCK_MHZ=$((BIG_HZ / 1000000))

# Nilai default.
MHZ=""
ADD_HZ=""
LITTLE_TARGET_MHZ=""
BIG_TARGET_MHZ=""

LITTLE_VOLTAGE="$LITTLE_VOLTAGE_STOCK"
BIG_VOLTAGE="$BIG_VOLTAGE_STOCK"

# ============================================================
# MENU FREQUENCY
# ============================================================
while true; do
    clear
    echo "================================================"
    echo " X6840 CPU OVERCLOCK BUILDER"
    echo "================================================"
    echo
    echo "========== CPU FREQUENCY =========="
    echo
    echo "Little stock : ${LITTLE_STOCK_MHZ} MHz"
    echo "Big stock    : ${BIG_STOCK_MHZ} MHz"
    echo
    echo "Masukkan tambahan OverClock."
    echo "Rentang: 1-500 MHz"
    echo

    read -rp "Tambahan OC [MHz]: " MHZ

    if ! [[ "$MHZ" =~ ^[0-9]+$ ]] || [ "$MHZ" -eq 0 ] || [ "$MHZ" -gt 500 ]; then
        echo
        echo "[ERROR] Masukkan angka 1-500 MHz."
        read -rp "Tekan Enter untuk mencoba lagi..."
        continue
    fi

    LITTLE_TARGET_MHZ=$((LITTLE_STOCK_MHZ + MHZ))
    BIG_TARGET_MHZ=$((BIG_STOCK_MHZ + MHZ))

    echo
    echo "Target:"
    echo "  Little : ${LITTLE_STOCK_MHZ} → ${LITTLE_TARGET_MHZ} MHz"
    echo "  Big    : ${BIG_STOCK_MHZ} → ${BIG_TARGET_MHZ} MHz"
    echo
    echo "[K] Kembali"
    echo "[Y] Lanjut"
    echo

    while true; do
        read -rp "Pilihan [K/Y]: " CHOICE
        CHOICE="${CHOICE,,}"

        case "$CHOICE" in
            y)
                ADD_HZ=$((MHZ * 1000000))
                break
                ;;
            k)
                echo
                echo "Konfigurasi dibatalkan."
                exit 0
                ;;
            *)
                echo "[ERROR] Pilih Y atau K."
                ;;
        esac
    done

    break
done

# ============================================================
# MENU VOLTAGE
# ============================================================
while true; do
    clear
    echo "================================================"
    echo " X6840 CPU OVERCLOCK BUILDER"
    echo "================================================"
    echo
    echo "========== VOLTAGE =========="
    echo
    echo "Little stock : ${LITTLE_VOLTAGE_STOCK} µV"
    echo "Big stock    : ${BIG_VOLTAGE_STOCK} µV"
    echo
    echo "Ubah voltage juga?"
    echo
    echo "[Y] Ya"
    echo "[N] Tidak"
    echo "[K] Kembali ke CPU Frequency"
    echo

    read -rp "Pilihan [Y/N/K]: " CHOICE
    CHOICE="${CHOICE,,}"

    case "$CHOICE" in
        y)
            while true; do
                clear
                echo "================================================"
                echo " PENGATURAN VOLTAGE"
                echo "================================================"
                echo
                echo "Little stock : ${LITTLE_VOLTAGE_STOCK} µV"
                echo "Big stock    : ${BIG_VOLTAGE_STOCK} µV"
                echo
                echo "Masukkan voltage ABSOLUT dalam µV."
                echo
                echo "[K] Kembali ke pilihan voltage"
                echo

                read -rp "Little voltage [µV]: " LITTLE_INPUT

                if [[ "$LITTLE_INPUT" == "k" || "$LITTLE_INPUT" == "K" ]]; then
                    break
                fi

                if ! [[ "$LITTLE_INPUT" =~ ^[0-9]+$ ]] || [ "$LITTLE_INPUT" -eq 0 ]; then
                    echo "[ERROR] Voltage Little tidak valid."
                    read -rp "Tekan Enter untuk mencoba lagi..."
                    continue
                fi

                read -rp "Big voltage [µV]: " BIG_INPUT

                if [[ "$BIG_INPUT" == "k" || "$BIG_INPUT" == "K" ]]; then
                    continue
                fi

                if ! [[ "$BIG_INPUT" =~ ^[0-9]+$ ]] || [ "$BIG_INPUT" -eq 0 ]; then
                    echo "[ERROR] Voltage Big tidak valid."
                    read -rp "Tekan Enter untuk mencoba lagi..."
                    continue
                fi

                LITTLE_VOLTAGE="$LITTLE_INPUT"
                BIG_VOLTAGE="$BIG_INPUT"
                break
            done
            ;;

        n)
            LITTLE_VOLTAGE="$LITTLE_VOLTAGE_STOCK"
            BIG_VOLTAGE="$BIG_VOLTAGE_STOCK"
            break
            ;;

        k)
            # Kembali ke menu frequency.
            while true; do
                clear
                echo "================================================"
                echo " CPU FREQUENCY"
                echo "================================================"
                echo
                echo "Little stock : ${LITTLE_STOCK_MHZ} MHz"
                echo "Big stock    : ${BIG_STOCK_MHZ} MHz"
                echo
                echo "OC saat ini  : +${MHZ} MHz"
                echo
                echo "[Y] Gunakan +${MHZ} MHz"
                echo "[K] Masukkan ulang frequency"
                echo

                read -rp "Pilihan [Y/K]: " FCHOICE
                FCHOICE="${FCHOICE,,}"

                case "$FCHOICE" in
                    y)
                        break
                        ;;

                    k)
                        read -rp "Tambahan OC [MHz]: " NEW_MHZ

                        if [[ "$NEW_MHZ" =~ ^[0-9]+$ ]] &&
                           [ "$NEW_MHZ" -gt 0 ] &&
                           [ "$NEW_MHZ" -le 500 ]; then
                            MHZ="$NEW_MHZ"
                            ADD_HZ=$((MHZ * 1000000))
                            LITTLE_TARGET_MHZ=$((LITTLE_STOCK_MHZ + MHZ))
                            BIG_TARGET_MHZ=$((BIG_STOCK_MHZ + MHZ))
                            break
                        fi

                        echo "[ERROR] Masukkan angka 1-500 MHz."
                        ;;

                    *)
                        echo "[ERROR] Pilih Y atau K."
                        ;;
                esac
            done
            ;;

        *)
            echo "[ERROR] Pilih Y, N, atau K."
            ;;
    esac

    # Jika konfigurasi voltage sudah selesai, lanjut summary.
    if [[ "$CHOICE" == "y" || "$CHOICE" == "n" ]]; then
        break
    fi

    # Jika K dari voltage dan frequency berhasil dipilih,
    # kembali tampilkan menu voltage.
done

# ============================================================
# MENU SUMMARY
# ============================================================
while true; do
    clear
    echo "================================================"
    echo " X6840 CPU OVERCLOCK BUILDER"
    echo "================================================"
    echo
    echo "========== KONFIGURASI AKHIR =========="
    echo
    echo "Little Cluster"
    echo "  Frequency : ${LITTLE_STOCK_MHZ} → ${LITTLE_TARGET_MHZ} MHz"
    echo "  Voltage   : ${LITTLE_VOLTAGE_STOCK} → ${LITTLE_VOLTAGE} µV"
    echo
    echo "Big Cluster"
    echo "  Frequency : ${BIG_STOCK_MHZ} → ${BIG_TARGET_MHZ} MHz"
    echo "  Voltage   : ${BIG_VOLTAGE_STOCK} → ${BIG_VOLTAGE} µV"
    echo
    echo "Hanya opp15 yang akan diubah."
    echo "opp0-opp14 tetap stock."
    echo
    echo "[K] Kembali ke Voltage"
    echo "[Y] Build"
    echo

    read -rp "Pilihan [K/Y]: " CHOICE
    CHOICE="${CHOICE,,}"

    case "$CHOICE" in
        y)
            break
            ;;

        k)
            while true; do
                clear
                echo "================================================"
                echo " VOLTAGE"
                echo "================================================"
                echo
                echo "Little voltage: ${LITTLE_VOLTAGE} µV"
                echo "Big voltage   : ${BIG_VOLTAGE} µV"
                echo
                echo "[Y] Ubah voltage"
                echo "[N] Gunakan voltage stock"
                echo "[K] Kembali ke CPU Frequency"
                echo

                read -rp "Pilihan [Y/N/K]: " VCHOICE
                VCHOICE="${VCHOICE,,}"

                case "$VCHOICE" in
                    y)
                        read -rp "Little voltage [µV]: " LITTLE_INPUT
                        read -rp "Big voltage [µV]: " BIG_INPUT

                        if [[ "$LITTLE_INPUT" =~ ^[0-9]+$ ]] &&
                           [ "$LITTLE_INPUT" -gt 0 ] &&
                           [[ "$BIG_INPUT" =~ ^[0-9]+$ ]] &&
                           [ "$BIG_INPUT" -gt 0 ]; then
                            LITTLE_VOLTAGE="$LITTLE_INPUT"
                            BIG_VOLTAGE="$BIG_INPUT"
                            break
                        fi

                        echo "[ERROR] Voltage tidak valid."
                        read -rp "Tekan Enter untuk mencoba lagi..."
                        ;;

                    n)
                        LITTLE_VOLTAGE="$LITTLE_VOLTAGE_STOCK"
                        BIG_VOLTAGE="$BIG_VOLTAGE_STOCK"
                        break
                        ;;

                    k)
                        # Kembali ke frequency dan pertahankan state.
                        while true; do
                            clear
                            echo "================================================"
                            echo " CPU FREQUENCY"
                            echo "================================================"
                            echo
                            echo "Little stock : ${LITTLE_STOCK_MHZ} MHz"
                            echo "Big stock    : ${BIG_STOCK_MHZ} MHz"
                            echo
                            echo "OC saat ini  : +${MHZ} MHz"
                            echo
                            echo "[Y] Gunakan +${MHZ} MHz"
                            echo "[K] Ubah frequency"
                            echo

                            read -rp "Pilihan [Y/K]: " FCHOICE
                            FCHOICE="${FCHOICE,,}"

                            case "$FCHOICE" in
                                y)
                                    break
                                    ;;

                                k)
                                    read -rp "Tambahan OC [MHz]: " NEW_MHZ

                                    if [[ "$NEW_MHZ" =~ ^[0-9]+$ ]] &&
                                       [ "$NEW_MHZ" -gt 0 ] &&
                                       [ "$NEW_MHZ" -le 500 ]; then
                                        MHZ="$NEW_MHZ"
                                        ADD_HZ=$((MHZ * 1000000))
                                        LITTLE_TARGET_MHZ=$((LITTLE_STOCK_MHZ + MHZ))
                                        BIG_TARGET_MHZ=$((BIG_STOCK_MHZ + MHZ))
                                        break
                                    fi

                                    echo "[ERROR] Masukkan angka 1-500 MHz."
                                    ;;

                                *)
                                    echo "[ERROR] Pilih Y atau K."
                                    ;;
                            esac
                        done
                        break
                        ;;

                    *)
                        echo "[ERROR] Pilih Y, N, atau K."
                        ;;
                esac
            done
            ;;

        *)
            echo "[ERROR] Pilih Y atau K."
            ;;
    esac

    if [[ "$CHOICE" == "y" ]]; then
        break
    fi
done

# Setelah pengguna menekan Y pada Summary, baru tentukan output.
BASE="$(basename "$INPUT" .img)"
OUT_DIR="$SCRIPT_DIR/output"
mkdir -p "$OUT_DIR"
OUTPUT="$OUT_DIR/${BASE}_OC+${MHZ}MHz.img"

echo
echo "Konfigurasi diterima."
echo "Hasil akan disimpan:"
echo "$OUTPUT"
echo

# ============================================================
# TERAPKAN PERUBAHAN KE DTB
# ============================================================
echo "[4/8] Menerapkan konfigurasi ke tabel OPP CPU..."

for table in opp_table0 opp_table1; do
    if ! "$FDTGET" -l "$WORK/mt6768_oc.dtb" "/$table" >/dev/null 2>&1; then
        echo "[ERROR] /$table tidak ditemukan."
        exit 1
    fi
done

LITTLE_NEW_HZ=$((LITTLE_HZ + ADD_HZ))
BIG_NEW_HZ=$((BIG_HZ + ADD_HZ))

LITTLE_NEW_HZ_HEX="$(printf '%x' "$LITTLE_NEW_HZ")"
BIG_NEW_HZ_HEX="$(printf '%x' "$BIG_NEW_HZ")"

"$FDTPUT" -t x \
    "$WORK/mt6768_oc.dtb" \
    "/opp_table0/$NODE" \
    opp-hz 0 "$LITTLE_NEW_HZ_HEX"

"$FDTPUT" -t x \
    "$WORK/mt6768_oc.dtb" \
    "/opp_table1/$NODE" \
    opp-hz 0 "$BIG_NEW_HZ_HEX"

if [ "$LITTLE_VOLTAGE" != "$LITTLE_VOLTAGE_STOCK" ] ||
   [ "$BIG_VOLTAGE" != "$BIG_VOLTAGE_STOCK" ]; then

    "$FDTPUT" -t u \
        "$WORK/mt6768_oc.dtb" \
        "/opp_table0/$NODE" \
        opp-microvolt "$LITTLE_VOLTAGE"

    "$FDTPUT" -t u \
        "$WORK/mt6768_oc.dtb" \
        "/opp_table1/$NODE" \
        opp-microvolt "$BIG_VOLTAGE"

    echo "      Voltage OPP15 diubah."
else
    echo "      Voltage OPP15 tetap stock."
fi

# ============================================================
# TERAPKAN PERUBAHAN KE DTB
# ============================================================
echo
echo "[4/8] Menerapkan konfigurasi ke tabel OPP CPU..."

for table in opp_table0 opp_table1; do
    if ! "$FDTGET" -l "$WORK/mt6768_oc.dtb" "/$table" >/dev/null 2>&1; then
        echo "[ERROR] /$table tidak ditemukan."
        exit 1
    fi
done

LITTLE_NEW_HZ=$((LITTLE_HZ + ADD_HZ))
BIG_NEW_HZ=$((BIG_HZ + ADD_HZ))

LITTLE_NEW_HZ_HEX="$(printf '%x' "$LITTLE_NEW_HZ")"
BIG_NEW_HZ_HEX="$(printf '%x' "$BIG_NEW_HZ")"

"$FDTPUT" -t x \
    "$WORK/mt6768_oc.dtb" \
    "/opp_table0/$NODE" \
    opp-hz 0 "$LITTLE_NEW_HZ_HEX"

"$FDTPUT" -t x \
    "$WORK/mt6768_oc.dtb" \
    "/opp_table1/$NODE" \
    opp-hz 0 "$BIG_NEW_HZ_HEX"

if [ "$LITTLE_VOLTAGE" != "$LITTLE_VOLTAGE_STOCK" ] ||
   [ "$BIG_VOLTAGE" != "$BIG_VOLTAGE_STOCK" ]; then

    "$FDTPUT" -t u \
        "$WORK/mt6768_oc.dtb" \
        "/opp_table0/$NODE" \
        opp-microvolt "$LITTLE_VOLTAGE"

    "$FDTPUT" -t u \
        "$WORK/mt6768_oc.dtb" \
        "/opp_table1/$NODE" \
        opp-microvolt "$BIG_VOLTAGE"

    echo "      Voltage OPP15 diubah."
else
    echo "      Voltage OPP15 tetap stock."
fi

echo "[5/8] Membangun ulang tabel DT Android..."

python3 "$MKDTIMG" create \
    "$WORK/dtb_oc" \
    --page_size="$PAGE_SIZE" \
    --version="$DT_VERSION" \
    "$WORK/mt6768_oc.dtb"

echo "[6/8] Membangun ulang vendor_boot..."

ARGS="$(cat "$WORK/mkbootimg_args.txt")"

ARGS="$(printf '%s\n' "$ARGS" | sed \
    "s|--dtb [^ ]*|--dtb $WORK/dtb_oc|" \
)"

# shellcheck disable=SC2086
python3 "$MKBOOTIMG" $ARGS --vendor_boot "$WORK/vendor_boot_payload.img"

PAYLOAD_SIZE="$(stat -c '%s' "$WORK/vendor_boot_payload.img")"

if [ "$PAYLOAD_SIZE" -ne "$ORIGINAL_SIZE" ]; then
    echo "[ERROR] Repacked payload size changed."
    echo "Stock : $ORIGINAL_SIZE"
    echo "New   : $PAYLOAD_SIZE"
    exit 1
fi

echo "[7/8] Membangun ulang AVB footer..."

cp "$WORK/vendor_boot_payload.img" "$OUTPUT"

AVB_ARGS=(
    add_hash_footer
    --image "$OUTPUT"
    --partition_name vendor_boot
    --partition_size "$IMAGE_SIZE"
    --salt "$SALT"
)

if [ -n "$PROP_VALUE" ]; then
    AVB_ARGS+=(--prop "com.android.build.vendor_boot.fingerprint:$PROP_VALUE")
fi

python3 "$AVBTOOL" "${AVB_ARGS[@]}"

echo "[8/8] Verifikasi akhir..."

mkdir -p "$WORK/verify"

python3 "$UNPACK" \
    --boot_img "$OUTPUT" \
    --out "$WORK/verify" >/dev/null

python3 "$MKDTIMG" dump "$WORK/verify/dtb" > "$WORK/verify_dtinfo.txt"

VERIFY_OFFSET="$(awk '/dt_offset/ {print $3; exit}' "$WORK/verify_dtinfo.txt")"
VERIFY_SIZE="$(awk '/dt_size/ {print $3; exit}' "$WORK/verify_dtinfo.txt")"

dd if="$WORK/verify/dtb" \
   of="$WORK/final.dtb" \
   bs=1 skip="$VERIFY_OFFSET" count="$VERIFY_SIZE" \
   status=none

echo
echo "Frekuensi maksimum akhir:"

for table in opp_table0 opp_table1; do
    LAST="$("$FDTGET" -l "$WORK/final.dtb" "/$table" | tail -n1)"
    HEX="$("$FDTGET" -t x "$WORK/final.dtb" "/$table/$LAST" opp-hz | awk '{print $2}')"
    HZ=$((16#$HEX))
    MHZ_FINAL=$((HZ / 1000000))

    echo "  $table : ${MHZ_FINAL} MHz"
done

echo
echo "SHA256:"
sha256sum "$OUTPUT"

echo
echo "================================================"
echo " BUILD BERHASIL"
echo "================================================"
echo "Hasil:"
echo "$OUTPUT"
echo
echo "PERINGATAN:"
echo "Overclock dapat menyebabkan bootloop, ketidakstabilan,"
echo "suhu lebih tinggi, dan risiko kerusakan perangkat."
echo "Selalu simpan vendor_boot.img bawaan sebagai cadangan."
