# Auto-Overclock

Repository tools dan script untuk melakukan persiapan VPS serta
modifikasi CPU OPP pada `vendor_boot.img`.

**Pembuat:** Rizky X Loli

---

## Daftar Isi

- [Tentang Project](#tentang-project)
- [Fitur](#fitur)
- [Clone Repository](#1-clone-repository)
- [Pilih Setup VPS](#2-pilih-setup-vps)
- [VPS dengan SUDO/ROOT](#3-vps-dengan-sudoroot)
- [VPS tanpa SUDO/ROOT](#4-vps-tanpa-sudoroot)
- [Pemeriksaan Tools](#5-pemeriksaan-tools)
- [Persiapan vendor_boot.img](#6-persiapan-vendor_bootimg)
- [Menjalankan Auto Overclock](#7-menjalankan-auto-overclock)
- [Pengaturan CPU Frequency](#8-pengaturan-cpu-frequency)
- [Pengaturan Voltage](#9-pengaturan-voltage)
- [Navigasi K dan Y](#10-navigasi-k-dan-y)
- [Konfigurasi Akhir](#11-konfigurasi-akhir)
- [Build](#12-build)
- [Verifikasi](#13-verifikasi)
- [Output](#14-output)
- [Backup](#15-backup)
- [Keterbatasan](#16-keterbatasan)
- [Peringatan](#17-peringatan)
- [Disclaimer](#18-disclaimer)

---

# Tentang Project

`Auto-Overclock` merupakan repository yang menyediakan tools dan
script untuk membantu proses modifikasi image Android melalui VPS/Linux.

Salah satu fitur utama repository ini adalah:

```text
X6840-Auto-OC-Builder-v2.sh
Script tersebut digunakan untuk melakukan modifikasi CPU OPP pada
vendor_boot.img.

Target pengembangan saat ini:

Perangkat : Infinix Smart 20
Model     : X6840
Platform  : MediaTek
Target    : CPU OPP
Lokasi    : Device Tree di dalam vendor_boot

Pada X6840 yang digunakan dalam pengembangan, CPU OPP berada pada:

/opp_table0/opp15
/opp_table1/opp15

OPP maksimum yang digunakan:

opp_table0/opp15
opp_table1/opp15

OPP opp0 sampai opp14 tetap dipertahankan.

Fitur

Repository ini menyediakan:

Auto Setup tools untuk VPS
Setup untuk VPS dengan SUDO/ROOT
Setup untuk VPS tanpa SUDO/ROOT
Unpack vendor_boot.img
Membaca Device Tree
Membaca CPU OPP stock
Mengubah frequency OPP maksimum
Pilihan untuk mengubah voltage
Voltage dapat diatur secara manual dalam µV
Menu navigasi K dan Y
Dapat kembali ke pengaturan sebelumnya
Summary konfigurasi sebelum build
Rebuild Device Tree
Repack vendor_boot.img
Rebuild AVB
Verifikasi image hasil
SHA256 output
**1. Clone Repository**

Clone repository:

cd ~
git clone https://github.com/RizkyXLoli/Auto-Overclock-X6840

Masuk ke folder:

cd ~/Auto-Overclock-X6840

Periksa isi repository:

ls -lah
**2. Pilih Setup VPS**

Repository menyediakan dua script setup VPS:

Auto-SetUp-VPS-SUDO.sh
Auto-SetUp-VPS-NO-SUDO.sh

Gunakan salah satu sesuai kemampuan VPS.

VPS dengan SUDO/ROOT

Gunakan:

Auto-SetUp-VPS-SUDO.sh
VPS tanpa SUDO/ROOT

Gunakan:

Auto-SetUp-VPS-NO-SUDO.sh

Jangan menjalankan kedua script setup secara bersamaan.

**3. VPS dengan SUDO/ROOT**

Masuk ke repository:

cd ~/Auto-Overclock-X6840

Berikan permission:

chmod +x Auto-SetUp-VPS-SUDO.sh

Jalankan:

./Auto-SetUp-VPS-SUDO.sh

Ikuti proses setup sampai selesai.

Script ini ditujukan untuk VPS yang menyediakan akses
sudo/root sesuai kebutuhan setup.

**4. VPS tanpa SUDO/ROOT**

Masuk ke repository:

cd ~/Auto-Overclock-X6840

Berikan permission:

chmod +x Auto-SetUp-VPS-NO-SUDO.sh

Jalankan:

./Auto-SetUp-VPS-NO-SUDO.sh

Gunakan script ini untuk VPS yang tidak menyediakan akses
sudo/root.

Ikuti proses setup sampai selesai.

**5. Pemeriksaan Tools**

Setelah setup selesai, pastikan script Auto Overclock tersedia:

cd ~/Auto-Overclock
ls -lh X6840-Auto-OC-Builder-v2.sh

Periksa syntax:

bash -n X6840-Auto-OC-Builder-v2.sh

Jika tidak muncul error:

V2_FINAL_OK

atau tidak terdapat pesan error Bash, script dapat dilanjutkan
ke tahap pengujian.

Berikan permission:

chmod +x X6840-Auto-OC-Builder-v2.sh

Builder membutuhkan tools seperti:

mkbootimg
unpack_bootimg
mkdtboimg
fdtget
fdtput
avbtool
SUDAH OTOMATIS TERINSTALL SETELAH MENJALANKAN AUTO SETUP

Lokasi tools mengikuti konfigurasi yang digunakan oleh script
Auto Overclock.

**6. Persiapan vendor_boot.img**
6.1 Siapkan vendor_boot stock

Siapkan vendor_boot.img yang sesuai dengan firmware/perangkat.

Letakkan file tersebut langsung di:

~/Auto-Overclock/vendor_boot.img

Periksa:

ls -lh ~/Auto-Overclock/vendor_boot.img

Jika file ditemukan, builder akan mendeteksinya secara otomatis.

Tidak perlu memasukkan path vendor_boot.img melalui argument command.

**6.2 Backup vendor_boot stock**

Sangat disarankan membuat backup:

cd ~/Auto-Overclock

cp vendor_boot.img vendor_boot.stock.img

Periksa:

ls -lh vendor_boot*.img

Contoh:

vendor_boot.img
vendor_boot.stock.img

vendor_boot.stock.img merupakan cadangan sebelum modifikasi.

**7. Menjalankan Auto Overclock**

Masuk ke repository:

cd ~/Auto-Overclock

Jalankan:

./X6840-Auto-OC-Builder-v2.sh

Jika permission belum diberikan:

chmod +x X6840-Auto-OC-Builder-v2.sh

kemudian:

./X6840-Auto-OC-Builder-v2.sh

Builder akan mencari:

~/Auto-Overclock/vendor_boot.img

secara otomatis.

**8. Pengaturan CPU Frequency**

Builder akan membaca frequency stock dari Device Tree.

Contoh:

Little stock : 1800 MHz
Big stock    : 2000 MHz

Kemudian pengguna memasukkan tambahan frequency:

Tambahan OC [MHz]:

Contoh:

50

Maka target menjadi:

Little:

1800 + 50 = 1850 MHz

Big:

2000 + 50 = 2050 MHz

Rentang tambahan OC yang digunakan builder:

1-500 MHz

Contoh lain:

+100 MHz

Little : 1800 → 1900 MHz
Big    : 2000 → 2100 MHz
**9. Pengaturan Voltage**

Setelah frequency ditentukan, builder memberikan pilihan:

Ubah voltage juga?

[Y] Ya
[N] Tidak
[K] Kembali ke CPU Frequency
Jika memilih N

Voltage tetap menggunakan nilai stock.

Contoh:

Little:

Frequency : 1800 → 1850 MHz
Voltage   : 1006250 → 1006250 µV

Big:

Frequency : 2000 → 2050 MHz
Voltage   : 1087500 → 1087500 µV

Dalam kondisi ini voltage tidak dinaikkan.

Jika memilih Y

Pengguna dapat menentukan voltage sendiri.

Voltage dimasukkan dalam satuan:

µV

Contoh:

Little voltage [µV]: 1010000
Big voltage [µV]: 1090000

Maka:

Little:

1006250 → 1010000 µV

Big:

1087500 → 1090000 µV

Nilai yang dimasukkan merupakan nilai absolut, bukan
tambahan voltage.

Contoh:

1010000

berarti:

1010000 µV

bukan:

stock + 1010000 µV
**10. Navigasi K dan Y**

Builder menggunakan navigasi:

Y = Lanjut
N = Tidak
K = Kembali

Tidak menggunakan tombol B sebagai navigasi.

Dari Frequency

Contoh:

[K] Kembali
[Y] Lanjut

Pilihan [K/Y]:

Gunakan:

Y

untuk melanjutkan.

Gunakan:

K

untuk kembali.

Dari Voltage

Tersedia:

[Y] Ya
[N] Tidak
[K] Kembali ke CPU Frequency

Jika pengguna sedang mengatur voltage lalu ingin mengganti
CPU frequency, pilih:

K

Builder akan kembali ke menu CPU Frequency.

Dari Summary

Tersedia:

[K] Kembali ke Voltage
[Y] Build

Jika konfigurasi belum benar:

K

Jika konfigurasi sudah benar:

Y
**11. Konfigurasi Akhir**

Sebelum build, builder menampilkan Summary.

Contoh:

================================================
KONFIGURASI AKHIR
================================================

Little Cluster
  Frequency : 1800 → 1850 MHz
  Voltage   : 1006250 → 1010000 µV

Big Cluster
  Frequency : 2000 → 2050 MHz
  Voltage   : 1087500 → 1090000 µV

Hanya opp15 yang akan diubah.
opp0-opp14 tetap stock.

[K] Kembali ke Voltage
[Y] Build

Periksa:

Frequency
Voltage
Target OPP

Jika sudah benar, pilih:

Y

Jika ingin melakukan perubahan, pilih:

K
12. Build

Setelah memilih Y, builder melakukan proses:

[4/8] Menerapkan konfigurasi ke tabel OPP CPU...
[5/8] Membangun ulang tabel DT Android...
[6/8] Membangun ulang vendor_boot...
[7/8] Membangun ulang AVB footer...
[8/8] Verifikasi akhir...

Secara umum proses terdiri dari:

vendor_boot.img
      |
      v
Unpack
      |
      v
Device Tree
      |
      v
Baca CPU OPP
      |
      v
Modifikasi opp15
      |
      v
Build DT
      |
      v
Repack vendor_boot
      |
      v
Rebuild AVB
      |
      v
Verifikasi
**13. Verifikasi**

Builder melakukan verifikasi terhadap image hasil build.

Salah satu hasil yang ditampilkan:

Frekuensi maksimum akhir:

  opp_table0 : 1850 MHz
  opp_table1 : 2050 MHz

Jika voltage diubah, property opp-microvolt juga dapat
diperiksa.

Contoh:

=== opp_table0/opp15 ===
opp-hz       : 0 6e44c280
opp-microvolt: 1010000

=== opp_table1/opp15 ===
opp-hz       : 0 7a308480
opp-microvolt: 1090000

Nilai hexadecimal opp-hz dapat dikonversi menjadi frequency
dalam MHz untuk memastikan hasil sesuai konfigurasi.

**14. Output**

Image hasil build disimpan di:

~/Auto-Overclock/output/

Contoh:

output/
├── vendor_boot_OC+50MHz.img
├── vendor_boot_OC+100MHz.img
└── vendor_boot_OC+165MHz.img

Nama file mengikuti konfigurasi OverClock yang dibuat.

SHA256 image juga ditampilkan setelah proses build.

Periksa secara manual:

sha256sum output/vendor_boot_OC+100MHz.img

Sesuaikan nama file dengan image yang dibuat.

**15. Backup**

Sebelum melakukan modifikasi, selalu simpan:

vendor_boot.img
vendor_boot.stock.img

Jangan menghapus image stock sampai image hasil pengujian
dipastikan aman dan stabil.

Sebaiknya simpan juga SHA256:

sha256sum vendor_boot.img
sha256sum vendor_boot.stock.img
**16. Keterbatasan**

Builder ini dikembangkan berdasarkan struktur Device Tree
Infinix Smart 20 (X6840).

Target OPP:

/opp_table0/opp15
/opp_table1/opp15

Karena itu script ini tidak otomatis universal untuk semua
perangkat MediaTek atau semua perangkat Android 16.

Perangkat lain dapat memiliki:

Nama OPP table berbeda
Jumlah OPP berbeda
Jumlah CPU cluster berbeda
Struktur Device Tree berbeda
Lokasi DTB berbeda
Format vendor_boot berbeda
Property OPP berbeda
Implementasi DVFS berbeda

Jangan menggunakan builder X6840 pada perangkat lain tanpa
memeriksa Device Tree dan struktur OPP perangkat tersebut.

**17. Peringatan**

Overclock dapat menyebabkan:

Bootloop
Random reboot
Kernel crash
Freeze
Aplikasi/game crash
Suhu meningkat
Konsumsi daya meningkat
Ketidakstabilan sistem

Perubahan voltage juga dapat meningkatkan risiko terhadap
stabilitas dan hardware.

Gunakan konfigurasi secara bertahap.

Jangan langsung menggunakan nilai OC ekstrem.

Selalu simpan vendor_boot.img stock sebagai backup.

**18. Disclaimer**

KERUSAKAN PERANGKAT AKIBAT OVERCLOCK SEPENUHNYA SALAH PENGGUNA
**KALAU TIDAK TAHU ATUR VOLTASE SEBAIKNYA CARI TAHU DULU**
Penggunaan tool dan konfigurasi overclock dilakukan atas risiko
pengguna sendiri.
Pembuat tidak bertanggung jawab atas:

Bootloop
Kehilangan data
Kerusakan software
Ketidakstabilan sistem
Kerusakan hardware

yang mungkin terjadi akibat penggunaan project ini.

P
Author  : Rizky X Loli

Target pengembangan:
Infinix Smart 20 (X6840)
Platform:
MediaTek
Target:
CPU OPP
Method:
Modifikasi CPU OPP pada Device Tree vendor_boot
**TOOLS INI BISA DIJALANKAN DI VPS, TERMUX? COBA AJA SENDIRI, SAYA BELUM COBA DI TERMUX"
